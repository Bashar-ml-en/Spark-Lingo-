// Writing-system academy data.
//
// Honesty contract: the character inventories below are the standardized
// alphabets/syllabaries (Unicode-block canonical sets). Names and
// romanizations follow the conventional linguistic transcription of each
// script. Example words are high-frequency vocabulary; no invented words.

class ScriptEntry {
  final String glyph;
  final String name; // conventional letter/symbol name
  final String roman; // romanized value learners use for typing/recall
  final String? sound; // short pronunciation hint
  final String? example; // example word in the script
  final String? exampleMeaning;

  const ScriptEntry({
    required this.glyph,
    required this.name,
    required this.roman,
    this.sound,
    this.example,
    this.exampleMeaning,
  });
}

class ScriptSection {
  final String title;
  final String? subtitle;
  final List<ScriptEntry> entries;

  const ScriptSection({required this.title, this.subtitle, required this.entries});
}

class ScriptAcademy {
  final String languageKey;
  final String languageName;
  final String scriptName;
  final String intro;
  final List<ScriptSection> sections;

  const ScriptAcademy({
    required this.languageKey,
    required this.languageName,
    required this.scriptName,
    required this.intro,
    required this.sections,
  });
}

const ScriptAcademy russianAcademy = ScriptAcademy(
  languageKey: 'ru',
  languageName: 'Russian',
  scriptName: 'Cyrillic',
  intro:
      'Russian uses 33 Cyrillic letters. Ten vowels, twenty-one consonants, '
      'and two signs (ъ, ь) that modify sounds instead of being pronounced.',
  sections: [
    ScriptSection(title: 'The alphabet', subtitle: '33 letters, in order', entries: [
      ScriptEntry(glyph: 'А а', name: 'a', roman: 'a', sound: 'like "father"', example: 'арбуз', exampleMeaning: 'watermelon'),
      ScriptEntry(glyph: 'Б б', name: 'be', roman: 'b', sound: 'like "bat"', example: 'банк', exampleMeaning: 'bank'),
      ScriptEntry(glyph: 'В в', name: 've', roman: 'v', sound: 'like "vet"', example: 'вода', exampleMeaning: 'water'),
      ScriptEntry(glyph: 'Г г', name: 'ge', roman: 'g', sound: 'like "go"', example: 'город', exampleMeaning: 'city'),
      ScriptEntry(glyph: 'Д д', name: 'de', roman: 'd', sound: 'like "dog"', example: 'дом', exampleMeaning: 'house'),
      ScriptEntry(glyph: 'Е е', name: 'ye', roman: 'ye', sound: 'like "yes"', example: 'если', exampleMeaning: 'if'),
      ScriptEntry(glyph: 'Ё ё', name: 'yo', roman: 'yo', sound: 'like "yolk"', example: 'ёж', exampleMeaning: 'hedgehog'),
      ScriptEntry(glyph: 'Ж ж', name: 'zhe', roman: 'zh', sound: 'like "vision"', example: 'жизнь', exampleMeaning: 'life'),
      ScriptEntry(glyph: 'З з', name: 'ze', roman: 'z', sound: 'like "zoo"', example: 'замок', exampleMeaning: 'castle'),
      ScriptEntry(glyph: 'И и', name: 'i', roman: 'i', sound: 'like "meet"', example: 'игра', exampleMeaning: 'game'),
      ScriptEntry(glyph: 'Й й', name: 'short i', roman: 'y', sound: 'like "boy" ending', example: 'йогурт', exampleMeaning: 'yogurt'),
      ScriptEntry(glyph: 'К к', name: 'ka', roman: 'k', sound: 'like "kite"', example: 'кот', exampleMeaning: 'cat'),
      ScriptEntry(glyph: 'Л л', name: 'el', roman: 'l', sound: 'like "lamp"', example: 'луна', exampleMeaning: 'moon'),
      ScriptEntry(glyph: 'М м', name: 'em', roman: 'm', sound: 'like "map"', example: 'молоко', exampleMeaning: 'milk'),
      ScriptEntry(glyph: 'Н н', name: 'en', roman: 'n', sound: 'like "net"', example: 'ночь', exampleMeaning: 'night'),
      ScriptEntry(glyph: 'О о', name: 'o', roman: 'o', sound: 'like "more" (stressed)', example: 'окно', exampleMeaning: 'window'),
      ScriptEntry(glyph: 'П п', name: 'pe', roman: 'p', sound: 'like "pen"', example: 'папа', exampleMeaning: 'dad'),
      ScriptEntry(glyph: 'Р р', name: 'er', roman: 'r', sound: 'rolled r, like Spanish', example: 'рука', exampleMeaning: 'hand'),
      ScriptEntry(glyph: 'С с', name: 'es', roman: 's', sound: 'like "sun"', example: 'солнце', exampleMeaning: 'sun'),
      ScriptEntry(glyph: 'Т т', name: 'te', roman: 't', sound: 'like "top"', example: 'тигр', exampleMeaning: 'tiger'),
      ScriptEntry(glyph: 'У у', name: 'u', roman: 'u', sound: 'like "moon"', example: 'утро', exampleMeaning: 'morning'),
      ScriptEntry(glyph: 'Ф ф', name: 'ef', roman: 'f', sound: 'like "fun"', example: 'фото', exampleMeaning: 'photo'),
      ScriptEntry(glyph: 'Х х', name: 'kha', roman: 'kh', sound: 'like Scottish "loch"', example: 'хлеб', exampleMeaning: 'bread'),
      ScriptEntry(glyph: 'Ц ц', name: 'tse', roman: 'ts', sound: 'like "cats" ending', example: 'цветок', exampleMeaning: 'flower'),
      ScriptEntry(glyph: 'Ч ч', name: 'che', roman: 'ch', sound: 'like "church"', example: 'чай', exampleMeaning: 'tea'),
      ScriptEntry(glyph: 'Ш ш', name: 'sha', roman: 'sh', sound: 'like "shoe"', example: 'школа', exampleMeaning: 'school'),
      ScriptEntry(glyph: 'Щ щ', name: 'shcha', roman: 'shch', sound: 'soft long "sh"', example: 'щука', exampleMeaning: 'pike (fish)'),
      ScriptEntry(glyph: 'Ъ ъ', name: 'hard sign', roman: 'ʺ', sound: 'not pronounced; separates sounds'),
      ScriptEntry(glyph: 'Ы ы', name: 'yery', roman: 'y', sound: 'deep "ee" from the throat', example: 'сын', exampleMeaning: 'son'),
      ScriptEntry(glyph: 'Ь ь', name: 'soft sign', roman: 'ʹ', sound: 'not pronounced; softens the letter before it'),
      ScriptEntry(glyph: 'Э э', name: 'e', roman: 'e', sound: 'like "met"', example: 'это', exampleMeaning: 'this'),
      ScriptEntry(glyph: 'Ю ю', name: 'yu', roman: 'yu', sound: 'like "you"', example: 'юг', exampleMeaning: 'south'),
      ScriptEntry(glyph: 'Я я', name: 'ya', roman: 'ya', sound: 'like "yard"', example: 'яблоко', exampleMeaning: 'apple'),
    ]),
  ],
);

