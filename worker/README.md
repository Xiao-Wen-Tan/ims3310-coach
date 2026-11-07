# Course helper server (Cloudflare Worker)

This small server sits between the course page and Claude. The page sends it a student's request; the server adds the syllabus facts and the most relevant lecture-slide excerpts, asks Claude, and sends the answer back. The Anthropic API key is stored as a Cloudflare secret, so it never appears in the page or in this repository.

It handles three kinds of student request and two instructor requests:

| Request | What it does |
|---|---|
| Answer | A direct answer, streamed word by word |
| Hint-first tutor | A hint and a guiding question first; the student replies and the tutor continues (up to 3 rounds) |
| Practice quiz | Five multiple-choice questions written from one chapter's slides |
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
9. **Check it.** Open https://wen-tan.com/ims3310-coach/, ask a question, try a practice quiz, then open https://wen-tan.com/ims3310-coach/#instructor, enter the password from step 6 and press Summarize.

## What it costs

Each request sends the syllabus facts (about 4,000 tokens, a token being roughly three quarters of a word) plus slide excerpts, and gets a short answer back. The syllabus part is cached, so repeat requests within 5 minutes pay about a tenth of the normal price for it. Rough cost per request at the published prices (input / output per million tokens):

| Model (`MODEL` in `wrangler.toml`) | Price | One answer | One 5-question quiz |
|---|---|---|---|
| `claude-opus-5` (default) | $5 / $25 | about 2 to 4 cents | about 5 to 7 cents |
| `claude-sonnet-5` | $2 / $10 | about 1 to 2 cents | about 2 to 3 cents |
| `claude-haiku-4-5` | $1 / $5 | under 1 cent | about 1 cent |

Worked example: 40 students who each ask 25 questions and take 5 quizzes in a term make 1,000 answers and 200 quizzes. On `claude-opus-5` that is roughly 1,000 x $0.03 + 200 x $0.06 = $42 for the term; on `claude-sonnet-5` roughly $17. These are estimates; the Anthropic Console's Usage page shows the real figure.

To switch models, change `MODEL` in `wrangler.toml` and run `npx wrangler deploy` again. `EFFORT` (low, medium, high) trades speed and cost against depth; it is ignored for Haiku.

## Settings (`wrangler.toml`)

- `ALLOWED_ORIGINS`: the only web pages allowed to call this server.
- `MODEL`, `EFFORT`: see above.
- `ASK_LIMITER`: at most 5 requests per minute from one network address.
- `DB`: the question-log database from step 5. Remove this block to turn logging off.

After changing settings, run `npx wrangler deploy` again.

## Safeguards and privacy

- Only the course page's address can call the server. Questions are capped at 600 characters and answers at 2,000 tokens.
- The server builds the prompt itself, so it cannot be used as a general-purpose chatbot. Claude is told to answer only course questions, not to do graded work, and to send anything needing a decision to Professor Tan.
- The question log stores the time, the mode, the quiz chapter and the question text. It never stores names, emails or network addresses (the address is used only for the per-minute limit and is not saved). The page tells students not to type personal information.
- UT Dallas guidance (Information Security Office, ai.utdallas.edu) says FERPA-protected or confidential data must not be entered into AI tools the university does not provide. Anonymous course questions are normally not student records, but a student could still type something identifying. Before a live term, confirm the setup with the Information Security Office, or run the same server through a university-provided service (Claude for Education or Amazon Bedrock are on the university's approved list).

## Testing without an API key

`npx wrangler deploy --dry-run --outdir <folder>` bundles the server without deploying it, so it can be tested offline with a stub in place of Claude.
