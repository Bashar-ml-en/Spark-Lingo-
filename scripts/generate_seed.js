const fs = require('fs');
const path = require('path');

const dataPath = path.join(__dirname, '../assets/curriculum/syllabus_master.json');
const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));

const langMap = {
  spanish: { id: 'es', name: 'Spanish', code: 'es' },
  english: { id: 'en', name: 'English', code: 'en' },
  french: { id: 'fr', name: 'French', code: 'fr' },
  mandarin: { id: 'zh', name: 'Mandarin', code: 'zh' },
  hindi: { id: 'hi', name: 'Hindi', code: 'hi' },
  russian: { id: 'ru', name: 'Russian', code: 'ru' },
  'bahasa melayu': { id: 'ms', name: 'Malay', code: 'ms' },
  arabic: { id: 'ar', name: 'Arabic', code: 'ar' }
};

const missingLanguageMappings = Object.keys(data).filter((language) => !langMap[language]);
if (missingLanguageMappings.length > 0) {
  throw new Error(`Missing language mappings: ${missingLanguageMappings.join(', ')}`);
}

let sql = '-- Generated from assets/curriculum/syllabus_master.json. Do not edit by hand.\n\n';
const escape = (value) => {
  if (value === null || value === undefined) return 'NULL';
  // SQL string literals use doubled single quotes. This avoids malformed seed
  // SQL if curriculum copy contains a dollar-quote delimiter or apostrophes.
  return `'${String(value).replace(/\u0000/g, '').replace(/'/g, "''")}'`;
};

for (const [langKey, langData] of Object.entries(data)) {
  const lang = langMap[langKey];
  if (!lang) continue;

  sql += `INSERT INTO languages (id, name, code) VALUES (${escape(lang.id)}, ${escape(lang.name)}, ${escape(lang.code)}) ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, code = EXCLUDED.code;\n`;

  let unitIndex = 0;
  for (const unit of langData.units || []) {
    sql += `INSERT INTO units (id, language_id, title, description, order_index, is_reviewed) VALUES (${escape(unit.id)}, ${escape(lang.id)}, ${escape(unit.title)}, ${escape(unit.description)}, ${unitIndex++}, true) ON CONFLICT (id) DO UPDATE SET language_id = EXCLUDED.language_id, title = EXCLUDED.title, description = EXCLUDED.description, order_index = EXCLUDED.order_index, is_reviewed = true;\n`;

    let lessonIndex = 0;
    for (const lesson of unit.lessons || []) {
      sql += `INSERT INTO lessons (id, unit_id, title, description, order_index) VALUES (${escape(lesson.id)}, ${escape(unit.id)}, ${escape(lesson.title)}, ${escape(lesson.description)}, ${lessonIndex++}) ON CONFLICT (id) DO UPDATE SET unit_id = EXCLUDED.unit_id, title = EXCLUDED.title, description = EXCLUDED.description, order_index = EXCLUDED.order_index;\n`;

      for (const card of lesson.flashcards || []) {
        sql += `INSERT INTO flashcards (id, lesson_id, front_text, back_text, context_sentence, audio_url) VALUES (${escape(card.id)}, ${escape(lesson.id)}, ${escape(card.front)}, ${escape(card.back)}, ${escape(card.context)}, ${escape(card.audioUrl)}) ON CONFLICT (id) DO UPDATE SET lesson_id = EXCLUDED.lesson_id, front_text = EXCLUDED.front_text, back_text = EXCLUDED.back_text, context_sentence = EXCLUDED.context_sentence, audio_url = EXCLUDED.audio_url;\n`;
      }
    }
  }
}

fs.writeFileSync(path.join(__dirname, 'seed.sql'), sql);
console.log('Successfully generated seed.sql');
