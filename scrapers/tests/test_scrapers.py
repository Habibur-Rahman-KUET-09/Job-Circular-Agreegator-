import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google.api_core.exceptions import AlreadyExists  # noqa: E402

from base_scraper import BaseScraper  # noqa: E402
from bdjobs_scraper import BDJobsScraper, html_to_text, parse_details, parse_experience, parse_ng_state  # noqa: E402
from firestore_ingestion import FirestoreIngestion, job_doc_id  # noqa: E402
from run_scrapers import backfill_bdjobs_details, run_app_sources  # noqa: E402
from selector_scraper import SelectorScraper, parse_deadline  # noqa: E402


class _Scraper(BaseScraper):
    def scrape(self):
        return []


class _FakeDoc:
    def __init__(self, store, doc_id):
        self.store, self.id = store, doc_id
        self.reference = self

    def to_dict(self):
        return dict(self.store[self.id])

    def get(self):
        return self

    def update(self, data):
        self.store[self.id].update(data)

    def create(self, data, **kwargs):
        if self.id in self.store:
            raise AlreadyExists("exists")
        self.store[self.id] = data


class _FakeCollection:
    def __init__(self, store, filters=()):
        self.store, self.filters = store, filters

    def document(self, doc_id):
        return _FakeDoc(self.store, doc_id)

    def where(self, field, op, value):
        assert op == "=="
        return _FakeCollection(self.store, self.filters + ((field, value),))

    def stream(self):
        return [_FakeDoc(self.store, doc_id) for doc_id, data in list(self.store.items())
                if all(data.get(f) == v for f, v in self.filters)]


class _FakeDb:
    def __init__(self):
        self.stores = {"jobs": {}}

    @property
    def store(self):
        return self.stores["jobs"]

    def collection(self, name):
        return _FakeCollection(self.stores.setdefault(name, {}))


def _ingestion():
    ingestion = FirestoreIngestion.__new__(FirestoreIngestion)
    ingestion.db = _FakeDb()
    ingestion.jobs_collection = "jobs"
    ingestion.sources_collection = "scraperSources"
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

    def test_scraped_jobs_are_published_without_review(self):
        ingestion = _ingestion()
        ingestion.ingest_jobs([self._job()], "bdjobs")
        stored = next(iter(ingestion.db.store.values()))

        self.assertEqual(stored["status"], "approved")
        self.assertEqual(stored["sourceType"], "scraped")
        self.assertNotIn("id", stored)

    def test_approve_pending_scraped_leaves_manual_jobs_pending(self):
        ingestion = _ingestion()
        ingestion.db.store.update({
            "s1": {"sourceType": "scraped", "status": "pending"},
            "s2": {"sourceType": "scraped", "status": "rejected"},
            "m1": {"sourceType": "manual", "status": "pending"},
        })
        self.assertEqual(ingestion.approve_pending_scraped(), 1)
        self.assertEqual(ingestion.db.store["s1"]["status"], "approved")
        self.assertEqual(ingestion.db.store["s2"]["status"], "rejected")
        self.assertEqual(ingestion.db.store["m1"]["status"], "pending")

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
        scraper = BDJobsScraper(delay_seconds=0, fetch_details=False)
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


_SITE_PAGE = """<html><body><div class="list">
<div class="job-card"><h3><a href="/jobs/101">Senior Officer, IT</a></h3>
  <span class="org">Pubali Bank PLC</span><span class="place">Dhaka</span>
  <span class="deadline">Deadline: 30 Oct 2026</span></div>
<div class="job-card"><h3><a href="https://other.example/jobs/102">Sales   Executive</a></h3>
  <span class="org"></span><span class="deadline">Apply before 5/11/2026</span></div>
<div class="job-card"><h3><a href="/jobs/101">Senior Officer, IT</a></h3></div>
<div class="job-card"><p>No title here</p></div>
</div></body></html>"""

