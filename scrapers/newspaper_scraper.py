"""Scraper for job circulars in newspaper PDFs using OCR."""

import re
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path
import pytesseract
from pdf2image import convert_from_path
from base_scraper import BaseScraper


class NewspaperScraper(BaseScraper):
    """Scraper for job circulars in newspaper PDFs."""

    def __init__(self, pdf_directory: str = "./newspapers"):
        super().__init__("newspaper")
        self.pdf_directory = Path(pdf_directory)
        self.pdf_directory.mkdir(parents=True, exist_ok=True)

    def scrape(self) -> List[Dict]:
        """Scrape jobs from newspaper PDFs in the directory."""
        try:
            self.log_info(f"Starting scrape of PDFs in {self.pdf_directory}")

            # Find all PDF files
            pdf_files = list(self.pdf_directory.glob("*.pdf"))
            self.log_info(f"Found {len(pdf_files)} PDF files")

            for pdf_file in pdf_files:
                try:
                    self._process_pdf(pdf_file)
                except Exception as e:
                    self.log_error(f"Error processing PDF {pdf_file.name}: {str(e)}")

            self.log_info(f"Successfully scraped {len(self.scraped_jobs)} jobs from newspapers")
            return self.scraped_jobs

        except Exception as e:
            self.log_error(f"Unexpected error during scraping: {str(e)}")
            return []

    def _process_pdf(self, pdf_path: Path):
        """Process a single PDF file and extract job listings."""
        try:
            self.log_info(f"Processing PDF: {pdf_path.name}")

            # Convert PDF to images
            images = convert_from_path(str(pdf_path), first_page=1, last_page=10)
            self.log_info(f"Converted PDF to {len(images)} page images")

            for page_num, image in enumerate(images, 1):
                try:
                    # Extract text using OCR
                    text = pytesseract.image_to_string(image, lang='ben+eng')

                    # Parse job listings from extracted text
                    jobs = self._parse_text_for_jobs(text, pdf_path.stem, page_num)
                    self.scraped_jobs.extend(jobs)

                except Exception as e:
                    self.log_error(f"Error processing page {page_num} of {pdf_path.name}: {str(e)}")

        except Exception as e:
            self.log_error(f"Error converting PDF {pdf_path.name}: {str(e)}")

    def _parse_text_for_jobs(self, text: str, source_name: str, page_num: int) -> List[Dict]:
        """Parse OCR text to extract job listings."""
        jobs = []
        try:
            # Split text by common job listing delimiters
            job_blocks = re.split(r'\n(?=[A-Z][A-Za-z\s]*(?:\n|$))', text)

            for block in job_blocks:
                if len(block.strip()) < 20:
                    continue

                try:
                    job_data = self._extract_job_from_block(block, source_name, page_num)
                    if job_data:
                        jobs.append(job_data)
                except Exception as e:
                    self.log_error(f"Error extracting job from text block: {str(e)}")

        except Exception as e:
            self.log_error(f"Error parsing text for jobs: {str(e)}")

        return jobs

    def _extract_job_from_block(self, block: str, source_name: str, page_num: int) -> Optional[Dict]:
        """Extract a job listing from a text block."""
        try:
            lines = [line.strip() for line in block.strip().split('\n') if line.strip()]
            if len(lines) < 2:
                return None

            # Assume first line is title
            title = lines[0]

            # Extract company (look for lines with "Ltd", "Ltd.", "Inc", etc.)
            company = "Unknown"
            for line in lines[1:4]:
                if any(suffix in line for suffix in ["Ltd", "Ltd.", "Inc", "Inc.", "Company", "Corporation"]):
                    company = line
                    break

            # Extract location (look for common city names)
            location = self._extract_location(block)

            # Extract deadline
            deadline = self._extract_deadline(block)

            # Extract job type
            job_type = self._extract_job_type(block)

            # Extract category
            category = self._extract_category(block)

            # Extract description (remaining text)
            description = '\n'.join(lines[1:10])[:500]

            # Create job dictionary
            job_data = self._create_job_dict(
                title=title,
                company=company,
                location=location,
                category=category,
                description=description,
                deadline=deadline,
                job_type=job_type,
                apply_link=f"Newspaper - {source_name} (Page {page_num})",
            )

            return job_data

        except Exception as e:
            self.log_error(f"Error extracting job from block: {str(e)}")
            return None

    def _extract_location(self, text: str) -> str:
        """Extract location from text."""
        cities = ["Dhaka", "Chittagong", "Sylhet", "Khulna", "Rajshahi", "Barisal", "Mymensingh", "Rangpur"]
        for city in cities:
            if city.lower() in text.lower():
                return city
        return "Not specified"

    def _extract_deadline(self, text: str) -> Optional[datetime]:
        """Extract deadline from text."""
        try:
            # Look for date patterns
            date_patterns = [
                r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
                r'(\d{1,2}\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4})',
            ]

            for pattern in date_patterns:
                match = re.search(pattern, text, re.IGNORECASE)
                if match:
                    date_str = match.group(1)
                    formats = ["%d/%m/%Y", "%d-%m-%Y", "%Y-%m-%d", "%d %B %Y"]
                    for fmt in formats:
                        try:
                            return datetime.strptime(date_str, fmt)
                        except ValueError:
                            continue

            return None
        except Exception:
            return None

    def _extract_job_type(self, text: str) -> Optional[str]:
        """Extract job type from text."""
        job_types = ["Full-time", "Part-time", "Contract", "Temporary", "Freelance"]
        for jtype in job_types:
            if jtype.lower() in text.lower():
                return jtype
        return None

    def _extract_category(self, text: str) -> str:
        """Extract job category from text."""
        categories = {
            "it": ["software", "developer", "programmer", "it", "tech", "engineer"],
            "finance": ["accountant", "finance", "accounting", "cfo"],
            "sales": ["sales", "business development", "executive"],
            "marketing": ["marketing", "brand", "digital"],
            "hr": ["human resources", "hr", "recruitment"],
            "education": ["teacher", "lecturer", "professor", "education"],
            "healthcare": ["doctor", "nurse", "medical", "healthcare"],
        }

        text_lower = text.lower()
        for category, keywords in categories.items():
            for keyword in keywords:
                if keyword in text_lower:
                    return category

        return "other"


if __name__ == "__main__":
    scraper = NewspaperScraper(pdf_directory="./newspapers")
    jobs = scraper.scrape()
    print(f"\nScraped {len(jobs)} jobs from newspapers")
    print(f"Stats: {scraper.get_stats()}")
    if jobs:
        print(f"\nFirst job:\n{jobs[0]}")