const ScriptAcademy japaneseAcademy = ScriptAcademy(
  languageKey: 'ja',
  languageName: 'Japanese',
  scriptName: 'Hiragana & Katakana',
  intro:
      'Japanese uses three scripts. Start with the two phonetic ones: '
      'hiragana (native words, grammar) and katakana (foreign words). Each '
      'has 46 basic characters representing one syllable each.',
  sections: [
    ScriptSection(title: 'Hiragana', subtitle: '46 basic characters', entries: [
      ..._hiragana,
    ]),
    ScriptSection(title: 'Katakana', subtitle: '46 basic characters', entries: [
      ..._katakana,
    ]),
  ],
);

const List<ScriptEntry> _hiragana = [
  ScriptEntry(glyph: 'あ', name: 'a', roman: 'a'),
  ScriptEntry(glyph: 'い', name: 'i', roman: 'i'),
  ScriptEntry(glyph: 'う', name: 'u', roman: 'u'),
  ScriptEntry(glyph: 'え', name: 'e', roman: 'e'),
  ScriptEntry(glyph: 'お', name: 'o', roman: 'o'),
  ScriptEntry(glyph: 'か', name: 'ka', roman: 'ka', example: 'かさ', exampleMeaning: 'umbrella (kasa)'),
  ScriptEntry(glyph: 'き', name: 'ki', roman: 'ki'),
  ScriptEntry(glyph: 'く', name: 'ku', roman: 'ku', example: 'くち', exampleMeaning: 'mouth (kuchi)'),
  ScriptEntry(glyph: 'け', name: 'ke', roman: 'ke'),
  ScriptEntry(glyph: 'こ', name: 'ko', roman: 'ko'),
  ScriptEntry(glyph: 'さ', name: 'sa', roman: 'sa', example: 'さくら', exampleMeaning: 'cherry blossom (sakura)'),
  ScriptEntry(glyph: 'し', name: 'shi', roman: 'shi'),
  ScriptEntry(glyph: 'す', name: 'su', roman: 'su', example: 'すし', exampleMeaning: 'sushi'),
  ScriptEntry(glyph: 'せ', name: 'se', roman: 'se'),
  ScriptEntry(glyph: 'そ', name: 'so', roman: 'so'),
  ScriptEntry(glyph: 'た', name: 'ta', roman: 'ta'),
  ScriptEntry(glyph: 'ち', name: 'chi', roman: 'chi'),
  ScriptEntry(glyph: 'つ', name: 'tsu', roman: 'tsu'),
  ScriptEntry(glyph: 'て', name: 'te', roman: 'te', example: 'て', exampleMeaning: 'hand (te)'),
  ScriptEntry(glyph: 'と', name: 'to', roman: 'to', example: 'とり', exampleMeaning: 'bird (tori)'),
  ScriptEntry(glyph: 'な', name: 'na', roman: 'na', example: 'なつ', exampleMeaning: 'summer (natsu)'),
  ScriptEntry(glyph: 'に', name: 'ni', roman: 'ni'),
  ScriptEntry(glyph: 'ぬ', name: 'nu', roman: 'nu', example: 'いぬ', exampleMeaning: 'dog (inu)'),
  ScriptEntry(glyph: 'ね', name: 'ne', roman: 'ne', example: 'ねこ', exampleMeaning: 'cat (neko)'),
  ScriptEntry(glyph: 'の', name: 'no', roman: 'no'),
  ScriptEntry(glyph: 'は', name: 'ha', roman: 'ha'),
  ScriptEntry(glyph: 'ひ', name: 'hi', roman: 'hi', example: 'ひと', exampleMeaning: 'person (hito)'),
  ScriptEntry(glyph: 'ふ', name: 'fu', roman: 'fu', example: 'ふね', exampleMeaning: 'boat (fune)'),
  ScriptEntry(glyph: 'へ', name: 'he', roman: 'he'),
  ScriptEntry(glyph: 'ほ', name: 'ho', roman: 'ho'),
  ScriptEntry(glyph: 'ま', name: 'ma', roman: 'ma'),
  ScriptEntry(glyph: 'み', name: 'mi', roman: 'mi', example: 'みず', exampleMeaning: 'water (mizu)'),
  ScriptEntry(glyph: 'む', name: 'mu', roman: 'mu'),
  ScriptEntry(glyph: 'め', name: 'me', roman: 'me', example: 'め', exampleMeaning: 'eye (me)'),
  ScriptEntry(glyph: 'も', name: 'mo', roman: 'mo'),
  ScriptEntry(glyph: 'や', name: 'ya', roman: 'ya', example: 'やま', exampleMeaning: 'mountain (yama)'),
  ScriptEntry(glyph: 'ゆ', name: 'yu', roman: 'yu', example: 'ゆき', exampleMeaning: 'snow (yuki)'),
  ScriptEntry(glyph: 'よ', name: 'yo', roman: 'yo'),
  ScriptEntry(glyph: 'ら', name: 'ra', roman: 'ra'),
  ScriptEntry(glyph: 'り', name: 'ri', roman: 'ri'),
  ScriptEntry(glyph: 'る', name: 'ru', roman: 'ru'),
  ScriptEntry(glyph: 'れ', name: 're', roman: 're'),
  ScriptEntry(glyph: 'ろ', name: 'ro', roman: 'ro'),
  ScriptEntry(glyph: 'わ', name: 'wa', roman: 'wa', example: 'わたし', exampleMeaning: 'I/me (watashi)'),
  ScriptEntry(glyph: 'を', name: 'wo', roman: 'wo', sound: 'object-marking particle, pronounced "o"'),
  ScriptEntry(glyph: 'ん', name: 'n', roman: 'n', sound: 'nasal n ending'),
];

