# Aether: Personal Productivity App Design Document

## 1. Overview
**Aether** is a beautiful, premium personal task tracker and productivity web application. It combines weekly planning, real-time alarms, daily reflections, long-term project tracking, and an intelligent habit-coaching engine to provide a holistic productivity experience.

## 2. Core Features
- **Weekly Planner:** Schedule tasks with specific start and end times across different categories (coding, study, exercise, urgent).
- **Task Management:** Create, read, update, and delete daily tasks, complete with alarm toggles and actual time tracking.
- **Projects & Milestones:** Group tasks under larger, long-term projects broken down into actionable milestones with due dates.
- **Daily Reflections:** Log daily reflections to track adherence, focus, and energy scores, along with notes on successes, struggles, and improvements.
- **Smart Coaching Engine:** An analytics engine that spots low adherence patterns, day slumps, and energy-focus correlations to provide actionable coaching tips.

## 3. Technology Stack (Proposed Migration)
- **Frontend:** Vanilla HTML/CSS/JS (Glassmorphism design, vibrant UI).
- **Backend/API:** Node.js with Express.
- **Database:** Supabase (migrating from SQLite) for scalable, real-time cloud data storage.
- **Mobile App:** Android App (Native or wrapped web view via Capacitor/React Native).
- **Hosting:** Vercel/Render for the web app and Supabase for the database.

## 4. Architecture & User Flow
1. **Dashboard:** The user lands on a beautiful glassmorphism dashboard showing today's tasks and the weekly overview.
2. **Task Execution:** When a task begins, real-time alarms notify the user. The user logs actual minutes spent upon completion.
3. **End of Day:** The user submits a daily reflection.
4. **Analytics:** The Smart Coaching Engine crunches the completed tasks vs. scheduled tasks and the reflection scores to offer personalized productivity advice.

## 5. Next Steps
- Polish the web interface and brand it as "Aether".
- Migrate the database schema from local SQLite to Supabase (PostgreSQL).
- Deploy the web application.
- Initialize an Android Studio project for the mobile version.
