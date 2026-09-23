# Job Circular Aggregator - Data Scrapers

This directory contains the data scraping infrastructure for the Job Circular Aggregator project. It provides a modular, extensible architecture for collecting job listings from multiple sources and ingesting them into Firestore.

## Overview

The scraper system consists of:

1. **BaseScraper** - Abstract base class providing common functionality
2. **Source-Specific Scrapers** - Individual scrapers for each job source
3. **FirestoreIngestion** - Handles job ingestion and duplicate detection
4. **ScraperManager** - Orchestrates all scrapers and coordinates workflows
5. **Cloud Functions** - Scheduled triggers and on-demand operations

## Architecture

```
┌─────────────────┐
│ ScraperManager  │
└────────┬────────┘
         │
    ┌────┴────────┬──────────────┐
    │             │              │
┌───▼──┐   ┌──────▼──┐   ┌──────▼────┐
│BDJobs│   │ Chakri  │   │Newspaper  │
└───┬──┘   └──────┬──┘   └──────┬────┘
    │             │              │
    └─────────────┼──────────────┘
                  │
          ┌───────▼────────┐
          │ FirestoreDB    │
          │  - Deduplication
          │  - Approval Workflow
          │  - Cleanup
          └────────────────┘
```

## Scrapers

### 1. BDJobsScraper
- **Source**: bdjobs.com
- **Method**: HTTP requests + HTML parsing
- **Fields Extracted**: title, company, location, deadline, category, description, job_type, apply_link
- **Status**: Production-ready

```python
from bdjobs_scraper import BDJobsScraper

scraper = BDJobsScraper()
jobs = scraper.scrape()
stats = scraper.get_stats()
```

### 2. ChakriScraper
- **Source**: chakri.com
- **Method**: HTTP requests + HTML parsing
- **Fields Extracted**: Same as BDJobsScraper
- **Status**: Production-ready

```python
from chakri_scraper import ChakriScraper

scraper = ChakriScraper()
jobs = scraper.scrape()
stats = scraper.get_stats()
```

### 3. NewspaperScraper
- **Source**: PDF newspaper job circulars
- **Method**: PDF to image conversion + OCR (Tesseract)
- **Fields Extracted**: Extracted via OCR pattern matching
- **Status**: Production-ready
- **Requirements**: 
  - Tesseract OCR installed on system
  - Poppler installed for PDF processing
  - PDF files placed in `./newspapers/` directory

```python
from newspaper_scraper import NewspaperScraper

scraper = NewspaperScraper(pdf_directory="./newspapers")
jobs = scraper.scrape()
stats = scraper.get_stats()
```

## Setup

### Prerequisites

1. Python 3.8+
2. Firebase Admin SDK credentials
3. System dependencies:
   - Tesseract OCR: `sudo apt-get install tesseract-ocr`
   - Poppler: `sudo apt-get install poppler-utils`

### Installation

```bash
# Install Python dependencies
pip install -r requirements.txt

# Copy environment configuration
cp .env.example .env
# Edit .env with your Firebase credentials
```

### Firebase Setup

1. Download Firebase credentials JSON from Firebase Console
2. Place in project root or set `FIREBASE_CREDENTIALS_PATH` in `.env`
3. Ensure Firestore database is initialized

## Usage

### Run All Scrapers

```python
from scraper_manager import ScraperManager

manager = ScraperManager(pdf_directory="./newspapers")

# Run all scrapers
stats = manager.run_all(approve_automatically=False)

# Run with auto-approval for trusted sources
stats = manager.run_all(approve_automatically=True)
```

### Run Single Scraper

```python
from scraper_manager import ScraperManager

manager = ScraperManager()
stats = manager.run_single_scraper("bdjobs")
```

### Manual Job Management

```python
from firestore_ingestion import FirestoreIngestion

ingestion = FirestoreIngestion()

# Get pending jobs
pending_jobs = ingestion.get_pending_jobs(limit=50)

# Approve jobs
ingestion.approve_jobs(job_ids=["job1", "job2", "job3"])

# Reject jobs
ingestion.reject_jobs(
    job_ids=["job4", "job5"],
    reason="Duplicate or invalid"
)

# Cleanup expired jobs
ingestion.cleanup_expired_jobs(days=90)
```

## Cloud Functions Integration

The scrapers are orchestrated via Firebase Cloud Functions for automated, scheduled execution.

### Scheduled Functions

1. **runScrapersDaily** - Runs all scrapers at 6:00 AM (Asia/Dhaka)
2. **autoApproveTrustedJobs** - Auto-approves jobs from trusted sources at 8:00 AM
3. **cleanupExpiredJobs** - Removes expired jobs weekly on Sunday at 2:00 AM

### On-Demand Function

**triggerScrapersOnDemand** - Callable function to manually trigger scrapers (admin/moderator only)

## Duplicate Detection

The system uses string similarity matching (Levenshtein distance-based) to detect duplicates:

- Duplicates are identified within 7-day windows
- Default similarity threshold: 85%
- Matched duplicates increment view count instead of creating new entries
- Configurable via `duplicate_threshold` parameter

## Job Status Workflow

```
┌─────────┐
│ Scraped │  Jobs start as "pending" when scraped
└────┬────┘
     │
     ├──────────────────┐
     │                  │
     ▼                  ▼
┌───────────┐   ┌──────────┐
│ Approved  │   │ Rejected │  Moderator review
└───────────┘   └──────────┘
     │
     ├──────────┬────────────┐
     │          │            │
  Applied   Expired    Reposted

Final: Jobs auto-cleanup 90 days after deadline
```

