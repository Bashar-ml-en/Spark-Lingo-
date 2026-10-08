# Stitch Design System: LingoCraft Obsidian
**Source Project:** `projects/13077383863298841327` (AI Language Learning Platform)  
**Extracted:** 2026-10-07 / 2026-10-08  
**Theme:** LingoCraft Obsidian (Dark-First Neo-Editorial Glassmorphism)

---

## 1. Color System

### Foundation Surfaces (OLED Deep Obsidian Architecture)
- **Canvas Base (`#090A0F`)**: Deep zero-level obsidian background for global screens.
- **Surface Container Lowest (`#0B0E18`)**: Ground-level inset wells and background track layers.
- **Surface Container Low (`#12141F`)**: Primary container layer for passive study cards, sentence breakdowns, and list rows.
- **Surface Container (`#1D1F2A`)**: Standard elevated card surfaces, lesson pathway nodes, and dialog backgrounds.
- **Surface Container High (`#272935`)**: Hover/active states, bento metric chips, and top bars.
- **Surface Container Highest (`#323440`)**: Floating chips and highlighted borders.
- **Structural Border (`#2A2F45`)**: Razor-thin 1px border framing for glassmorphic delineation without visual bulk.

### Semantic & Performance Accents
- **Primary Indigo (`#6366F1`) & Violet Aura (`#8B5CF6`)**: Active prompts, voice synthesis generation, and core navigational interactive targets. Primary gradient: `linear-gradient(135deg, #6366F1, #8B5CF6)`.
- **Mastery Emerald (`#10B981`)**: Validated syntax, perfect acoustic pronunciation scores, and graduated memory retention intervals.
- **Kinetic Amber (`#F59E0B`)**: Streak maintenance, spacing cadence warnings, critical phonetic tips, and active burn rates.
- **Diagnostic Rose (`#F43F5E`)**: Grammar inflection anomalies, mispronounced phonemes, and structural corrections.

### Text Contrast Tiers
- **Text Primary (`#F8FAFC`)**: Highest contrast tier for target language vocab, primary inputs, and core prompts.
- **Text Secondary (`#94A3B8`)**: Translation equivalents, grammatical glosses, and secondary metadata.
- **Text Tertiary (`#475569`)**: Inactive indicators, syntax category labels, and timestamp metadata.

---

## 2. Typographic Scale

| Role | Font Family | Size | Weight | Line Height | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Hero** | Plus Jakarta Sans | 40px (30px mobile) | 700 / 800 | 48px (38px) | Hero welcome, course title |
| **Headline Large** | Plus Jakarta Sans | 26px | 600 / 700 | 34px | Screen titles, unit banners |
| **Headline Medium**| Plus Jakarta Sans | 20px | 600 | 28px | Card headers, section headers |
| **Headline Small** | Plus Jakarta Sans | 17px | 600 | 24px | Lesson titles, sheet headers |
| **Body Large** | Inter | 18px | 400 | 28px | Reading passages, long explanations |
| **Body Medium** | Inter | 15px | 400 | 22px | Vocabulary definitions, chat bubbles |
| **Body Small** | Inter | 13px | 400 | 18px | Captions, auxiliary translation tips |
| **Label Tabular Lg**| JetBrains Mono | 16px | 600 | 20px | Large scores, fluency indices |
| **Label Tabular Md**| JetBrains Mono | 13px | 500 | 16px | Timers, XP pills, streak counts |
| **Label Tabular Sm**| JetBrains Mono | 11px | 500 | 14px | Micro metrics, frequency tags |
| **Badge CEFR** | JetBrains Mono | 12px | 700 | 12px | CEFR levels: A1, A2, B1, B2, C1, C2 |

---

## 3. Shape & Corner Radii Scale
- **Cards & Panels:** `8px` (`rounded-sm`) to `16px` (`rounded-lg`)
- **Interactive Exercise Chips & Option Blocks:** `12px` (`rounded-md`)
- **Pills, Badges & Voice Triggers:** `9999px` (`rounded-full`)

---

## 4. Elevation, Depth & Specular Glows
- **Glass Tier 1:** `#12141F` background with `1px solid rgba(42, 47, 69, 0.7)` (`#2A2F45`).
- **Glass Tier 2:** `#1A1D2E` background with `1px solid rgba(99, 102, 241, 0.25)`.
- **Active State / Recording Glow:** `BoxShadow(color: Color(0x406366F1), blurRadius: 24)`.
- **Mastery Glow:** `BoxShadow(color: Color(0x3310B981), blurRadius: 20)`.
- **Diagnostic Correction Glow:** `BoxShadow(color: Color(0x33F43F5E), blurRadius: 16)`.

---

## 5. Screen Inventory in Stitch

1. **Adaptive Flight Path Dashboard** (`projects/13077383863298841327/screens/8373820986834a77a77946d9ca3ceaff`)  
   - Header with CEFR Level badge, XP / Diamond tier, and Spaced-Repetition Retention decay ring (e.g., `94%`).
   - Sinuous learning pathway with phase milestones, mastery nodes, and continue action tray.
2. **Multimodal AI Voice Lab** (`projects/13077383863298841327/screens/17b6b283c3944dcc927c086d27826de0`)  
   - 72px centralized voice recording actuator with concentric pulse ripples.
   - Dual-color reactive acoustic visualizer (Emerald `#10B981` & Rose `#F43F5E`).
   - Clean dark-glass speech bubble transcripts.
3. **Fluency Intelligence Analytics** (`projects/13077383863298841327/screens/14bdcd7120674a3b8f031705a12a293a`)  
   - CEFR competency breakdown (Speaking, Listening, Reading, Grammar).
   - Real-time vocabulary mastery ledger.
4. **Interactive Grammar Engine** (`projects/13077383863298841327/screens/ee1d64cc5fd14a1ba260004cdadda107`)  
   - Syntax block arrangement, fill-in-the-blank, and multi-option response cards.
5. **AI Scenario Selector** (`projects/13077383863298841327/screens/cc7ab83ce57a47419da80009fd1230f4`)  
   - Roleplay cards for practical immersion conversations.
