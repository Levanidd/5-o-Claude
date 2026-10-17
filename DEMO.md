# Taxability · 2-minute demo video

Record on the real iPhone. Claude answers live; each AI step takes 3–10 seconds, so cut the waiting in the editor or keep talking over it.

## Before recording (5 minutes)

1. The backend runs on Cloudflare, no laptop needed. Check it: open `https://taxability.kurdyukov-leo-ger.workers.dev/health` → `"ok": true`. The iPhone works on any network, even mobile data.
2. iPhone: Family tab → **Demo mode** off. Then **Delete my data** so the app starts at the language screen.
3. Print `fixtures/pflegegrad_bescheid.pdf` and `fixtures/pflegekasse_brief.pdf` (or open the PNGs full screen on a laptop). Both are fictional and marked MUSTER.
4. iPhone: Focus / Do Not Disturb on, brightness up, battery charged.
5. Record the screen: plug the iPhone into the Mac → QuickTime Player → File → New Movie Recording → click the arrow next to the record button → choose the iPhone as camera and microphone. (Alternative: iOS Control Center → Screen Recording.)

## Script (answers = demo family Priya & Arjun)

| Time | On screen | Voice-over |
|---|---|---|
| 0:00–0:12 | Language screen → English → Continue → Welcome | "Meet Priya. She moved to Berlin two years ago. Her son Arjun has autism. Her German is basic, and every letter about him is in official German." |
| 0:12–0:35 | **Start the check**: Priya / Arjun · GdB 50 · no marks · care level 3 · care at home · up to 30 h · since 2025 · gets Kindergeld + Pflegegeld · new to Germany: yes. The € meter climbs. | "Taxability asks one simple question per screen, in her language. Every answer moves the meter: this is money she is entitled to." |
| 0:35–0:45 | Last step **Scan a document** → **Take a photo** of the printed care-level decision → values appear → **Confirm** | "She photographs the care-level decision. Claude reads it, she confirms every value." |
| 0:45–0:55 | Result: **≈ €6,287 a year + €672 from past years** → Go to my dashboard | "About six thousand euros a year she wasn't claiming. The amounts come from fixed legal rules, not from AI." |
| 0:55–1:10 | Money → **Disability lump-sum allowance** → "Why you qualify" → **Add to my Taxfix return** → Add ✓ | "Each card shows why she qualifies and the legal source. One tap adds it to her tax return." |
| 1:10–1:30 | Capture → **Take a photo** of the printed letter → "Your letter": what it says, **deadline 14.11.2026**, what to do | "Then a letter from the care insurer arrives. Photo, and Claude explains it in plain English: send proof of a care visit by the 14th of November, or the care money gets cut." |
| 1:30–1:50 | **Reply in German** → text is pre-filled → **Write my German letter** → German and English side by side, file number locked | "She says what she wants in her own words. Claude writes a formal German letter, with a translation next to it, and keeps the file number and dates exactly as in the original." |
| 1:50–2:00 | Home → **Deadlines**: letter deadline on top with next steps; respite budget runs out 31.12 | "Her dashboard now tracks every deadline with the next steps. Taxability: the support your family is entitled to, in your language." |

## If something goes wrong

- Claude doesn't answer (no internet on the phone): Family → turn **Demo mode** on. The app shows cached answers marked "demo answer", so the video still runs.
- The camera can't read the paper: use **Choose a photo** with the PNG from `fixtures/`, or the **Use sample … (MUSTER)** buttons.
- Too long: drop the profile questions and use **Use demo family (Priya & Arjun)** on the welcome screen. You lose the € meter but save 25 seconds.