## Monitoring and Logging

### ScraperRuns Collection
Track all scraper executions in Firestore:

```
{
  "timestamp": Timestamp,
  "status": "running|completed|failed|no_jobs_found",
  "jobsProcessed": Number,
  "jobsInserted": Number,
  "jobsDuplicate": Number,
  "errorCount": Number,
  "completedAt": Timestamp,
  "triggeredBy": String (user ID for manual runs)
}
```

### Logging Output
- Console logging: INFO level by default
- Errors include job title and descriptive messages
- Statistics aggregated per scraper and per run

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FIREBASE_CREDENTIALS_PATH` | Path to Firebase credentials JSON | `./firebase-credentials.json` |
| `PDF_DIRECTORY` | Directory containing newspaper PDFs | `./newspapers` |
| `SCRAPER_TIMEOUT` | HTTP request timeout in seconds | `10` |
| `LOG_LEVEL` | Logging verbosity | `INFO` |

### Scraper-Specific Settings

**BDJobsScraper**
- `BASE_URL`: https://www.bdjobs.com
- `SEARCH_ENDPOINT`: /jobcircular?view=list
- Deadline formats: "X days left", "%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d"

**ChakriScraper**
- `BASE_URL`: https://www.chakri.com
- `SEARCH_ENDPOINT`: /jobs
- Deadline formats: Extended support for "%d %B %Y", "%d %b %Y"

**NewspaperScraper**
- Auto-detects cities: Dhaka, Chittagong, Sylhet, Khulna, Rajshahi, Barisal, Mymensingh, Rangpur
- Supported job types: Full-time, Part-time, Contract, Temporary, Freelance
- Category detection via keyword matching

## Adding New Scrapers

To add a new scraper for a job source:

1. Create `new_source_scraper.py`:

```python
from base_scraper import BaseScraper

class NewSourceScraper(BaseScraper):
    def __init__(self):
        super().__init__("new_source")
        # Initialize source-specific attributes
    
    def scrape(self) -> List[Dict]:
        # Implement scraping logic
        pass
    
    def _parse_job_item(self, item) -> Optional[Dict]:
        # Implement item parsing logic
        pass
```

2. Add to `scraper_manager.py`:

```python
from new_source_scraper import NewSourceScraper

self.scrapers["new_source"] = NewSourceScraper()
```

3. Test via:

```python
manager.run_single_scraper("new_source")
```

## Performance Considerations

- **Batch Processing**: Jobs are processed in batches for Firestore efficiency
- **Duplicate Detection**: Limited to 7-day window for performance
- **Timeout**: 10-second timeout per HTTP request prevents hanging
- **Throttling**: Implement delays between requests to respect server resources

## Troubleshooting

### OCR Not Working
```bash
# Install Tesseract
sudo apt-get install tesseract-ocr tesseract-ocr-ben

# Install Poppler
sudo apt-get install poppler-utils
```

### Firebase Connection Issues
1. Verify credentials in `.env`
2. Check Firestore security rules allow ingestion
3. Ensure `jobs` collection exists in Firestore

### Duplicate False Positives
Adjust `duplicate_threshold` in `firestore_ingestion.py` (default: 0.85)

### Memory Issues with Large PDFs
Limit page processing with `first_page` and `last_page` in `_process_pdf()`

## Testing

Run individual scrapers:

```bash
python bdjobs_scraper.py
python chakri_scraper.py
python newspaper_scraper.py
```

Run scraper manager:

```bash
python scraper_manager.py
```

## Deployment

### Firebase Cloud Functions

```bash
firebase deploy --only functions
```

This deploys:
- `runScrapersDaily` - Daily scheduled execution
- `autoApproveTrustedJobs` - Auto-approval function
- `cleanupExpiredJobs` - Weekly cleanup
- `triggerScrapersOnDemand` - On-demand callable function

### Python Services

For production deployment of Python scrapers:

1. **Cloud Run** (Recommended)
   - Containerize scrapers in Docker
   - Deploy to Cloud Run
   - Trigger via Cloud Tasks or Cloud Scheduler

2. **Cloud Functions with Cloud Run**
   - Implement `triggerScraperService()` in `runScrapers.ts`
   - Call Cloud Run endpoint with scraper instructions

3. **VM/Server**
   - Install dependencies
   - Set up cron job for scheduled execution
   - Use `scraper_manager.py` directly

## Future Enhancements

- [ ] Headless browser support for JavaScript-heavy sites
- [ ] Proxy rotation for rate-limit handling
- [ ] Advanced ML-based duplicate detection
- [ ] Job enrichment with salary prediction
- [ ] Real-time scraping with WebSockets
- [ ] Custom scraper builder UI
- [ ] Scraper performance analytics dashboard

## Contributing

When adding new scrapers or features:

1. Extend `BaseScraper` class
2. Implement `scrape()` and `_parse_job_item()` methods
3. Use `_create_job_dict()` for standardized output
4. Add logging via `log_info()` and `log_error()`
5. Include error handling for malformed data
6. Test with real data before production deployment

## License

Part of the Job Circular Aggregator project.

---

_Generated with [Claude Code](https://claude.ai/code)_
