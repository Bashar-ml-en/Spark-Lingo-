const fs = require('fs');
const path = require('path');

const projectRoot = path.resolve(__dirname, '..');
const homeScreenPath = path.join(
  projectRoot,
  'lib',
  'features',
  'home',
  'home_screen.dart',
);
const source = fs.readFileSync(homeScreenPath, 'utf8');

const required = [
  "import 'flashcard_study_session.dart';",
  "import 'sparky_chat_session.dart';",
  'child: SparkyChatSession(language: langKey, lesson: lesson)',
  'child: SparkyChatSession(language: langKey)',
  'FlashcardStudySession(',
];

const forbidden = [
  '_AISpeechPracticeSession',
  'class _FlashcardStudySession',
  '_generateIntelligentFallbackResponse',
  'Evaluation completed locally',
  'Audio Player Placeholder',
];

const missing = required.filter((entry) => !source.includes(entry));
const present = forbidden.filter((entry) => source.includes(entry));

if (missing.length || present.length) {
  console.error('Canonical learning-flow validation failed.');
  if (missing.length) console.error(`Missing: ${missing.join(', ')}`);
  if (present.length) console.error(`Legacy implementation found: ${present.join(', ')}`);
  process.exit(1);
}

console.log('Canonical learning-flow validation passed.');
