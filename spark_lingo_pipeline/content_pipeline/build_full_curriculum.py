"""



Spark Lingo — full-course curriculum builder.







Generates a complete syllabus_master.json for ALL 15 catalog languages from



Tatoeba dataset exports (CC-BY 2.0). Every flashcard is a real, linked



sentence pair — no invented content.







Course structure per language:



    up to 10 thematic units x 5 lessons x up to 12 flashcards



Theme assignment is done by keyword classification of the ENGLISH side of



each pair (deterministic, auditable). Units that cannot fill 60 cards keep



whatever real pairs exist (some low-resource languages have small corpora —



the pipeline never pads with invented sentences).







Language-code map (verified against Tatoeba exports 2026-08-23):



    en=eng fr=fra de=deu es=spa it=ita pt=por zh=cmn ja=jpn ko=kor



    ru=rus ar=ara hi=hin th=tha tl=tgl ms=zsm+zlm



"""







import argparse



import bz2



import json



from pathlib import Path







TATOEBA_ATTRIBUTION = "Sentences © Tatoeba.org contributors (CC-BY 2.0)"







LANGS = {



    # curriculumKey -> (display id prefix, [tatoeba codes])



    "english":      ("en", ["eng"]),



    "french":       ("fr", ["fra"]),



    "german":       ("de", ["deu"]),



    "spanish":      ("es", ["spa"]),



    "italian":      ("it", ["ita"]),



    "portuguese":   ("pt", ["por"]),



    "mandarin":     ("zh", ["cmn"]),



    "japanese":     ("ja", ["jpn"]),



    "korean":       ("ko", ["kor"]),



    "russian":      ("ru", ["rus"]),



    "arabic":       ("ar", ["ara"]),



    "hindi":        ("hi", ["hin"]),



    "thai":         ("th", ["tha"]),



    "tagalog":      ("tl", ["tgl"]),



    "bahasa melayu": ("ms", ["zsm", "zlm"]),



}







UNIT_THEMES = [



    ("Greetings & Introductions", ["hello", "hi", "nice to meet", "name is", "my name", "good morning", "good night", "goodbye", "how are you", "introduce", "pleased", "welcome"]),



    ("Food & Drink", ["eat", "food", "drink", "water", "coffee", "tea", "hungry", "breakfast", "lunch", "dinner", "restaurant", "cook", "meal", "fruit", "bread", "rice", "milk"]),



    ("Travel & Transport", ["airport", "train", "bus", "car", "taxi", "ticket", "hotel", "trip", "travel", "flight", "station", "city", "country", "visit", "map", "road", "drive"]),



    ("Family & People", ["mother", "father", "sister", "brother", "family", "child", "children", "friend", "wife", "husband", "son", "daughter", "grandmother", "grandfather", "people"]),



    ("Work & School", ["work", "job", "office", "school", "study", "teacher", "student", "learn", "class", "homework", "exam", "boss", "meeting", "company", "book", "read"]),



    ("Weather & Nature", ["rain", "snow", "sun", "weather", "cold", "hot", "warm", "wind", "storm", "season", "spring", "summer", "winter", "autumn", "flower", "tree", "mountain", "sea", "river"]),



    ("Shopping & Money", ["buy", "shop", "store", "price", "money", "pay", "cheap", "expensive", "cost", "sell", "market", "cash", "change", "discount"]),



    ("Health & Body", ["doctor", "hospital", "sick", "pain", "hurt", "medicine", "health", "sleep", "tired", "head", "hand", "eye", "heart", "exercise", "rest"]),



    ("Home & Daily Life", ["home", "house", "room", "door", "window", "kitchen", "bed", "morning", "evening", "today", "tomorrow", "yesterday", "time", "clock", "phone", "key"]),



    ("Feelings & Opinions", ["happy", "sad", "love", "like", "think", "feel", "afraid", "angry", "hope", "believe", "agree", "sorry", "thank", "great", "beautiful", "funny", "interesting"]),



]







MIN_CHARS = 6



MAX_CHARS = 200



CARDS_PER_LESSON = 12



LESSONS_PER_UNIT = 5











