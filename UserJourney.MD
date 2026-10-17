# User Journey – Family Support Check (iOS)

An iOS app for parents of children with disabilities, built on familiar Taxfix patterns: one question per screen, a live "€ found" counter, and the Taxfix tax return as the main place money gets claimed.

## Journey overview

```
Entry → Welcome → Quick profile → Scan documents → First result → Understand → Act → Track → Dashboard → Return triggers
                                                   (aha, < 3 min)                                      ↺ back to Understand
```

## Steps

| # | Stage | What the parent does | What the app does | Value moment |
|---|---|---|---|---|
| 0 | **Entry** | Answers "Do you have a child with a disability or care level?" during their Taxfix return, or installs the app on a referral from a counsellor or another parent | Offers a "Family Support Check" | — |
| 1 | **Language and trust** (2 screens) | **Picks their language** (EN, TR, AR, UK, RU, PL, ES…) and reads the promise. No account needed yet | Shows "3 minutes, no paperwork needed, no German needed" and a short privacy promise with consent for each data type | Feels safe and understood |
| 2 | **Quick profile** (~90 sec) | Taps answers or uses voice in any language. 6–8 questions: child's age, state, disability degree (GdB), ID marks (Merkzeichen), care level (Pflegegrad), health insurance, what they already receive, **"New to Germany?"** | A live "€ found" counter goes up with each answer, and a "why we ask" chip sits on every question. Newcomers also get a first-90-days checklist | Watches money appear |
| 3 | **Scan documents** (optional) | Photographs the disability ID or care-level decision | The AI reads the fields and the parent confirms them with ticks. This fills gaps and corrects the estimate | "It understood my paperwork" |
| 4 | **First result** (the "aha" moment) | Sees the summary, then **signs in** (Apple or Taxfix account) to save it | Shows "€X per year available, plus €Y from past years," with ranked opportunity cards | **Main value, inside 3 minutes** |
| 5 | **Understand** | Opens a card | Plain-language explanation, why they qualify, the legal source, effort and deadline. "Ask a question" opens AI chat about that card | Understands without googling |
| 6 | **Act** | Picks one of three paths | **Add to Taxfix return** (one tap, in their language), **generate the application or letter** in formal German with a side-by-side translation to sign and send, or **get help** from a Taxfix expert or free counselling (EUTB) who speaks their language | Admin done in minutes, without German |
| 7 | **Track and communicate** | Marks it as submitted, later scans the reply from the authority | The reply is **translated and summarized** (what it says, what to do, deadline). Moves it through Found → Submitted → Approved, with push reminders before deadlines. A rejection opens an appeal flow: the parent explains in their language and gets a German letter | Nothing falls through, nothing is lost in translation |
| 8 | **Dashboard** (home) | Comes back weekly, monthly or at tax time | See below | Ongoing reason to return |
| 9 | **Return triggers** | Gets a push notification | Life events (child turns 18, care-level review), new programs, rule changes and tax season lead back to step 5 | Long-term retention |

## Home dashboard

- **Hero numbers:** "€ secured this year" next to "€ still available," with a progress ring.
- **Next best action:** one card only, e.g. "Apply for the relief budget, 5 min, €X."
- **Deadlines:** a timeline of the next 90 days.
- **Opportunities by status:** found, in progress, submitted, approved.
- **"For you" feed:** new programs, rule changes and foundation grants, filtered to this family.
- **Community entry:** "12 parents near you with a child the same age."
- **Document vault:** official decisions and receipts, ready for the next tax return.

**Tab bar:** Home · Opportunities · Ask · Documents · Community

## Design principles

1. **Value inside 3 minutes.** Show money before asking for anything heavy.
2. **One decision per screen.** Show one next best action, never a wall of options.
3. **Always show why.** Every number links to its reasoning and source. This is the trust layer.
4. **Easy to pause and resume.** Progress saves automatically, and the app says "pick up where you left off."
5. **Taxfix as the main way to claim.** Tax items go straight into the return, and everything else ends in a ready-to-send document.
6. **No German needed.** Everything is in the parent's language. Letters to authorities are written in German and always shown side by side with a translation before sending.

## Hackathon scope

- **Build:** steps 2 → 4 → 5 → 6 (Taxfix handoff and one generated letter) plus a static dashboard, and the **official letter explainer with a German reply** (English ↔ German side by side).
- **Mock in the pitch:** steps 7–9 (tracking, feed, community).
