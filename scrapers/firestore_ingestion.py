"""Firestore ingestion layer for storing scraped jobs with duplicate detection."""

from datetime import datetime, timedelta
from typing import List, Dict, Optional
import firebase_admin
from firebase_admin import credentials, firestore
import logging
from difflib import SequenceMatcher

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


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
        self.duplicate_threshold = 0.85  # 85% similarity = duplicate

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
        """Ingest a single job and return the result (inserted/duplicate/updated/error)."""
        try:
            # Check for duplicates
            duplicate_job = self._find_duplicate(job)

            if duplicate_job:
                logger.info(f"Found duplicate for job: {job['title']}")
                # Update existing job (increment view count, etc.)
                self._update_existing_job(duplicate_job['id'], job)
                return "duplicate"

            # Insert new job
            job_data = {
                **job,
                "status": "pending",
                "source": source,
                "createdAt": datetime.now().isoformat(),
                "updatedAt": datetime.now().isoformat(),
            }

            # Remove id if it's a temp uuid
            if "id" in job_data:
                job_data.pop("id")

            doc_ref = self.db.collection(self.jobs_collection).add(job_data)
            logger.info(f"Inserted job: {job['title']} with ID: {doc_ref[1].id}")
            return "inserted"

        except Exception as e:
            logger.error(f"Error ingesting job: {str(e)}")
            raise

    def _find_duplicate(self, job: Dict) -> Optional[Dict]:
        """Find a duplicate job in Firestore."""
        try:
            # Search for jobs with similar title and company from same source
            title = job.get("title", "")
            company = job.get("company", "")
            source = job.get("source", "")

            # Query jobs from same source and company within last 7 days
            seven_days_ago = datetime.now() - timedelta(days=7)

            query = self.db.collection(self.jobs_collection) \
                .where("source", "==", source) \
                .where("company", "==", company) \
                .where("createdAt", ">=", seven_days_ago.isoformat())

            docs = query.stream()

            for doc in docs:
                existing_job = doc.to_dict()
                existing_job["id"] = doc.id

                # Check title similarity
                similarity = self._calculate_similarity(
                    title,
                    existing_job.get("title", "")
                )

                if similarity >= self.duplicate_threshold:
                    return existing_job

            return None

        except Exception as e:
            logger.error(f"Error finding duplicate: {str(e)}")
            return None

    def _calculate_similarity(self, str1: str, str2: str) -> float:
        """Calculate similarity between two strings (0-1)."""
        matcher = SequenceMatcher(None, str1.lower(), str2.lower())
        return matcher.ratio()

    def _update_existing_job(self, job_id: str, new_job: Dict):
        """Update an existing job document."""
        try:
            update_data = {
                "updatedAt": datetime.now().isoformat(),
                "viewCount": firestore.Increment(1),
            }

            self.db.collection(self.jobs_collection).document(job_id).update(update_data)
            logger.info(f"Updated job: {job_id}")

        except Exception as e:
            logger.error(f"Error updating job {job_id}: {str(e)}")

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
