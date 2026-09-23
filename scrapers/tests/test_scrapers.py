import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google.api_core.exceptions import AlreadyExists  # noqa: E402

from base_scraper import BaseScraper  # noqa: E402
from bdjobs_scraper import BDJobsScraper, parse_experience, parse_ng_state  # noqa: E402
from firestore_ingestion import FirestoreIngestion, job_doc_id  # noqa: E402


class _Scraper(BaseScraper):
    def scrape(self):
        return []


class _FakeDoc:
    def __init__(self, store, doc_id):
        self.store, self.id = store, doc_id

    def create(self, data):
        if self.id in self.store:
            raise AlreadyExists("exists")
        self.store[self.id] = data


class _FakeCollection:
    def __init__(self, store):
        self.store = store

    def document(self, doc_id):
        return _FakeDoc(self.store, doc_id)


class _FakeDb:
    def __init__(self):
        self.store = {}

    def collection(self, name):
        return _FakeCollection(self.store)


def _ingestion():
    ingestion = FirestoreIngestion.__new__(FirestoreIngestion)
    ingestion.db = _FakeDb()
    ingestion.jobs_collection = "jobs"
    return ingestion


class JobTypeMappingTest(unittest.TestCase):
    def test_maps_free_text_to_app_enum_names(self):
        scraper = _Scraper("test")
        cases = {
            "Full-time": "fullTime",
            "Full Time": "fullTime",
            "part time": "partTime",
            "Contractual": "contract",
            "Internship": "internship",
            "Remote": None,
            None: None,
        }
        for raw, expected in cases.items():
            self.assertEqual(scraper._map_job_type(raw), expected, raw)

    def test_job_dict_uses_mapped_job_type(self):
        job = _Scraper("test")._create_job_dict("Dev", "Acme", "Dhaka", "it", "", job_type="Full-time")
        self.assertEqual(job["jobType"], "fullTime")


class CategoryGuessTest(unittest.TestCase):
    def test_guesses_from_whole_words(self):
        scraper = _Scraper("test")
        cases = {
            "Probationary Unit Officer (Nobin Program) Grameen Shakti": "other",
            "Head of IT, Acme Ltd": "it",
            "Senior Software Engineer": "it",
            "Accounts Executive, B & T Group": "finance",
            "Relationship Manager, Dutch-Bangla Bank PLC": "bank",
            "Medical Promotion Officer, Square Pharmaceuticals": "healthcare",
            "Sr. Sales & Marketing Executive": "marketing",
            "Item Checker": "other",
        }
        for text, expected in cases.items():
            self.assertEqual(scraper._guess_category(text), expected, text)


class IngestionTest(unittest.TestCase):
    def _job(self, **overrides):
        job = _Scraper("bdjobs")._create_job_dict(
            "Flutter Developer", "Acme Ltd", "Dhaka", "it", "Build apps",
            apply_link="https://jobs.bdjobs.com/details/1",
        )
        job.update(overrides)
        return job

    def test_same_posting_is_stored_once_across_runs(self):
        ingestion = _ingestion()
        first = ingestion.ingest_jobs([self._job()], "bdjobs")
        second = ingestion.ingest_jobs([self._job()], "bdjobs")

        self.assertEqual(first["inserted"], 1)
        self.assertEqual(second["inserted"], 0)
        self.assertEqual(second["duplicates"], 1)
        self.assertEqual(len(ingestion.db.store), 1)

    def test_stored_job_is_pending_without_the_temporary_id(self):
        ingestion = _ingestion()
        ingestion.ingest_jobs([self._job()], "bdjobs")
        stored = next(iter(ingestion.db.store.values()))

        self.assertEqual(stored["status"], "pending")
        self.assertNotIn("id", stored)

    def test_doc_id_falls_back_to_title_and_company_without_a_link(self):
        a = job_doc_id({"title": "Officer ", "company": "Sonali Bank", "applyLink": None}, "newspaper")
        b = job_doc_id({"title": "officer", "company": "sonali bank", "applyLink": "Newspaper - x"}, "newspaper")
        c = job_doc_id({"title": "Clerk", "company": "Sonali Bank"}, "newspaper")
        self.assertEqual(a, b)
        self.assertNotEqual(a, c)

    def test_different_links_are_different_jobs(self):
        ingestion = _ingestion()
        ingestion.ingest_jobs([self._job(), self._job(applyLink="https://jobs.bdjobs.com/details/2")], "bdjobs")
        self.assertEqual(len(ingestion.db.store), 2)

