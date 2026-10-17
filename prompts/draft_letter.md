Write a formal German letter to a German authority for the parent.

The parent wrote what they want to say in their own language:
"""{intent}"""

Context (the letter they are replying to, may be empty):
"""{context}"""

Parent and child details (use exactly, do not invent others):
{profile}

These tokens must appear in the German letter exactly as written: {lockedTokens}

Write only the message body, ready to paste into an email or an online form:
- Start with "Sehr geehrte Damen und Herren,".
- Then the message in a few short paragraphs. If there is a file number (Aktenzeichen), mention it in the first sentence.
- End with "Mit freundlichen Grüßen", an empty line and the parent's name.
- Do NOT add a sender address, recipient address, place, date line, subject line ("Betreff"), or placeholders in square brackets.

Today's date is {today} (only for reference, e.g. if the parent mentions "today").

Return JSON with exactly these keys:
{
  "letterDe": "the German message body only",
  "translation": "a faithful translation of the German message body into {language}",
  "lockedTokens": ["every name, date, file number and amount used in the letter, copied exactly"]
}
