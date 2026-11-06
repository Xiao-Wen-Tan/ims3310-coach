# Course helper server (Cloudflare Worker)

This server receives a question from the course page, finds the most relevant lecture-slide excerpts, and streams back an answer from Claude. The Anthropic API key is stored as a Cloudflare secret, so it never appears in the page or in this repository.

## One-time setup (instructor)

1. **Anthropic API key.** Sign in at https://console.anthropic.com, add billing, and create an API key. Under Settings > Limits, set a monthly spend limit (for example $20) so costs can never run away.
2. **Cloudflare account.** Sign up for the free plan at https://dash.cloudflare.com/sign-up.
3. **Deploy.** In a terminal, from this `worker` folder:

   ```
   npm install
   npx wrangler login
   npx wrangler secret put ANTHROPIC_API_KEY
   npx wrangler deploy
   ```

   `wrangler login` opens a browser to approve access. `secret put` asks you to paste the API key. `deploy` prints the server address, which looks like `https://ims3310-helper.<your-subdomain>.workers.dev`.
4. **Connect the page.** Put that address in `public_config.json` (next to the build script), rebuild with `python "Course coach/build_coach.py" --public`, then commit and push.

## Settings (`wrangler.toml`)

- `ALLOWED_ORIGINS`: the only web pages allowed to call this server.
- `MODEL`: `claude-opus-5` by default. `claude-haiku-4-5` costs about one fifth as much per question.
- `EFFORT`: `low` keeps answers fast and cheap.
- `ASK_LIMITER`: at most 5 questions per minute from one network address.

After changing settings, run `npx wrangler deploy` again.

## Safeguards

- Only the course page's address can call the server, questions are capped at 600 characters, and answers at 2,000 tokens.
- The server builds the prompt itself, so it cannot be used as a general-purpose chatbot.
- Claude is told to answer only course questions, not to do graded work, and to send anything needing a decision to Professor Tan.
