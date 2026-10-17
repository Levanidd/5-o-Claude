# Taxability

**One line:** An iOS app that finds the money and support parents of disabled children in Germany are entitled to, explains it in their own language, and writes the German letters for them.

Built in one day at the [Claude Impact Lab Berlin](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17) (theme: AI education for everyone).

## Who it is for
Parents of children with disabilities in Germany, especially expats and newcomers who don't read official German.

## What problem it solves
- **Money left on the table.** These families leave thousands of euros a year unclaimed: tax allowances, care allowance, relief budgets, pension points for caregivers. The rules are spread across tax law and care insurance law, and every letter from an office is in official German.
- **AI they can't trust.** General chatbots invent rules and amounts and can't be trusted with official letters, so these parents either avoid AI or trust it blindly.
- **What Taxability does about it:** fixed rules with legal sources decide eligibility and €, and Claude does what AI is good at: reading documents, explaining letters in the parent's language and writing German replies. Every AI step is labelled and confirmed by the parent, so they learn what AI can do for them and where rules and people decide.

## How to run it
Requirements: a Mac with Xcode 27 and an iOS 26+ simulator or iPhone. No API key needed: the app talks to our hosted backend out of the box.

1. Clone and open the project:
   ```bash
   git clone https://github.com/Levanidd/5-o-Claude.git
   cd 5-o-Claude
   open TaxHelper.xcodeproj
   ```
2. Pick the **TaxHelper** scheme and an iPhone simulator, press **Run** (⌘R). For a real iPhone, select your own team under *Signing & Capabilities* first.
3. Try the 1-minute path: choose a language → **"Use demo family (Priya & Arjun)"** → **Go to my dashboard** → **Capture** tab → **"Use sample letter from care insurer (MUSTER)"** → **Reply in German**.

Good to know:
- **Demo mode** (Family tab) uses cached AI answers, so the demo works offline. If the backend is unreachable, the app falls back to them automatically.
- Printable fictional documents to photograph: `fixtures/pflegegrad_bescheid.pdf` (care-level decision) and `fixtures/pflegekasse_brief.pdf` (letter from the care insurer). Video script: [DEMO.md](DEMO.md).

**Optional: run your own backend.** The API key always stays on the backend (in `.env` or a Cloudflare secret), never in the app or in Git.

```bash
# Cloudflare Worker
cd worker && npm install
npx wrangler deploy
npx wrangler secret put ANTHROPIC_API_KEY      # paste the key when asked

# or locally, Python standard library only
cp .env.example .env && python3 server/server.py   # http://127.0.0.1:8787
```

Then set `BACKEND_URL` in the TaxHelper target's build settings, or paste the URL in the app: Family tab → AI connection.

## What it does
- **Quick check (~90 s, no account):** one question per screen, a live "€ found" meter climbs with every answer.
- **Result:** "≈ €X per year + €Y from past years", ranked opportunities.
- **Explainable cards:** "Why you qualify" rule chain, how we calculated it, legal source, confidence badge (Confirmed / Likely / Needs 1 answer).
- **Scan, then confirm:** photo of a care-level decision → Claude reads the fields → parent confirms each value.
- **Official letter explainer:** photo of a German letter → what it says, what to do, deadline, amount — in the parent's language. Deadline lands on the dashboard.
- **Reply in German:** the parent writes in their language → formal German message body, side by side with a translation, locked file numbers/dates, one-tap copy, share or print.
- **Dashboard:** € secured vs. € open, one Next best action, deadlines with next steps. "Add to Taxfix return" is a mock handoff.

## How Claude is used
Claude is the reading, explaining and writing layer — **not** the decision maker.
- **Fixed rules decide eligibility and €** (`TaxHelper/Rules/RulesEngine.swift`, 10 German rules, 2026 amounts). Claude never calculates money.
- Claude (vision + text, default model `claude-sonnet-5-5`, configurable via `ANTHROPIC_MODEL`) does: read official documents into JSON, explain official letters in the parent's language, write formal German letters, explain a card, answer questions on a card.
- Every AI output is labelled ✨ (lilac colour), has a "This isn't right" link, and says when it is a cached demo answer.
- Prompts live in [`prompts/`](prompts/). The backend is a Cloudflare Worker ([`worker/`](worker/), live at `https://taxability.kurdyukov-leo-ger.workers.dev`, health check at `/health`) or the same API as a local Python server ([`server/server.py`](server/server.py)).

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
