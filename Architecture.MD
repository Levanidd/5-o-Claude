# App Architecture – Family Support Check (iOS)

> **The idea in one line:** the AI does the work and the parent approves it. There is no blank chat box. AI runs in the background behind structured screens: it reads documents, works out estimates, writes letters and watches deadlines, and the parent confirms with a tap.

---

## 1. Business goals and how the architecture serves them

| Goal | What the architecture does |
|---|---|
| **Immediate value** | A euro estimate appears **before sign-up**, within about 90 seconds. The account is created *after* the aha moment |
| **Money recovered (north-star KPI)** | Every opportunity ends in an action (Taxfix return, generated letter, expert). Status is tracked through to "Approved €" |
| **Taxfix growth** | Tax items flow into the Taxfix return in one tap. The app brings in high-value, recurring filers |
| **Retention** | Background watchers (deadlines, rule changes, life events) send one-tap push actions |
| **Trust and compliance** | Fixed rules decide eligibility. The AI only explains, reads documents and drafts, and everything has a cited source |
| **Jury: "people learn and use AI"** | Every AI output is visible and explained: "How we calculated this," confidence badges, and AI-drafted content marked as such |
| **Reach expats and newcomers** | The whole app works in the parent's own language, and all communication with authorities is handled for them: reading official letters, writing letters in German, preparing calls and appointments, and filing taxes. This group is the most underserved and the most likely to leave money unclaimed |

---

## 2. Core building blocks (domain model)

```
Family ─┬─ Caregiver(s)        (jobs, care hours, insurance,
        │                       app language, German level,
        │                       residence status, year moved, foreign income)
        └─ Child(ren)          (age, disability degree, ID marks, care level, needs)
                │
                ▼
        Entitlement (rule)     ← versioned rules catalogue with legal source
                │ matched by the rules engine
                ▼
        Opportunity            (est. €/year, confidence, effort, deadline, status)
                │ acted on
                ▼
        Case                   (Found → In progress → Submitted → Approved / Rejected → Appeal)
                │
        Document ── Deadline ── Event (life events, rule changes)
                │
        Letter                 (incoming or outgoing · German original +
                                translation in the parent's language ·
                                linked to a Case and its Deadline)
```

**The Opportunity is the main object in the app.** Every screen either produces opportunities, explains them, acts on them or tracks them.

---

## 3. Navigation

Tab bar with 4 tabs and a central capture button:

| Tab | Purpose | Key screens |
|---|---|---|
| **Home** | "What should I do now?" | Hero € numbers, *Next best action*, deadlines, "For you" feed |
| **Money** | All opportunities | List grouped by status, filters (tax / care / grants / local), opportunity detail |
| **[ + ] Capture** | One input for everything | Camera (decisions, receipts, **letters from authorities → translated and explained**), voice note in any language, share sheet from Mail/Files |
| **Family** | The profile as a living source of truth | Child card(s), caregivers, document vault, "what-if" simulator |
| **Community** | Peers and help | Matched parents, Q&A by topic, expert and counselling handoff |

Why no "Chat" tab: questions are asked **in context** (on a card, a document or a letter), so every answer is tied to a specific object and can be acted on.

---

## 4. AI UX patterns (instead of plain chat)

