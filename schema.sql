-- Aether Supabase Schema
-- Please run this entirely in your Supabase SQL Editor.
-- NOTE: This schema is designed for single-user use via a server-side service role key.
-- user_id columns are omitted since auth is not used.

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Projects Table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Milestones Table
CREATE TABLE IF NOT EXISTS milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  due_date DATE,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tasks Table
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  day_of_week TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT NOT NULL,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  alarm_enabled BOOLEAN DEFAULT TRUE,
  actual_minutes_spent INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Reflections Table
CREATE TABLE IF NOT EXISTS reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  date DATE NOT NULL UNIQUE,
  adherence_score INTEGER CHECK (adherence_score >= 0 AND adherence_score <= 100),
  focus_score INTEGER CHECK (focus_score >= 1 AND focus_score <= 10),
  energy_score INTEGER CHECK (energy_score >= 1 AND energy_score <= 10),
  notes_success TEXT,
  notes_struggles TEXT,
  notes_improvements TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable RLS (using service role key server-side, no user auth)
ALTER TABLE projects DISABLE ROW LEVEL SECURITY;
ALTER TABLE milestones DISABLE ROW LEVEL SECURITY;
ALTER TABLE tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE reflections DISABLE ROW LEVEL SECURITY;
