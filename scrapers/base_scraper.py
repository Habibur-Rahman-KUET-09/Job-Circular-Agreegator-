"""Base scraper class for all job scrapers."""

from abc import ABC, abstractmethod
from datetime import datetime
from typing import List, Dict, Optional
from uuid import uuid4
import logging
import re

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
        posted_date: Optional[datetime] = None,
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
            "postedDate": (posted_date or datetime.now()).isoformat(),
            "deadline": deadline.isoformat() if deadline else None,
            "jobType": self._map_job_type(job_type),
            "salaryMin": salary_min,
            "salaryMax": salary_max,
            "requiredSkills": required_skills or [],
            "minYearsExperience": min_years,
            "maxYearsExperience": max_years,
            "applyLink": apply_link,
            "scrapedAt": datetime.now().isoformat(),
            "postedBy": None,
            "status": "approved",
            "viewCount": 0,
            "applicationCount": 0,
            "createdAt": datetime.now().isoformat(),
        }

    def _map_job_type(self, raw_job_type: Optional[str]) -> Optional[str]:
        """Map free-text job type to the app's JobType enum names (e.g. fullTime)."""
        if not raw_job_type:
            return None
        normalized = "".join(ch for ch in raw_job_type.lower() if ch.isalpha())
        job_type_mapping = {
            "fulltime": "fullTime",
            "permanent": "fullTime",
            "parttime": "partTime",
            "contract": "contract",
            "contractual": "contract",
            "temporary": "temporary",
            "internship": "internship",
            "intern": "internship",
            "freelance": "freelance",
        }
        return job_type_mapping.get(normalized)

    # Regexes checked in order, so "bank" wins over the broader finance terms.
    # Word boundaries matter: a bare "it" would match "unit" or "item".
    _CATEGORY_PATTERNS = [
        ("bank", r"\bbank"),
        ("ngo", r"\bngo\b|\bfoundation\b|\bunicef\b|\bbrac\b"),
        ("govt", r"\bgovernment\b|\bministry\b|\bdirectorate\b|\bpublic service\b"),
        ("it", r"\bit\b|\bsoftware\b|\bdeveloper\b|\bprogrammer\b|\bnetwork\b|\bdevops\b|\bweb\b"),
        ("finance", r"\baccount|\bfinanc|\baudit|\btax\b|\bvat\b"),
        ("healthcare", r"\bdoctor|\bnurse|\bmedical\b|\bpharm|\bhospital|\bclinic|\bdental\b|\bhealth"),
        ("education", r"\bteacher|\blecturer|\bschool|\buniversity|\bcollege|\btutor"),
        ("hr", r"\bhuman resource|\bhr\b|\brecruit|\btalent"),
        ("marketing", r"\bmarketing\b|\bbrand"),
        ("sales", r"\bsales\b|\bbusiness development\b|\bshowroom"),
        ("operations", r"\boperation|\bsupply chain\b|\blogistic|\bprocurement\b|\bproduction\b"),
    ]

    def _guess_category(self, text: str) -> str:
        """Best-effort category from free text such as the title and company."""
        lowered = text.lower()
        for category, pattern in self._CATEGORY_PATTERNS:
            if re.search(pattern, lowered):
                return category
        return "other"

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