_SITE_CONFIG = {
    "name": "Example Jobs",
    "listUrl": "https://jobs.example.com/latest",
    "itemSelector": "div.job-card",
    "titleSelector": "h3 a",
    "companySelector": ".org",
    "locationSelector": ".place",
    "deadlineSelector": ".deadline",
    "enabled": True,
}


class _FakeResponse:
    def __init__(self, text, url, status=200):
        self.text, self.url, self.status_code = text, url, status

    def raise_for_status(self):
        if self.status_code >= 400:
            import requests
            raise requests.HTTPError(f"{self.status_code}")


class _FakeSession:
    def __init__(self, pages):
        self.pages, self.headers = pages, {}

    def get(self, url, timeout=None):
        return _FakeResponse(self.pages.get(url, ""), url, 200 if url in self.pages else 404)


class SelectorScraperTest(unittest.TestCase):
    def _scrape(self, config=None, pages=None):
        config = config or _SITE_CONFIG
        session = _FakeSession(pages if pages is not None else {config["listUrl"]: _SITE_PAGE})
        scraper = SelectorScraper("src1", config, session=session)
        return scraper, scraper.scrape()

    def test_reads_each_job_card(self):
        scraper, jobs = self._scrape()
        self.assertEqual([j["title"] for j in jobs], ["Senior Officer, IT", "Sales Executive"])
        officer, sales = jobs
        self.assertEqual(officer["applyLink"], "https://jobs.example.com/jobs/101")
        self.assertEqual(officer["company"], "Pubali Bank PLC")
        self.assertEqual(officer["location"], "Dhaka")
        self.assertEqual(officer["category"], "bank")
        self.assertEqual(officer["deadline"][:10], "2026-10-30")
        self.assertEqual(officer["source"], "Example Jobs")
        self.assertEqual(officer["status"], "approved")
        # Missing company falls back to the site's name; a day-first date is read.
        self.assertEqual(sales["company"], "Example Jobs")
        self.assertEqual(sales["location"], "Not specified")
        self.assertEqual(sales["applyLink"], "https://other.example/jobs/102")
        self.assertEqual(sales["deadline"][:10], "2026-11-05")
        self.assertEqual(scraper.key, "site:src1")

    def test_title_defaults_to_first_link(self):
        config = {k: v for k, v in _SITE_CONFIG.items() if k in ("name", "listUrl", "itemSelector")}
        _, jobs = self._scrape(config)
        self.assertEqual([j["title"] for j in jobs], ["Senior Officer, IT", "Sales Executive"])
        self.assertEqual(jobs[0]["applyLink"], "https://jobs.example.com/jobs/101")

    def test_unreachable_page_and_bad_selector_are_errors(self):
        scraper, jobs = self._scrape(pages={})
        self.assertEqual(jobs, [])
        self.assertIn("Could not load", scraper.errors[0])

        scraper, jobs = self._scrape(dict(_SITE_CONFIG, itemSelector="div[["))
        self.assertEqual(jobs, [])
        self.assertIn("Could not read the page", scraper.errors[0])

    def test_parse_deadline(self):
        self.assertEqual(parse_deadline("Deadline: 30 Oct 2026").date().isoformat(), "2026-10-30")
        self.assertIsNone(parse_deadline("Not mentioned"))
        self.assertIsNone(parse_deadline(""))


class AppSourcesRunTest(unittest.TestCase):
    def test_runs_enabled_sources_and_records_results(self):
        import run_scrapers

        ingestion = _ingestion()
        ingestion.db.stores["scraperSources"] = {
            "good": dict(_SITE_CONFIG),
            "broken": dict(_SITE_CONFIG, name="Broken", listUrl="https://down.example/"),
            "off": dict(_SITE_CONFIG, name="Off", enabled=False),
        }
        pages = {_SITE_CONFIG["listUrl"]: _SITE_PAGE}
        original = run_scrapers.SelectorScraper
        run_scrapers.SelectorScraper = lambda sid, cfg: original(sid, cfg, session=_FakeSession(pages))
        try:
            found = run_app_sources(ingestion)
            again = run_app_sources(ingestion)
        finally:
            run_scrapers.SelectorScraper = original

        self.assertEqual((found, again), (2, 2))
        self.assertEqual(len(ingestion.db.store), 2)  # the second run stored nothing new
        sources = ingestion.db.stores["scraperSources"]
        self.assertEqual(sources["good"]["lastJobCount"], 2)
        self.assertIsNone(sources["good"]["lastError"])
        self.assertEqual(sources["broken"]["lastJobCount"], 0)
        self.assertIn("Could not load", sources["broken"]["lastError"])
        self.assertNotIn("lastRunAt", sources["off"])


