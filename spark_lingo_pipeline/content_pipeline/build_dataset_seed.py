"""
Spark Lingo content pipeline — dataset-based seed generator.

Joins Tatoeba weekly dataset exports (downloaded by download_exports.py)
into flashcard rows matching the app's `flashcards` schema
(supabase/migrations/001_core_schema.sql):

    id, lesson_id, front_text, back_text, context_sentence, audio_url,
    source, source_attribution

Why dataset exports instead of the search API:
- The search API (fetch_tatoeba.py) is rate-limited and caps out at a few
  hundred pairs per run. The exports give us tens of thousands of linked
  pairs in one deterministic, reproducible pass.
- Exports are weekly snapshots: pin the snapshot date and the seed is
  auditable (sentence IDs are stable).

Language-code correctness:
- Bahasa Melayu on Tatoeba is `zsm` (Standard Malay) + `zlm` (Malay,
  individual language). ISO 639-2 `mal` is MALAYALAM and must never be
  used for Malay. Both are merged into Spark Lingo's `ms` catalog entry.
- Mandarin is `cmn` (not `zh`), Arabic is `ara`, Spanish is `spa`.

Audio policy (verified 2026-08-23):
- Tatoeba's per-clip audio is overwhelmingly CC BY-NC-* (non-commercial),
  which is incompatible with a freemium product. This generator therefore
  sets audio_url = NULL and attaches no Tatoeba audio.
- Native-speaker audio comes from Mozilla Common Voice (CC0) via
  process_common_voice.py once a dataset tarball has been downloaded
  through Mozilla's email-gated page.

Output rows are written with is_reviewed = false semantics: the unit they
land in stays unreviewed until a native speaker signs off (see
docs/release/CONTENT_AND_CLAIMS_REGISTER.md). Attribution strings follow
Tatoeba's CC-BY 2.0 requirement.

Usage:
    python build_dataset_seed.py --exports ./exports --out ../output

Produces one JSON file per direction:
    ms_from_en, es_from_en, ar_from_en, zh_from_en  (target from English)
"""

import argparse
import bz2
import json
from pathlib import Path

TATOEBA_ATTRIBUTION = "Sentences © Tatoeba.org contributors (CC-BY 2.0)"

# Spark Lingo language key -> Tatoeba codes merged for that language.
TARGET_CODES = {
    "ms": ["zsm", "zlm"],
    "es": ["spa"],
    "ar": ["ara"],
    "zh": ["cmn"],
}

# Length quality gates: skip fragments and walls of text.
MIN_CHARS = 8
MAX_CHARS = 240


def read_tsv_bz2(path: Path):
    with bz2.open(path, "rt", encoding="utf-8") as fh:
        for line in fh:
            parts = line.rstrip("\n").split("\t")
            yield parts


def load_sentences(exports: Path, code: str) -> dict[str, str]:
    """id -> text for one Tatoeba language."""
    path = exports / f"{code}_sentences.tsv.bz2"
    out: dict[str, str] = {}
    for parts in read_tsv_bz2(path):
        if len(parts) >= 3 and parts[1] == code:
            out[parts[0]] = parts[2]
    return out


def load_links(exports: Path, code: str) -> list[tuple[str, str]]:
    """(english_id, target_id) pairs from eng-<code>_links.tsv.bz2."""
    path = exports / f"eng-{code}_links.tsv.bz2"
    out: list[tuple[str, str]] = []
    for parts in read_tsv_bz2(path):
        if len(parts) >= 2:
            out.append((parts[0], parts[1]))
    return out


def acceptable(text: str) -> bool:
    text = text.strip()
    if not (MIN_CHARS <= len(text) <= MAX_CHARS):
        return False
    # Reject placeholder/malformed rows.
    if "\u0000" in text or text.lower() in {"null", "\\n", "-"}:
        return False
    return True


def build_direction(
    exports: Path,
    lang_key: str,
    target_codes: list[str],
    english: dict[str, str],
    max_pairs: int,
) -> list[dict]:
    sentences: dict[str, str] = {}
    for code in target_codes:
        sentences.update(load_sentences(exports, code))

    seen_pairs: set[tuple[str, str]] = set()
    rows: list[dict] = []
    for code in target_codes:
        for eng_id, tgt_id in load_links(exports, code):
            if len(rows) >= max_pairs:
                break
            if (eng_id, tgt_id) in seen_pairs:
                continue
            seen_pairs.add((eng_id, tgt_id))
            eng_text = english.get(eng_id)
            tgt_text = sentences.get(tgt_id)
            if not eng_text or not tgt_text:
                continue
            if not acceptable(eng_text) or not acceptable(tgt_text):
                continue
            rows.append(
                {
                    "id": f"tat_{lang_key}_{eng_id}_{tgt_id}",
                    "lesson_id": "REPLACE_WITH_LESSON_ID",
                    "front_text": tgt_text.strip(),
                    "back_text": eng_text.strip(),
                    "context_sentence": None,
                    "audio_url": None,  # CC0 audio attached later (Common Voice)
                    "source": "tatoeba",
                    "source_attribution": TATOEBA_ATTRIBUTION,
                    "tatoeba_source_id": tgt_id,
                    "tatoeba_link_id": eng_id,
                }
            )
        if len(rows) >= max_pairs:
            break
    return rows


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--exports", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--max-pairs", type=int, default=2000)
    args = parser.parse_args()

    exports = Path(args.exports)
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    english = load_sentences(exports, "eng")
    print(f"loaded {len(english)} English sentences")

    total = 0
    for lang_key, codes in TARGET_CODES.items():
        rows = build_direction(exports, lang_key, codes, english, args.max_pairs)
        dest = out_dir / f"{lang_key}_from_en.json"
        dest.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
        total += len(rows)
        print(f"{lang_key}: {len(rows)} pairs -> {dest}")

    print(f"\nTOTAL: {total} flashcard rows (is_reviewed stays false until native review)")
    return 0 if total > 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
