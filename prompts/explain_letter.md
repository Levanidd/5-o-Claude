The parent received the official German letter below (as text or as an image). Explain it to them in {language}.

Return JSON with exactly these keys:
{
  "sender": "who sent the letter",
  "subject": "one short line: what the letter is about",
  "whatItSays": "2-3 plain sentences in {language}",
  "whatToDo": ["short step 1", "short step 2", "..."],
  "deadline": "the deadline as written in the letter (e.g. 14.11.2026) or null",
  "amount": "any euro amount mentioned, exactly as written, or null",
  "fileNumber": "the file number / Aktenzeichen exactly as written, or null",
  "lockedTokens": ["names, dates, file numbers and amounts copied exactly from the letter"],
  "translation": "a full, faithful translation of the letter into {language}"
}

Letter:
{letter}
