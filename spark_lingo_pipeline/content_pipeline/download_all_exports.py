"""Download ALL Tatoeba exports needed for all 15 Spark Lingo languages."""
import sys
import time
import urllib.request
from pathlib import Path

BASE = "https://downloads.tatoeba.org/exports/per_language"

# codes needed: sentences for every language + eng-X links for every non-eng
CODES = ["eng", "fra", "deu", "spa", "ita", "por", "cmn", "jpn", "kor",
         "rus", "ara", "hin", "tha", "tgl", "zsm", "zlm"]

FILES = []
for c in CODES:
    FILES.append((c, f"{c}_sentences.tsv.bz2"))
for c in CODES:
    if c != "eng":
        FILES.append(("eng", f"eng-{c}_links.tsv.bz2"))

out = Path(sys.argv[1] if len(sys.argv) > 1 else "./exports")
out.mkdir(parents=True, exist_ok=True)

ok, fail = 0, []
for code, name in FILES:
    dest = out / name
    if dest.exists() and dest.stat().st_size > 0:
        ok += 1
        print(f"skip (exists): {name} ({dest.stat().st_size} bytes)")
        continue
    url = f"{BASE}/{code}/{name}"
    print(f"download: {url}")
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "spark-lingo-content-pipeline/1.0"})
        with urllib.request.urlopen(req, timeout=180) as resp, open(dest, "wb") as fh:
            while True:
                chunk = resp.read(1 << 20)
                if not chunk:
                    break
                fh.write(chunk)
        ok += 1
        print(f"  -> {dest.stat().st_size} bytes")
    except Exception as exc:
        print(f"  FAILED: {exc}", file=sys.stderr)
        fail.append(name)
        dest.unlink(missing_ok=True)
    time.sleep(0.4)

print(f"\nDONE: {ok} ok, {len(fail)} failed: {fail}")
sys.exit(1 if fail else 0)
