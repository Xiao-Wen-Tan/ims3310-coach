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