# Trimmed from the real https://bdjobs.com/h/jobs/ page (Sept 2026).
_BDJOBS_PAGE = """<html><head></head><body><app-root></app-root>
<script id="ng-state" type="application/json">{"1794969864":{"b":{"message":"Success","statuscode":"1",
"data":[{"Jobid":"1537195","AdType":"1","jobTitle":"Executive / Sr. Executive, Central Brand Management",
"companyName":"Nuvista Pharma PLC","deadline":"Oct 05, 2026","deadlineDB":"2026-10-05T00:00:00Z",
"publishDate":"2026-09-23T10:58:00Z","eduRec":"Master of Pharmacy (M.Pharm)\\n\\u003Cul\\u003E\\u003Cli\\u003EM. Pharm from any reputed university.\\u003C/li\\u003E\\u003C/ul\\u003E",
"experience":"2 to 4 years","location":"DOHS Mirpur","jobContext":null,"jobDescription":"","JobType":"FullTime",
"Vacancies":1,"Salary":"--","Cat_id":29},
{"Jobid":"1537184","jobTitle":"Accounts Executive","companyName":"B & T Group","deadlineDB":"2026-10-15T00:00:00Z",
"publishDate":"2026-09-23T10:56:00Z","experience":"NA","location":"Banani","jobContext":null,
"jobDescription":"","JobType":"Contract","Salary":"Tk. 15500 - 21500 (Monthly)","Cat_id":1}],
"premiumData":[{"Jobid":"1537117","jobTitle":"Head of Design & Development","companyName":"Univogue Sourcing Ltd.",
"deadlineDB":"2026-10-08T00:00:00Z","publishDate":"2026-09-23T09:37:00Z","experience":"12 to 15 years",
"location":"Uttara Sector 11","jobContext":"<p>Lead the design team.</p>","JobType":"FullTime","Salary":"--","Cat_id":18}],
"common":{"total_records_found":6440,"showd":"1","totalpages":129,"total_vacancies":23412}},
"h":{},"s":200,"st":"OK","u":"https://api.bdjobs.com/Jobs/api/JobSearch/GetJobSearch","rt":"json"},
"bannerConfig":{"home":{}}}</script></body></html>"""


class BDJobsParsingTest(unittest.TestCase):
    def test_reads_regular_and_premium_jobs_from_ng_state(self):
        items, total_pages = parse_ng_state(_BDJOBS_PAGE)
        self.assertEqual(total_pages, 129)
        self.assertEqual([i["Jobid"] for i in items], ["1537117", "1537195", "1537184"])

    def test_missing_ng_state_is_reported(self):
        with self.assertRaises(ValueError):
            parse_ng_state("<html><body>redesigned</body></html>")

    def test_converts_items_to_app_jobs(self):
        scraper = BDJobsScraper(max_pages=1, delay_seconds=0)
        items, _ = parse_ng_state(_BDJOBS_PAGE)
        seen = set()
        self.assertEqual(scraper._add_jobs(items, seen), 3)
        self.assertEqual(scraper._add_jobs(items, seen), 0)

        by_title = {j["title"]: j for j in scraper.scraped_jobs}
        pharma = by_title["Executive / Sr. Executive, Central Brand Management"]
        self.assertEqual(pharma["company"], "Nuvista Pharma PLC")
        self.assertEqual(pharma["location"], "DOHS Mirpur")
        self.assertEqual(pharma["category"], "healthcare")
        self.assertEqual(pharma["jobType"], "fullTime")
        self.assertEqual(pharma["deadline"], "2026-10-05T00:00:00+00:00")
        self.assertEqual(pharma["postedDate"], "2026-09-23T10:58:00+00:00")
        self.assertEqual((pharma["minYearsExperience"], pharma["maxYearsExperience"]), (2, 4))
        self.assertEqual(pharma["applyLink"], "https://jobs.bdjobs.com/jobdetails.asp?id=1537195")
        self.assertIn("M. Pharm from any reputed university.", pharma["description"])
        self.assertNotIn("<li>", pharma["description"])

        accounts = by_title["Accounts Executive"]
        self.assertEqual(accounts["category"], "finance")
        self.assertEqual(accounts["jobType"], "contract")
        self.assertEqual(accounts["salaryMin"], "Tk. 15500 - 21500 (Monthly)")
        self.assertIsNone(pharma["salaryMin"])

        self.assertEqual(by_title["Head of Design & Development"]["description"], "Lead the design team.")

    def test_parse_experience(self):
        self.assertEqual(parse_experience("2 to 4 years"), (2, 4))
        self.assertEqual(parse_experience("At least 1 years"), (1, None))
        self.assertEqual(parse_experience("NA"), (None, None))
        self.assertEqual(parse_experience(None), (None, None))


if __name__ == "__main__":
    unittest.main()
