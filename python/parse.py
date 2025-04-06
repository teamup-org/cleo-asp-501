import sys
import os
import re
import json
import logging
from typing import List, Dict, Optional
import pdfplumber

# Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)
logger = logging.getLogger(__name__)


def extract_text_from_pdf(pdf_path: str) -> str:
    try:
        logger.info(f"Opening PDF: {pdf_path}")
        text = ""
        with pdfplumber.open(pdf_path) as pdf:
            for i, page in enumerate(pdf.pages, start=1):
                page_text = page.extract_text()
                if page_text:
                    text += f"\n--- PAGE {i} ---\n{page_text}"
        logger.info("Text extraction complete.")
        return text
    except Exception as e:
        logger.error(f"Failed to extract text: {e}")
        raise


def parse_courses_from_text(text: str) -> List[Dict[str, str]]:
    lines = [line.strip() for line in text.splitlines()]
    # More flexible semester pattern that can handle various formats
    semester_pattern = re.compile(r"^(?:Term|Semester|Session)?\s*(Fall|Spring|Summer|Winter)?\s*(\d{4})", re.IGNORECASE)
    course_code_pattern = re.compile(r"^([A-Z]{2,4})\s+(\d{3}[A-Z]?)\s+(.*?)\s+(\d\.\d{3})\s+([A-Z][+-]?|S|U|P|NP|CR|TCR)$")

    current_semester = "Unknown Semester"
    parsed_courses = []
    buffer = []
    seen_courses = set()  # Track seen courses to avoid duplicates

    for line in lines:
        # Check for semester header with more flexible matching
        semester_match = semester_pattern.match(line)
        if semester_match:
            if buffer:
                # Process any buffered courses before changing semester
                for buffered_line in buffer:
                    course_data = extract_course(buffered_line, current_semester)
                    if course_data:
                        # Check for duplicates before adding
                        course_key = (course_data["ccode"], course_data["cnumber"], course_data["semester"])
                        if course_key not in seen_courses:
                            parsed_courses.append(course_data)
                            seen_courses.add(course_key)
                buffer = []
            
            # Extract semester and year from the match
            season = semester_match.group(1) or "Unknown"
            year = semester_match.group(2)
            current_semester = f"{season} {year}" if season != "Unknown" else "Unknown Semester"
            continue

        # Ignore obvious headers and footers
        if any(skip in line for skip in ["Subj", "Course Title", "Cred", "Pts", "EHRS", "Qpts", "GPA", "Term Totals", "Page", "Name:", "PROGRAM", "CREDIT ACCEPTED", "UNOFFICIAL", "TRANSCRIPT TOTALS", "Engineering - Computer Engineering"]):
            continue

        # Check if line starts with a course code and number
        if re.match(r"^[A-Z]{2,4}\s+\d{3}[A-Z]?\s+", line):
            if buffer:
                # Process previous buffered course
                course_data = extract_course(''.join(buffer), current_semester)
                if course_data:
                    # Check for duplicates before adding
                    course_key = (course_data["ccode"], course_data["cnumber"], course_data["semester"])
                    if course_key not in seen_courses:
                        parsed_courses.append(course_data)
                        seen_courses.add(course_key)
            buffer = [line]
        elif buffer:
            # Only append to buffer if it's part of the course description
            buffer.append(line)

    # Process any remaining buffered courses
    if buffer:
        course_data = extract_course(''.join(buffer), current_semester)
        if course_data:
            # Check for duplicates before adding
            course_key = (course_data["ccode"], course_data["cnumber"], course_data["semester"])
            if course_key not in seen_courses:
                parsed_courses.append(course_data)
                seen_courses.add(course_key)

    logger.info(f"Extracted {len(parsed_courses)} unique course(s)")
    return parsed_courses


