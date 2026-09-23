"""Base scraper class for all job scrapers."""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import List, Dict, Optional
from uuid import uuid4
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class BaseScraper(ABC):
    """Abstract base class for all job scrapers."""

    def __init__(self, source_name: str):
        self.source_name = source_name
        self.scraped_jobs: List[Dict] = []
        self.errors: List[str] = []

    @abstractmethod
    def scrape(self) -> List[Dict]:
        """Scrape jobs from the source. Must be implemented by subclasses."""
        pass

    def _create_job_dict(
        self,
        title: str,
        company: str,
        location: str,
        category: str,
        description: str,
        deadline: Optional[datetime] = None,
        job_type: Optional[str] = None,
        salary_min: Optional[str] = None,
        salary_max: Optional[str] = None,
        required_skills: Optional[List[str]] = None,
        min_years: Optional[int] = None,
        max_years: Optional[int] = None,
        apply_link: Optional[str] = None,
    ) -> Dict:
        """Create a standardized job dictionary."""
        return {
            "id": str(uuid4()),
            "title": title.strip(),
            "company": company.strip(),
            "location": location.strip(),
            "category": category.lower(),
            "description": description.strip(),
            "source": self.source_name,
            "sourceType": "scraped",
            "postedDate": datetime.now().isoformat(),
            "deadline": deadline.isoformat() if deadline else None,
            "jobType": job_type.lower() if job_type else None,
            "salaryMin": salary_min,
            "salaryMax": salary_max,
            "requiredSkills": required_skills or [],
            "minYearsExperience": min_years,
            "maxYearsExperience": max_years,
            "applyLink": apply_link,
            "scrapedAt": datetime.now().isoformat(),
            "postedBy": None,
            "status": "pending",
            "viewCount": 0,
            "applicationCount": 0,
            "createdAt": datetime.now().isoformat(),
        }

    def _map_category(self, raw_category: str) -> str:
        """Map raw category from source to standard categories."""
        category_mapping = {
            "it": "it",
            "software": "it",
            "programming": "it",
            "technology": "it",
            "finance": "finance",
            "accounting": "finance",
            "bank": "bank",
            "banking": "bank",
            "government": "govt",
            "govt": "govt",
            "public": "govt",
            "ngo": "ngo",
            "nonprofit": "ngo",
            "healthcare": "healthcare",
            "medical": "healthcare",
            "education": "education",
            "teaching": "education",
            "sales": "sales",
            "marketing": "marketing",
            "operations": "operations",
            "hr": "hr",
            "human resources": "hr",
        }

        normalized = raw_category.lower().strip()
        return category_mapping.get(normalized, "other")

    def log_error(self, error: str):
        """Log an error."""
        self.errors.append(error)
        logger.error(f"[{self.source_name}] {error}")

    def log_info(self, message: str):
        """Log info message."""
        logger.info(f"[{self.source_name}] {message}")

    def get_stats(self) -> Dict:
        """Get scraping statistics."""
        return {
            "source": self.source_name,
            "total_jobs_scraped": len(self.scraped_jobs),
            "errors": len(self.errors),
            "timestamp": datetime.now().isoformat(),
        }
