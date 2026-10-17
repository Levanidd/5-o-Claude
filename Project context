# PROJECT_CONTEXT.md — Family Support Check (Taxfix Hackathon)

> **For the builders and their coding agent (Cursor).** Read this file first. Two companion files go into more detail:
> - `user-journey.md` — the steps from entry to dashboard
> - `app-architecture.md` — navigation, AI UX patterns and system design
>
> If this file and a companion file disagree, **this file wins**.

---

## 1. What we're building (TL;DR)

An **iOS app for parents of children with disabilities in Germany** that:

1. learns about the family through a short, tap-based profile and photos of documents,
2. **finds the money and support they're entitled to** (tax allowances, care benefits, grants) and shows a € estimate within ~90 seconds,
3. **explains every result in plain language**, with the reasoning and the legal source,
4. **helps them act**: one tap into the Taxfix tax return, AI-drafted applications and letters in German, or a handoff to an expert,
5. works **in the parent's own language**. Official German letters are explained, and replies are written in German with a side-by-side translation.

**Main idea: the AI does the work and the parent approves it.** This is **not a chatbot.** The AI runs in the background behind structured screens.

---

## 2. Hackathon context

- **Host:** Taxfix. **Challenge:** "Build a working prototype that helps real people learn or use AI."
- **Jury criteria:** **Impact 40%** · Product quality 20% · Creativity 20% · Technical quality 20%.
- What this means for the build:
  - **Impact:** the demo must show **real euros found** and **a real action taken** (a letter drafted, an item added to the tax return).
  - **Product quality:** polished, Taxfix-like flow. One question per screen, no dead ends.
  - **Creativity:** AI patterns beyond chat (scan → confirm, live € meter, explainable cards, letter explainer).
  - **Technical quality:** a clean split between **fixed rules (eligibility and €)** and **AI (reading, explaining, drafting)**.

---

## 3. Users and demo persona

**Target users:** parents and caregivers of disabled children in Germany. They're exhausted and short on time, and the system is fragmented. A large group are **expats and newcomers who don't read official German.**

**Demo persona (use it everywhere: seed data, screenshots, demo):**

| Field | Value |
|---|---|
| Parent | **Priya**, 36, moved from India to Berlin 2 years ago, speaks English, very little German |
| Partner | Raj, employed full-time. Priya works 20 h/week |
| Child | **Arjun**, 7, autism |
| Disability degree (GdB) | 50, no marks on the ID (Merkzeichen) |
| Care level (Pflegegrad) | 3, granted March 2025 |
| Insurance | Statutory (GKV) |
| Already receives | Child benefit (Kindergeld) and care allowance (Pflegegeld) |
| Not yet claimed | Disability lump-sum in tax return, caregiver lump-sum, relief amount, respite care, caregiver pension credits |
| Pending letter | A German letter from the care insurer she doesn't understand (a request for information with a deadline) |

---

## 4. Product principles (non-negotiable)

1. **Value before sign-up.** A € estimate within ~90 s, with no account needed. Sign-up happens after the first result.
2. **Not a chatbot.** No open chat tab. Questions are asked **on a specific object** (a card, a document, a letter) using suggested question chips.
3. **The AI proposes, the parent approves.** Nothing is sent or submitted without an explicit tap.
4. **Fixed rules decide eligibility and €.** The LLM never decides whether a family qualifies and never calculates amounts.
5. **Always show why.** Every number links to "Why you qualify" (the rule chain), the calculation and the legal source.
6. **Show confidence:** `confirmed` / `likely` / `needs_info`. Never promise money with certainty.
7. **One decision per screen.** One *Next best action* on Home.
8. **No German needed.** All UI is in the user's language. Outgoing letters are in German, shown **side by side** with a translation.
9. **Easy to pause and resume.** Save state on every step. Parents get interrupted.
10. **Warm, plain, respectful tone.** No pity, no jargon, no blame.

---

## 5. Hackathon scope