const List<ScriptEntry> _katakana = [
  ScriptEntry(glyph: 'ア', name: 'a', roman: 'a'),
  ScriptEntry(glyph: 'イ', name: 'i', roman: 'i'),
  ScriptEntry(glyph: 'ウ', name: 'u', roman: 'u'),
  ScriptEntry(glyph: 'エ', name: 'e', roman: 'e'),
  ScriptEntry(glyph: 'オ', name: 'o', roman: 'o'),
  ScriptEntry(glyph: 'カ', name: 'ka', roman: 'ka', example: 'カメラ', exampleMeaning: 'camera'),
  ScriptEntry(glyph: 'キ', name: 'ki', roman: 'ki'),
  ScriptEntry(glyph: 'ク', name: 'ku', roman: 'ku'),
  ScriptEntry(glyph: 'ケ', name: 'ke', roman: 'ke'),
  ScriptEntry(glyph: 'コ', name: 'ko', roman: 'ko', example: 'コーヒー', exampleMeaning: 'coffee'),
  ScriptEntry(glyph: 'サ', name: 'sa', roman: 'sa'),
  ScriptEntry(glyph: 'シ', name: 'shi', roman: 'shi'),
  ScriptEntry(glyph: 'ス', name: 'su', roman: 'su'),
  ScriptEntry(glyph: 'セ', name: 'se', roman: 'se'),
  ScriptEntry(glyph: 'ソ', name: 'so', roman: 'so'),
  ScriptEntry(glyph: 'タ', name: 'ta', roman: 'ta', example: 'タクシー', exampleMeaning: 'taxi'),
  ScriptEntry(glyph: 'チ', name: 'chi', roman: 'chi'),
  ScriptEntry(glyph: 'ツ', name: 'tsu', roman: 'tsu'),
  ScriptEntry(glyph: 'テ', name: 'te', roman: 'te', example: 'テレビ', exampleMeaning: 'television'),
  ScriptEntry(glyph: 'ト', name: 'to', roman: 'to', example: 'トイレ', exampleMeaning: 'toilet'),
  ScriptEntry(glyph: 'ナ', name: 'na', roman: 'na'),
  ScriptEntry(glyph: 'ニ', name: 'ni', roman: 'ni'),
  ScriptEntry(glyph: 'ヌ', name: 'nu', roman: 'nu'),
  ScriptEntry(glyph: 'ネ', name: 'ne', roman: 'ne'),
  ScriptEntry(glyph: 'ノ', name: 'no', roman: 'no'),
  ScriptEntry(glyph: 'ハ', name: 'ha', roman: 'ha'),
  ScriptEntry(glyph: 'ヒ', name: 'hi', roman: 'hi'),
  ScriptEntry(glyph: 'フ', name: 'fu', roman: 'fu'),
  ScriptEntry(glyph: 'ヘ', name: 'he', roman: 'he'),
  ScriptEntry(glyph: 'ホ', name: 'ho', roman: 'ho', example: 'ホテル', exampleMeaning: 'hotel'),
  ScriptEntry(glyph: 'マ', name: 'ma', roman: 'ma'),
  ScriptEntry(glyph: 'ミ', name: 'mi', roman: 'mi'),
  ScriptEntry(glyph: 'ム', name: 'mu', roman: 'mu'),
  ScriptEntry(glyph: 'メ', name: 'me', roman: 'me'),
  ScriptEntry(glyph: 'モ', name: 'mo', roman: 'mo'),
  ScriptEntry(glyph: 'ヤ', name: 'ya', roman: 'ya'),
  ScriptEntry(glyph: 'ユ', name: 'yu', roman: 'yu'),
  ScriptEntry(glyph: 'ヨ', name: 'yo', roman: 'yo'),
  ScriptEntry(glyph: 'ラ', name: 'ra', roman: 'ra'),
  ScriptEntry(glyph: 'リ', name: 'ri', roman: 'ri'),
  ScriptEntry(glyph: 'ル', name: 'ru', roman: 'ru'),
  ScriptEntry(glyph: 'レ', name: 're', roman: 're'),
  ScriptEntry(glyph: 'ロ', name: 'ro', roman: 'ro'),
  ScriptEntry(glyph: 'ワ', name: 'wa', roman: 'wa'),
  ScriptEntry(glyph: 'ヲ', name: 'wo', roman: 'wo'),
  ScriptEntry(glyph: 'ン', name: 'n', roman: 'n'),
];

