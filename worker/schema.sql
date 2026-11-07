-- Anonymous log of student questions to the course helper.
-- No names, emails or network addresses are stored.
CREATE TABLE IF NOT EXISTS questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts TEXT NOT NULL,          -- time in UTC, ISO format
  mode TEXT NOT NULL,        -- answer, tutor or quiz
  chapter INTEGER,           -- chapter number for practice quizzes, otherwise empty
  question TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS questions_ts ON questions (ts);

-- Weekly "News this week" stories for the course page, written by the Worker's cron job.
-- stories is a JSON list of {headline, date, summary, chapter, concept, why, sources: [{title, url}]}.
CREATE TABLE IF NOT EXISTS news (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,  -- time in UTC, ISO format
  week_start TEXT NOT NULL,  -- first day covered, YYYY-MM-DD
  week_end TEXT NOT NULL,    -- last day covered, YYYY-MM-DD
  stories TEXT NOT NULL
);