# Trimmed from the real details API response for job 1535146 (Sept 2026).
_DETAILS = {
    "JobId": "1535146", "JobFound": "True", "JobTitle": "Assistant Manager / Senior Sales Executive",
    "JobVacancies": "2",
    "JobDescription": "<p>Almadina Abashon Ltd. is looking for a Senior Sales Executive.</p>"
                      "<p><strong>Key Responsibilities:</strong></p><ul><li><p>Sell plots and land</p></li>"
                      "<li><p>Build relationships with clients</p></li></ul>",
    "JobNature": "Full Time", "JobWorkPlace": "Work at office", "EducationRequirements": "",
    "SkillsRequired": "Customer Relationship,Customer Service,Sales & Marketing",
    "experience": "<ul><li>3 to 5 years</li><li>The applicants should have experience in: Real Estate</li></ul>",
    "AdditionJobRequirements": "<ul><li>Age 24 to 50 years</li><li>Only Male</li></ul>",
    "JobLocation": "Dhaka (Mirpur 2)", "CompanyBusiness": "A real estate company.\r\n\r\nWhy Join Us?",
    "CompanyAddress": "Plot C-11, Mirpur-2, Dhaka", "CompanyWeb": "",
    "JobOtherBenifits": "<ul><li>Mobile bill</li><li>Salary Review: Yearly</li></ul>",
    "JobSalaryRangeText": "Tk. 30000 - 40000 (Monthly)",
}


class _JsonResponse:
    def __init__(self, payload=None, text="", status=200):
        self.payload, self.text, self.status_code = payload, text, status

    def raise_for_status(self):
        if self.status_code >= 400:
            import requests
            raise requests.HTTPError(str(self.status_code))

    def json(self):
        return self.payload


class _BDJobsSession:
    def __init__(self, details_by_id, fail_ids=()):
        self.details_by_id, self.fail_ids, self.headers = details_by_id, set(fail_ids), {}

    def get(self, url, params=None, timeout=None):
        if url == BDJobsScraper.LIST_URL:
            return _JsonResponse(text=_BDJOBS_PAGE)
        job_id = str(params["jobId"])
        if job_id in self.fail_ids:
            return _JsonResponse(status=503)
        details = self.details_by_id.get(job_id)
        if details is None:
            return _JsonResponse({"statuscode": "0", "data": [{"JobFound": "False"}]})
        return _JsonResponse({"statuscode": "0", "message": "Success", "data": [details]})