const ScriptAcademy koreanAcademy = ScriptAcademy(
  languageKey: 'ko',
  languageName: 'Korean',
  scriptName: 'Hangul',
  intro:
      'Hangul is built from 24 basic jamo: 14 consonants and 10 vowels. '
      'Letters combine into syllable blocks, so every word you read is a '
      'grid of these building blocks.',
  sections: [
    ScriptSection(title: 'Consonants', subtitle: '14 basic', entries: [
      ScriptEntry(glyph: 'ㄱ', name: 'giyeok', roman: 'g/k', sound: 'g at start of syllable, k at end', example: '가방', exampleMeaning: 'bag (gabang)'),
      ScriptEntry(glyph: 'ㄴ', name: 'nieun', roman: 'n', example: '나라', exampleMeaning: 'country (nara)'),
      ScriptEntry(glyph: 'ㄷ', name: 'digeut', roman: 'd/t', example: '달', exampleMeaning: 'moon (dal)'),
      ScriptEntry(glyph: 'ㄹ', name: 'rieul', roman: 'r/l', example: '라면', exampleMeaning: 'ramyeon'),
      ScriptEntry(glyph: 'ㅁ', name: 'mieum', roman: 'm', example: '물', exampleMeaning: 'water (mul)'),
      ScriptEntry(glyph: 'ㅂ', name: 'bieup', roman: 'b/p', example: '밥', exampleMeaning: 'rice (bap)'),
      ScriptEntry(glyph: 'ㅅ', name: 'siot', roman: 's', example: '사람', exampleMeaning: 'person (saram)'),
      ScriptEntry(glyph: 'ㅇ', name: 'ieung', roman: 'silent/ng', sound: 'silent at start, "ng" at end', example: '아침', exampleMeaning: 'morning (achim)'),
      ScriptEntry(glyph: 'ㅈ', name: 'jieut', roman: 'j', example: '집', exampleMeaning: 'house (jip)'),
      ScriptEntry(glyph: 'ㅊ', name: 'chieut', roman: 'ch', example: '차', exampleMeaning: 'tea/car (cha)'),
      ScriptEntry(glyph: 'ㅋ', name: 'kieuk', roman: 'k', example: '커피', exampleMeaning: 'coffee (keopi)'),
      ScriptEntry(glyph: 'ㅌ', name: 'tieut', roman: 't', example: '토끼', exampleMeaning: 'rabbit (tokki)'),
      ScriptEntry(glyph: 'ㅍ', name: 'pieup', roman: 'p', example: '피자', exampleMeaning: 'pizza (pija)'),
      ScriptEntry(glyph: 'ㅎ', name: 'hieut', roman: 'h', example: '하늘', exampleMeaning: 'sky (haneul)'),
    ]),
    ScriptSection(title: 'Vowels', subtitle: '10 basic', entries: [
      ScriptEntry(glyph: 'ㅏ', name: 'a', roman: 'a', sound: 'like "father"'),
      ScriptEntry(glyph: 'ㅑ', name: 'ya', roman: 'ya'),
      ScriptEntry(glyph: 'ㅓ', name: 'eo', roman: 'eo', sound: 'open "uh" like "butter"'),
      ScriptEntry(glyph: 'ㅕ', name: 'yeo', roman: 'yeo'),
      ScriptEntry(glyph: 'ㅗ', name: 'o', roman: 'o', sound: 'like "go"'),
      ScriptEntry(glyph: 'ㅛ', name: 'yo', roman: 'yo'),
      ScriptEntry(glyph: 'ㅜ', name: 'u', roman: 'u', sound: 'like "moon"'),
      ScriptEntry(glyph: 'ㅠ', name: 'yu', roman: 'yu'),
      ScriptEntry(glyph: 'ㅡ', name: 'eu', roman: 'eu', sound: 'unrounded "oo"'),
      ScriptEntry(glyph: 'ㅣ', name: 'i', roman: 'i', sound: 'like "meet"'),
    ]),
  ],
);

