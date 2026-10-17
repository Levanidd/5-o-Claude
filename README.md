# Taxability

**One line:** An iOS app that finds the money and support parents of disabled children in Germany are entitled to, explains it in their own language, and writes the German letters for them.

Built in one day at the [Claude Impact Lab Berlin](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17) (theme: AI education for everyone).

## Who it's for
- **Audience:** parents of children with disabilities in Germany, especially expats and newcomers who don't read official German.
- **Their problem with AI today:** general chatbots invent rules and amounts and can't be trusted with official letters, so these parents either avoid AI or trust it blindly.
- **What our demo lets them do:** photograph a German letter or decision, understand it in their own language, see which money they are entitled to (decided by fixed rules with legal sources), and get a German reply drafted, with every AI step labelled so they learn what AI is good at and where rules and people decide.

## The problem
Parents of children with disabilities in Germany leave thousands of euros a year unclaimed: tax allowances, care budgets, supplies. The rules are spread across tax law and care insurance, and every letter is in official German. Expats and newcomers who don't read German are hit hardest.

## What it does
- **Quick check (~90 s, no account):** one question per screen, a live "€ found" meter climbs with every answer.
- **Result:** "≈ €X per year + €Y from past years", ranked opportunities.
- **Explainable cards:** "Why you qualify" rule chain, how we calculated it, legal source, confidence badge (Confirmed / Likely / Needs 1 answer).
- **Scan, then confirm:** photo of a care-level decision → Claude reads the fields → parent confirms each value.
- **Official letter explainer:** photo of a German letter → what it says, what to do, deadline, amount — in the parent's language. Deadline lands on the dashboard.
- **Reply in German:** the parent writes in their language → formal German message body, side by side with a translation, locked file numbers/dates, one-tap copy, share or print.
- **Dashboard:** € secured vs. € open, one Next best action, deadlines. "Add to Taxfix return" is a mock handoff.

## How Claude is used
Claude is the reading, explaining and writing layer — **not** the decision maker.
- **Fixed rules decide eligibility and €** (`TaxHelper/Rules/RulesEngine.swift`, 10 German rules, 2026 amounts). Claude never calculates money.
- Claude (vision + text, default model `claude-sonnet-5-5`, configurable via `ANTHROPIC_MODEL`) does: read official documents into JSON, explain official letters in the parent's language, write formal German letters, explain a card, answer questions on a card.
- Every AI output is labelled ✨ (lilac colour), has a "This isn't right" link, and says when it is a cached demo answer.
- Prompts live in [`prompts/`](prompts/). The API key stays on a tiny backend, never in the app: a Cloudflare Worker ([`worker/`](worker/), live at `https://taxability.kurdyukov-leo-ger.workers.dev`) or the same API as a local Python server ([`server/server.py`](server/server.py)).

## How to run it
Requirements: macOS with Xcode 27, iOS 26+ (simulator or iPhone).

```bash
open TaxHelper.xcodeproj      # run the TaxHelper scheme; it talks to the hosted Worker out of the box
```

Run your own backend instead (both keep the key in `.env` or a Cloudflare secret, never in Git):

```bash
# Cloudflare Worker
cd worker && npm install
npx wrangler deploy
npx wrangler secret put ANTHROPIC_API_KEY      # paste the key when asked

# or locally, Python standard library only
cp .env.example .env && python3 server/server.py   # http://127.0.0.1:8787
```

Then set `BACKEND_URL` in the TaxHelper target's build settings, or paste the URL in the app: Family tab → AI connection.

- Fastest demo: on the welcome screen tap **"Use demo family (Priya & Arjun)"**, then Capture → **"Use sample letter from care insurer (MUSTER)"** → **Reply in German**.
- **Demo mode** (Family tab) uses cached AI answers, so the pitch works offline. If the backend is unreachable the app falls back to them automatically.
- Printable fictional documents to photograph: `fixtures/pflegegrad_bescheid.pdf` (care-level decision) and `fixtures/pflegekasse_brief.pdf` (letter from the care insurer). Video script: [DEMO.md](DEMO.md).

**Live link:** there is no web app, Taxability is an iOS app. The hosted backend answers at `https://taxability.kurdyukov-leo-ger.workers.dev/health`.

## Screenshots / demo
**Demo video (2 min):** TODO add link before submitting.

## Team
| Name | Role / background |
|---|---|
| [Leonid](https://github.com/Levanidd) | Builder |
| [vitast](https://github.com/vitast) | TODO role |
| TODO name | TODO role |
| TODO name | TODO role |
| TODO name | TODO role |

## Credits
- [Claude API](https://docs.claude.com) by Anthropic — document reading, explanations, German letters.
- Apple SwiftUI, PhotosUI and SF Symbols.
- [Cloudflare Workers](https://developers.cloudflare.com/workers/) and Wrangler — hosting for the backend.
- Rule amounts compiled from §33b EStG and SGB XI (gesetze-im-internet.de) and the secondary sources listed in `Project context.MD`.
- Colours approximate the Taxfix brand; no Taxfix logos or illustrations are used. All documents are fictional "MUSTER" samples, no real personal data.
