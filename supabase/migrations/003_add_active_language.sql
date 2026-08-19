-- Add active_language column to profiles table
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS active_language text;
