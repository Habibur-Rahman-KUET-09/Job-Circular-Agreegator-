"""Scraper for bdjobs.com job listings."""

import re
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import requests
from bs4 import BeautifulSoup
from base_scraper import BaseScraper


class BDJobsScraper(BaseScraper):
    """Scraper for bdjobs.com"""

    BASE_URL = "https://www.bdjobs.com"
    SEARCH_ENDPOINT = "/jobcircular?view=list"

    def __init__(self):
        super().__init__("bdjobs")
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })

    def scrape(self) -> List[Dict]:
        """Scrape jobs from bdjobs.com"""
        try:
            self.log_info("Starting scrape of bdjobs.com")

            # Get job listings page
            url = f"{self.BASE_URL}{self.SEARCH_ENDPOINT}"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, "lxml")

            # Find all job postings
            job_items = soup.find_all("div", class_="job-item")
            self.log_info(f"Found {len(job_items)} job listings")

            for job_item in job_items:
                try:
                    job_data = self._parse_job_item(job_item)
                    if job_data:
                        self.scraped_jobs.append(job_data)
                except Exception as e:
                    self.log_error(f"Error parsing job item: {str(e)}")

            self.log_info(f"Successfully scraped {len(self.scraped_jobs)} jobs")
            return self.scraped_jobs

        except requests.RequestException as e:
            self.log_error(f"Request failed: {str(e)}")
            return []
        except Exception as e:
            self.log_error(f"Unexpected error: {str(e)}")
            return []

    def _parse_job_item(self, job_item) -> Optional[Dict]:
        """Parse a single job item from the listing."""
        try:
            # Extract title
            title_elem = job_item.find("h2", class_="job-title")
            if not title_elem:
                return None
            title = title_elem.get_text(strip=True)

            # Extract company
            company_elem = job_item.find("p", class_="company-name")
            company = company_elem.get_text(strip=True) if company_elem else "Unknown"

            # Extract location
            location_elem = job_item.find("span", class_="location")
            location = location_elem.get_text(strip=True) if location_elem else "Not specified"

            # Extract deadline
            deadline_elem = job_item.find("span", class_="deadline")
            deadline = None
            if deadline_elem:
                deadline_text = deadline_elem.get_text(strip=True)
                deadline = self._parse_deadline(deadline_text)

            # Extract category
            category_elem = job_item.find("span", class_="category")
            category = "other"
            if category_elem:
                raw_category = category_elem.get_text(strip=True)
                category = self._map_category(raw_category)

            # Extract description
            desc_elem = job_item.find("p", class_="description")
            description = desc_elem.get_text(strip=True) if desc_elem else ""

            # Extract job type
            job_type = None
            type_elem = job_item.find("span", class_="job-type")
            if type_elem:
                job_type = type_elem.get_text(strip=True)

            # Extract apply link
            apply_link = None
            link_elem = job_item.find("a", class_="apply-btn")
            if link_elem and link_elem.get("href"):
                apply_link = link_elem.get("href")
                if not apply_link.startswith("http"):
                    apply_link = f"{self.BASE_URL}{apply_link}"

            # Create job dict
            job_data = self._create_job_dict(
                title=title,
                company=company,
                location=location,
                category=category,
                description=description,
                deadline=deadline,
                job_type=job_type,
                apply_link=apply_link,
            )

            return job_data

        except Exception as e:
            self.log_error(f"Error parsing job item: {str(e)}")
            return None

    def _parse_deadline(self, deadline_text: str) -> Optional[datetime]:
        """Parse deadline text to datetime."""
        try:
            # Handle "X days left" format
            if "day" in deadline_text.lower():
                match = re.search(r"(\d+)\s*days?", deadline_text)
                if match:
                    days = int(match.group(1))
                    return datetime.now() + timedelta(days=days)

            # Handle date formats
            formats = ["%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d"]
            for fmt in formats:
                try:
                    return datetime.strptime(deadline_text.strip(), fmt)
                except ValueError:
                    continue

            return None
        except Exception:
            return None


if __name__ == "__main__":
    scraper = BDJobsScraper()
    jobs = scraper.scrape()
    print(f"\nScraped {len(jobs)} jobs")
    print(f"Stats: {scraper.get_stats()}")
    if jobs:
        print(f"\nFirst job:\n{jobs[0]}")