| # | Pattern | Where | How it works |
|---|---|---|---|
| 1 | **Scan, then confirm** | Onboarding and Capture | A photo of a decision letter gets read into fields. The parent sees the extracted values with ✓ / edit chips. Confirming is faster than typing |
| 2 | **Live value meter** | Quick profile | A "€ found" counter goes up after each answer. Every answer feels worth giving (the Taxfix refund-ticker pattern) |
| 3 | **Explainable card** | Opportunity detail | "Why you qualify" shows the rule chain (*care level 3 ✓ + caring at home ✓ → eligible*), the € calculation, the legal source link and a confidence badge |
| 4 | **Confidence states** | All cards | **Confirmed** / **Likely** / **Need 1 answer**. Uncertainty becomes a one-tap question instead of a wrong promise |
| 5 | **Questions on the card** | Card, document, letter | Suggested question chips ("Can I get this for past years?") plus a free-text field, answered from that object and its sources |
| 6 | **Draft for review** | Applications, appeals | The AI pre-fills the form or letter. Personal data is highlighted, the draft is marked "AI-drafted," and the parent can tap any sentence to make it simpler, firmer or translated. Then sign and send |
| 7 | **Next best action** | Home | One card ranked by € × likelihood ÷ effort, with deadline urgency. Never a wall of options |
| 8 | **Background watchers** | Push and feed | Agents monitor deadlines, rule changes, new programs and the child's milestones, then notify with one ready-made action |
| 9 | **What-if simulator** | Family | "If the care level goes up to 4 → +€X/year, here's how to request a reassessment." Shows people what's possible |
| 10 | **Reading replies** | Capture | A scanned reply from an authority is read automatically: approved updates the € secured, rejected opens a pre-drafted appeal with the deadline |
| 11 | **Handoff with context** | Any card | "Talk to an expert" sends the full case summary, so the parent never repeats themselves |
| 12 | **Correction loop** | Every AI output | "This isn't right" → fix → the estimate recalculates. It also feeds rule and extraction quality |
| 13 | **Voice in, structure out** | Profile, capture | The parent talks freely ("Leo has autism, we got care level 3 in March…") and the AI turns it into structured fields to confirm |

**Main rule:** the AI proposes and the parent approves. Nothing is submitted without an explicit tap.

---

## 4b. Language and communication layer (expats and newcomers)

Many parents in Germany don't read official German. The app keeps them in their own language and handles the German side for them.

