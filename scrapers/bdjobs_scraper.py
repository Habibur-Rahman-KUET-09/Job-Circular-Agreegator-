"""Scraper for bdjobs.com.

The jobs page (https://bdjobs.com/h/jobs/) is an Angular app that embeds its
newest ~60 jobs as JSON in <script id="ng-state">, the same data its
GetJobSearch API returns. Reading that JSON is far more stable than scraping
rendered HTML. The API gives no further pages to plain requests, so the
scheduled run goes often instead.

The list only has a summary, so each job's full circular (responsibilities,
requirements, benefits, company) comes from the JSON API the job details
page (https://jobs.bdjobs.com/jobdetails/?id=N) calls.
"""

import json
import re
import time
from datetime import datetime
from typing import Dict, List, Optional, Tuple

import requests
from bs4 import BeautifulSoup, NavigableString

from base_scraper import BaseScraper

DETAILS_API = "https://gateway.bdjobs.com/ActtivejobsTest/api/JobSubsystem/jobDetails"

# Circular sections as stored on the job (`details` map) -> bdjobs field.
DETAIL_SECTIONS = {
    "responsibilities": "JobDescription",
    "education": "EducationRequirements",
    "experience": "experience",
    "requirements": "AdditionJobRequirements",
    "benefits": "JobOtherBenifits",
    "process": "RecruitmentProcessingInformation",
    "company": "CompanyBusiness",
}


class BDJobsScraper(BaseScraper):
    LIST_URL = "https://bdjobs.com/h/jobs/"
    # Kept as the stored apply link: document IDs are derived from it.
    DETAIL_URL = "https://jobs.bdjobs.com/jobdetails.asp?id={job_id}"

    def __init__(self, delay_seconds: float = 0.5, fetch_details: bool = True):
        super().__init__("bdjobs")
        self.delay_seconds = delay_seconds
        self.fetch_details = fetch_details
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })

    def scrape(self) -> List[Dict]:
        try:
            response = self.session.get(self.LIST_URL, timeout=30)
            response.raise_for_status()
            items, _ = parse_ng_state(response.text)
        except (requests.RequestException, ValueError) as e:
            self.log_error(f"Could not load the job list: {e}")
            return []

        self._add_jobs(items, set())
        if self.fetch_details:
            fetched = 0
            for job in self.scraped_jobs:
                job_id = bdjobs_id(job.get("applyLink"))
                details = self.get_details(job_id) if job_id else {"detailsFetched": False}
                # A failed request is retried by later runs (see run_scrapers).
                job["detailsPending"] = details is None
                if details:
                    job.update(details)
                    fetched += bool(details.get("detailsFetched"))
            self.log_info(f"Fetched details for {fetched} of {len(self.scraped_jobs)} jobs")

        self.log_info(f"Scraped {len(self.scraped_jobs)} jobs")
        return self.scraped_jobs

    def get_details(self, job_id: str) -> Optional[Dict]:
        """Fields to add to a job from its full circular.

        None when the request failed (worth retrying later); only
        {"detailsFetched": False} when bdjobs no longer has the job.
        """
        time.sleep(self.delay_seconds)
        try:
            response = self.session.get(
                DETAILS_API,
                params={"jobId": job_id, "ln": 1, "IsCorporate": "false", "drafted": 0},
                timeout=30,
            )
            response.raise_for_status()
            body = response.json()
        except (requests.RequestException, ValueError) as e:
            self.log_error(f"Details for job {job_id} failed: {e}")
            return None
        data = body.get("data") if isinstance(body, dict) else None
        if not isinstance(body, dict) or body.get("statuscode") != "0" or not data \
                or str(data[0].get("JobFound", "True")).lower() != "true":
            return {"detailsFetched": False}
        return parse_details(data[0])

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


def bdjobs_id(link: Optional[str]) -> Optional[str]:
    match = re.search(r"[?&]id=(\d+)", link or "")
    return match.group(1) if match else None


def parse_details(data: Dict) -> Dict:
    """Job fields from the details API: the circular's sections and extras."""
    sections = {}
    for key, field in DETAIL_SECTIONS.items():
        text = html_to_text(data.get(field) or "")
        if text:
            sections[key] = text

    fields: Dict = {"details": sections, "detailsFetched": True}
    if sections.get("responsibilities"):
        fields["description"] = sections["responsibilities"]

    skills = [s.strip() for s in (data.get("SkillsRequired") or "").split(",") if s.strip()]
    if skills:
        fields["requiredSkills"] = skills

    salary = _clean(data.get("JobSalaryRangeText") or data.get("JobSalaryRange") or "")
    if salary and salary.lower() not in ("negotiable", "--"):
        fields["salaryMin"] = salary

    for target, field in (("vacancies", "JobVacancies"), ("workplace", "JobWorkPlace"),
                          ("companyAddress", "CompanyAddress"), ("companyWebsite", "CompanyWeb"),
                          ("jobLocationDetail", "JobLocation")):
        value = _clean(data.get(field) or "")
        if value and value not in ("0", "NA"):
            fields[target] = value
    return fields


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


_BLOCK_TAGS = ("p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "tr")


def html_to_text(value: str) -> str:
    """Readable text: one paragraph per line and list items as '• item'."""
    if not value or not value.strip():
        return ""
    if "<" not in value:
        return "\n".join(line for line in (_clean(l) for l in value.splitlines()) if line)
    soup = BeautifulSoup(value, "lxml")
    for br in soup.find_all("br"):
        br.replace_with(NavigableString("\n"))
    # Innermost first, so a nested list is folded into its parent item.
    for li in reversed(soup.find_all("li")):
        li.replace_with(NavigableString(f"\n• {_clean(li.get_text(' '))}\n"))
    for tag in soup.find_all(_BLOCK_TAGS):
        tag.insert_before(NavigableString("\n"))
        tag.insert_after(NavigableString("\n"))
    lines = (_clean(line) for line in soup.get_text().splitlines())
    return "\n".join(line for line in lines if line and line != "•")


def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", text or "").strip()


if __name__ == "__main__":
    scraper = BDJobsScraper()
    jobs = scraper.scrape()
    print(f"Scraped {len(jobs)} jobs; stats: {scraper.get_stats()}")
    if jobs:
        print(json.dumps(jobs[0], indent=2, ensure_ascii=False))
