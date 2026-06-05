import json
import re
from pathlib import Path

text = Path(r"C:\Users\User\Documents\bayetav\BAYETAV_TEK_DOSYA.html").read_text(encoding="utf-8", errors="replace")

def find_obj(s, start):
    depth = 0
    ins = False
    esc = False
    quote = ""
    for i in range(start, len(s)):
        ch = s[i]
        if ins:
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == quote:
                ins = False
        else:
            if ch in ("'", '"'):
                ins = True
                quote = ch
            elif ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return s[start:i+1]
    raise RuntimeError

idx = text.index("const embeddedDocs = ")
docs = json.loads(find_obj(text, text.index("{", idx)))
for k in ["ket1-exam","ket2-exam","flyers1-exam","flyers2-exam"]:
    d = docs[k]
    print("\n===", k, "len", len(d))
    for pat in ["answer", "key", "correct", "Teacher", "ANSWERS", "Answer"]:
        print(pat, d.lower().find(pat.lower()))
    for m in re.finditer("answer|key|correct|teacher", d, re.I):
        i = max(0, m.start()-250)
        print("---", m.group(), m.start())
        print(d[i:m.start()+650].replace("\n"," ")[:1000])
        break
    print("TAIL")
    print(re.sub(r"\s+"," ",d[-3000:])[:3000])
