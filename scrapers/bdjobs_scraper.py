"""Scraper for bdjobs.com.

The jobs page (https://bdjobs.com/h/jobs/) is an Angular app that embeds the
first page of results as JSON in <script id="ng-state">, the same data its
GetJobSearch API returns. Reading that JSON is far more stable than scraping
rendered HTML.
"""

import json
import re
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import requests
from bs4 import BeautifulSoup

from base_scraper import BaseScraper

# Tried in order to find the query parameter that selects a results page.
PAGE_PARAM_CANDIDATES = ("pg", "page", "pn", "p")


class BDJobsScraper(BaseScraper):
    LIST_URL = "https://bdjobs.com/h/jobs/"
    DETAIL_URL = "https://jobs.bdjobs.com/jobdetails.asp?id={job_id}"

    def __init__(self, max_pages: int = 10, delay_seconds: float = 1.0):
        super().__init__("bdjobs")
        self.max_pages = max_pages
        self.delay_seconds = delay_seconds
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })

    def scrape(self) -> List[Dict]:
        try:
            first_page, total_pages = self._fetch_page(None)
        except (requests.RequestException, ValueError) as e:
            self.log_error(f"Could not load the job list: {e}")
            return []

        seen = set()
        self._add_jobs(first_page, seen)

        page_param = self._find_page_param(seen) if total_pages > 1 else None
        if page_param:
            for page in range(3, min(self.max_pages, total_pages) + 1):
                time.sleep(self.delay_seconds)
                try:
                    items, _ = self._fetch_page({page_param: page})
                except (requests.RequestException, ValueError) as e:
                    self.log_error(f"Page {page} failed: {e}")
                    break
                if not self._add_jobs(items, seen):
                    break
        elif total_pages > 1:
            self.log_info("No working page parameter found; only the first page was read")

        self.log_info(f"Scraped {len(self.scraped_jobs)} jobs")
        return self.scraped_jobs

    def _find_page_param(self, seen: set) -> Optional[str]:
        for param in PAGE_PARAM_CANDIDATES:
            time.sleep(self.delay_seconds)
            try:
                items, _ = self._fetch_page({param: 2})
            except (requests.RequestException, ValueError):
                continue
            if self._add_jobs(items, seen):
                self.log_info(f"Paging with ?{param}=N")
                return param
        return None

    def _fetch_page(self, params: Optional[Dict]) -> Tuple[List[Dict], int]:
        response = self.session.get(self.LIST_URL, params=params, timeout=30)
        response.raise_for_status()
        return parse_ng_state(response.text)

    def _add_jobs(self, items: List[Dict], seen: set) -> int:
        """Convert and keep unseen jobs; returns how many were new."""
        added = 0
        for item in items:
            job_id = str(item.get("Jobid") or "")
            if not job_id or job_id in seen:
                continue
            seen.add(job_id)
            try:
                self.scraped_jobs.append(self._to_job(item))
                added += 1
            except Exception as e:
                self.log_error(f"Could not convert job {job_id}: {e}")
        return added

    def _to_job(self, item: Dict) -> Dict:
        title = (item.get("jobTitle") or "").strip()
        company = (item.get("companyName") or "").strip() or "Unknown"
        min_years, max_years = parse_experience(item.get("experience"))
        salary = (item.get("Salary") or "").strip()
        return self._create_job_dict(
            title=title,
            company=company,
            location=(item.get("location") or "").strip() or "Not specified",
            category=self._guess_category(f"{title} {company}"),
            description=html_to_text(item.get("jobContext") or item.get("jobDescription") or item.get("eduRec") or ""),
            deadline=parse_iso(item.get("deadlineDB")),
            job_type=item.get("JobType"),
            salary_min=salary if salary and salary != "--" else None,
            min_years=min_years,
            max_years=max_years,
            apply_link=self.DETAIL_URL.format(job_id=item["Jobid"]),
            posted_date=parse_iso(item.get("publishDate")),
        )


def parse_ng_state(page_html: str) -> Tuple[List[Dict], int]:
    """Return (job items, total pages) from the page's embedded ng-state JSON."""
    soup = BeautifulSoup(page_html, "lxml")
    script = soup.find("script", id="ng-state")
    if script is None or not script.string:
        raise ValueError("ng-state JSON not found; the page layout has changed")
    state = json.loads(script.string)
    for entry in state.values():
        body = entry.get("b") if isinstance(entry, dict) else None
        if isinstance(body, dict) and isinstance(body.get("data"), list) and "common" in body:
            items = list(body.get("premiumData") or []) + list(body["data"])
            total_pages = int((body.get("common") or {}).get("totalpages") or 1)
            return items, total_pages
    raise ValueError("no job search results in ng-state")


def parse_iso(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def parse_experience(text: Optional[str]) -> Tuple[Optional[int], Optional[int]]:
    """'2 to 4 years' -> (2, 4); 'At least 1 years' -> (1, None); 'NA' -> (None, None)."""
    numbers = [int(n) for n in re.findall(r"\d+", text or "")]
    if len(numbers) >= 2:
        return numbers[0], numbers[1]
    if len(numbers) == 1:
        return numbers[0], None
    return None, None


def html_to_text(value: str) -> str:
    return BeautifulSoup(value, "lxml").get_text("\n", strip=True) if value else ""


if __name__ == "__main__":
    scraper = BDJobsScraper(max_pages=2)
    jobs = scraper.scrape()
    print(f"Scraped {len(jobs)} jobs; stats: {scraper.get_stats()}")
    if jobs:
        print(json.dumps(jobs[0], indent=2, ensure_ascii=False))
