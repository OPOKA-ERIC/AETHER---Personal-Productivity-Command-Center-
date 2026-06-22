-- Run this in Supabase SQL editor to add the date column to tasks
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS date TEXT;
