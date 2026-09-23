"""Manager to orchestrate all job scrapers and coordinate ingestion."""

from typing import List, Dict
from datetime import datetime
import logging
from bdjobs_scraper import BDJobsScraper
from chakri_scraper import ChakriScraper
from newspaper_scraper import NewspaperScraper
from firestore_ingestion import FirestoreIngestion

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ScraperManager:
    """Orchestrate all scrapers and manage ingestion into Firestore."""

    def __init__(self, pdf_directory: str = "./newspapers"):
        """Initialize scraper manager."""
        self.pdf_directory = pdf_directory
        self.scrapers = {
            "bdjobs": BDJobsScraper(),
            "chakri": ChakriScraper(),
            "newspaper": NewspaperScraper(pdf_directory=pdf_directory),
        }
        self.ingestion = FirestoreIngestion()
        self.run_stats = {}

    def run_all(self, approve_automatically: bool = False) -> Dict:
        """Run all scrapers and ingest jobs into Firestore."""
        try:
            logger.info("Starting complete scraping cycle")
            start_time = datetime.now()

            total_stats = {
                "start_time": start_time.isoformat(),
                "scrapers": {},
                "ingestion": {
                    "total": 0,
                    "inserted": 0,
                    "duplicates": 0,
                    "updated": 0,
                    "errors": 0,
                },
                "approval": {
                    "total": 0,
                    "approved": 0,
                    "errors": 0,
                } if approve_automatically else None,
            }

            # Run each scraper
            for scraper_name, scraper in self.scrapers.items():
                try:
                    logger.info(f"Running {scraper_name} scraper")
                    jobs = scraper.scrape()
                    stats = scraper.get_stats()
                    stats["jobs_count"] = len(jobs)
                    total_stats["scrapers"][scraper_name] = stats

                    # Ingest jobs into Firestore
                    if jobs:
                        ingestion_result = self.ingestion.ingest_jobs(jobs, scraper_name)
                        # Aggregate ingestion stats
                        for key in ["total", "inserted", "duplicates", "updated", "errors"]:
                            total_stats["ingestion"][key] += ingestion_result.get(key, 0)

                except Exception as e:
                    logger.error(f"Error running {scraper_name} scraper: {str(e)}")
                    total_stats["scrapers"][scraper_name] = {
                        "error": str(e),
                        "jobs_count": 0,
                    }

            # Auto-approve jobs if requested
            if approve_automatically:
                try:
                    pending_jobs = self.ingestion.get_pending_jobs(limit=1000)
                    if pending_jobs:
                        job_ids = [job["id"] for job in pending_jobs]
                        approval_result = self.ingestion.approve_jobs(job_ids)
                        total_stats["approval"] = approval_result
                except Exception as e:
                    logger.error(f"Error auto-approving jobs: {str(e)}")

            end_time = datetime.now()
            total_stats["end_time"] = end_time.isoformat()
            total_stats["duration_seconds"] = (end_time - start_time).total_seconds()

            logger.info(f"Scraping cycle complete. Stats: {total_stats}")
            self.run_stats = total_stats

            return total_stats

        except Exception as e:
            logger.error(f"Unexpected error during scraping cycle: {str(e)}")
            return {
                "error": str(e),
                "start_time": datetime.now().isoformat(),
            }

    def run_single_scraper(self, scraper_name: str) -> Dict:
        """Run a single scraper and ingest jobs."""
        try:
            if scraper_name not in self.scrapers:
                logger.error(f"Unknown scraper: {scraper_name}")
                return {"error": f"Unknown scraper: {scraper_name}"}

            logger.info(f"Running {scraper_name} scraper")
            scraper = self.scrapers[scraper_name]
            jobs = scraper.scrape()

            stats = {
                "scraper": scraper_name,
                "scraper_stats": scraper.get_stats(),
                "jobs_count": len(jobs),
            }

            if jobs:
                ingestion_result = self.ingestion.ingest_jobs(jobs, scraper_name)
                stats["ingestion"] = ingestion_result

            logger.info(f"{scraper_name} scraper complete. Stats: {stats}")
            return stats

        except Exception as e:
            logger.error(f"Error running {scraper_name} scraper: {str(e)}")
            return {
                "error": str(e),
                "scraper": scraper_name,
            }

    def get_pending_jobs_for_review(self, limit: int = 100) -> List[Dict]:
        """Get pending jobs for moderator review."""
        try:
            return self.ingestion.get_pending_jobs(limit=limit)
        except Exception as e:
            logger.error(f"Error retrieving pending jobs: {str(e)}")
            return []

    def approve_jobs(self, job_ids: List[str]) -> Dict:
        """Approve multiple jobs."""
        return self.ingestion.approve_jobs(job_ids)

    def reject_jobs(self, job_ids: List[str], reason: str) -> Dict:
        """Reject multiple jobs."""
        return self.ingestion.reject_jobs(job_ids, reason)

    def cleanup_expired_jobs(self, days: int = 90) -> Dict:
        """Remove expired jobs."""
        return self.ingestion.cleanup_expired_jobs(days=days)

    def get_last_run_stats(self) -> Dict:
        """Get statistics from last run."""
        return self.run_stats


if __name__ == "__main__":
    manager = ScraperManager(pdf_directory="./newspapers")

    # Run all scrapers
    stats = manager.run_all(approve_automatically=False)
    print(f"\nScraping cycle complete!")
    print(f"Total inserted: {stats['ingestion']['inserted']}")
    print(f"Total duplicates: {stats['ingestion']['duplicates']}")
    print(f"Duration: {stats['duration_seconds']} seconds")

    # Check pending jobs
    pending = manager.get_pending_jobs_for_review(limit=5)
    print(f"\nPending jobs for review: {len(pending)}")
    for job in pending:
        print(f"  - {job.get('title')} at {job.get('company')}")