const ScriptAcademy arabicAcademy = ScriptAcademy(
  languageKey: 'ar',
  languageName: 'Arabic',
  scriptName: 'Arabic alphabet',
  intro:
      'Arabic has 28 letters, written right to left. Most letters change '
      'shape depending on position (initial, medial, final). Short vowels '
      'are marks above and below the letters.',
  sections: [
    ScriptSection(title: 'The alphabet', subtitle: '28 letters, in order', entries: [
      ScriptEntry(glyph: 'ا', name: 'alif', roman: 'a', sound: 'long "aa"', example: 'أسد', exampleMeaning: 'lion (asad)'),
      ScriptEntry(glyph: 'ب', name: 'ba', roman: 'b', example: 'باب', exampleMeaning: 'door (bab)'),
      ScriptEntry(glyph: 'ت', name: 'ta', roman: 't', example: 'تفاحة', exampleMeaning: 'apple (tuffaha)'),
      ScriptEntry(glyph: 'ث', name: 'tha', roman: 'th', sound: 'like "think"', example: 'ثعلب', exampleMeaning: 'fox (tha\'lab)'),
      ScriptEntry(glyph: 'ج', name: 'jim', roman: 'j', example: 'جمل', exampleMeaning: 'camel (jamal)'),
      ScriptEntry(glyph: 'ح', name: 'ha', roman: 'h', sound: 'deep breathy h', example: 'حصان', exampleMeaning: 'horse (hisan)'),
      ScriptEntry(glyph: 'خ', name: 'kha', roman: 'kh', sound: 'like Scottish "loch"', example: 'خبز', exampleMeaning: 'bread (khubz)'),
      ScriptEntry(glyph: 'د', name: 'dal', roman: 'd', example: 'دب', exampleMeaning: 'bear (dubb)'),
      ScriptEntry(glyph: 'ذ', name: 'dhal', roman: 'dh', sound: 'like "this"', example: 'ذهب', exampleMeaning: 'gold (dhahab)'),
      ScriptEntry(glyph: 'ر', name: 'ra', roman: 'r', sound: 'rolled r', example: 'رمان', exampleMeaning: 'pomegranate (rumman)'),
      ScriptEntry(glyph: 'ز', name: 'zay', roman: 'z', example: 'زهرة', exampleMeaning: 'flower (zahra)'),
      ScriptEntry(glyph: 'س', name: 'sin', roman: 's', example: 'سماء', exampleMeaning: 'sky (sama\')'),
      ScriptEntry(glyph: 'ش', name: 'shin', roman: 'sh', example: 'شمس', exampleMeaning: 'sun (shams)'),
      ScriptEntry(glyph: 'ص', name: 'sad', roman: 's', sound: 'emphatic deep s', example: 'صقر', exampleMeaning: 'falcon (saqr)'),
      ScriptEntry(glyph: 'ض', name: 'dad', roman: 'd', sound: 'emphatic deep d', example: 'ضوء', exampleMeaning: 'light (daw\')'),
      ScriptEntry(glyph: 'ط', name: 'ta (emphatic)', roman: 't', sound: 'emphatic deep t', example: 'طاولة', exampleMeaning: 'table (tawila)'),
      ScriptEntry(glyph: 'ظ', name: 'zha', roman: 'z', sound: 'emphatic deep dh', example: 'ظرف', exampleMeaning: 'envelope (zarf)'),
      ScriptEntry(glyph: 'ع', name: 'ayn', roman: '\'', sound: 'deep throat sound, no English equivalent', example: 'عين', exampleMeaning: 'eye (ayn)'),
      ScriptEntry(glyph: 'غ', name: 'ghayn', roman: 'gh', sound: 'French-style gargled r', example: 'غابة', exampleMeaning: 'forest (ghaba)'),
      ScriptEntry(glyph: 'ف', name: 'fa', roman: 'f', example: 'فيل', exampleMeaning: 'elephant (fil)'),
      ScriptEntry(glyph: 'ق', name: 'qaf', roman: 'q', sound: 'deep k from the throat', example: 'قمر', exampleMeaning: 'moon (qamar)'),
      ScriptEntry(glyph: 'ك', name: 'kaf', roman: 'k', example: 'كتاب', exampleMeaning: 'book (kitab)'),
      ScriptEntry(glyph: 'ل', name: 'lam', roman: 'l', example: 'ليمون', exampleMeaning: 'lemon (laymun)'),
      ScriptEntry(glyph: 'م', name: 'mim', roman: 'm', example: 'مفتاح', exampleMeaning: 'key (miftah)'),
      ScriptEntry(glyph: 'ن', name: 'nun', roman: 'n', example: 'نمر', exampleMeaning: 'tiger (nimr)'),
      ScriptEntry(glyph: 'ه', name: 'ha', roman: 'h', example: 'هلال', exampleMeaning: 'crescent (hilal)'),
      ScriptEntry(glyph: 'و', name: 'waw', roman: 'w/u', sound: 'w, or long "uu"', example: 'وردة', exampleMeaning: 'rose (warda)'),
      ScriptEntry(glyph: 'ي', name: 'ya', roman: 'y/i', sound: 'y, or long "ii"', example: 'يد', exampleMeaning: 'hand (yad)'),
    ]),
  ],
);

