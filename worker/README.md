# Course coach server (Cloudflare Worker)

This small server sits between the course page and Claude. The page sends it a student's request; the server adds the syllabus facts and the most relevant lecture-slide excerpts, asks Claude, and sends the answer back. The Anthropic API key is stored as a Cloudflare secret, so it never appears in the page or in this repository.

It handles two kinds of student request and two instructor requests, plus the weekly discussion board (see "Discussion board" below). (The practice quiz is built into the page and does not use this server.)

| Request | What it does |
|---|---|
| Answer | A direct answer, streamed word by word |
| Report tutor, step-by-step tutorial | Coaches a group through a pre-written six-step tutorial for its mid-term or final report, one step at a time (up to 4 rounds per step). The steps are in `tutorials` in `Course coach/course_facts.json` |
| Report tutor, feedback | Feedback on a pasted draft (up to 24,000 characters, about 4,000 words, enough for a whole report) or an uploaded PDF (up to 5 MB), by final report rubric criterion or by the mid-term topic list, then follow-up questions |
| Instructor summary | Claude groups the last 7, 30 or 120 days of student questions into themes |
| Instructor question list | Shown on the instructor page as soon as the password is entered: the questions from the chosen period, newest first, with the time and the type of request |
| Instructor CSV | All saved questions as a spreadsheet file |

## One-time setup

You need about 30 minutes, a credit card for the Anthropic account, and a terminal open in this `worker` folder.

1. **Create an Anthropic API key.** Sign in at https://console.anthropic.com, add billing, then go to API Keys and create a key named `ims3310-helper`. Copy it somewhere safe for step 6. Under Settings > Limits, set a monthly spend limit (for example $30) so costs can never run away.
2. **Create a free Cloudflare account** at https://dash.cloudflare.com/sign-up. No credit card is needed for the free plan.
3. **Install the tools.** Install Node.js 22 or newer from https://nodejs.org if `node --version` does not work. Then run:
   ```
   npm install
   ```
4. **Log in to Cloudflare from the terminal.**
   ```
   npx wrangler login
   ```
   A browser tab opens; click Allow.
5. **Create the question-log database.**
   ```
   npx wrangler d1 create ims3310-log
   ```
   It prints a block that includes `database_id = "..."`. Copy that id into `wrangler.toml`, replacing `PASTE-THE-ID-FROM-d1-create-HERE`. Then create the table:
   ```
   npx wrangler d1 execute ims3310-log --remote --file=schema.sql
   ```
6. **Store the two secrets.** Each command asks you to paste a value.
   ```
   npx wrangler secret put ANTHROPIC_API_KEY
   npx wrangler secret put ADMIN_TOKEN
   ```
   For `ANTHROPIC_API_KEY`, paste the key from step 1. For `ADMIN_TOKEN`, make up a long password (for example four random words); it unlocks the instructor view.
7. **Deploy.**
   ```
   npx wrangler deploy
   ```
   It prints the server address, which looks like `https://ims3310-helper.<your-subdomain>.workers.dev`.
8. **Connect the page.** Put that address in `Course coach/public_config.json`:
   ```
   { "worker_url": "https://ims3310-helper.<your-subdomain>.workers.dev" }
   ```
   From the IMS3310 folder, rebuild the page, then commit and push the `ims3310-coach` repository:
   ```
   python "Course coach/build_coach.py" --public
   ```
9. **Check it.** Open https://wen-tan.com/ims3310-coach/, ask a question, try the report tutor, then open https://wen-tan.com/ims3310-coach/#instructor, enter the password from step 6 and press Summarize.

## Office-hours booking emails

The Office hours tab lets a student book a 10-minute time in the posted office hours, or ask for another time. The server then emails Xiaowen.Tan@utdallas.edu from office-hours@wen-tan.com, with the student's address as the reply-to. Before this works, do this once in the Cloudflare dashboard:

1. Open **wen-tan.com > Email > Email Routing** and turn it on. Cloudflare adds the mail (MX) records it needs to wen-tan.com.
2. Under **Destination addresses**, add `Xiaowen.Tan@utdallas.edu` and click the link in the verification email Cloudflare sends.
   Cloudflare saves the address in lower case (`xiaowen.tan@utdallas.edu`), so `OFFICE_HOURS_TO` and `destination_address` in `wrangler.toml` must be written in lower case too. With capitals, every booking fails with the error `E_RECIPIENT_NOT_ALLOWED`, which shows in `npx wrangler tail`.
3. Create the bookings table and deploy:
   ```
   npx wrangler d1 execute ims3310-log --remote --file schema.sql
   npx wrangler deploy
   ```

