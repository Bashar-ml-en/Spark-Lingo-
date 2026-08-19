# Prompt 09 — QA, Accessibility, RTL & Polish Pass

Run after Prompt 08. This is the unglamorous stage that store reviewers
and real users actually notice first — don't skip or rush it.

---

**Checklist to work through and fix, not just report:**

1. **RTL correctness**: full manual pass through onboarding → home →
   exam-prep in Arabic. Every icon that implies direction (back
   chevron, progress bar fill direction, flashcard swipe) must mirror
   correctly. Anything still hardcoded LTR (raw `Alignment.centerLeft`
   instead of `AlignmentDirectional.centerStart`, etc.) gets fixed here.

2. **Accessibility**: minimum 48x48dp tap targets throughout (flag
   tiles, mock-exam answer options), sufficient color contrast for
   every `LanguageTheme` primary/accent pair against text (check the
   ones with light accent colors, e.g. Spanish's yellow, against white
   text), screen-reader labels on icon-only buttons (record button,
   language switcher, flag tiles — flag alone isn't sufficient
   labeling, include the language name).

3. **Error/empty/offline states**: every network call (Sparky, mock
   exam submission, flashcard sync) needs a real error state, not a
   silent failure or infinite spinner — this is one of the most common
   App Store rejection reasons ("app is buggy / incomplete").
   `syllabus_master.json`'s offline fallback should extend to graceful
   "you're offline, here's cached content" messaging, not just silent
   degradation.

4. **Credits/attribution screen**: add a Settings → About/Credits screen
   listing Tatoeba (CC-BY 2.0) and Mozilla Common Voice (CC0)
   attribution per Prompt 05's `sourceAttribution` field — required for
   license compliance, not optional polish.

5. **Font loading**: confirm all `NotoSans*` font files registered in
   Prompt 01 actually render for their scripts (Japanese, Korean,
   Simplified Chinese, Arabic, Devanagari, Thai) on both a fresh iOS and
   Android build — missing font files silently fall back to tofu boxes
   (☐☐☐) and this is very easy to miss if you only test in English/
   French during development.

6. **Performance**: cold start time, especially with the language theme
   registry now parsing a JSON file at startup (Prompt 02) — profile
   and cache/precompute if it's adding noticeable delay.

**Verify:** run through the full user journey once as if you were a
brand-new user in each of: English, Arabic, Japanese, and one
under-resourced language (Thai). Fix everything found, don't defer to
"known issues."