class BDJobsDetailsTest(unittest.TestCase):
    def test_parse_details_keeps_sections_as_readable_text(self):
        fields = parse_details(_DETAILS)
        sections = fields["details"]
        self.assertEqual(sections["responsibilities"],
                         "Almadina Abashon Ltd. is looking for a Senior Sales Executive.\n"
                         "Key Responsibilities:\n• Sell plots and land\n• Build relationships with clients")
        self.assertEqual(sections["experience"],
                         "• 3 to 5 years\n• The applicants should have experience in: Real Estate")
        self.assertEqual(sections["requirements"], "• Age 24 to 50 years\n• Only Male")
        self.assertEqual(sections["benefits"], "• Mobile bill\n• Salary Review: Yearly")
        self.assertEqual(sections["company"], "A real estate company.\nWhy Join Us?")
        self.assertNotIn("education", sections)
        self.assertEqual(fields["description"], sections["responsibilities"])
        self.assertEqual(fields["requiredSkills"], ["Customer Relationship", "Customer Service", "Sales & Marketing"])
        self.assertEqual(fields["salaryMin"], "Tk. 30000 - 40000 (Monthly)")
        self.assertEqual(fields["vacancies"], "2")
        self.assertEqual(fields["workplace"], "Work at office")
        self.assertEqual(fields["companyAddress"], "Plot C-11, Mirpur-2, Dhaka")
        self.assertNotIn("companyWebsite", fields)
        self.assertTrue(fields["detailsFetched"])

    def test_nested_lists_fold_into_their_item(self):
        self.assertEqual(html_to_text("<ul><li>Skills<ul><li>Excel</li></ul></li></ul>"), "• Skills • Excel")

    def test_scrape_adds_details_and_flags_failures_for_retry(self):
        scraper = BDJobsScraper(delay_seconds=0)
        scraper.session = _BDJobsSession({"1537195": _DETAILS}, fail_ids={"1537184"})
        jobs = {j["applyLink"].rsplit("=", 1)[1]: j for j in scraper.scrape()}

        self.assertTrue(jobs["1537195"]["detailsFetched"])
        self.assertFalse(jobs["1537195"]["detailsPending"])
        self.assertIn("Sell plots and land", jobs["1537195"]["description"])
        # Request failed: retried by a later run.
        self.assertTrue(jobs["1537184"]["detailsPending"])
        self.assertNotIn("detailsFetched", jobs["1537184"])
        # Gone from bdjobs: not retried.
        self.assertFalse(jobs["1537117"]["detailsFetched"])
        self.assertFalse(jobs["1537117"]["detailsPending"])

    def test_stored_job_gets_details_once(self):
        ingestion = _ingestion()
        job = BDJobsScraper(delay_seconds=0, fetch_details=False)._to_job(
            {"Jobid": "1535146", "jobTitle": "Sales", "companyName": "Almadina"})
        ingestion.ingest_jobs([job], "bdjobs")
        detailed = dict(job, **parse_details(_DETAILS), detailsPending=False)

        self.assertEqual(ingestion.ingest_jobs([detailed], "bdjobs")["updated"], 1)
        self.assertEqual(ingestion.ingest_jobs([detailed], "bdjobs")["duplicates"], 1)
        stored = next(iter(ingestion.db.store.values()))
        self.assertIn("Sell plots and land", stored["description"])
        self.assertEqual(stored["status"], "approved")

    def test_backfill_fills_pending_and_older_jobs(self):
        ingestion = _ingestion()
        link = BDJobsScraper.DETAIL_URL.format
        ingestion.db.store.update({
            "pending": {"source": "bdjobs", "applyLink": link(job_id="1535146"), "detailsPending": True},
            "old": {"source": "bdjobs", "applyLink": link(job_id="1535146")},
            "done": {"source": "bdjobs", "applyLink": link(job_id="1"), "detailsFetched": True},
            "gone": {"source": "bdjobs", "applyLink": link(job_id="999"), "detailsPending": True},
        })
        original = BDJobsScraper.__init__

        def patched(self, *args, **kwargs):
            original(self, delay_seconds=0)
            self.session = _BDJobsSession({"1535146": _DETAILS})

        BDJobsScraper.__init__ = patched
        try:
            self.assertEqual(backfill_bdjobs_details(ingestion), 1)  # regular run: pending only
            self.assertNotIn("details", ingestion.db.store["old"])
            self.assertFalse(ingestion.db.store["gone"]["detailsFetched"])
            self.assertEqual(backfill_bdjobs_details(ingestion, scan_all=True), 1)  # one-off: older too
        finally:
            BDJobsScraper.__init__ = original

        self.assertTrue(ingestion.db.store["pending"]["detailsFetched"])
        self.assertFalse(ingestion.db.store["pending"]["detailsPending"])
        self.assertIn("responsibilities", ingestion.db.store["old"]["details"])
        self.assertNotIn("details", ingestion.db.store["done"])


if __name__ == "__main__":
    unittest.main()
