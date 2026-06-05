import json
import re
from html import unescape
from pathlib import Path

src = Path(r"C:\Users\User\Documents\bayetav\BAYETAV_TEK_DOSYA.html")
text = src.read_text(encoding="utf-8", errors="replace")

def find_balanced_object(s, start):
    depth = 0
    in_str = False
    esc = False
    quote = ""
    for i in range(start, len(s)):
        ch = s[i]
        if in_str:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == quote:
                in_str = False
        else:
            if ch in ("'", '"'):
                in_str = True
                quote = ch
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return s[start:i + 1]
    raise RuntimeError("object not closed")

idx = text.index("const embeddedDocs = ")
obj_start = text.index("{", idx)
embedded = json.loads(find_balanced_object(text, obj_start))

def clean_html(s):
    s = re.sub(r"<script[\s\S]*?</script>", " ", s, flags=re.I)
    s = re.sub(r"<style[\s\S]*?</style>", " ", s, flags=re.I)
    s = re.sub(r"<[^>]+>", " ", s)
    s = unescape(s)
    s = re.sub(r"\s+", " ", s)
    return s.strip()

for key, doc in embedded.items():
    if not key.endswith("-exam"):
        continue
    plain = clean_html(doc)
    hits = []
    for pat in [
        r"(?:Answer Key|Answers|Teacher answer key|ANSWER KEY)(.{0,2500})",
        r"(?:Reading and Writing|READING AND WRITING)(.{0,1200})(?:Listening|LISTENING)(.{0,1200})",
    ]:
        for m in re.finditer(pat, plain, flags=re.I):
            hits.append(m.group(0))
    print("\n==", key, "==")
    if hits:
        for h in hits[:3]:
            print(h[:2500])
    else:
        # last resort: show tail likely containing key
        print(plain[-2500:])
