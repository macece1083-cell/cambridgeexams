import json
from pathlib import Path

text = Path(r"C:\Users\User\Documents\bayetav\BAYETAV_TEK_DOSYA.html").read_text(encoding="utf-8", errors="replace")

def find_obj(s, start):
    depth=0; ins=False; esc=False; quote=''
    for i,ch in enumerate(s[start:], start):
        if ins:
            if esc: esc=False
            elif ch=='\\': esc=True
            elif ch==quote: ins=False
        else:
            if ch in "'\"": ins=True; quote=ch
            elif ch=='{': depth += 1
            elif ch=='}':
                depth -= 1
                if depth == 0: return s[start:i+1]
    raise RuntimeError

idx=text.index("const embeddedDocs = ")
docs=json.loads(find_obj(text, text.index("{", idx)))
for k,d in docs.items():
    if not k.endswith("-exam"): continue
    print("\n==",k)
    for term in ["ANSWERS","ANSWER","Answer Key","Teacher"]:
        pos=d.find(term)
        print(term,pos)
        if pos!=-1:
            print(d[max(0,pos-500):pos+3000].replace("\n"," ")[:3600])