def load_sentences(exports: Path, code: str) -> dict:



    path = exports / f"{code}_sentences.tsv.bz2"



    if not path.exists():



        return {}



    out = {}



    with bz2.open(path, "rt", encoding="utf-8") as fh:



        for line in fh:



            parts = line.rstrip("\n").split("\t")



            if len(parts) >= 3 and parts[1] == code:



                out[parts[0]] = parts[2]



    return out











_bridge_cache: dict = {}











def sentences_bridge(sentence_id: str, codes: list, exports: Path):



    """Look up a sentence in any bridge-language file (English course mode)."""



    global _bridge_cache



    if not _bridge_cache:



        for code in codes:



            _bridge_cache.update(load_sentences(exports, code))



    return _bridge_cache.get(sentence_id)











def load_pairs(exports: Path, codes: list, inverted: bool = False) -> list:



    """Deduplicated (eng_id, tgt_id) links for all codes of a language.







    With inverted=True the returned pairs are (foreign_id, eng_id): used for



    the ENGLISH course, where the learner's target language is English and



    the bridging language supplies the translation side.



    """



    seen = set()



    pairs = []



    for code in codes:



        path = exports / f"eng-{code}_links.tsv.bz2"



        if not path.exists():



            continue



        with bz2.open(path, "rt", encoding="utf-8") as fh:



            for line in fh:



                parts = line.rstrip("\n").split("\t")



                if len(parts) >= 2:



                    pair = (parts[1], parts[0]) if inverted else (parts[0], parts[1])



                    if pair not in seen:



                        seen.add(pair)



                        pairs.append(pair)



    return pairs











def classify(english: str) -> int:



    """Return unit index for an English sentence (keyword bucketing)."""



    text = english.lower()



    best_idx, best_hits = None, 0



    for idx, (_name, keywords) in enumerate(UNIT_THEMES):



        hits = sum(1 for kw in keywords if kw in text)



        if hits > best_hits:



            best_idx, best_hits = idx, hits



    return best_idx if best_idx is not None else -1











def acceptable(front: str, back: str) -> bool:



    if not (MIN_CHARS <= len(front) <= MAX_CHARS):



        return False



    if not (MIN_CHARS <= len(back) <= MAX_CHARS):



        return False



    if "\u0000" in front or "\ufffd" in front or "\u0000" in back or "\ufffd" in back:



        return False



    if front.strip().lower() == back.strip().lower():



        return False



    return True











