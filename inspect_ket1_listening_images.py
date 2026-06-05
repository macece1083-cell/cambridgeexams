import re
from pathlib import Path

path = Path(r"C:\Users\User\Downloads\ket_test1_full (1).html")
html = path.read_text(encoding="utf-8", errors="replace")
blocks = re.findall(r'(<div class="listening-q">.*?)(?=<div class="listening-q">|<div style="font-size:8pt|<div class="footer")', html, re.S)
print("blocks", len(blocks))
for i, block in enumerate(blocks[:5], 1):
    print(f"\n--- Q{i} ---")
    labels = re.findall(r'<div class="abc-label">(.*?)</div>', block, re.S)
    alts = re.findall(r'alt="([^"]*)"', block)
    text = re.sub(r'<img[^>]+>', '[IMG]', block)
    text = re.sub(r'<[^>]+>', ' ', text)
    text = re.sub(r'\s+', ' ', text).strip()
    print("labels:", labels)
    print("alts:", alts)
    print(text[:1000])
