-- Add is_reviewed and source_attribution to units
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS is_reviewed boolean NOT NULL DEFAULT false;
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS source_attribution text;

-- Add source_attribution to lessons
ALTER TABLE public.lessons ADD COLUMN IF NOT EXISTS source_attribution text;

-- Add source and source_attribution to flashcards
ALTER TABLE public.flashcards ADD COLUMN IF NOT EXISTS source text;
ALTER TABLE public.flashcards ADD COLUMN IF NOT EXISTS source_attribution text;