def build_language(prefix: str, codes: list, english: dict, exports: Path,



                   max_cards_per_language: int,



                   bridge_codes: list | None = None) -> tuple:



    """Build one language's course.







    Normal mode: front = target-language sentence, back = English bridge.



    English mode (bridge_codes given): front = English sentence, back =



    native-language bridge; pairs come from eng-<bridge>_links inverted.



    """



    is_english_course = bridge_codes is not None



    if is_english_course:



        sentences = english



        link_codes = bridge_codes



        inverted = True



    else:



        sentences = {}



        for code in codes:



            sentences.update(load_sentences(exports, code))



        link_codes = codes



        inverted = False







    # Collect real pairs per unit theme



    themed: list = [[] for _ in UNIT_THEMES]



    unthemed: list = []



    seen_text = set()



    collected = 0



    for first_id, second_id in load_pairs(exports, link_codes, inverted=inverted):

        if is_english_course:

            # pair = (foreign_id, eng_id): front is the English sentence the

            # learner studies; back is their native-language bridge.

            front_text = english.get(second_id)

            bridge_text = sentences_bridge(first_id, bridge_codes, exports)

            theme_source = front_text

        else:

            # pair = (eng_id, tgt_id): front is the target-language sentence;

            # back is the English bridge.

            front_text = sentences.get(second_id)

            bridge_text = english.get(first_id)

            theme_source = bridge_text

        if not front_text or not bridge_text:

            continue

        if not acceptable(front_text, bridge_text):

            continue

        pair_key = (front_text.strip(), bridge_text.strip())

        if pair_key in seen_text:

            continue

        seen_text.add(pair_key)

        idx = classify(theme_source)

        if idx >= 0:



            themed[idx].append((front_text.strip(), bridge_text.strip()))



        else:



            unthemed.append((front_text.strip(), bridge_text.strip()))



        collected += 1



        if collected >= max_cards_per_language * 3:



            break  # collect enough candidates before trimming







    # Fill units; spill unthemed pairs into the weakest units



    unit_cards: list = []



    for pairs in themed:



        pairs.sort(key=lambda p: (len(p[0]), p[0]))



        unit_cards.append(pairs)



    unthemed.sort(key=lambda p: (len(p[0]), p[0]))



    # top up the emptiest units so every unit gets real content when possible



    while unthemed:



        weakest = min(range(len(unit_cards)), key=lambda i: len(unit_cards[i]))



        if len(unit_cards[weakest]) >= CARDS_PER_LESSON * LESSONS_PER_UNIT:



            break



        unit_cards[weakest].append(unthemed.pop(0))







    units = []



    card_counter = 0



    for ui, (name, _kws) in enumerate(UNIT_THEMES, start=1):



        cards_all = unit_cards[ui - 1][:CARDS_PER_LESSON * LESSONS_PER_UNIT]



        if not cards_all:



            continue  # never ship an empty unit



        lessons = []



        for li in range(LESSONS_PER_UNIT):



            chunk = cards_all[li * CARDS_PER_LESSON:(li + 1) * CARDS_PER_LESSON]



            if not chunk:



                continue



            flashcards = []



            for front, back in chunk:



                card_counter += 1



                flashcards.append({



                    "id": f"{prefix}_card_{card_counter}",



                    "front": front,



                    "back": back,



                    "context": None,



                })



            lessons.append({



                "id": f"{prefix}_u{ui}_l{li + 1}",



                "title": f"{name} {li + 1}" if LESSONS_PER_UNIT > 1 else name,



                "description": f"Real sentence practice: {name.lower()} (Tatoeba CC-BY).",



                "flashcards": flashcards,



            })



        units.append({



            "id": f"{prefix}_unit_{ui}",



            "title": name,



            "description": f"Thematic practice built from real {name.lower()} sentences.",



            "lessons": lessons,



        })







    total_cards = sum(len(l["flashcards"]) for u in units for l in u["lessons"])



    return units, total_cards











def main() -> int:

    parser = argparse.ArgumentParser()

    parser.add_argument("--exports", required=True)

    parser.add_argument("--out", required=True)

    parser.add_argument("--max-cards", type=int, default=600)

    parser.add_argument(
        "--lessons-per-unit",
        type=int,
        default=5,
        help="Lessons generated per thematic unit (default 5). Raise to ship "
             "more vocabulary per language; each lesson holds "
             "CARDS_PER_LESSON cards.",
    )

    args = parser.parse_args()

    global LESSONS_PER_UNIT
    LESSONS_PER_UNIT = max(1, args.lessons_per_unit)






    exports = Path(args.exports)



    english = load_sentences(exports, "eng")



    print(f"loaded {len(english)} English sentences")







    syllabus = {}



    grand_total = 0



    # Malay first: the product's home market is Malaysia, so English-course

    # bridges prefer zsm/zlm, then the remaining languages alphabetically.

    all_bridges = sorted({c for _, (_, cs) in LANGS.items() for c in cs if cs != ["eng"]})

    bridge_codes = ["zsm", "zlm"] + [c for c in all_bridges if c not in ("zsm", "zlm")]



    for key, (prefix, codes) in LANGS.items():



        if codes == ["eng"]:



            # English course: English front, native-language bridge back.



            units, total = build_language(prefix, codes, english, exports,



                                          args.max_cards, bridge_codes=bridge_codes)



        else:



            units, total = build_language(prefix, codes, english, exports, args.max_cards)



        syllabus[key] = {"units": units}



        grand_total += total



        print(f"{key:>14}: {len(units)} units, "



              f"{sum(len(u['lessons']) for u in units)} lessons, {total} cards")







    out = Path(args.out)



    out.parent.mkdir(parents=True, exist_ok=True)



    out.write_text(json.dumps(syllabus, ensure_ascii=False, indent=2), encoding="utf-8")



    print(f"\nTOTAL: {grand_total} flashcards across {len(LANGS)} languages -> {out}")



    return 0 if grand_total > 0 else 1











if __name__ == "__main__":



    raise SystemExit(main())



