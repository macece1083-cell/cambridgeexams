import base64
import re
from pathlib import Path

html = Path(r"C:\Users\User\Downloads\ket_test1_full (1).html").read_text(encoding="utf-8", errors="replace")
out_dir = Path(r"C:\Users\User\Documents\bayetav\_inspect_images")
out_dir.mkdir(exist_ok=True)
for q in [1, 2, 3, 4, 5]:
    pattern = rf'<div class="listening-q-num">{q}.*?</div>.*?<img src="data:image/(png|jpeg);base64,([^"]+)"'
    match = re.search(pattern, html, re.S)
    if not match:
        print("missing", q)
        continue
    ext = "jpg" if match.group(1) == "jpeg" else "png"
    path = out_dir / f"ket1_listening_q{q}.{ext}"
    path.write_bytes(base64.b64decode(match.group(2)))
    print(path)
