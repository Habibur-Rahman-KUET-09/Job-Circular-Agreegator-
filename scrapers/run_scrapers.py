"""Command-line entry point for the scheduled scraper run.

    python run_scrapers.py --mode ingest    # scrape and store new jobs (needs credentials)
    python run_scrapers.py --mode dry-run   # scrape and print, no Firestore
    python run_scrapers.py --mode inspect [URL ...]  # print page structure to fix selectors

Exits non-zero when no jobs were scraped at all, so a scheduled run that
silently breaks (site redesign, blocked request) shows up as a failed run.
"""

import argparse
import json
import re
import sys
from collections import Counter
from typing import Dict, List

import requests
from bs4 import BeautifulSoup

from bdjobs_scraper import BDJobsScraper
from chakri_scraper import ChakriScraper

INSPECT_URLS = [
    BDJobsScraper.BASE_URL + BDJobsScraper.SEARCH_ENDPOINT,
    "https://jobs.bdjobs.com/jobsearch.asp",
    ChakriScraper.BASE_URL + ChakriScraper.SEARCH_ENDPOINT,
]


def scrape_all() -> Dict[str, List[Dict]]:
    results = {}
    for scraper in (BDJobsScraper(), ChakriScraper()):
        jobs = scraper.scrape()
        print(f"[{scraper.source_name}] {len(jobs)} jobs, {len(scraper.errors)} errors")
        for error in scraper.errors[:5]:
            print(f"  error: {error}")
        results[scraper.source_name] = jobs
    return results


def _describe(el) -> str:
    classes = ".".join(el.get("class") or [])
    return f"{el.name}.{classes}" if classes else el.name


def inspect(urls: List[str]) -> None:
    session = requests.Session()
    session.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    for url in urls:
        print(f"\n===== {url}")
        try:
            response = session.get(url, timeout=30)
        except requests.RequestException as e:
            print(f"request failed: {e}")
            continue
        print(f"status={response.status_code} final_url={response.url} bytes={len(response.content)} "
              f"type={response.headers.get('content-type')}")
        soup = BeautifulSoup(response.content, "lxml")
        print(f"title: {soup.title.get_text(strip=True) if soup.title else None}")

        anchors = [a for a in soup.find_all("a", href=True) if re.search(r"job|circular|details", a["href"], re.I)]
        print(f"job-like links: {len(anchors)}")
        for a in anchors[:10]:
            chain = " < ".join(_describe(p) for p in list(a.parents)[:4])
            print(f"  {a.get_text(' ', strip=True)[:70]!r} -> {a['href'][:110]}\n      in {chain}")

        ancestors = Counter()
        for a in anchors:
            for parent in list(a.parents)[:5]:
                if parent.get("class"):
                    ancestors[_describe(parent)] += 1
        print("most common classed ancestors of job links:")
        for name, count in ancestors.most_common(20):
            print(f"  {count:4d}  {name}")

        endpoints = sorted(set(re.findall(r"""https?://[^"'\s<>]*(?:api|json|ajax)[^"'\s<>]*""", response.text, re.I)))
        print(f"api-like urls in page: {endpoints[:15]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["ingest", "dry-run", "inspect"], default="dry-run")
    parser.add_argument("urls", nargs="*")
    args = parser.parse_args()

    if args.mode == "inspect":
        inspect(args.urls or INSPECT_URLS)
        return 0

    results = scrape_all()
    total = sum(len(jobs) for jobs in results.values())

    if args.mode == "dry-run":
        for source, jobs in results.items():
            for job in jobs[:3]:
                print(json.dumps({k: job[k] for k in ("title", "company", "location", "deadline", "jobType", "applyLink")},
                                 ensure_ascii=False))
    else:
        from firestore_ingestion import FirestoreIngestion

        ingestion = FirestoreIngestion()
        for source, jobs in results.items():
            if jobs:
                stats = ingestion.ingest_jobs(jobs, source)
                print(f"[{source}] inserted={stats['inserted']} already_stored={stats['duplicates']} errors={stats['errors']}")

    if total == 0:
        print("No jobs scraped from any source; the site layouts have probably changed.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
