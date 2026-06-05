import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(r"C:\Users\User\Downloads")
FILES = [
    "KET_Practice_Test_1_Units_1-4.docx",
    "KET_Practice_Test_2_Units_5-8.docx",
    "FLYERS_EXAM_1_Units_1-4.docx",
    "FLYERS_EXAM_2_Units_5-8.docx",
    "Impact_2_KET_Exam_1.docx",
]

NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def docx_text(path):
    with zipfile.ZipFile(path) as archive:
        xml = archive.read("word/document.xml")
    root = ET.fromstring(xml)
    paragraphs = []
    for para in root.findall(".//w:p", NS):
        text = "".join(node.text or "" for node in para.findall(".//w:t", NS))
        if text.strip():
            paragraphs.append(text.strip())
    return "\n".join(paragraphs)


for filename in FILES:
    path = ROOT / filename
    if not path.exists():
        continue
    text = docx_text(path)
    print(f"\n===== {filename} =====")
    matches = list(re.finditer(r"\[ANSWER KEY\]", text, flags=re.I))
    print(f"answer blocks: {len(matches)}")
    for i, match in enumerate(matches, 1):
        start = match.end()
        next_header = re.search(r"\n\[(?:AUDIO SCRIPT|ANSWER KEY)\]", text[start:], flags=re.I)
        end = start + next_header.start() if next_header else min(len(text), start + 1200)
        block = text[start:end].strip()
        print(f"\n--- block {i} ---")
        print(block[:2500])
    if not matches:
        lines = [line.strip() for line in text.splitlines() if re.search(r"^Answers?:", line.strip(), flags=re.I)]
        if lines:
            print("\n--- inline answer lines ---")
            for line in lines:
                print(line)
        lower = text.lower()
        idx = lower.find("paper 2: listening")
        if idx >= 0:
            print("\n--- listening context ---")
            print(text[idx:idx + 12000])