The days, times, room, slot length and how many weeks ahead students can book are set in `office_hours` in `Course coach/public_config.json`. Rebuild the page after changing them. Only the booked time and a SHA-256 code of the student's email are stored (so one student can hold one upcoming time). Names and topics go only into the email. To free a slot after a cancellation, delete its row:
```
npx wrangler d1 execute ims3310-log --remote --command "DELETE FROM bookings WHERE slot_start = '2026-11-10 17:10'"
```

## Discussion board

The Discussion tab runs one guided discussion a week. A bot labelled "Course discussion bot" follows the instructions in `AI in teaching talk/prompts/discussion bot instructions v1.md` (the build copies the text below its `---` line into `course_data.json`). It has five jobs:

| Job | When | What it does |
|---|---|---|
| Draft | The Draft button, or automatically on Friday 6 PM for the next week | Writes the discussion goal and the opening post from the first slides of that week's chapters and the most recent "News this week" story on one of those chapters (else the latest story, or the chapter alone if there is no news). Nothing is posted; the instructor reads and edits the draft |
| Open | The Publish thread button, or Monday 8 AM Central | Posts the reviewed draft exactly as saved. With no draft yet, the Monday job writes one and waits for the instructor instead of opening |
| Reply | Right after each student's new post | One short reply with one follow-up question. Never to a reply or to the bot's own posts. A post the bot judges disrespectful, off-topic or personal is flagged and hidden until the instructor restores it |
| Nudge | Wednesday 6 PM Central, or the Nudge now button | A fresh angle, if the thread has had no post for 48 hours |
| Summary | Friday 6 PM Central, or the Write summary now button | The class part is posted to the thread. The part for Professor Tan only (posts, replies, a note and suggested points per student) is shown only in the instructor view |

Weeks follow the Fall 2024 schedule. The Monday job opens a thread only on the Monday of a 2024 schedule week that has a chapter, so outside Fall 2024 it never opens one, and threads are opened from the instructor view instead. Weeks without a chapter (exams, project instructions and presentations, Thanksgiving) are skipped.

**Setting it up** (each step changes the live server or database):

1. Create the new tables: `npx wrangler d1 execute ims3310-log --remote --file schema.sql` (all tables use `IF NOT EXISTS`, so existing data is kept).
2. Deploy: `npx wrangler deploy`. This also adds the second cron schedule in `wrangler.toml`.
3. Open https://wen-tan.com/ims3310-coach/#instructor, enter the password (the Discussion board box loads by itself), open "Roster and sign-in codes" and paste the roster, one student per line as `First name, Last name, email` (a paste from a spreadsheet with three columns works too). A file with each student's code downloads. The codes are stored only as SHA-256 codes, so they cannot be shown again; "New code" makes a fresh one for a student who lost theirs.
4. Send each student their code, for example through eLearning. Students sign in on the Discussion tab with their @utdallas.edu email and code.
5. For each week, pick it, press Draft from slides and news, read the goal and the opening post, edit anything, and press Publish thread. The points rule box starts with the example from the bot instructions and takes effect when you save or publish. It is used only in the private summary; if it is empty, the summary gives counts and notes but no suggested points.

**Gradebook CSV.** One row per roster student per thread, with columns week, student name, email, posts, replies, suggested points and an empty final points column for the instructor. Counts leave out hidden posts.

## What it costs

Each request sends the syllabus facts (about 4,000 tokens, a token being roughly three quarters of a word) plus slide excerpts, and gets a short answer back. The syllabus part is cached, so repeat requests within 5 minutes pay about a tenth of the normal price for it. Rough cost per request at the published prices (input / output per million tokens):

| Model (`MODEL` in `wrangler.toml`) | Price | One answer or tutorial reply | Feedback on a pasted whole report | Feedback on a 10-page PDF |
|---|---|---|---|---|
| `claude-opus-5` (default) | $5 / $25 | about 2 to 4 cents | about 8 to 12 cents | about 15 to 25 cents |
| `claude-sonnet-5` | $2 / $10 | about 1 to 2 cents | about 3 to 5 cents | about 6 to 10 cents |
| `claude-haiku-4-5` | $1 / $5 | under 1 cent | about 2 to 3 cents | about 3 to 5 cents |

A PDF costs more than pasted text because Claude reads each page as both text and an image (roughly 1,500 to 3,000 tokens a page), so it also sees tables, charts and layout. The file is sent again with each follow-up question, but it is cached, so a follow-up within 5 minutes costs about 3 to 5 cents on `claude-opus-5`.

