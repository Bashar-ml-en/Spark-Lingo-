"""
Spark Lingo content pipeline — Mozilla Common Voice ingestion.

Common Voice (https://commonvoice.mozilla.org/en/datasets) publishes
CC0-licensed native-speaker audio for 130+ languages, released quarterly
as per-language tarballs (clips/ + validated.tsv). Because it requires
clicking through an email-gated download on their site, this script
does NOT fetch automatically — it processes a dataset you've already
downloaded and unzipped locally, then uploads validated clips to
Supabase Storage and links them to flashcard rows by matching sentence
text (e.g. against Tatoeba-sourced flashcards from fetch_tatoeba.py).

Directory expected (Common Voice's standard export layout):
    cv-corpus-<version>-<date>/<lang_code>/
        validated.tsv
        clips/
            common_voice_<lang>_<id>.mp3

Usage:
    python process_common_voice.py \
        --cv-dir ./cv-corpus-19.0-2024-09-13/fr \
        --flashcards ../output/fr_flashcards_seed.json \
        --supabase-url https://<project>.supabase.co \
        --supabase-bucket pronunciation-audio \
        --out ../output/fr_flashcards_with_audio.json
"""

import argparse
import csv
import json
from pathlib import Path


def load_validated_clips(cv_dir: Path) -> dict[str, Path]:
    """Map normalized sentence text -> local clip path, using only
    community-validated (2+ upvote) recordings for quality."""
    tsv_path = cv_dir / "validated.tsv"
    mapping: dict[str, Path] = {}
    with tsv_path.open(encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter="\t")
        for row in reader:
            sentence = row.get("sentence", "").strip()
            clip_file = row.get("path", "").strip()
            if not sentence or not clip_file:
                continue
            key = sentence.lower().strip()
            # keep first validated clip found per sentence
            mapping.setdefault(key, cv_dir / "clips" / clip_file)
    return mapping


def attach_audio_to_flashcards(flashcards_path: Path, clip_map: dict[str, Path]) -> list[dict]:
    flashcards = json.loads(flashcards_path.read_text(encoding="utf-8"))
    matched = 0
    for card in flashcards:
        key = card["front_text"].lower().strip()
        clip_path = clip_map.get(key)
        if clip_path and clip_path.exists():
            card["native_audio_local_path"] = str(clip_path)
            card["native_audio_source"] = "common_voice"
            card["source_attribution"] += " | Voice clips \u00a9 Mozilla Common Voice contributors (CC0)"
            matched += 1
    print(f"Matched {matched}/{len(flashcards)} flashcards to native-speaker audio")
    return flashcards


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--cv-dir", required=True, help="Path to unzipped Common Voice language folder")
    parser.add_argument("--flashcards", required=True, help="Flashcard JSON from fetch_tatoeba.py")
    parser.add_argument("--out", required=True)
    parser.add_argument("--supabase-url", help="Optional: project URL to upload clips to Storage")
    parser.add_argument("--supabase-bucket", default="pronunciation-audio")
    args = parser.parse_args()

    cv_dir = Path(args.cv_dir)
    clip_map = load_validated_clips(cv_dir)
    merged = attach_audio_to_flashcards(Path(args.flashcards), clip_map)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(merged, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(merged)} merged flashcard rows to {out_path}")

    if args.supabase_url:
        print(
            "NOTE: actual upload to Supabase Storage needs the "
            "supabase-py client + a service-role key — intentionally "
            "left as a manual step here so a service key never ends up "
            "in a checked-in script. See README for the 10-line upload loop."
        )


if __name__ == "__main__":
    main()
