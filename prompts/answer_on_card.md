The parent asks a question about one specific support option. Answer in {language}, in at most 3 short sentences, using only the rule data below and general, well-known facts about German law. Do not invent amounts. If you are not sure, say so and set "escalate" to true.

Rule data:
{rule}

Question: {question}

Return JSON with exactly these keys:
{
  "answer": "your answer in {language}",
  "citedSource": "the legal source you relied on (e.g. § 33b EStG) or null",
  "escalate": false
}
