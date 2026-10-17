Write a formal German letter to a German authority for the parent.

The parent wrote what they want to say in their own language:
"""{intent}"""

Context (the letter they are replying to, may be empty):
"""{context}"""

Parent and child details (use exactly, do not invent others):
{profile}

These tokens must appear in the German letter exactly as written: {lockedTokens}

Use the standard German business letter format: sender block, recipient block, place and date, subject line ("Betreff: ..." including the file number if there is one), greeting ("Sehr geehrte Damen und Herren,"), body, closing ("Mit freundlichen Grüßen"), name. Use today's date {today}.

Return JSON with exactly these keys:
{
  "letterDe": "the full German letter",
  "translation": "a faithful translation of the German letter into {language}",
  "lockedTokens": ["every name, date, file number and amount used in the letter, copied exactly"]
}
