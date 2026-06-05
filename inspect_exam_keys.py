from html.parser import HTMLParser
from pathlib import Path


class TextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
    def handle_data(self, data):
        text = " ".join(data.split())
        if text:
            self.parts.append(text)


def text_from_html(html):
    parser = TextParser()
    parser.feed(html)
    return "\n".join(parser.parts)


for file in [
    r"C:\Users\User\Downloads\ket_test1_full (1).html",
    r"C:\Users\User\Downloads\ket_test2_full (1).html",
    r"C:\Users\User\Downloads\flyers_exam1 (2).html",
    r"C:\Users\User\Downloads\flyers_exam2 (1).html",
    r"C:\Users\User\Downloads\impact2ket1-exam.html",
]:
    path = Path(file)
    if not path.exists():
        continue
    text = text_from_html(path.read_text(encoding="utf-8", errors="replace"))
    print("\n===", path.name, "===")
    for marker in ["PAPER 2: LISTENING", "Part 1", "ANSWER KEY", "Reading and Writing"]:
        idx = text.find(marker)
        if idx >= 0:
            print("\n---", marker, "---")
            print(text[idx:idx+2200])
            break