const ScriptAcademy hindiAcademy = ScriptAcademy(
  languageKey: 'hi',
  languageName: 'Hindi',
  scriptName: 'Devanagari',
  intro:
      'Hindi uses Devanagari, written left to right with a horizontal line '
      'across the top of words. Vowels attach to consonants as marks; a '
      'consonant alone carries an inherent "a" sound.',
  sections: [
    ScriptSection(title: 'Vowels', subtitle: 'independent forms', entries: [
      ScriptEntry(glyph: 'अ', name: 'a', roman: 'a', sound: 'short "u" like "about"'),
      ScriptEntry(glyph: 'आ', name: 'aa', roman: 'aa', sound: 'long "a" like "father"', example: 'आम', exampleMeaning: 'mango (aam)'),
      ScriptEntry(glyph: 'इ', name: 'i', roman: 'i', sound: 'short i'),
      ScriptEntry(glyph: 'ई', name: 'ii', roman: 'ii', sound: 'long "ee"', example: 'ईख', exampleMeaning: 'sugarcane'),
      ScriptEntry(glyph: 'उ', name: 'u', roman: 'u', sound: 'short u'),
      ScriptEntry(glyph: 'ऊ', name: 'uu', roman: 'uu', sound: 'long "oo"'),
      ScriptEntry(glyph: 'ए', name: 'e', roman: 'e', sound: 'like "they"'),
      ScriptEntry(glyph: 'ऐ', name: 'ai', roman: 'ai', sound: 'like "air"'),
      ScriptEntry(glyph: 'ओ', name: 'o', roman: 'o', sound: 'like "go"'),
      ScriptEntry(glyph: 'औ', name: 'au', roman: 'au', sound: 'like "house"'),
    ]),
    ScriptSection(title: 'Consonants', subtitle: '33 in the standard set', entries: [
      ScriptEntry(glyph: 'क', name: 'ka', roman: 'k', example: 'कमल', exampleMeaning: 'lotus (kamal)'),
      ScriptEntry(glyph: 'ख', name: 'kha', roman: 'kh', example: 'खरगोश', exampleMeaning: 'rabbit (khargosh)'),
      ScriptEntry(glyph: 'ग', name: 'ga', roman: 'g', example: 'गाय', exampleMeaning: 'cow (gaay)'),
      ScriptEntry(glyph: 'घ', name: 'gha', roman: 'gh', sound: 'aspirated g', example: 'घर', exampleMeaning: 'house (ghar)'),
      ScriptEntry(glyph: 'ङ', name: 'nga', roman: 'ng', sound: 'nasal, mostly in combinations'),
      ScriptEntry(glyph: 'च', name: 'cha', roman: 'ch', example: 'चाय', exampleMeaning: 'tea (chaay)'),
      ScriptEntry(glyph: 'छ', name: 'chha', roman: 'chh', sound: 'aspirated ch', example: 'छाता', exampleMeaning: 'umbrella (chhata)'),
      ScriptEntry(glyph: 'ज', name: 'ja', roman: 'j', example: 'जल', exampleMeaning: 'water (jal)'),
      ScriptEntry(glyph: 'झ', name: 'jha', roman: 'jh', sound: 'aspirated j', example: 'झंडा', exampleMeaning: 'flag (jhanda)'),
      ScriptEntry(glyph: 'ञ', name: 'nya', roman: 'ny', sound: 'nasal, mostly in combinations'),
      ScriptEntry(glyph: 'ट', name: 'ta (retroflex)', roman: 't', sound: 'tongue curled back', example: 'टमाटर', exampleMeaning: 'tomato (tamatar)'),
      ScriptEntry(glyph: 'ठ', name: 'tha (retroflex)', roman: 'th', example: 'ठंडा', exampleMeaning: 'cold (thanda)'),
      ScriptEntry(glyph: 'ड', name: 'da (retroflex)', roman: 'd', example: 'डर', exampleMeaning: 'fear (dar)'),
      ScriptEntry(glyph: 'ढ', name: 'dha (retroflex)', roman: 'dh', example: 'ढोल', exampleMeaning: 'drum (dhol)'),
      ScriptEntry(glyph: 'ण', name: 'na (retroflex)', roman: 'n', sound: 'rare alone, common in combinations'),
      ScriptEntry(glyph: 'त', name: 'ta', roman: 't', example: 'ताला', exampleMeaning: 'lock (tala)'),
      ScriptEntry(glyph: 'थ', name: 'tha', roman: 'th', example: 'थाली', exampleMeaning: 'plate (thali)'),
      ScriptEntry(glyph: 'द', name: 'da', roman: 'd', example: 'दूध', exampleMeaning: 'milk (doodh)'),
      ScriptEntry(glyph: 'ध', name: 'dha', roman: 'dh', example: 'धन', exampleMeaning: 'wealth (dhan)'),
      ScriptEntry(glyph: 'न', name: 'na', roman: 'n', example: 'नमक', exampleMeaning: 'salt (namak)'),
      ScriptEntry(glyph: 'प', name: 'pa', roman: 'p', example: 'पानी', exampleMeaning: 'water (pani)'),
      ScriptEntry(glyph: 'फ', name: 'pha', roman: 'ph', example: 'फल', exampleMeaning: 'fruit (phal)'),
      ScriptEntry(glyph: 'ब', name: 'ba', roman: 'b', example: 'बकरी', exampleMeaning: 'goat (bakri)'),
      ScriptEntry(glyph: 'भ', name: 'bha', roman: 'bh', example: 'भाई', exampleMeaning: 'brother (bhai)'),
      ScriptEntry(glyph: 'म', name: 'ma', roman: 'm', example: 'मछली', exampleMeaning: 'fish (machhli)'),
      ScriptEntry(glyph: 'य', name: 'ya', roman: 'y', example: 'यज्ञ', exampleMeaning: 'ritual (yagya)'),
      ScriptEntry(glyph: 'र', name: 'ra', roman: 'r', example: 'रथ', exampleMeaning: 'chariot (rath)'),
      ScriptEntry(glyph: 'ल', name: 'la', roman: 'l', example: 'लाल', exampleMeaning: 'red (laal)'),
      ScriptEntry(glyph: 'व', name: 'va', roman: 'v/w', example: 'वन', exampleMeaning: 'forest (van)'),
      ScriptEntry(glyph: 'श', name: 'sha', roman: 'sh', example: 'शहर', exampleMeaning: 'city (shahar)'),
      ScriptEntry(glyph: 'ष', name: 'sha (retroflex)', roman: 'sh', sound: 'formal/loan words'),
      ScriptEntry(glyph: 'स', name: 'sa', roman: 's', example: 'सड़क', exampleMeaning: 'road (sadak)'),
      ScriptEntry(glyph: 'ह', name: 'ha', roman: 'h', example: 'हाथी', exampleMeaning: 'elephant (hathi)'),
    ]),
  ],
);

