from __future__ import annotations

import base64
import hashlib
import re
from pathlib import Path


ROOT = Path(r"C:\Users\User\Documents\bayetav")
SOURCE = Path(r"C:\Users\User\Downloads\BAYETAV_TEK_DOSYA (1).html")
OUT_DIR = ROOT / "web-site"
ASSET_DIR = OUT_DIR / "assets"


DATA_URI_RE = re.compile(
    r"data:(audio/wav|text/html);(?:charset=utf-8;)?base64,([A-Za-z0-9+/=]+)"
)


def extension_for(mime: str) -> str:
    if mime == "audio/wav":
        return ".wav"
    if mime == "text/html":
        return ".html"
    raise ValueError(f"Unhandled MIME type: {mime}")


def folder_for(mime: str) -> Path:
    if mime == "audio/wav":
        return ASSET_DIR / "audio"
    if mime == "text/html":
        return ASSET_DIR / "docs"
    raise ValueError(f"Unhandled MIME type: {mime}")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    (ASSET_DIR / "audio").mkdir(parents=True, exist_ok=True)
    (ASSET_DIR / "docs").mkdir(parents=True, exist_ok=True)

    html = SOURCE.read_text(encoding="utf-8")
    counters: dict[str, int] = {"audio/wav": 0, "text/html": 0}
    seen: dict[str, str] = {}
    written: list[tuple[str, int]] = []

    def replace(match: re.Match[str]) -> str:
      mime = match.group(1)
      b64 = match.group(2)
      digest = hashlib.sha256((mime + ":" + b64).encode("ascii")).hexdigest()
      if digest in seen:
          return seen[digest]

      counters[mime] += 1
      prefix = "audio" if mime == "audio/wav" else "doc"
      rel = f"assets/{'audio' if mime == 'audio/wav' else 'docs'}/{prefix}_{counters[mime]:03d}{extension_for(mime)}"
      data = base64.b64decode(b64)
      target = OUT_DIR / rel
      target.write_bytes(data)
      seen[digest] = rel
      written.append((rel, len(data)))
      return rel

    html = DATA_URI_RE.sub(replace, html)
    (OUT_DIR / "index.html").write_text(html, encoding="utf-8", newline="\n")

    total = sum(size for _, size in written)
    print(f"Created {OUT_DIR / 'index.html'}")
    print(f"Externalized {len(written)} assets, {total:,} bytes")
    for rel, size in written[:20]:
        print(f"{rel}\t{size:,}")
    if len(written) > 20:
        print(f"... {len(written) - 20} more")


if __name__ == "__main__":
    main()
