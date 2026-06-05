import re
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

files = [
    r"C:\Users\User\Downloads\KET_Practice_Test_1_Units_1-4.docx",
    r"C:\Users\User\Downloads\KET_Practice_Test_2_Units_5-8.docx",
    r"C:\Users\User\Downloads\FLYERS_EXAM_1_Units_1-4.docx",
    r"C:\Users\User\Downloads\FLYERS_EXAM_2_Units_5-8.docx",
    r"C:\Users\User\Downloads\Impact_2_KET_Exam_1.docx",
]

ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}

def docx_text(path):
    with zipfile.ZipFile(path) as z:
        xml = z.read("word/document.xml")
    root = ET.fromstring(xml)
    paras = []
    for p in root.findall(".//w:p", ns):
        texts = [t.text or "" for t in p.findall(".//w:t", ns)]
        if texts:
            paras.append("".join(texts))
    return "\n".join(paras)

for f in files:
    p = Path(f)
    if not p.exists():
        continue
    txt = docx_text(p)
    print("\n===", p.name, "===")
    lower = txt.lower()
    positions = [m.start() for m in re.finditer(r"answer|key|cevap|answers|listening script", lower)]
    if positions:
        for pos in positions[:6]:
            print(txt[max(0, pos-600):pos+3000])
            print("---")
    else:
        print(txt[-4000:])
