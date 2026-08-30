-- LEG-001 registration (rows inactive until product-owner approval).
INSERT INTO public.legal_document_versions
  (document_key, version, public_url, is_active, change_reference)
VALUES
  ('ai_processing', '1.0.0',
   'https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html',
   false, 'Draft registration - awaiting product owner approval'),
  ('voice_processing', '1.0.0',
   'https://spark-lingo.vercel.app/legal/ai-and-voice-notice.html',
   false, 'Draft registration - awaiting product owner approval'),
  ('analytics', '1.0.0',
   'https://spark-lingo.vercel.app/legal/analytics-notice.html',
   false, 'Draft registration - awaiting product owner approval');
