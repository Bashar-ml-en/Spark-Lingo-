"""
Spark Lingo content pipeline — download Tatoeba dataset exports.

This is the volume path for content ingestion. The per-pair search API
(fetch_tatoeba.py) is fine for small live pulls but is rate-limited; for
thousands of sentence pairs we use Tatoeba's official weekly dataset
exports at https://downloads.tatoeba.org/exports/per_language/ (CC-BY 2.0
for sentences; audio clips carry their own per-clip license and are mostly
CC BY-NC-* — this pipeline only keeps explicitly permissive audio).

Tatoeba language codes are ISO 639-3. IMPORTANT for Malay: the ISO 639-2
code `mal` is MALAYALAM (a Dravidian language of India). Standard Malay /
Bahasa Melayu on Tatoeba is split across `zsm` (Standard Malay) and `zlm`
(Malay (individual language)). Spark Lingo's `ms` catalog merges both.

Usage:
    python download_exports.py --out ./exports

Downloads are resumable-friendly (files are skipped when already present).
Total download for the five priority languages is ~35 MB compressed.
"""

import argparse
import sys
import time
import urllib.request
from pathlib import Path

BASE = "https://downloads.tatoeba.org/exports/per_language"

# (tatoeba_code, file) pairs needed by build_dataset_seed.py
FILES = [
    # sentence files: id \t lang \t text
    ("eng", "eng_sentences.tsv.bz2"),
    ("zsm", "zsm_sentences.tsv.bz2"),
    ("zlm", "zlm_sentences.tsv.bz2"),
    ("spa", "spa_sentences.tsv.bz2"),
    ("ara", "ara_sentences.tsv.bz2"),
    ("cmn", "cmn_sentences.tsv.bz2"),
    # link files: sentence_id_a \t sentence_id_b  (a is in the dir's language)
    ("eng", "eng-zsm_links.tsv.bz2"),
    ("eng", "eng-zlm_links.tsv.bz2"),
    ("eng", "eng-spa_links.tsv.bz2"),
    ("eng", "eng-ara_links.tsv.bz2"),
    ("eng", "eng-cmn_links.tsv.bz2"),
    # per-clip audio licence metadata: id \t user_id \t username \t licence
    ("spa", "spa_sentences_with_audio.tsv.bz2"),
    ("ara", "ara_sentences_with_audio.tsv.bz2"),
    ("cmn", "cmn_sentences_with_audio.tsv.bz2"),
    ("eng", "eng_sentences_with_audio.tsv.bz2"),
    # NOTE: zsm/zlm have no sentences_with_audio export (404 as of
    # 2026-08-23) — Malay audio must come from Common Voice instead.
]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", default="./exports", help="download directory")
    args = parser.parse_args()
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    failures = []
    for code, name in FILES:
        dest = out_dir / name
        if dest.exists() and dest.stat().st_size > 0:
            print(f"skip (exists): {name}")
            continue
        url = f"{BASE}/{code}/{name}"
        print(f"download: {url}")
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "spark-lingo-content-pipeline/1.0"})
            with urllib.request.urlopen(req, timeout=120) as resp, open(dest, "wb") as fh:
                while True:
                    chunk = resp.read(1 << 20)
                    if not chunk:
                        break
                    fh.write(chunk)
            print(f"  -> {dest.stat().st_size} bytes")
        except Exception as exc:  # noqa: BLE001 - report and continue
            print(f"  FAILED: {exc}", file=sys.stderr)
            failures.append(name)
            dest.unlink(missing_ok=True)
        time.sleep(0.5)  # be polite to a free community mirror

    if failures:
        print(f"\n{len(failures)} download(s) failed: {failures}", file=sys.stderr)
        return 1
    print("\nAll exports downloaded.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