| ✅ Build for real | 🎭 Fake or mock (looks real) | ❌ Out of scope |
|---|---|---|
| Language picker (EN + DE; a third language like TR or AR is a bonus) | Sign-in (fake Apple button → local user) | Real Taxfix or ELSTER submission |
| Quick profile, one question per screen, with live € meter | Taxfix return handoff (success screen) | Payments |
| Rules engine with about 10 seed rules (§7) | Push notifications (one scripted in-app banner) | Real community or chat between users |
| Document scan → AI field reading → confirm screen | Community tab (static matched parents) | Scraping official sites |
| Results screen + explainable opportunity cards | Expert handoff (summary screen) | Real user data |
| Questions on a card (suggested chips + short answer) | What-if simulator (optional) | |
| **Official letter explainer** (scan a German letter → summary in user's language) | Deadlines timeline (seeded) | |
| **Reply in German** (user's words → formal German letter, side by side, export PDF / share) | | |
| Home dashboard: € secured / € open, Next best action, deadlines | | |

**Demo-critical path (build first, polish most):**
Language → Profile + € meter → Result → Card detail ("Why you qualify") → Letter explainer → German reply → Add to Taxfix (mock) → Dashboard.

---

## 6. Recommended tech stack

Optimized for speed in Cursor and a live demo on a real iPhone.

| Layer | Choice | Why |
|---|---|---|
| App | **Expo (React Native) + TypeScript + expo-router** | Fastest to build in Cursor, runs on an iPhone through Expo Go, hot reload |
| Styling | NativeWind (Tailwind) or StyleSheet with a small theme file | Speed and consistency |
| State | Zustand + persisted with AsyncStorage | Pause and resume |
| i18n | i18next + react-i18next. Arabic needs right-to-left layout | Multiple languages |
| Camera / images | expo-image-picker (camera + library) | Document scan |
| PDF / share | expo-print + expo-sharing | Export the German letter |
| Backend | Small Node server (Hono or Express) **or** Expo API routes | **Keeps the LLM API key off the device** |
| LLM | Claude API (vision for documents, text for explanations and letters) | Reads documents, drafts German well |
| Validation | Zod schemas for every LLM response | Reliable structured output |

> If the team prefers **SwiftUI**, the architecture stays the same. Port the rules engine to Swift and keep the backend as is.

**Demo safety:** add a `DEMO_MODE` flag that returns **cached AI responses** for the persona's sample documents if the network or API fails during the pitch.

---

## 7. Rules engine (fixed rules, the core of trust)

### 7.1 Design

- Rules are **data** (TypeScript objects or JSON), not hard-coded `if`s scattered through the UI.
- Each rule has: `id`, `category`, `title` (an i18n key), `conditions` (reading the profile), `estimate(profile) → { amount, unit, kind }`, `confidence(profile)`, `legalSource`, `howToClaim` (an action type), `effortMinutes`, `deadline?`, `sourceUrl`, `validFrom` / `verifiedOn`.
- The engine returns `Opportunity[]` with the **explanation chain**: which conditions were met, which are missing, and which answer would confirm them.
- **Tax vs. cash.** Tax allowances (`kind: "tax_deduction"`) reduce taxable income; they **aren't cash**. Convert them to an estimated tax saving using an **assumed marginal rate** (demo default 30%, shown as "≈"), and say so in the UI. Benefits (`kind: "cash_benefit"`) are paid out directly. Never add the two together without labelling them.
- **Ranking** for Next best action: `score = estimatedEuroPerYear × likelihood ÷ effortMinutes`, boosted by deadline urgency.

### 7.2 Seed rules (Germany, amounts as of 2026)

> ⚠️ **Check amounts against official sources before the demo** and set `verifiedOn`. These were compiled from secondary sources in Oct 2026, and care amounts may change in 2027/2028.

| id | Benefit (DE / EN) | Condition (simplified) | Amount | Kind | How to claim |
|---|---|---|---|---|---|
| `tax_disability_lumpsum` | Behinderten-Pauschbetrag / disability lump-sum allowance (§33b EStG) | Child's GdB ≥ 20. Can be transferred to the parents | GdB 20: €384 · 30: €620 · 40: €860 · **50: €1,140** · 60: €1,440 · 70: €1,780 · 80: €2,120 · 90: €2,460 · 100: €2,840 · marks H/Bl/TBl: €7,400 per year | tax_deduction | Taxfix return (child section) |
| `tax_caregiver_lumpsum` | Pflege-Pauschbetrag / caregiver allowance (§33b(6) EStG) | Unpaid care at home, care level ≥ 2 | Care level 2: €600 · **3: €1,100** · 4/5 or mark H: €1,800 per year | tax_deduction | Taxfix return |
| `tax_travel_lumpsum` | Behinderungsbedingte Fahrtkostenpauschale / disability travel allowance | GdB ≥ 80, **or** GdB ≥ 70 + mark G → €900. Marks aG/Bl/TBl/H → €4,500 | €900 / €4,500 per year | tax_deduction | Taxfix return |
| `tax_past_years` | Amending past tax returns | Disability degree or care level dates back to earlier years with returns not yet final | Sum of the above per eligible year (usually up to 4 years back) | tax_deduction | Taxfix: amend or file past years |
| `care_allowance` | Pflegegeld / care allowance | Care level ≥ 2, care at home | Care level 2: €347 · **3: €599** · 4: €800 · 5: €990 per month | cash_benefit | Care insurer (Pflegekasse) application |
| `care_relief_amount` | Entlastungsbetrag / relief amount | Care level ≥ 1 | €131 per month (paid as reimbursement for approved services; unused amounts can carry over) | cash_benefit | Invoices to the care insurer |
| `care_respite_budget` | Verhinderungs- + Kurzzeitpflege / respite and short-term care (combined budget) | Care level ≥ 2 | Up to €3,539 per year | cash_benefit | Care insurer application |
| `care_consumables` | Pflegehilfsmittel zum Verbrauch / care supplies | Care level ≥ 1, care at home | Up to €42 per month | cash_benefit | Care insurer application |
| `care_home_adaptation` | Wohnumfeldverbessernde Maßnahmen / home adaptation grant | Care level ≥ 1, adaptation needed | Up to €4,180 per measure | cash_benefit | Care insurer application **before** the work starts |
| `pension_caregiver` | Rentenpunkte für Pflegepersonen / caregiver pension credits | Care level ≥ 2, ≥ 10 h/week caring over ≥ 2 days, caregiver works ≤ 30 h/week | Pension credits (show as "builds your pension", no € per year) | non_cash | Care insurer reports it, so the parent should check it's registered |

`likely` vs `confirmed`: a rule is `confirmed` only when all its inputs come from a confirmed document or explicit answers; otherwise it's `likely`. If an input is missing, it's `needs_info`, with the one question that would resolve it.

**Persona check (Arjun: GdB 50, care level 3):** disability lump-sum €1,140 + caregiver lump-sum €1,100 → about €670 tax saving per year at 30% · relief amount €1,572/yr · respite €3,539/yr · supplies €504/yr · plus past years. That gives a believable "€X found" on screen.

---

## 8. Data model (TypeScript)

```ts
type Lang = "en" | "de" | "tr" | "ar" | "uk" | "ru" | "pl" | "es";
type Confidence = "confirmed" | "likely" | "needs_info";
type Source = "answer" | "document" | "derived";

interface Field<T> { value: T | null; source: Source; confirmed: boolean; docId?: string }

interface Family {
  id: string;
  language: Lang;
  germanLevel: "none" | "basic" | "good" | "native";
  state: Field<string>;                 // Bundesland, e.g. "BE"
  newToGermany: Field<boolean>;
  yearMoved?: Field<number>;
  residenceStatus?: Field<"eu" | "permit" | "settled" | "citizen" | "unknown">;
  singleParent: Field<boolean>;
  insurance: Field<"gkv" | "pkv">;
  incomeBand?: Field<"lt30" | "30to60" | "gt60" | "skip">;
  caregivers: Caregiver[];
  children: Child[];
  alreadyReceives: string[];            // rule ids already claimed
}

interface Caregiver { name: string; weeklyWorkHours: Field<number>; weeklyCareHours: Field<number> }

interface Child {
  id: string; nickname: string; birthDate: Field<string>;
  gdb: Field<number>; gdbSince?: Field<string>;
  merkzeichen: Field<string[]>;         // ["G","aG","H","Bl","TBl","B","Gl"]
  pflegegrad: Field<0|1|2|3|4|5>; pflegegradSince?: Field<string>;
  statusGdb: "none" | "pending" | "granted" | "rejected";
  statusPflegegrad: "none" | "pending" | "granted" | "rejected";
}

interface Opportunity {
  ruleId: string;
  estimate: { amount: number; unit: "year" | "month" | "once"; kind: "tax_deduction" | "cash_benefit" | "non_cash"; taxSavingApprox?: number };
  confidence: Confidence;
  reasons: { label: string; met: boolean; source: Source }[];  // the "Why you qualify" chain
  missing?: { questionKey: string };
  action: "taxfix" | "letter" | "form" | "expert" | "info";
  effortMinutes: number; deadline?: string;
  status: "found" | "in_progress" | "submitted" | "approved" | "rejected";
}

interface Letter {
  id: string; direction: "incoming" | "outgoing";
  originalDe: string; translation: string; translationLang: Lang;
  summary?: { whatItSays: string; whatToDo: string[]; deadline?: string; amount?: number; sender?: string };
  lockedTokens: string[];               // names, dates, file numbers, amounts
  linkedRuleId?: string;
}
```

---

## 9. AI layer: tasks, contracts, guardrails

All LLM calls go **through the backend**. Every response is **JSON validated with Zod**, and the UI falls back gracefully if validation fails.

| Task | Input | Output (JSON) | Notes |
|---|---|---|---|
| `extractDocument` | Image of a care-level decision or disability ID | `{ docType, fields: { pflegegrad?, gdb?, merkzeichen?, validFrom?, deadline?, fileNumber? }, confidencePerField }` | The user confirms each field. Never fill the profile silently |
| `parseFreeText` | Voice or text in any language | Partial `Family` / `Child` fields + `confidencePerField` | Shown as chips to confirm |
| `explainOpportunity` | Rule + opportunity + profile (**no names**) | `{ plainExplanation, whyBullets[], howToSteps[] }` in the user's language | Must only paraphrase the rule data. **No new numbers** |
| `answerOnCard` | Question + rule + source excerpt | `{ answer, citedSource, escalate: boolean }` | If unsure → `escalate: true` → offer an expert |
| `explainLetter` | Image or text of an incoming German letter | `{ sender, whatItSays, whatToDo[], deadline, amount, lockedTokens[], translation }` | Creates a deadline and a "Reply" button |
| `draftGermanLetter` | User intent in their language + profile + letter context | `{ letterDe, translation, lockedTokens[] }` | Formal German letter format (sender, recipient, file number, date, subject, greeting, closing). Locked tokens copied exactly |

**Guardrails (put these in the system prompts):**

- Never decide eligibility and never invent amounts. Use only values passed in from the rules engine.
- Always answer in `family.language`. Outgoing official letters are always in **German**.
- Copy names, dates, file numbers and amounts **exactly**, then check after generation that every `lockedToken` appears unchanged.
- Say when you're unsure. Prefer "I'm not sure, here's who can help" over guessing.
- Frame everything as **information, not legal or tax advice**. Show one short disclaimer in the UI, not in every message.
- Strip personal identifiers (real names, addresses, insurance numbers) before prompts where possible. Use the child's nickname.

**Show the AI in the UI (this helps the "learn AI" score):** small "✨ AI-read" / "✨ AI-drafted" labels, a "How we calculated this" sheet, confidence badges, and a "This isn't right" button on every AI output.

---

## 10. Screens and routes (expo-router)

```
app/
  (onboarding)/language.tsx        L1  language picker
  (onboarding)/welcome.tsx         trust + privacy (no account)
  (onboarding)/profile/[step].tsx  one question per screen + € meter
  (onboarding)/scan.tsx            camera → extract → confirm fields
  (onboarding)/result.tsx          "€X/yr + €Y past years" → sign-in (mock)
  (tabs)/home.tsx                  € secured/open, Next best action, deadlines, feed
  (tabs)/money/index.tsx           opportunities grouped by status
  (tabs)/money/[ruleId].tsx        explainable card + actions + question chips
  (tabs)/capture.tsx               scan document / letter / receipt, voice note
  (tabs)/family.tsx                child card, caregivers, document vault
  (tabs)/community.tsx             static matched parents (mock)
  letter/explain/[id].tsx          incoming letter summary (user lang) + original
  letter/reply/[id].tsx            user intent → German draft, side by side, export
  taxfix/handoff.tsx               mock "added to your Taxfix return"
  expert/handoff.tsx               mock case summary
```

Suggested code layout: `src/rules/` (catalogue + engine + tests), `src/ai/` (client calls + Zod schemas), `src/i18n/` (locales), `src/store/`, `src/components/` (EuroMeter, OpportunityCard, ConfidenceBadge, ReasonChain, SideBySideLetter, QuestionChips, NextBestAction), `server/` (LLM routes, prompts, demo cache).

---

## 11. UX and UI guidelines

- **Taxfix feel:** clean, friendly, lots of white space, big tap targets, one question per screen, progress bar, sticky € meter at the top during the profile. Colours, fonts and components are in **§11b**.
- **Animate the € meter.** Counting up on each answer is the signature moment.
- **Cards:** title · € (labelled "tax saving ≈" or "paid to you") · confidence badge · effort ("5 min") · deadline.
- **Copy tone:** short sentences, second person, warm, no jargon. German official terms appear **in italics with a tap-to-explain chip**: *Pflegegrad* → "care level".
- **Accessibility:** Dynamic Type, VoiceOver labels, contrast at least 4.5:1, never rely on colour alone for status.
- **i18n:** no hard-coded strings. Use `t("key")` everywhere. Leave room for longer German text. Test right-to-left layout if Arabic is added.
- **Empty and error states:** always offer a next step ("Couldn't read this — retake photo or enter manually").
- **Privacy UI:** consent per data type on the welcome screen, a "Delete my data" item in Family, and Face ID lock (optional).

---

## 11b. Visual language (follows the Taxfix brand)

Taxfix's 2024 rebrand (agency Kallan & Co, strategy "Fix finance for all") is built on: **a vivid green as the main colour**, **lilac, gold and blue as secondary colours** (taken from Euro banknotes), the **ROM typeface** (ABC Dinamo, a precise sans-serif with rounded punctuation and several widths for long German words), **€ and % symbols as graphic building blocks**, grainy 3D-style illustrations, and a tone that is **"precise and pragmatic in stressful moments, celebratory in rewarding ones."**

> ⚠️ Taxfix doesn't publish hex values. The colours below are **approximations**. Before building, open taxfix.de and the Taxfix iOS app, pick the real colours with a colour picker and update `theme.ts`. Ask the organisers whether the Taxfix logo and ROM font may be used. If not, use the fallbacks below and the line "Built for Taxfix" rather than the logo.

### Colours: each one has a job

| Token | Approx. value | Use it for |
|---|---|---|
| `green.500` (brand) | `#00B26B` | Main buttons, € found, progress, "approved" |
| `green.800` (deep) | `#0B3D2E` | Headings and text on light backgrounds, dark hero cards |
| `green.100` (mist) | `#E3F5EC` | Positive backgrounds, € meter track |
| `lilac.400` | `#B9A6F0` | **Everything AI:** ✨ AI-read / AI-drafted labels, AI suggestion chips, the "How we calculated this" sheet |
| `lilac.100` | `#F1ECFD` | Background of AI-generated blocks (letter drafts, explanations) |
| `gold.400` | `#F2C14E` | **Celebration and urgency:** "€X found" highlight, deadline soon, new opportunity |
| `blue.500` | `#3D6FE0` | **Expertise and trust:** legal source links, "Talk to an expert", German original of letters |
| `ink.900` | `#14171A` | Body text |
| `ink.500` | `#6B7178` | Secondary text |
| `paper` | `#FAF8F4` | App background (warm off-white, not pure white) |
| `surface` | `#FFFFFF` | Cards |
| `danger` | `#D64545` | Errors and rejections only, used sparingly |

**Contrast rule:** brand green isn't readable as body text on white, so use `green.800` for green text and keep `green.500` for fills with white or deep-green text on top. Check every pair for at least 4.5:1.

**Colour meaning stays fixed:** green = money and progress · lilac = AI · gold = moments that matter · blue = official or expert. Consistent colour-coding also helps users learn which parts the AI produced.

### Typography

| Role | Font | Size / weight |
|---|---|---|
| Display (the € meter, "€X found") | ROM wide **or fallback: Instrument Sans (width axis set wide)** | 44–56 pt, semibold, tabular numbers |
| Title | ROM / Instrument Sans | 28 pt semibold |
| Heading | same | 20 pt semibold |
| Body | ROM / Instrument Sans (or SF Pro) | 17 pt regular, line height 1.4 |
| Caption / labels | same | 13 pt medium |

- Instrument Sans is free on Google Fonts (`@expo-google-fonts/instrument-sans`) and has a width axis, which helps with long German words like *Pflege-Pauschbetrag*.
- Always use **tabular numbers** for euro amounts so the counting € meter doesn't jitter.
- Support Dynamic Type: sizes scale, and layouts must wrap rather than cut text off.

### € and % as design elements

- The **€ meter** is the signature element: a very large number in display type that counts up, on a `green.100` track.
- Use an oversized, cropped **€ or %** shape (5–10% opacity) as a background on the result screen, Home hero and celebration screens. This echoes Taxfix's motif system without copying its assets.
- Opportunity category icons are simple line icons (SF Symbols are fine): € for tax, a heart or hand for care, a graduation cap for grants, a house for home adaptation.

### Components

- **Buttons:** pill-shaped (fully rounded), 52 pt high, full width at the bottom of the screen. Main = `green.500`, secondary = outlined in `green.800`, text links in `blue.500` for official or expert actions.
- **Cards:** `surface` on `paper`, 20 pt corner radius, a very soft shadow or a 1 pt `#EAE6DF` border, 20 pt padding.
- **Opportunity card:** category icon · title · **€ amount (display weight)** with a "tax saving ≈" or "paid to you" label · confidence badge · effort chip · deadline chip in gold if due soon.
- **Confidence badges:** confirmed = green check, likely = outlined green, needs info = gold with a "1 question" chip. Always text plus icon, never colour alone.
- **AI blocks:** `lilac.100` background, ✨ label in `lilac.400`/`ink.900`, a "This isn't right" link at the bottom.
- **Side-by-side letter:** German original on a `blue` accent, translation on a `lilac` accent, locked tokens (names, dates, file numbers) underlined with a lock icon.
- **Spacing:** 4-pt grid (4, 8, 12, 16, 20, 24, 32). Generous white space, at most one main action per screen.

### Illustration and imagery

- Taxfix uses grainy, 3D-style illustrations of diverse people. **Don't copy or recreate Taxfix's own illustrations.** For the prototype, use the € and % shapes plus soft gradient blobs in brand colours with a subtle grain texture.
- If you show people, show diverse families, shot naturally at eye level, never pitying. Prefer no images over stock photos of wheelchairs.

### Motion

- **Celebratory moments:** the € meter counts up with a gentle spring, a short gold shimmer on "€X found", a light haptic (`Haptics.notificationAsync(Success)`) when money is found or a letter is ready.
- **Stressful moments** (official letters, deadlines, rejections): calm, no confetti, short transitions, clear next step.
- Respect **Reduce Motion**: replace counting and shimmer with a simple fade.

### Tone of voice (matching Taxfix)

- Friendly expert: "Here's what this letter means" rather than "AI analysis complete."
- **Precise when it's stressful:** "Your care insurer needs a form by 14 Nov. It takes about 10 minutes."
- **Celebratory when it's a win:** "Nice — that's about €1,570 a year you can now claim."
- Use "you", short sentences, no jargon. German terms in italics with a tap-to-explain chip.

### `theme.ts` starter

```ts
export const theme = {
  color: {
    green: { 100: "#E3F5EC", 500: "#00B26B", 800: "#0B3D2E" }, // ⚠️ approximations, sample from taxfix.de
    lilac: { 100: "#F1ECFD", 400: "#B9A6F0" },                // AI
    gold:  { 400: "#F2C14E" },                                // celebrate / urgent
    blue:  { 500: "#3D6FE0" },                                // official / expert
    ink:   { 500: "#6B7178", 900: "#14171A" },
    paper: "#FAF8F4", surface: "#FFFFFF", border: "#EAE6DF", danger: "#D64545",
  },
  radius: { card: 20, chip: 999, button: 999 },
  space: [0, 4, 8, 12, 16, 20, 24, 32, 48],
  font: {
    family: { display: "InstrumentSans_600SemiBold", body: "InstrumentSans_400Regular" }, // swap for ROM if licensed
    size: { display: 52, title: 28, heading: 20, body: 17, caption: 13 },
  },
} as const;
```

---

## 12. Sample data and test assets

- Create **clearly fictional sample documents** with "MUSTER / SAMPLE" printed on them: a care-level decision (care level 3, Arjun, from 03/2025) and a request-for-information letter from a care insurer with a 4-week deadline.
- **Don't use real insurer logos or names** (use e.g. "Muster-Pflegekasse"). Use no real personal data.
- Put `fixtures/persona.json`, `fixtures/pflegegrad_bescheid.jpg`, `fixtures/pflegekasse_brief.jpg` and their cached AI responses in `server/demo-cache/`.
- **Unit-test the rules engine** with the persona plus 3 edge cases: GdB 80 + mark G (travel allowance), mark H (€7,400 + €1,800), and no status yet (should suggest applying for a disability degree or care level first).

---

## 13. Privacy and safety (prototype level)

- Health data about children is **special-category data under GDPR**. Even in the prototype, use **fake data only**.
- Keep the API key on the server only. Don't log prompts with personal data. Use EU hosting if anything is deployed.
- Disclaimer (once, in onboarding and in Settings): *"Information, not legal or tax advice. Amounts are estimates. Official decisions come from the authorities."*

---

## 14. Demo script (3 minutes)

1. "Meet Priya. She moved to Berlin two years ago and her son Arjun has autism. Her German is basic." → app in **English**.
2. Quick profile → **€ meter climbs** → photo of the care-level decision → fields read → confirm.
3. **Result:** "≈ €X per year + €Y from past years," with ranked cards.
4. Open the **disability lump-sum** card → "Why you qualify" chain + source → **Add to Taxfix return** ✓.
5. **Capture → photo of a confusing German letter** → "Your care insurer is asking for X. Deadline: 14 Nov. Here's what to do."
6. Priya speaks her reply in English → **formal German letter, side by side** → export PDF.
7. **Dashboard:** € secured vs. open, Next best action, deadline added. End with the impact numbers.

---

## 15. Definition of done (for the demo build)

- [ ] The demo path in §14 runs end-to-end on a real iPhone **3 times in a row without crashing**
- [ ] `DEMO_MODE` works with the network turned off
- [ ] All € values come from the rules engine. Search the code and confirm no amount comes from an LLM response
- [ ] Every AI output has a label, a confidence badge or "This isn't right", and the user's language
- [ ] English + German locales complete for all demo screens
- [ ] Rules engine unit tests pass

---

## 16. Instructions for the coding agent

**Do**
- Read §4 (principles) and §9 (guardrails) before writing any AI-related code.
- Keep rules in `src/rules/catalogue.ts` as data, and add a test for every new rule.
- Validate every LLM response with Zod and handle failure with a friendly fallback.
- Use i18n keys for every user-facing string.
- Build the demo path (§5) first, then polish it before adding breadth.

**Don't**
- ❌ Add a general chat screen or chat tab.
- ❌ Let the LLM calculate amounts or decide eligibility.
- ❌ Put API keys in the app bundle.
- ❌ Use real personal data, real insurer branding, or scraped content.
- ❌ Send anything (letters, returns) without an explicit user confirmation step.
- ❌ Show tax deductions as if they were cash.

---

## 17. Glossary (DE → EN)

| German | English | Meaning |
|---|---|---|
| GdB (Grad der Behinderung) | Disability degree | 20–100, set by the state disability office (Versorgungsamt) |
| Merkzeichen | ID marks | Letters on the disability ID: G (walking impaired), aG (severely), H (helpless), Bl (blind), TBl (deafblind), B (needs companion), Gl (deaf) |
| Schwerbehindertenausweis | Disability ID card | Issued when GdB ≥ 50 |
| Pflegegrad | Care level | 1–5, assessed for the care insurer (Pflegekasse) |
| Pflegekasse | Care insurer | Part of statutory health insurance |
| Bescheid | Official decision letter | Usually comes with a 1-month appeal deadline |
| Widerspruch | Formal appeal | Objection to a decision |
| Pauschbetrag | Lump-sum allowance | Tax deduction with no receipts needed |
| Außergewöhnliche Belastungen | Extraordinary expenses | Tax-deductible exceptional costs |
| Kindergeld / Familienkasse | Child benefit / its office | |
| EUTB | Independent disability counselling | Free, nationwide |
| ELSTER | Tax authority's online portal | |
| Anmeldung | Address registration | First step for newcomers |

---

## 18. Sources

**Taxfix visual language**
- [taxfix.de – Taxfix's rebrand](https://taxfix.de/en/rebrand)
- [PRINT – Kallan & Co's rebrand of Taxfix](https://www.printmag.com/branding-identity-design/kallan-and-cos-customer-centric-rebrand-of-taxfix/)
- [Abduzeedo – Taxfix's new look](https://abduzeedo.com/taxfixs-new-look-branding-visual-identity-unveiled)

**Rule amounts (check before the demo)**

- [steuerschroeder.de – tax allowances for disability (as of 26.06.2026)](https://www.steuerschroeder.de/einkommensteuererklaerung_Behinderung.html)
- [pflegekompass.de – Pflegegeld 2026](https://pflegekompass.de/magazin/ratgeber/pflegegeld-2026)
- [gegen-hartz.de – changes to Pflegegeld from 2026](https://www.gegen-hartz.de/news/alle-wichtigen-nderungen-beim-pflegegeld-ab-1-januar-2026-pflegekasse)
- [gegen-hartz.de – Pflegegeld set to rise from 2027](https://www.gegen-hartz.de/news/pflegegeld-soll-ab-2027-steigen-warum-vom-plus-aber-nichts-uebrig-bleibt) *(check whether this changes the amounts)*
- Primary sources to confirm against: §33b EStG (tax allowances), SGB XI §§ 37, 39, 40, 42, 45b (care benefits), on gesetze-im-internet.de
