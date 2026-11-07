# Course helper server (Cloudflare Worker)

This small server sits between the course page and Claude. The page sends it a student's request; the server adds the syllabus facts and the most relevant lecture-slide excerpts, asks Claude, and sends the answer back. The Anthropic API key is stored as a Cloudflare secret, so it never appears in the page or in this repository.

It handles two kinds of student request and two instructor requests. (The practice quiz is built into the page and does not use this server.)

| Request | What it does |
|---|---|
| Answer | A direct answer, streamed word by word |
| Report tutor, step-by-step tutorial | Coaches a group through a pre-written six-step tutorial for its mid-term or final report, one step at a time (up to 4 rounds per step). The steps are in `tutorials` in `Course coach/course_facts.json` |
| Report tutor, feedback | Feedback on a pasted draft (up to 24,000 characters, about 4,000 words, enough for a whole report) or an uploaded PDF (up to 5 MB), by final report rubric criterion or by the mid-term topic list, then follow-up questions |
| Instructor summary | Claude groups the last 7, 30 or 120 days of student questions into themes |
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
3. Create the bookings table and deploy:
   ```
   npx wrangler d1 execute ims3310-log --remote --file schema.sql
   npx wrangler deploy
   ```

The days, times, room, slot length and how many weeks ahead students can book are set in `office_hours` in `Course coach/public_config.json`. Rebuild the page after changing them. Only the booked time and a SHA-256 code of the student's email are stored (so one student can hold one upcoming time). Names and topics go only into the email. To free a slot after a cancellation, delete its row:
```
npx wrangler d1 execute ims3310-log --remote --command "DELETE FROM bookings WHERE slot_start = '2026-11-10 17:10'"
```

## What it costs

Each request sends the syllabus facts (about 4,000 tokens, a token being roughly three quarters of a word) plus slide excerpts, and gets a short answer back. The syllabus part is cached, so repeat requests within 5 minutes pay about a tenth of the normal price for it. Rough cost per request at the published prices (input / output per million tokens):

| Model (`MODEL` in `wrangler.toml`) | Price | One answer or tutorial reply | Feedback on a pasted whole report | Feedback on a 10-page PDF |
|---|---|---|---|---|
| `claude-opus-5` (default) | $5 / $25 | about 2 to 4 cents | about 8 to 12 cents | about 15 to 25 cents |
| `claude-sonnet-5` | $2 / $10 | about 1 to 2 cents | about 3 to 5 cents | about 6 to 10 cents |
| `claude-haiku-4-5` | $1 / $5 | under 1 cent | about 2 to 3 cents | about 3 to 5 cents |

A PDF costs more than pasted text because Claude reads each page as both text and an image (roughly 1,500 to 3,000 tokens a page), so it also sees tables, charts and layout. The file is sent again with each follow-up question, but it is cached, so a follow-up within 5 minutes costs about 3 to 5 cents on `claude-opus-5`.

Worked example: 40 students who each ask 25 questions in a term make 1,000 answers, and 10 groups that each use the report tutor for 30 tutorial replies, 3 text feedbacks and 3 PDF feedbacks add 300 tutorial replies, 30 text feedbacks and 30 PDF feedbacks. On `claude-opus-5` that is roughly 1,300 x $0.03 + 30 x $0.10 + 30 x $0.20 = $48 for the term; on `claude-sonnet-5` roughly $19. Practice quizzes cost nothing. These are estimates; the Anthropic Console's Usage page shows the real figure.

To switch models, change `MODEL` in `wrangler.toml` and run `npx wrangler deploy` again. `EFFORT` (low, medium, high) trades speed and cost against depth; it is ignored for Haiku.

## Settings (`wrangler.toml`)

- `ALLOWED_ORIGINS`: the only web pages allowed to call this server.
- `MODEL`, `EFFORT`: see above.
- `ASK_LIMITER`: at most 5 requests per minute from one network address.
- `DB`: the question-log database from step 5. Remove this block to turn logging off.

After changing settings, run `npx wrangler deploy` again.

## Safeguards and privacy

- Only the course page's address can call the server. Questions are capped at 600 characters, pasted drafts at 24,000 characters, uploaded drafts at one PDF of 5 MB, and answers at 2,000 tokens (4,000 for draft feedback).
- The server builds the prompt itself, so it cannot be used as a general-purpose chatbot. Claude is told to answer only course questions, not to do graded work, and to send anything needing a decision to Professor Tan.
- The question log stores the time, the mode and the question text. For a draft it stores only a line such as "(final report draft feedback, 1,240 words)" or "(final report draft feedback, uploaded PDF, 412 KB)", never the draft or the file itself. A PDF can include a cover page with names, so the page asks students to leave the cover page out. It never stores names, emails or network addresses (the address is used only for the per-minute limit and is not saved). The page tells students not to type personal information.
- UT Dallas guidance (Information Security Office, ai.utdallas.edu) says FERPA-protected or confidential data must not be entered into AI tools the university does not provide. Anonymous course questions are normally not student records, but a student could still type something identifying. Before a live term, confirm the setup with the Information Security Office, or run the same server through a university-provided service (Claude for Education or Amazon Bedrock are on the university's approved list).

## Testing without an API key

`npx wrangler deploy --dry-run --outdir <folder>` bundles the server without deploying it, so it can be tested offline with a stub in place of Claude.
