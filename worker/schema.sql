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

-- Office-hours bookings. Only the booked time and a SHA-256 code of the student's email are kept
-- (so one student can't hold more than one upcoming time). Names and topics go only into the email.
CREATE TABLE IF NOT EXISTS bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL,         -- time in UTC, ISO format
  slot_start TEXT NOT NULL UNIQUE,  -- US Central local time, "YYYY-MM-DD HH:MM"
  email_hash TEXT NOT NULL
);

-- ---------- Discussion board ----------
-- Unlike the tables above, these hold student records (names, emails and posts), so the board
-- is behind a sign-in and nothing here is public. Times are UTC, ISO format.

-- Class roster, pasted in by the instructor. The sign-in code is stored only as a SHA-256 code.
CREATE TABLE IF NOT EXISTS students (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,      -- always ends in @utdallas.edu, lower case
  code_hash TEXT NOT NULL,
  created_at TEXT NOT NULL
);

-- Signed-in browsers. The session token is stored only as a SHA-256 code.
CREATE TABLE IF NOT EXISTS sessions (
  token_hash TEXT PRIMARY KEY,
  student_id INTEGER NOT NULL,
  expires_at TEXT NOT NULL
);

-- One thread per opened week. The newest thread is the current one.
CREATE TABLE IF NOT EXISTS threads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  week INTEGER NOT NULL,           -- schedule week number (Fall 2024 schedule)
  chapter TEXT NOT NULL,           -- for example "Ch6 Investing Abroad Directly; Ch12 Making Alliances and Acquisitions Work"
  news TEXT,                       -- the news story used, as JSON, or empty
  goal TEXT,                       -- the discussion goal at the time the thread opened
  opened_at TEXT NOT NULL
);

-- Posts. parent_id is empty for a top-level post. student_id is empty for the bot.
-- kind: open, nudge, summary (bot, top level), post (student, top level), reply (student),
-- bot-reply (the bot's one reply to a student's top-level post).
CREATE TABLE IF NOT EXISTS posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  thread_id INTEGER NOT NULL,
  parent_id INTEGER,
  student_id INTEGER,
  kind TEXT NOT NULL,
  body TEXT NOT NULL,
  created_at TEXT NOT NULL,
  hidden INTEGER NOT NULL DEFAULT 0,
  flagged INTEGER NOT NULL DEFAULT 0,
  flag_reason TEXT
);
CREATE INDEX IF NOT EXISTS posts_thread ON posts (thread_id, id);
CREATE INDEX IF NOT EXISTS posts_student ON posts (student_id, created_at);

-- The bot's draft for each schedule week, written from the slides and the news story: the
-- discussion goal and the opening post. The instructor reads and edits it, then publishes it as
-- the thread's opening post. edited is 1 once the instructor has saved changes.
CREATE TABLE IF NOT EXISTS drafts (
  week INTEGER PRIMARY KEY,
  goal TEXT NOT NULL,
  opening TEXT NOT NULL,
  news TEXT,                       -- the news story used, as JSON, or empty
  updated_at TEXT NOT NULL,
  edited INTEGER NOT NULL DEFAULT 0
);

-- Board settings (key points_rule holds the points rule).
CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

-- The Friday summary. The class part is also posted to the thread; private holds the
-- instructor-only part as JSON: [{student_id, note, suggested_points, unsure}].
CREATE TABLE IF NOT EXISTS summaries (
  thread_id INTEGER PRIMARY KEY,
  class_text TEXT NOT NULL,
  private TEXT NOT NULL,
  created_at TEXT NOT NULL
);
