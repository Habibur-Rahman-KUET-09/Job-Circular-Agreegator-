"""Scraper for job sites an admin adds from the app (Account → Job sources).

Each source is a Firestore document in `scraperSources` holding the list page
URL and CSS selectors: one that matches every job on the page, and optional
ones inside it for the title, company, location, deadline and link. The app
runs the same selectors to preview a source before saving it.
"""

import re
from datetime import datetime
from typing import Dict, List, Optional
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup
from dateutil import parser as date_parser

from base_scraper import BaseScraper

MAX_ITEMS = 150
FIELDS = ("title", "company", "location", "deadline", "link")


def source_key(source_id: str) -> str:
    """The `source` value stored on jobs from an app-added source."""
    return f"site:{source_id}"


class SelectorScraper(BaseScraper):
    def __init__(self, source_id: str, config: Dict, session: Optional[requests.Session] = None):
        self.display_name = (config.get("name") or source_id).strip()
        # Jobs show the site's name; document IDs use the stable key so
        # renaming a source doesn't store its jobs a second time.
        super().__init__(self.display_name)
        self.source_id = source_id
        self.key = source_key(source_id)
        self.config = config
        self.session = session or requests.Session()
        self.session.headers.setdefault(
            "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

    def scrape(self) -> List[Dict]:
        url = (self.config.get("listUrl") or "").strip()
        item_selector = (self.config.get("itemSelector") or "").strip()
        if not url or not item_selector:
            self.log_error("listUrl and itemSelector are required")
            return []
        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
        except requests.RequestException as e:
            self.log_error(f"Could not load {url}: {e}")
            return []
        try:
            self.scraped_jobs = self.parse(response.text, response.url)
        except Exception as e:  # a bad selector raises from soupsieve
            self.log_error(f"Could not read the page: {e}")
            return []
        self.log_info(f"Scraped {len(self.scraped_jobs)} jobs from {url}")
        return self.scraped_jobs

    def parse(self, page_html: str, page_url: str) -> List[Dict]:
        soup = BeautifulSoup(page_html, "lxml")
        jobs, seen = [], set()
        for item in soup.select(self.config["itemSelector"])[:MAX_ITEMS]:
            fields = extract_fields(item, self.config, page_url)
            title = fields["title"]
            key = fields["link"] or title
            if not title or key in seen:
                continue
            seen.add(key)
            company = fields["company"] or self.display_name
            jobs.append(self._create_job_dict(
                title=title,
                company=company,
                location=fields["location"] or "Not specified",
                category=self._guess_category(f"{title} {company}"),
                description="",
                deadline=parse_deadline(fields["deadline"]),
                apply_link=fields["link"] or page_url,
            ))
        return jobs


def _selector(config: Dict, field: str) -> str:
    return (config.get(f"{field}Selector") or "").strip()


def extract_fields(item, config: Dict, page_url: str) -> Dict[str, str]:
    """Text of each configured field inside one job element, plus its absolute link."""
    fields = {}
    for field in ("title", "company", "location", "deadline"):
        selector = _selector(config, field)
        if selector:
            el = item.select_one(selector)
            fields[field] = _clean(el.get_text(" ", strip=True)) if el else ""
        else:
            fields[field] = ""
    if not _selector(config, "title"):
        # Without a title selector the job's first link text is the title.
        anchor = item if item.name == "a" else item.find("a")
        fields["title"] = _clean(anchor.get_text(" ", strip=True)) if anchor else ""

    link_selector = _selector(config, "link") or _selector(config, "title")
    link_el = item.select_one(link_selector) if link_selector else None
    if link_el is None or not link_el.get("href"):
        link_el = item if item.name == "a" and item.get("href") else item.find("a", href=True)
    href = (link_el.get("href") or "").strip() if link_el is not None else ""
    fields["link"] = urljoin(page_url, href) if href and not href.startswith(("javascript:", "#")) else ""
    return fields


def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


_DEADLINE_PREFIX = re.compile(r"^(deadline|last date|apply before|closing date)\s*[:\-]?\s*", re.I)


def parse_deadline(text: str) -> Optional[datetime]:
    """'Deadline: 30 Sep 2026' -> datetime; anything unreadable -> None."""
    text = _DEADLINE_PREFIX.sub("", _clean(text))
    if not text or not re.search(r"\d", text):
        return None
    try:
        return date_parser.parse(text, fuzzy=True, dayfirst=True)
    except (ValueError, OverflowError):
        return None