def extract_course(line: str, semester: str) -> Optional[Dict[str, str]]:
    try:
        # Clean up the line by removing any semester references
        line = re.sub(r"(Fall|Spring|Summer)\s+\d{4}\s+-\s+.*?Semester", "", line)
        line = re.sub(r"Semester$", "", line)
        line = re.sub(r"TB\s+\d\.\d{3}\s+0\.\d{3}", "", line)
        line = re.sub(r"TA\s+\d\.\d{3}\s+0\.\d{3}", "", line)
        line = re.sub(r"NEWTONIAN MECHANICS", "", line)  # Remove specific course references
        line = re.sub(r"ENGR & SCI", "", line)  # Remove specific course references
        line = ' '.join(line.split())  # Normalize whitespace

        # First try to match the complete course pattern
        course_match = re.match(r"^([A-Z]{2,4})\s+(\d{3}[A-Z]?)\s+(.*?)\s+(\d\.\d{3})\s+([A-Z][+-]?|S|U|P|NP|CR|TCR)$", line)
        if course_match:
            subject, number, title, credits, grade = course_match.groups()
            # Ensure course code is at least 4 characters
            subject = subject.ljust(4, 'X')
            # Extract only numeric part of course number and ensure it's not empty
            number = re.sub(r'[^0-9]', '', number)
            if not number:  # If no numbers found, use a default
                number = "000"
            return {
                "semester": semester,
                "ccode": subject,
                "cnumber": number,
                "cname": title.strip(),
                "credit_hours": credits,
                "grade": grade
            }

        # If full pattern fails, try to extract parts separately
        parts = line.strip().split()
        if len(parts) < 3:
            return None

        # Extract course code and number
        subject = parts[0]
        number = parts[1]
        
        # Ensure course code is at least 4 characters
        subject = subject.ljust(4, 'X')
        # Extract only numeric part of course number and ensure it's not empty
        number = re.sub(r'[^0-9]', '', number)
        if not number:  # If no numbers found, use a default
            number = "000"
        
        # Find the last credit hours and grade
        credit_match = re.search(r"(\d\.\d{3})", line)
        grade_match = re.search(r"\b([ABCDF][+-]?|S|U|P|NP|CR|TCR)\b", line)
        
        if credit_match and grade_match:
            credit_start = credit_match.start()
            grade_start = grade_match.start()
            
            # Extract title as everything between course number and credit hours
            title = line[line.find(number) + len(number):credit_start].strip()
            
            # Clean up title
            title = re.sub(r"\s+\d\.\d{3}\s+.*$", "", title)  # Remove any trailing numbers
            title = re.sub(r"\s+Semester$", "", title)  # Remove "Semester" if present
            title = re.sub(r"\s+Fall\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            title = re.sub(r"\s+Spring\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            title = re.sub(r"\s+Summer\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            
            return {
                "semester": semester,
                "ccode": subject,
                "cnumber": number,
                "cname": title,
                "credit_hours": credit_match.group(1),
                "grade": grade_match.group(1)
            }
        else:
            # If we can't find credit/grade, just extract what we can
            title = ' '.join(parts[2:])
            title = re.sub(r"\s+\d\.\d{3}\s+.*$", "", title)  # Remove any trailing numbers
            title = re.sub(r"\s+Fall\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            title = re.sub(r"\s+Spring\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            title = re.sub(r"\s+Summer\s+\d{4}\s+-\s+.*$", "", title)  # Remove semester references
            return {
                "semester": semester,
                "ccode": subject,
                "cnumber": number,
                "cname": title,
                "credit_hours": "3.000",
                "grade": "N/A"
            }

    except Exception as e:
        logger.warning(f"Failed to parse line: {line} — {e}")
        return None


def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py transcript.pdf", file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]
    if not os.path.exists(pdf_path):
        print(f"File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    text = extract_text_from_pdf(pdf_path)
    courses = parse_courses_from_text(text)
    print(json.dumps(courses, indent=2))


if __name__ == "__main__":
    main()