const ScriptAcademy thaiAcademy = ScriptAcademy(
  languageKey: 'th',
  languageName: 'Thai',
  scriptName: 'Thai script',
  intro:
      'Thai has 44 consonants and a rich vowel system, written left to right '
      'with no spaces between words. Consonants come in three classes that '
      'determine tone. Start with the consonants — each is named with a word.',
  sections: [
    ScriptSection(title: 'Consonants', subtitle: '44, with traditional names', entries: [
      ScriptEntry(glyph: 'ก', name: 'ko kai', roman: 'k', example: 'ไก่', exampleMeaning: 'chicken'),
      ScriptEntry(glyph: 'ข', name: 'kho khai', roman: 'kh', example: 'ไข่', exampleMeaning: 'egg'),
      ScriptEntry(glyph: 'ค', name: 'kho khwai', roman: 'kh', example: 'ควาย', exampleMeaning: 'buffalo'),
      ScriptEntry(glyph: 'ง', name: 'ngo ngu', roman: 'ng', example: 'งู', exampleMeaning: 'snake'),
      ScriptEntry(glyph: 'จ', name: 'cho chan', roman: 'ch', example: 'จาน', exampleMeaning: 'plate'),
      ScriptEntry(glyph: 'ฉ', name: 'cho ching', roman: 'ch', example: 'ฉิ่ง', exampleMeaning: 'cymbals'),
      ScriptEntry(glyph: 'ช', name: 'cho chang', roman: 'ch', example: 'ช้าง', exampleMeaning: 'elephant'),
      ScriptEntry(glyph: 'ซ', name: 'so so', roman: 's', example: 'โซ่', exampleMeaning: 'chain'),
      ScriptEntry(glyph: 'ฌ', name: 'cho choe', roman: 'ch', example: 'เฌอ', exampleMeaning: 'tree (archaic)'),
      ScriptEntry(glyph: 'ญ', name: 'yo ying', roman: 'y', example: 'หญิง', exampleMeaning: 'woman'),
      ScriptEntry(glyph: 'ด', name: 'do dek', roman: 'd', example: 'เด็ก', exampleMeaning: 'child'),
      ScriptEntry(glyph: 'ต', name: 'to tao', roman: 't', example: 'เต่า', exampleMeaning: 'turtle'),
      ScriptEntry(glyph: 'ถ', name: 'tho thung', roman: 'th', example: 'ถุง', exampleMeaning: 'sack'),
      ScriptEntry(glyph: 'ท', name: 'tho thahan', roman: 'th', example: 'ทหาร', exampleMeaning: 'soldier'),
      ScriptEntry(glyph: 'ธ', name: 'tho thong', roman: 'th', example: 'ธง', exampleMeaning: 'flag'),
      ScriptEntry(glyph: 'น', name: 'no nu', roman: 'n', example: 'หนู', exampleMeaning: 'rat'),
      ScriptEntry(glyph: 'บ', name: 'bo baimai', roman: 'b', example: 'ใบไม้', exampleMeaning: 'leaf'),
      ScriptEntry(glyph: 'ป', name: 'po pla', roman: 'p', example: 'ปลา', exampleMeaning: 'fish'),
      ScriptEntry(glyph: 'ผ', name: 'pho phueng', roman: 'ph', example: 'ผึ้ง', exampleMeaning: 'bee'),
      ScriptEntry(glyph: 'ฝ', name: 'fo fa', roman: 'f', example: 'ฝา', exampleMeaning: 'lid'),
      ScriptEntry(glyph: 'พ', name: 'pho phan', roman: 'ph', example: 'พาน', exampleMeaning: 'pedestal tray'),
      ScriptEntry(glyph: 'ฟ', name: 'fo fan', roman: 'f', example: 'ฟัน', exampleMeaning: 'tooth'),
      ScriptEntry(glyph: 'ภ', name: 'pho samphao', roman: 'ph', example: 'สำเภา', exampleMeaning: 'junk boat'),
      ScriptEntry(glyph: 'ม', name: 'mo ma', roman: 'm', example: 'ม้า', exampleMeaning: 'horse'),
      ScriptEntry(glyph: 'ย', name: 'yo yak', roman: 'y', example: 'ยักษ์', exampleMeaning: 'giant'),
      ScriptEntry(glyph: 'ร', name: 'ro rua', roman: 'r', example: 'เรือ', exampleMeaning: 'boat'),
      ScriptEntry(glyph: 'ล', name: 'lo ling', roman: 'l', example: 'ลิง', exampleMeaning: 'monkey'),
      ScriptEntry(glyph: 'ว', name: 'wo waen', roman: 'w', example: 'แหวน', exampleMeaning: 'ring'),
      ScriptEntry(glyph: 'ศ', name: 'so sala', roman: 's', example: 'ศาลา', exampleMeaning: 'pavilion'),
      ScriptEntry(glyph: 'ษ', name: 'so ruesi', roman: 's', example: 'ฤๅษี', exampleMeaning: 'hermit'),
      ScriptEntry(glyph: 'ส', name: 'so sua', roman: 's', example: 'เสือ', exampleMeaning: 'tiger'),
      ScriptEntry(glyph: 'ห', name: 'ho hip', roman: 'h', example: 'หีบ', exampleMeaning: 'chest'),
      ScriptEntry(glyph: 'อ', name: 'o ang', roman: '', sound: 'silent anchor for vowels', example: 'อ่าง', exampleMeaning: 'basin'),
      ScriptEntry(glyph: 'ฮ', name: 'ho nokhuk', roman: 'h', example: 'นกฮูก', exampleMeaning: 'owl'),
    ]),
  ],
);

const ScriptAcademy chineseAcademy = ScriptAcademy(
  languageKey: 'zh',
  languageName: 'Chinese (Mandarin)',
  scriptName: 'Hanzi & Pinyin',
  intro:
      'Mandarin writes characters (hanzi) and sounds them with pinyin. '
      'Start with pinyin initials and finals — they unlock pronunciation of '
      'every character you meet, plus the four tones.',
  sections: [
    ScriptSection(title: 'The four tones', subtitle: 'same syllable, different meaning', entries: [
      ScriptEntry(glyph: 'mā 妈', name: 'tone 1 (flat, high)', roman: 'mā', example: '妈妈', exampleMeaning: 'mother'),
      ScriptEntry(glyph: 'má 麻', name: 'tone 2 (rising)', roman: 'má', example: '芝麻', exampleMeaning: 'sesame'),
      ScriptEntry(glyph: 'mǎ 马', name: 'tone 3 (dipping)', roman: 'mǎ', example: '马', exampleMeaning: 'horse'),
      ScriptEntry(glyph: 'mà 骂', name: 'tone 4 (falling)', roman: 'mà', example: '骂', exampleMeaning: 'to scold'),
    ]),
    ScriptSection(title: 'First characters', subtitle: 'high-frequency starters', entries: [
      ScriptEntry(glyph: '你好', name: 'nǐ hǎo', roman: 'ni hao', example: '你好！', exampleMeaning: 'hello'),
      ScriptEntry(glyph: '谢谢', name: 'xièxie', roman: 'xie xie', exampleMeaning: 'thank you'),
      ScriptEntry(glyph: '水', name: 'shuǐ', roman: 'shui', exampleMeaning: 'water'),
      ScriptEntry(glyph: '火', name: 'huǒ', roman: 'huo', exampleMeaning: 'fire'),
      ScriptEntry(glyph: '人', name: 'rén', roman: 'ren', exampleMeaning: 'person'),
      ScriptEntry(glyph: '大', name: 'dà', roman: 'da', exampleMeaning: 'big'),
      ScriptEntry(glyph: '小', name: 'xiǎo', roman: 'xiao', exampleMeaning: 'small'),
      ScriptEntry(glyph: '爱', name: 'ài', roman: 'ai', exampleMeaning: 'love'),
    ]),
  ],
);

