# Job scrapers

Collects job postings and stores them in Firestore as `approved` jobs, so
they appear in the app's feed right away. Jobs added by hand in the app are
the ones that wait for an admin or moderator in **Review jobs**.

## Sources

| Source | File | How it reads jobs |
|--------|------|-------------------|
| bdjobs.com | `bdjobs_scraper.py` | Reads the job list JSON embedded in `https://bdjobs.com/h/jobs/` (`<script id="ng-state">`) and follows result pages |
| Newspaper PDFs | `newspaper_scraper.py` | OCR (Tesseract) over PDFs in `./newspapers/`; run manually, not part of the daily job |

chakri.com was removed: the site returns Cloudflare 523 (origin unreachable).

## Daily run

`.github/workflows/scrape-jobs.yml` runs every day at 06:00 Asia/Dhaka and
can be started by hand from the repository's **Actions** tab:

- `ingest`: scrape and store new jobs (the default)
- `dry-run`: scrape and print a sample, no Firestore
- `inspect` / `probe`: print page structure or JSON shape, used to fix a scraper after a site change

`ingest` needs the service-account JSON in the repository secret
`FIREBASE_CREDENTIALS` (Settings → Secrets and variables → Actions). A run
fails when no jobs were scraped, so a site redesign shows up as a failed
workflow and GitHub emails you.

## Storage

Each posting gets a stable document ID (from its source and link, or title
and company), created with `create()`. A job seen again on a later run is
skipped, so an approve/reject decision is never overwritten.

## Run locally

```bash
pip install -r requirements.txt
python -m unittest discover -s tests
python run_scrapers.py --mode dry-run
GOOGLE_APPLICATION_CREDENTIALS=../firebase-credentials.json python run_scrapers.py --mode ingest
```

## Adding a source

Subclass `BaseScraper`, implement `scrape()` returning dicts built with
`_create_job_dict()`, and add it to `scrape_all()` in `run_scrapers.py`.
