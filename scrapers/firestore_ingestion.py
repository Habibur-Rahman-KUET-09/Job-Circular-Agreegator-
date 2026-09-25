"""Firestore ingestion layer for storing scraped jobs, skipping ones already stored."""

from datetime import datetime, timedelta
from typing import List, Dict, Optional
import firebase_admin
from firebase_admin import credentials, firestore
import logging
import hashlib

from google.api_core.exceptions import AlreadyExists

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def job_doc_id(job: Dict, source: str) -> str:
    """Stable Firestore ID so the same posting maps to the same document every run."""
    link = (job.get("applyLink") or "").strip()
    if link.startswith("http"):
        key = f"{source}|{link}"
    else:
        key = f"{source}|{job.get('title', '').strip().lower()}|{job.get('company', '').strip().lower()}"
    return hashlib.sha1(key.encode("utf-8")).hexdigest()[:20]


class FirestoreIngestion:
    """Handle storing scraped jobs in Firestore with duplicate detection."""

    def __init__(self, credentials_path: Optional[str] = None):
        """Initialize Firestore connection."""
        try:
            # Try to get existing app
            self.app = firebase_admin.get_app()
        except ValueError:
            # App doesn't exist, initialize it
            if credentials_path:
                cred = credentials.Certificate(credentials_path)
                self.app = firebase_admin.initialize_app(cred)
            else:
                self.app = firebase_admin.initialize_app()

        self.db = firestore.client()
        self.jobs_collection = "jobs"

    def ingest_jobs(self, jobs: List[Dict], source: str) -> Dict:
        """Ingest a list of jobs into Firestore."""
        stats = {
            "total": len(jobs),
            "inserted": 0,
            "duplicates": 0,
            "updated": 0,
            "errors": 0,
        }

        logger.info(f"Starting ingestion of {len(jobs)} jobs from {source}")

        for job in jobs:
            try:
                result = self._ingest_single_job(job, source)
                if result == "inserted":
                    stats["inserted"] += 1
                elif result == "duplicate":
                    stats["duplicates"] += 1
                elif result == "updated":
                    stats["updated"] += 1
            except Exception as e:
                logger.error(f"Error ingesting job {job.get('title', 'Unknown')}: {str(e)}")
                stats["errors"] += 1

        logger.info(f"Ingestion complete. Stats: {stats}")
        return stats

    def _ingest_single_job(self, job: Dict, source: str) -> str:
        """Create the job unless it already exists; returns 'inserted' or 'duplicate'."""
        now = datetime.now().isoformat()
        job_data = {k: v for k, v in job.items() if k != "id"}
        job_data.update({
            "status": "pending",
            "source": source,
            "createdAt": now,
            "updatedAt": now,
        })
        doc_ref = self.db.collection(self.jobs_collection).document(job_doc_id(job, source))
        try:
            # create() fails if the document exists, so a re-scraped job never
            # overwrites a moderator's approve/reject decision.
            doc_ref.create(job_data, timeout=60)
        except AlreadyExists:
            return "duplicate"
        logger.info(f"Inserted job: {job['title']} ({doc_ref.id})")
        return "inserted"

    def approve_jobs(self, job_ids: List[str]) -> Dict:
        """Approve multiple jobs (moderator action)."""
        stats = {
            "total": len(job_ids),
            "approved": 0,
            "errors": 0,
        }

        for job_id in job_ids:
            try:
                self.db.collection(self.jobs_collection).document(job_id).update({
                    "status": "approved",
                    "updatedAt": datetime.now().isoformat(),
                })
                stats["approved"] += 1
            except Exception as e:
                logger.error(f"Error approving job {job_id}: {str(e)}")
                stats["errors"] += 1

        logger.info(f"Approval complete. Stats: {stats}")
        return stats

    def reject_jobs(self, job_ids: List[str], reason: str) -> Dict:
        """Reject multiple jobs (moderator action)."""
        stats = {
            "total": len(job_ids),
            "rejected": 0,
            "errors": 0,
        }

        for job_id in job_ids:
            try:
                self.db.collection(self.jobs_collection).document(job_id).update({
                    "status": "rejected",
                    "rejectionReason": reason,
                    "updatedAt": datetime.now().isoformat(),
                })
                stats["rejected"] += 1
            except Exception as e:
                logger.error(f"Error rejecting job {job_id}: {str(e)}")
                stats["errors"] += 1

        logger.info(f"Rejection complete. Stats: {stats}")
        return stats

    def get_pending_jobs(self, limit: int = 100) -> List[Dict]:
        """Get pending jobs for moderation."""
        try:
            docs = self.db.collection(self.jobs_collection) \
                .where("status", "==", "pending") \
                .limit(limit) \
                .stream()

            jobs = []
            for doc in docs:
                job = doc.to_dict()
                job["id"] = doc.id
                jobs.append(job)

            logger.info(f"Retrieved {len(jobs)} pending jobs")
            return jobs

        except Exception as e:
            logger.error(f"Error retrieving pending jobs: {str(e)}")
            return []

    def cleanup_expired_jobs(self, days: int = 90) -> Dict:
        """Remove jobs that are past their deadline by X days."""
        stats = {
            "total": 0,
            "deleted": 0,
            "errors": 0,
        }

        try:
            expired_date = datetime.now() - timedelta(days=days)

            docs = self.db.collection(self.jobs_collection) \
                .where("deadline", "<=", expired_date.isoformat()) \
                .where("status", "==", "approved") \
                .stream()

            for doc in docs:
                try:
                    self.db.collection(self.jobs_collection).document(doc.id).delete()
                    stats["deleted"] += 1
                except Exception as e:
                    logger.error(f"Error deleting job {doc.id}: {str(e)}")
                    stats["errors"] += 1

                stats["total"] += 1

            logger.info(f"Cleanup complete. Stats: {stats}")
            return stats

        except Exception as e:
            logger.error(f"Error during cleanup: {str(e)}")
            return stats


if __name__ == "__main__":
    ingestion = FirestoreIngestion()

    # Example: Get pending jobs
    pending = ingestion.get_pending_jobs(limit=10)
    print(f"Pending jobs: {len(pending)}")

    # Example: Approve jobs
    if pending:
        job_ids = [job["id"] for job in pending[:5]]
        result = ingestion.approve_jobs(job_ids)
        print(f"Approval result: {result}")
