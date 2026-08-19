"""
Spark Lingo content pipeline — Tatoeba ingestion.

Pulls real, community-contributed sentence/translation pairs from the
Tatoeba public API (https://tatoeba.org/en/api_v0) and shapes them into
rows matching the app's `flashcards` table (Flashcard model in
lib/shared/models/).

Tatoeba's dataset is CC-BY 2.0 (attribution required — surface
"Sentences © Tatoeba.org contributors" somewhere in the app, e.g. an
About/Credits screen).

Usage:
    python fetch_tatoeba.py --from eng --to fra --max-sentences 500 \
        --out ../output/fr_flashcards_seed.json

Note: this repo's sandbox has no outbound network access to tatoeba.org,
so this script is meant to be run in your own dev/CI environment (e.g.
a GitHub Action or local machine) where it can reach the public internet,
then the output JSON gets bulk-inserted into Supabase.
"""

import argparse
import json
import time
from pathlib import Path

import requests

TATOEBA_SEARCH_URL = "https://tatoeba.org/eng/api_v0/search"


def fetch_sentence_pairs(from_lang: str, to_lang: str, max_sentences: int) -> list[dict]:
    """
    from_lang/to_lang use Tatoeba's 3-letter codes (eng, fra, deu, spa, ita,
    por, cmn, jpn, kor, rus, ara, hin, ...). Full list:
    https://tatoeba.org/en/api_v0#!/search/getSearch
    """
    results = []
    page = 1
    while len(results) < max_sentences:
        params = {
            "from": from_lang,
            "to": to_lang,
            "trans_filter": "limit",
            "trans_to": to_lang,
            "sort": "relevance",
            "page": page,
        }
        resp = requests.get(TATOEBA_SEARCH_URL, params=params, timeout=30)
        resp.raise_for_status()
        payload = resp.json()

        rows = payload.get("results", [])
        if not rows:
            break

        for row in rows:
            translations = row.get("translations", [])
            flat_translations = [t for group in translations for t in group]
            if not flat_translations:
                continue
            best = flat_translations[0]
            results.append(
                {
                    "source_text": row.get("text"),
                    "source_lang": from_lang,
                    "target_text": best.get("text"),
                    "target_lang": to_lang,
                    "tatoeba_source_id": row.get("id"),
                    "tatoeba_translation_id": best.get("id"),
                    "has_audio": bool(row.get("audios")),
                    "audio_url": (
                        f"https://audio.tatoeba.org/sentences/{from_lang}/{row['audios'][0]['id']}.mp3"
                        if row.get("audios")
                        else None
                    ),
                }
            )
            if len(results) >= max_sentences:
                break

        page += 1
        time.sleep(0.5)  # be polite to a free community API

    return results


def to_flashcard_rows(pairs: list[dict], unit_id_placeholder: str = "REPLACE_WITH_UNIT_ID") -> list[dict]:
    """Shape into rows ready for the `flashcards` table / SM-2 engine."""
    rows = []
    for p in pairs:
        rows.append(
            {
                "unit_id": unit_id_placeholder,
                "front_text": p["target_text"],
                "back_text": p["source_text"],
                "audio_url": p["audio_url"],
                "source": "tatoeba",
                "source_attribution": "Sentences © Tatoeba.org contributors (CC-BY 2.0)",
                "srs_state": {
                    "e_factor": 2.5,
                    "interval_days": 0,
                    "repetitions": 0,
                    "due_at": None,
                },
            }
        )
    return rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--from", dest="from_lang", required=True, help="Tatoeba 3-letter source lang code")
    parser.add_argument("--to", dest="to_lang", required=True, help="Tatoeba 3-letter target lang code")
    parser.add_argument("--max-sentences", type=int, default=300)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    pairs = fetch_sentence_pairs(args.from_lang, args.to_lang, args.max_sentences)
    rows = to_flashcard_rows(pairs)

    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {len(rows)} flashcard rows to {out_path}")


if __name__ == "__main__":
    main()
