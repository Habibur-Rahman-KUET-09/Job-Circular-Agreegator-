import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google.api_core.exceptions import AlreadyExists  # noqa: E402

from base_scraper import BaseScraper  # noqa: E402
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


if __name__ == "__main__":
    unittest.main()
