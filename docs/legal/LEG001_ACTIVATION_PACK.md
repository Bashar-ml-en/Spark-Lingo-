# LEG-001 ACTIVATION PACK — everything prepped, one human gate remains

Date: 2026-08-28. Status: TECHNICALLY COMPLETE / LEGALLY GATED.

## What is DONE and verified (all URLs return HTTP 200)

Seven legal pages live at https://spark-lingo.vercel.app/legal/:
  privacy.html, terms.html, ai-and-voice-notice.html,
  analytics-notice.html, account-deletion.html, data-export.html,
  subscription-management.html

All marked DRAFT on-page pending counsel sign-off. Content mirrors
docs/legal/*.md (code-verified claims).

## Build flags (ready to add to the store build command)

--dart-define=TERMS_OF_SERVICE_URL=https://spark-lingo.vercel.app/legal/terms.html
--dart-define=PRIVACY_POLICY_URL=https://spark-lingo.vercel.app/legal/privacy.html
--dart-define=SUPPORT_URL=mailto:abulithbisha@gmail.com
--dart-define=AI_AND_VOICE_NOTICE_URL=https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html
--dart-define=AI_AND_VOICE_NOTICE_VERSION=1.0.0-draft
--dart-define=ANALYTICS_NOTICE_URL=https://spark-lingo.vercel.app/legal/analytics-notice.html
--dart-define=ANALYTICS_NOTICE_VERSION=1.0.0-draft
--dart-define=ACCOUNT_DELETION_URL=https://spark-lingo.vercel.app/legal/account-deletion.html
--dart-define=DATA_EXPORT_URL=https://spark-lingo.vercel.app/legal/data-export.html
--dart-define=SUBSCRIPTION_MANAGEMENT_URL=https://spark-lingo.vercel.app/legal/subscription-management.html

(These make LegalConfig.hasRequiredPurchaseLinks true — verified logic in
lib/core/constants/legal_config.dart.)

## Server-side consent document registration

legal_document_versions is currently EMPTY (verified via API query).
Registration SQL — run after counsel approves (rows stay is_active=false):

INSERT INTO public.legal_document_versions
  (document_key, version, public_url, is_active, change_reference)
VALUES
  ('ai_processing', '1.0.0',
   'https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html',
   false, 'Initial draft registration pending counsel approval'),
  ('voice_processing', '1.0.0',
   'https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html',
   false, 'Initial draft registration pending counsel approval'),
  ('analytics', '1.0.0',
   'https://spark-lingo.vercel.app/legal/analytics-notice.html',
   false, 'Initial draft registration pending counsel approval');

## THE ONE ACTIVATION SENTENCE (after counsel approves)

UPDATE public.legal_document_versions
SET is_active = true, activated_at = now()
WHERE version = '1.0.0' AND is_active = false;

Then rebuild with ENABLE_TEST_CONSENT removed and the flags above →
store builds get real consent-gated AI. Nothing needs to change in code.

## Human gates remaining
1. Counsel review of docs/legal/*.md drafts (or pages directly).
2. Remove the DRAFT banners + bump versions to 1.0.0 final.
3. Run the activation SQL.
4. Rebuild store binaries WITHOUT ENABLE_TEST_CONSENT.
