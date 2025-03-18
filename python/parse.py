import sys
import os
import re
import sys
import json
import logging
from typing import List, Dict, Any, Optional

# Configure logging to output to stderr for Rails to capture
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)
logger = logging.getLogger(__name__)

# logger.info(sys.path)  # Log the current Python path for debugging

sys.path.insert(0, os.path.dirname(__file__))  # Add the current directory to the Python path
logger.info(sys.path)  # Log the updated
import pdfplumber

def extract_text_from_pdf(pdf_path: str) -> str:
    """Extracts text from a given PDF file."""
    try:
        logger.info(f"Opening PDF file: {pdf_path}")
        text = ""
        with pdfplumber.open(pdf_path) as pdf:
            logger.info(f"PDF has {len(pdf.pages)} pages")
            for i, page in enumerate(pdf.pages, 1):
                logger.info(f"Processing page {i}")
                extracted_text = page.extract_text()
                if extracted_text:
                    text += extracted_text + "\n"
                    logger.info(f"Page {i} extracted {len(extracted_text)} characters")
                else:
                    logger.warning(f"Page {i} extracted no text")
        
        if not text.strip():
            logger.error("No text was extracted from the PDF")
            return ""
            
        logger.info(f"Total extracted text length: {len(text)}")
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {str(e)}")
        raise

def parse_courses_from_text(text: str) -> List[Dict[str, Any]]:
    """Parses course information from extracted text using regex patterns."""
    if not text.strip():
        logger.error("Empty text provided to parse_courses_from_text")
        return []

    # Log the first 500 characters of text for debugging
    logger.info(f"First 500 chars of text to parse: {text[:500]}")
    
    # Enhanced patterns for better matching
    course_pattern = re.compile(r"""
        ^                           # Start of line
        ([A-Z]{2,4})\s+            # Course code (2-4 letters)
        (\d{3}[A-Z]?)\s+           # Course number (3 digits + optional letter)
        ([A-Za-z0-9 &\-\.\(\)]+?)  # Course name
        (?:                         # Optional credit/grade group
            \s+
            (\d+(?:\.\d+)?)\s*     # Credit hours
            (?:                     # Optional grade info
                ([A-Z][+-]?|TCR)   # Grade or TCR
                (?:\s+\d+\.\d+)?   # Optional grade points
            )?
        )?
        \s*$                       # End of line
    """, re.VERBOSE)
    semester_pattern = re.compile(r"(Fall|Spring|Summer|Winter)\s+(\d{4})")
    transfer_section_pattern = re.compile(r"TRANSFER CREDIT ACCEPTED|CREDIT BY EXAM|ADVANCED PLACEMENT|TRANSFER CREDIT FROM")
    in_progress_section_pattern = re.compile(r"COURSES IN PROGRESS|CURRENT ENROLLMENT|REGISTERED COURSES")
    ignore_pattern = re.compile(r"^\s*(?:Subj|No\.|Course|Title|Cred|Grade|Pts|R|Semester)\s*$")

    courses: List[Dict[str, Any]] = []
    current_semester: Optional[str] = None
    is_transfer_section = False
    is_in_progress_section = False
    
    try:
        lines = text.split("\n")
        logger.info(f"Processing {len(lines)} lines of text")
        
        for i, line in enumerate(lines, 1):
            line = line.strip()
            
            # Skip empty lines and header rows
            if not line or ignore_pattern.match(line):
                continue

            # Reset section flags when a new semester is found
            semester_match = semester_pattern.search(line)
            if semester_match:
                current_semester = f"{semester_match.group(1)} {semester_match.group(2)}"
                logger.info(f"Found semester header: {current_semester}")
                is_transfer_section = False
                is_in_progress_section = False
                continue

            # Detect special sections
            if transfer_section_pattern.search(line):
                is_transfer_section = True
                current_semester = "Transfer Credit"
                logger.info("Found transfer credit section")
                continue
            
            if in_progress_section_pattern.search(line):
                is_in_progress_section = True
                current_semester = "In Progress"
                logger.info("Found in-progress section")
                continue

            # Match course entries
            course_match = course_pattern.match(line)
            if course_match:
                subj, number, title, hours, grade = course_match.groups()
                
                # Clean up the course title
                title = re.sub(r"(?:TCR|College:.*|CREDENTIAL\(S\) AWARDED.*|^\s+|\s+$)", "", title)
                title = ' '.join(title.split())  # Normalize whitespace

                # Handle credit hours
                try:
                    credit_hours = float(hours) if hours else 3.0
                except ValueError:
                    credit_hours = 3.0
                    logger.warning(f"Invalid credit hours for course {subj} {number}, defaulting to 3.0")

                # Skip if credit hours are 0 or unreasonably high
                if credit_hours <= 0 or credit_hours > 12:
                    logger.warning(f"Skipping course {subj} {number} due to invalid credit hours: {credit_hours}")
                    continue

                # Determine the semester
                semester = current_semester
                if is_transfer_section:
                    semester = "Transfer Credit"
                elif is_in_progress_section:
                    semester = "In Progress"
                elif not semester:
                    semester = "Unknown Semester"
                    logger.warning(f"Course found without semester context: {line}")

                course_data = {
                    'semester': semester,
                    'ccode': subj,
                    'cnumber': number,
                    'cname': title,
                    'credit_hours': credit_hours,
                    'grade': grade if grade and grade != 'TCR' else None
                }
                
                logger.info(f"Found course: {course_data}")
                courses.append(course_data)

        logger.info(f"Found total of {len(courses)} courses")
        
        if not courses:
            logger.warning("No courses were found in the text")
            return []

        # Sort courses by semester (chronologically)
        def semester_sort_key(course):
            sem = course['semester']
            if sem == "Transfer Credit":
                return (0, 0)  # Always first
            elif sem == "In Progress":
                return (9999, 9999)  # Always last
            elif sem == "Unknown Semester":
                return (9998, 9998)  # Just before "In Progress"
            else:
                try:
                    season, year = sem.split()
                    season_order = {'Spring': 0, 'Summer': 1, 'Fall': 2, 'Winter': 3}
                    return (int(year), season_order.get(season, 4))
                except:
                    return (9997, 9997)

        courses.sort(key=semester_sort_key)
        return courses
    
    except Exception as e:
        logger.error(f"Error parsing transcript text: {str(e)}")
        logger.error(f"Problematic text: {text[:500]}...")
        raise

def main():
    """Main execution function."""
    try:
        if len(sys.argv) != 2:
            logger.error("No PDF file path provided")
            sys.exit(1)
        
        pdf_path = sys.argv[1]
        logger.info(f"Starting transcript parsing for file: {pdf_path}")
        
        text = extract_text_from_pdf(pdf_path)
        if not text.strip():
            logger.error("No text extracted from PDF")
            sys.exit(1)
            
        courses = parse_courses_from_text(text)
        
        # Write JSON to stdout (this will be captured by Rails)
        sys.stdout.write(json.dumps(courses, indent=2))
        sys.stdout.flush()
        
    except Exception as e:
        logger.error(f"Error processing transcript: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
