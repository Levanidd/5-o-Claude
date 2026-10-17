Translate the user interface strings of a mobile app into {language}.

The app helps parents of children with disabilities in Germany find tax allowances and care benefits. Keep the tone warm, plain and short, and address the user informally but respectfully, as a friendly app would.

Rules:
- Keep every "%@" placeholder exactly, in the same order.
- Keep German official terms in brackets unchanged, e.g. "(Pflegegrad)", "(GdB)", "(Kindergeld)".
- Keep "€", "AI", "Claude", "Taxfix", "MUSTER", "EUTB", legal references like "§ 33b EStG" unchanged.
- Keep button labels short.

Input: a JSON array of English strings.
Return JSON: {"translations": {"<English string>": "<translation>", ...}} with every input string as a key.

Strings:
{strings}
