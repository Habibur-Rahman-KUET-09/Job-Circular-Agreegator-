"""Scraper for chakri.com job listings."""

import re
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import requests
from bs4 import BeautifulSoup
from base_scraper import BaseScraper


class ChakriScraper(BaseScraper):
    """Scraper for chakri.com"""

    BASE_URL = "https://www.chakri.com"
    SEARCH_ENDPOINT = "/jobs"

    def __init__(self):
        super().__init__("chakri")
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })

    def scrape(self) -> List[Dict]:
        """Scrape jobs from chakri.com"""
        try:
            self.log_info("Starting scrape of chakri.com")

            # Get job listings page
            url = f"{self.BASE_URL}{self.SEARCH_ENDPOINT}"
            response = self.session.get(url, timeout=10)
            response.raise_for_status()

            soup = BeautifulSoup(response.content, "lxml")

            # Find all job postings (chakri.com uses different structure)
            job_items = soup.find_all("div", class_="job-card")
            if not job_items:
                job_items = soup.find_all("article", class_="job-listing")

            self.log_info(f"Found {len(job_items)} job listings")

            for job_item in job_items:
                try:
                    job_data = self._parse_job_item(job_item)
                    if job_data:
                        self.scraped_jobs.append(job_data)
                except Exception as e:
                    self.log_error(f"Error parsing job item: {str(e)}")

            self.log_info(f"Successfully scraped {len(self.scraped_jobs)} jobs from chakri.com")
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
            title_elem = job_item.find("h3", class_="job-title") or job_item.find("a", class_="job-link")
            if not title_elem:
                return None
            title = title_elem.get_text(strip=True)

            # Extract company
            company_elem = job_item.find("div", class_="company-info") or job_item.find("span", class_="company")
            company = company_elem.get_text(strip=True) if company_elem else "Unknown"

            # Extract location
            location_elem = job_item.find("span", class_="location") or job_item.find("div", class_="job-location")
            location = location_elem.get_text(strip=True) if location_elem else "Not specified"

            # Extract deadline
            deadline_elem = job_item.find("span", class_="deadline") or job_item.find("span", class_="expiry-date")
            deadline = None
            if deadline_elem:
                deadline_text = deadline_elem.get_text(strip=True)
                deadline = self._parse_deadline(deadline_text)

            # Extract category
            category_elem = job_item.find("span", class_="category") or job_item.find("span", class_="job-category")
            category = "other"
            if category_elem:
                raw_category = category_elem.get_text(strip=True)
                category = self._map_category(raw_category)

            # Extract description
            desc_elem = job_item.find("p", class_="description") or job_item.find("p", class_="summary")
            description = desc_elem.get_text(strip=True) if desc_elem else ""

            # Extract job type
            job_type = None
            type_elem = job_item.find("span", class_="job-type") or job_item.find("span", class_="employment-type")
            if type_elem:
                job_type = type_elem.get_text(strip=True)

            # Extract apply link
            apply_link = None
            link_elem = job_item.find("a", class_="apply-btn") or job_item.find("a", class_="job-apply-link")
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
            formats = ["%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%d %B %Y", "%d %b %Y"]
            for fmt in formats:
                try:
                    return datetime.strptime(deadline_text.strip(), fmt)
                except ValueError:
                    continue

            return None
        except Exception:
            return None


if __name__ == "__main__":
    scraper = ChakriScraper()
    jobs = scraper.scrape()
    print(f"\nScraped {len(jobs)} jobs from chakri.com")
    print(f"Stats: {scraper.get_stats()}")
    if jobs:
        print(f"\nFirst job:\n{jobs[0]}")