Worked example: 40 students who each ask 25 questions in a term make 1,000 answers, and 10 groups that each use the report tutor for 30 tutorial replies, 3 text feedbacks and 3 PDF feedbacks add 300 tutorial replies, 30 text feedbacks and 30 PDF feedbacks. On `claude-opus-5` that is roughly 1,300 x $0.03 + 30 x $0.10 + 30 x $0.20 = $48 for the term; on `claude-sonnet-5` roughly $19. Practice quizzes cost nothing. These are estimates; the Anthropic Console's Usage page shows the real figure.

**Discussion board, 40 students.** Each bot request sends the bot instructions and that week's slide excerpts (about 2,000 to 3,500 tokens) plus posts. These estimates assume no caching. In one week with 40 original posts and about 60 replies:

| Job | Requests a week | Tokens in / out per request | `claude-opus-5` | `claude-sonnet-5` |
|---|---|---|---|---|
| Draft (publishing a draft costs nothing) | 1 | about 3,000 / 400 | about 2 cents | under 1 cent |
| Reply | 40 (one per original post; replies get none) | about 4,500 / 150 | about $1.05 | about 40 cents |
| Nudge | 0 or 1 | about 8,000 / 150 | about 4 cents | about 2 cents |
| Summary | 1 | about 19,000 / 2,000 | about 15 cents | about 6 cents |
| **Week** | | | **about $1.30** | **about 50 cents** |

Ten weeks of the Fall 2024 schedule have a chapter, so a full term is about $13 on `claude-opus-5` and about $5 on `claude-sonnet-5`, on top of the worked example above.

To switch models, change `MODEL` in `wrangler.toml` and run `npx wrangler deploy` again. `EFFORT` (low, medium, high) trades speed and cost against depth; it is ignored for Haiku.

## Settings (`wrangler.toml`)

- `ALLOWED_ORIGINS`: the only web pages allowed to call this server.
- `MODEL`, `EFFORT`: see above.
- `ASK_LIMITER`: at most 5 requests per minute from one network address. Reading the discussion board and the instructor's board views are not counted, because a classroom shares one address.
- `[triggers] crons`: the news job (Sundays and Wednesdays) and the discussion board check (four times a day; it acts only on Monday 8 AM, Wednesday 6 PM and Friday 6 PM Central).
- `DB`: the question-log database from step 5. Remove this block to turn logging off.

After changing settings, run `npx wrangler deploy` again.

## Safeguards and privacy

- Only the course page's address can call the server. Questions are capped at 600 characters, pasted drafts at 24,000 characters, uploaded drafts at one PDF of 5 MB, and answers at 2,000 tokens (4,000 for draft feedback).
- The server builds the prompt itself, so it cannot be used as a general-purpose chatbot. Claude is told to answer only course questions, not to do graded work, and to send anything needing a decision to Professor Tan.
- The question log stores the time, the mode and the question text. For a draft it stores only a line such as "(final report draft feedback, 1,240 words)" or "(final report draft feedback, uploaded PDF, 412 KB)", never the draft or the file itself. A PDF can include a cover page with names, so the page asks students to leave the cover page out. It never stores names, emails or network addresses (the address is used only for the per-minute limit and is not saved). The page tells students not to type personal information.
- UT Dallas guidance (Information Security Office, ai.utdallas.edu) says FERPA-protected or confidential data must not be entered into AI tools the university does not provide. Anonymous course questions are normally not student records, but a student could still type something identifying. Before a live term, confirm the setup with the Information Security Office, or run the same server through a university-provided service (Claude for Education or Amazon Bedrock are on the university's approved list).
- **The discussion board does hold student records.** Its tables (`students`, `posts` and the rest) keep names, @utdallas.edu emails and posts, so every board request needs a student sign-in or the instructor password, and nothing on the board is public. Students see classmates' first names only (with a last initial when two share a first name). Claude receives post text and first names, with each student as a short number such as S12 that the server maps back; emails and last names are never sent. Student posts go to Claude inside marked data blocks and the bot is told they are never instructions. Hidden posts never reach Claude. Posts are capped at 1,500 characters and 10 per student in any 24 hours. Because post text with first names is an education record sent to an outside AI service, confirm the board with the Information Security Office before a live term, as above.

## Testing without an API key

`npx wrangler deploy --dry-run --outdir <folder>` bundles the server without deploying it, so it can be tested offline with a stub in place of Claude. The discussion board test (`board-test.mjs` in `IMS3310/.claude/scratch/wrangler-dry`) runs the real `schema.sql` in an in-memory SQLite database and simulates a week: roster, sign-in, opening, 10 posts with bot replies, replies, a flagged post, a hidden post, a nudge, the summary and the CSV, plus the clock times of the scheduled jobs in summer and winter time.
