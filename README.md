> 👋 **Starter for Claude Impact Lab teams.** Fill in each section below as you build and delete this note.
>
> 📅 **Agenda, rules, deadline and judging** are in the event repo: **[claude-impact-lab-berlin-2026-10-17](https://github.com/Claude-Community-Berlin/claude-impact-lab-berlin-2026-10-17)**. Read it first.
>
> ✅ **When you're finished:** record a 2-minute demo video, then submit with the **[submission form](https://tally.so/r/1WPr9Q)** before **16:00**. One submission per team.
>
> 🔑 Set your API key first: `cp .env.example .env`, then paste your key into `.env` (it's git-ignored, never commit it).

# Family Support Check

**One line:** An iOS app that finds the money and support parents of disabled children in Germany are entitled to, explains it in their own language, and writes the German letters for them.

## The problem
Parents of children with disabilities in Germany leave thousands of euros a year unclaimed: tax allowances, care budgets, supplies. The rules are spread across tax law and care insurance, and every letter is in official German. Expats and newcomers who don't read German are hit hardest.

## What it does
- **Quick check (~90 s, no account):** one question per screen, a live "€ found" meter climbs with every answer.
- **Result:** "≈ €X per year + €Y from past years", ranked opportunities.
- **Explainable cards:** "Why you qualify" rule chain, how we calculated it, legal source, confidence badge (Confirmed / Likely / Needs 1 answer).
- **Scan, then confirm:** photo of a care-level decision → Claude reads the fields → parent confirms each value.
- **Official letter explainer:** photo of a German letter → what it says, what to do, deadline, amount — in the parent's language. Deadline lands on the dashboard.
- **Reply in German:** the parent writes in their language → formal German letter, side by side with a translation, locked file numbers/dates, share or print.
- **Dashboard:** € secured vs. € open, one Next best action, deadlines. "Add to Taxfix return" is a mock handoff.

## How Claude is used
Claude is the reading, explaining and writing layer — **not** the decision maker.
- **Fixed rules decide eligibility and €** (`TaxHelper/Rules/RulesEngine.swift`, 10 German rules, 2026 amounts). Claude never calculates money.
- Claude (vision + text, default model `claude-sonnet-5-5`, configurable via `ANTHROPIC_MODEL`) does: read official documents into JSON, explain official letters in the parent's language, write formal German letters, explain a card, answer questions on a card.
- Every AI output is labelled ✨ (lilac colour), has a "This isn't right" link, and says when it is a cached demo answer.
- Prompts live in [`prompts/`](prompts/). The API key stays on a tiny Python backend ([`server/server.py`](server/server.py)), never in the app.

## How to run it
Requirements: macOS with Xcode 27 (iOS 27 simulator), Python 3.

```bash
cp .env.example .env          # paste your ANTHROPIC_API_KEY into .env
python3 server/server.py      # backend on http://127.0.0.1:8787 (standard library only)
open TaxHelper.xcodeproj      # run the TaxHelper scheme on an iPhone simulator
```

- Fastest demo: on the welcome screen tap **"Use demo family (Priya & Arjun)"**, then Capture → **"Use sample letter from care insurer (MUSTER)"** → **Reply in German**.
- On a real iPhone: Family tab → AI connection → set the backend URL to your Mac's IP (e.g. `http://192.168.1.20:8787`).
- **Demo mode** (Family tab) uses cached AI answers, so the pitch works offline. If the backend is unreachable the app falls back to them automatically.

**Live link (if any):** <link>

## Screenshots / demo
<Drop screenshots here, or link your 2-minute demo video.>

## Team
Teams of 5 (at least 1 builder, 1 product or design, 1 domain expert; plus founder or anyone). Link each name to a GitHub or LinkedIn profile, and replace the example row with your team.

| Name | Role / background |
|---|---|
| [Mehul Patel](https://github.com/nomadicmehul) *(example)* | Claude Ambassador, DevRel |
| [Your name](https://www.linkedin.com/in/your-profile) | Builder / Product or design / Domain expert / Founder |
| [Your name](https://github.com/your-username) | |
| [Your name](https://github.com/your-username) | |
| [Your name](https://github.com/your-username) *(optional)* | |
| [Your name](https://github.com/your-username) *(optional)* | |

## Credits
- [Claude API](https://docs.claude.com) by Anthropic — document reading, explanations, German letters.
- Apple SwiftUI, PhotosUI and SF Symbols.
- Rule amounts compiled from §33b EStG and SGB XI (gesetze-im-internet.de) and the secondary sources listed in `Project context.MD`.
- Colours approximate the Taxfix brand; no Taxfix logos or illustrations are used. All documents are fictional "MUSTER" samples, no real personal data.
