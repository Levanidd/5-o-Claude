Read this German official document (care-level decision "Pflegegrad-Bescheid" or disability decision / ID "Schwerbehindertenausweis", "GdB-Bescheid"). Extract only what is written. Use null when a field is not present.

Return JSON with exactly these keys:
{
  "docType": "pflegegrad_bescheid | gdb_bescheid | schwerbehindertenausweis | other",
  "pflegegrad": 3,
  "gdb": 50,
  "merkzeichen": ["G"],
  "validFrom": "date as written or null",
  "fileNumber": "file number as written or null",
  "childName": "child's first name as written or null",
  "summary": "one sentence in {language} describing the document",
  "confidence": "high | medium | low"
}

Document:
{document}