/// Latin-script pronunciation guides for languages whose letters carry
/// diacritics or unfamiliar letter values.
const ScriptAcademy frenchAcademy = ScriptAcademy(
  languageKey: 'fr',
  languageName: 'French',
  scriptName: 'Latin (French pronunciation)',
  intro:
      'French uses the Latin alphabet with accents that change sound or '
      'meaning. These are the letters that trip up new learners.',
  sections: [
    ScriptSection(title: 'Accents & special letters', entries: [
      ScriptEntry(glyph: 'é', name: 'e acute', roman: 'e', sound: 'like "say" without the y', example: 'été', exampleMeaning: 'summer'),
      ScriptEntry(glyph: 'è', name: 'e grave', roman: 'e', sound: 'open e like "met"', example: 'père', exampleMeaning: 'father'),
      ScriptEntry(glyph: 'ê', name: 'e circumflex', roman: 'e', sound: 'open e, often marks a lost s', example: 'fête', exampleMeaning: 'festival'),
      ScriptEntry(glyph: 'à', name: 'a grave', roman: 'a', sound: 'a like "father"', example: 'à', exampleMeaning: 'to/at'),
      ScriptEntry(glyph: 'ç', name: 'c cedilla', roman: 's', sound: 'soft s before a/o/u', example: 'garçon', exampleMeaning: 'boy'),
      ScriptEntry(glyph: 'û', name: 'u circumflex', roman: 'u', sound: 'long u', example: 'sûr', exampleMeaning: 'sure'),
      ScriptEntry(glyph: 'œ', name: 'oe ligature', roman: 'oe', sound: 'like "bird" without the r', example: 'cœur', exampleMeaning: 'heart'),
    ]),
  ],
);

const ScriptAcademy spanishAcademy = ScriptAcademy(
  languageKey: 'es',
  languageName: 'Spanish',
  scriptName: 'Latin (Spanish pronunciation)',
  intro:
      'Spanish pronunciation is famously regular: each letter maps to a '
      'consistent sound. Learn ñ, the accent marks, and the silent h.',
  sections: [
    ScriptSection(title: 'Special letters & accents', entries: [
      ScriptEntry(glyph: 'ñ', name: 'eñe', roman: 'ny', sound: 'like "canyon" without the ca', example: 'año', exampleMeaning: 'year'),
      ScriptEntry(glyph: 'á', name: 'a with accent', roman: 'a', sound: 'stressed a', example: 'está', exampleMeaning: 'is'),
      ScriptEntry(glyph: 'ü', name: 'u with dieresis', roman: 'w', sound: 'u sounded in gue/gui', example: 'pingüino', exampleMeaning: 'penguin'),
      ScriptEntry(glyph: 'h', name: 'hache', roman: 'silent', sound: 'always silent', example: 'hola', exampleMeaning: 'hello'),
      ScriptEntry(glyph: 'j', name: 'jota', roman: 'kh', sound: 'like Scottish "loch"', example: 'jugar', exampleMeaning: 'to play'),
    ]),
  ],
);

const ScriptAcademy germanAcademy = ScriptAcademy(
  languageKey: 'de',
  languageName: 'German',
  scriptName: 'Latin (German pronunciation)',
  intro:
      'German adds umlauts (ä, ö, ü) and ß. Umlauts change vowel quality and '
      'often grammar (singular → plural).',
  sections: [
    ScriptSection(title: 'Umlauts & ß', entries: [
      ScriptEntry(glyph: 'ä', name: 'a umlaut', roman: 'ae', sound: 'like "air"', example: 'Mädchen', exampleMeaning: 'girl'),
      ScriptEntry(glyph: 'ö', name: 'o umlaut', roman: 'oe', sound: 'rounded e; say "e" with round lips', example: 'schön', exampleMeaning: 'beautiful'),
      ScriptEntry(glyph: 'ü', name: 'u umlaut', roman: 'ue', sound: 'rounded i; say "ee" with round lips', example: 'über', exampleMeaning: 'over'),
      ScriptEntry(glyph: 'ß', name: 'eszett', roman: 'ss', sound: 'voiceless s after long vowels', example: 'Straße', exampleMeaning: 'street'),
    ]),
  ],
);

const ScriptAcademy portugueseAcademy = ScriptAcademy(
  languageKey: 'pt',
  languageName: 'Portuguese',
  scriptName: 'Latin (Portuguese pronunciation)',
  intro:
      'Portuguese uses tildes (ã, õ) for nasal vowels and cedilla (ç). '
      'Nasal vowels are the signature sound of the language.',
  sections: [
    ScriptSection(title: 'Nasal vowels & special letters', entries: [
      ScriptEntry(glyph: 'ã', name: 'a tilde', roman: 'a~', sound: 'nasal a', example: 'pão', exampleMeaning: 'bread'),
      ScriptEntry(glyph: 'õ', name: 'o tilde', roman: 'o~', sound: 'nasal o', example: 'põe', exampleMeaning: 'puts'),
      ScriptEntry(glyph: 'ç', name: 'c cedilla', roman: 's', sound: 'soft s', example: 'dança', exampleMeaning: 'dance'),
      ScriptEntry(glyph: 'lh', name: 'lh digraph', roman: 'ly', sound: 'like "million" without the mi', example: 'filho', exampleMeaning: 'son'),
      ScriptEntry(glyph: 'nh', name: 'nh digraph', roman: 'ny', sound: 'like "canyon" without the ca', example: 'amanhã', exampleMeaning: 'tomorrow'),
    ]),
  ],
);

/// Registry of all academies by language key.
const Map<String, ScriptAcademy> scriptAcademies = {
  'ru': russianAcademy,
  'ja': japaneseAcademy,
  'ko': koreanAcademy,
  'ar': arabicAcademy,
  'hi': hindiAcademy,
  'th': thaiAcademy,
  'zh': chineseAcademy,
  'fr': frenchAcademy,
  'es': spanishAcademy,
  'de': germanAcademy,
  'pt': portugueseAcademy,
};