| # | Feature | How it works |
|---|---|---|
| L1 | **App in their language** | Language is chosen on the first screen (EN, TR, AR, UK, RU, PL, ES…). Arabic is laid out right-to-left. Voice input works in any language |
| L2 | **Official letter explainer** | The parent photographs a letter from an authority and gets a summary in their language: **what it says · what you need to do · deadline · amount**. It also adds a deadline and a "Reply" button. The original stays one tap away |
| L3 | **German letter from their own words** | The parent explains in their own language (or a voice note) and the AI writes a correct, formal German letter: application, appeal, question or change notice |
| L4 | **Side-by-side review** | The German letter and its translation sit side by side, so the parent knows exactly what they're signing. Names, numbers, dates and file numbers are locked so translation can't change them |
| L5 | **German terms with explanations** | Official terms stay in German (they're what appear on forms), with a tap-to-explain chip, e.g. *Pflegegrad → care level: how much daily help your child needs* |
| L6 | **Form fill-along** | Point the camera at a German paper form and each field gets a translated label and the value to write, taken from the profile |
| L7 | **Call and appointment prep** | A simple German script for phone calls, a "show this screen to the clerk" summary, and a checklist of documents to bring |
| L8 | **Taxes in their language** | The Taxfix return runs in their language, with newcomer cases covered: first or last year in Germany, foreign income, child benefit when family lives abroad |
| L9 | **"New to Germany" path** | A first-90-days checklist: registering an address, health insurance, child benefit, tax ID, getting a German disability assessment (foreign diagnoses don't carry over automatically), and translating foreign medical reports |
| L10 | **Community and experts by language** | Matches parents who share a language, and hands off to advisors or counselling who speak it |

**Guardrails**

- The German version is the one that counts legally. Translations are for understanding only, and the screen says so.
- Every letter goes through the side-by-side review before sending, and names, numbers and dates are always locked.
- Residence status is an input to the rules engine, because some benefits depend on the type of residence permit. It's never guessed.
- When a translation is unclear, the app says so and offers a person who speaks the language.

---

## 5. Key screens

**Home**
```
┌───────────────────────────────┐
│ € 4,280 secured   € 2,950 open│  ← progress ring
├───────────────────────────────┤
│ ▶ NEXT BEST ACTION            │
│ Apply for relief budget       │
│ ~€1,600/yr · 5 min · Likely   │
│ [ Start ]                     │
├───────────────────────────────┤
│ Deadlines   ● Appeal 12 Nov   │
│             ○ Tax 2022 31 Dec │
├───────────────────────────────┤
│ For you · New state grant …   │
└───────────────────────────────┘
```

**Opportunity detail** (top to bottom): title and € estimate → confidence badge → "Why you qualify" (rule chain) → "How to claim" (3 steps, effort) → action buttons [Add to Taxfix return] / [Draft application] / [Get help] → question chips → sources.

---

## 6. System architecture

```
┌──────────────────────── iOS app (SwiftUI) ────────────────────────┐
│ Profile · Money · Capture (VisionKit, on-device text recognition) │
│ · Family · Community                                              │
│ Local encrypted cache · Face ID lock · Push                       │
└───────────────┬───────────────────────────────────────────────────┘
                │ HTTPS (EU-hosted backend)
┌───────────────▼───────────────────────────────────────────────────┐
│ API gateway / auth (Sign in with Apple, Taxfix SSO)               │
├───────────────────────────────────────────────────────────────────┤
│ Profile service      encrypted health-data store, consent records │
│ RULES ENGINE         fixed, versioned rules (JSON/DSL),           │
│                      each rule → legal source, € formula, inputs  │
│ Opportunity service  matching, ranking (€ × likelihood ÷ effort)  │
│ Case tracker         status machine, deadlines, reminders         │
│ Document service     vault, text recognition, field reading       │
│ Watcher jobs         rule-change feed, new programs, life events  │
│ Taxfix integration   pre-fill tax return (lump-sum, care, travel) │
├───────────────────────────────────────────────────────────────────┤
│ AI LAYER (LLM, guarded)                                           │
│  • Read fields from documents   → structured JSON + confidence    │
│  • Voice/free text → profile    → structured JSON to confirm      │
│  • Explain                      → grounded on rule + source       │
│  • Questions on a card          → search over curated sources     │
│  • Draft letters                → templates + profile fields      │
│  • Read authority replies       → decision, amount, deadline      │
│  • Translate and summarize      → official letters → own language │
│  • Write in German              → own-language input → formal DE  │
│    (names, numbers, dates locked · side-by-side review)           │
│ Guardrails: no eligibility or € from the LLM · sources required · │
│ personal data removed before prompts · sensitive-data consent     │
├───────────────────────────────────────────────────────────────────┤
│ Knowledge base  curated official sources (federal, state, local,  │
│                 foundations) · human review before publishing     │
│ Analytics       funnel + € KPIs (privacy-safe)                    │
└───────────────────────────────────────────────────────────────────┘
```

**Split of responsibility:** fixed rules decide eligibility and amounts. The AI reads, explains and drafts. This is how the app avoids AI mistakes about entitlements, and it's the main answer to the jury's trust question.

---

## 7. Flow to first value

```
Open app → 2 trust screens → 6–8 tap questions (€ meter climbing)
→ optional scan → RESULT "€X/yr + €Y back pay" → sign in to save → act
```

- **Target:** time to first € under 90 seconds, with no account needed.
- **Sign-up comes after value.** Saving progress, adding to the Taxfix return or generating a letter requires an account.

---

## 8. KPIs built in

| KPI | Tracked by |
|---|---|
| Time to first € | Onboarding start → result screen |
| € identified / € claimed / € approved per family | Opportunity and Case status |
| Action rate | Share of opportunities that reach "Submitted" |
| Taxfix conversion | Tax items pushed to a return, returns filed |
| Retention | Push-to-action rate, monthly active families |
| Trust | Correction rate, expert handoffs, ratings on explanations |
| Community | Matches made, peers actively engaging |
| Language reach | Share of non-German-language users, letters explained, German letters sent, € recovered by newcomer families |

---

## 9. Hackathon build plan

| Build for real | Fake or mock |
|---|---|
| Quick profile with live € meter | Community tab (static) |
| Rules engine with about 10 core German rules | Watchers (one scripted push) |
| Document reading on one sample care-level decision | Taxfix integration (handoff screen) |
| Explainable opportunity cards and questions on a card | Reply reading |
| AI-drafted application or letter for one benefit | Expert handoff |
| **Official letter explainer + German reply** (one real letter, EN ↔ DE side by side) | Form fill-along camera |
| App in English and one more language | Remaining languages, right-to-left layout |
| Home dashboard with next best action | |

**Demo story (3 min):** a parent who doesn't speak German (the app is in English or Turkish) → scan → € meter climbs → "€X found" → open a card and show "Why you qualify" → **scan a confusing German letter from the care insurer → "Here's what it means, here's your deadline" → speak a reply in their language → formal German letter, side by side** → add to the Taxfix return → dashboard shows "€ secured."
