"""Command-line entry point for the scheduled scraper run.

    python run_scrapers.py --mode ingest    # scrape and store new jobs (needs credentials)
    python run_scrapers.py --mode dry-run   # scrape and print, no Firestore
    python run_scrapers.py --mode inspect [URL ...]  # print page structure to fix selectors
    python run_scrapers.py --mode probe --keyword K URL ...  # show JSON shape / code around K

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

INSPECT_URLS = [BDJobsScraper.LIST_URL]


def scrape_all() -> Dict[str, List[Dict]]:
    results = {}
    for scraper in (BDJobsScraper(),):
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


def _shape(value, depth=0):
    if depth > 3:
        return "..."
    if isinstance(value, dict):
        return {k: _shape(v, depth + 1) for k, v in list(value.items())[:40]}
    if isinstance(value, list):
        return [_shape(value[0], depth + 1), f"({len(value)} items)"] if value else []
    return type(value).__name__


def probe(urls: List[str], keyword: str) -> None:
    session = requests.Session()
    session.headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    for url in urls:
        print(f"\n===== {url}")
        try:
            response = session.get(url, timeout=30)
        except requests.RequestException as e:
            print(f"request failed: {e}")
            continue
        print(f"status={response.status_code} final_url={response.url} type={response.headers.get('content-type')}")
        try:
            data = response.json()
        except ValueError:
            data = None
        if data is not None:
            print("json shape:", json.dumps(_shape(data), indent=1)[:4000])
            print("json sample:", json.dumps(data, ensure_ascii=False)[:3000])
            continue
        texts = [(url, response.text)]
        soup = BeautifulSoup(response.content, "lxml")
        sources = [tag["src"] for tag in soup.find_all("script", src=True)]
        sources += [tag["href"] for tag in soup.find_all("link", rel="modulepreload", href=True)]
        for source_path in sources[:60]:
            src = requests.compat.urljoin(response.url, source_path)
            try:
                texts.append((src, session.get(src, timeout=30).text))
            except requests.RequestException:
                pass
        for word in keyword.split(","):
            for source, text in texts:
                if source == url and len(texts) > 1:
                    continue
                for match in list(re.finditer(re.escape(word), text))[:2]:
                    start = max(0, match.start() - 700)
                    print(f"--- [{word}] {source} @ {match.start()}\n{text[start:match.end() + 700]}\n")


def check_credentials() -> bool:
    """Fail fast on a bad key; otherwise Firestore retries the auth error until the job times out."""
    import os

    import google.auth.transport.requests
    from google.auth.exceptions import RefreshError
    from google.oauth2 import service_account

    path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if not path:
        print("GOOGLE_APPLICATION_CREDENTIALS is not set.")
        return False
    try:
        with open(path) as f:
            info = json.load(f)
        creds = service_account.Credentials.from_service_account_info(
            info, scopes=["https://www.googleapis.com/auth/datastore"])
    except (OSError, ValueError, KeyError) as e:
        print(f"The service-account JSON could not be read ({type(e).__name__}); paste the whole file into the secret.")
        return False
    key_id = (info.get("private_key_id") or "")[:8]
    print(f"Using key {key_id}... of {info.get('client_email')} (project {info.get('project_id')})")
    try:
        creds.refresh(google.auth.transport.requests.Request())
    except RefreshError as e:
        print(f"Google rejected this key: {e.args[0] if e.args else e}")
        print("It was probably deleted. Create a new key and put it in the FIREBASE_CREDENTIALS secret.")
        return False
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["ingest", "dry-run", "inspect", "probe"], default="dry-run")
    parser.add_argument("--keyword", default="GetJobSearch")
    parser.add_argument("urls", nargs="*")
    args = parser.parse_args()

    if args.mode == "inspect":
        inspect(args.urls or INSPECT_URLS)
        return 0
    if args.mode == "probe":
        probe(args.urls, args.keyword)
        return 0

    if args.mode == "ingest" and not check_credentials():
        return 1

    results = scrape_all()
    total = sum(len(jobs) for jobs in results.values())

    if args.mode == "dry-run":
        for source, jobs in results.items():
            for job in jobs[:3]:
                print(json.dumps({k: job[k] for k in ("title", "company", "location", "category", "deadline",
                                                      "jobType", "minYearsExperience", "applyLink")},
                                 ensure_ascii=False))
            if jobs:
                link = jobs[0]["applyLink"]
                try:
                    r = requests.get(link, timeout=30, headers={"User-Agent": "Mozilla/5.0"})
                    print(f"apply link check: {link} -> {r.status_code} {r.url}")
                except requests.RequestException as e:
                    print(f"apply link check failed: {e}")
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
