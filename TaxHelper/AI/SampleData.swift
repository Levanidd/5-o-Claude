import Foundation

/// Fictional sample documents (MUSTER) and cached AI answers for DEMO_MODE / offline pitch.
enum SampleData {
    static let insurerLetter = """
    Muster-Pflegekasse · Postfach 10 20 30 · 10115 Berlin

    Frau Priya Sharma
    Musterstraße 12
    10437 Berlin

    Berlin, 17.10.2026
    Aktenzeichen: PK-2025-448812
    Versicherte Person: Arjun Sharma, geb. 04.02.2019

    Nachweis des Beratungseinsatzes nach § 37 Abs. 3 SGB XI

    Sehr geehrte Frau Sharma,

    Ihr Sohn Arjun bezieht seit dem 01.03.2025 Pflegegeld nach Pflegegrad 3 in Höhe von 599,00 Euro monatlich. \
    Pflegebedürftige der Pflegegrade 2 und 3, die ausschließlich Pflegegeld beziehen, sind verpflichtet, \
    halbjährlich einen Beratungseinsatz in der eigenen Häuslichkeit abzurufen.

    Für das zweite Halbjahr 2026 liegt uns bisher kein Nachweis vor. Bitte lassen Sie den Beratungseinsatz \
    durch einen zugelassenen Pflegedienst oder eine anerkannte Beratungsstelle durchführen und senden Sie uns \
    den Nachweis bis zum 14.11.2026 zu.

    Wird der Beratungseinsatz nicht abgerufen, sind wir gesetzlich verpflichtet, das Pflegegeld angemessen \
    zu kürzen und im Wiederholungsfall zu entziehen (§ 37 Abs. 6 SGB XI).

    Für Rückfragen erreichen Sie uns unter 030 1234 5678.

    Mit freundlichen Grüßen
    Ihre Muster-Pflegekasse
    MUSTER – SAMPLE DOCUMENT
    """

    static let careLevelDecision = """
    Muster-Pflegekasse · Bescheid über die Feststellung der Pflegebedürftigkeit
    MUSTER – SAMPLE DOCUMENT

    Aktenzeichen: PK-2025-448812
    Versicherte Person: Arjun Sharma, geb. 04.02.2019

    Sehr geehrte Frau Sharma,
    auf Grundlage des Gutachtens des Medizinischen Dienstes stellen wir fest, dass bei Arjun Sharma
    Pflegebedürftigkeit nach Pflegegrad 3 ab dem 01.03.2025 vorliegt.
    Die Pflege erfolgt durch Angehörige in häuslicher Umgebung. Pflegegeld: 599,00 Euro monatlich.

    Hinweis: Laut Bescheid des Landesamts für Gesundheit und Soziales Berlin beträgt der Grad der Behinderung (GdB) 50, ohne Merkzeichen.

    Gegen diesen Bescheid kann innerhalb eines Monats nach Bekanntgabe Widerspruch eingelegt werden.
    """

    static let letterExplanation = LetterExplanation(
        sender: "Muster-Pflegekasse (care insurer)",
        subject: "Proof of a care advice visit is needed",
        whatItSays: "Arjun gets €599 care allowance every month for care level 3. With this care level, the law asks for a short advice visit at home every six months. The care insurer has no proof of that visit for the second half of 2026 yet.",
        whatToDo: [
            "Book a care advice visit (Beratungseinsatz) with an approved care service or advice centre — it's free for you.",
            "Ask them to send the proof (Nachweis) to the care insurer, or send it yourself.",
            "Do this before 14.11.2026, otherwise your care allowance can be reduced.",
        ],
        deadline: "14.11.2026",
        amount: "599,00 Euro",
        fileNumber: "PK-2025-448812",
        lockedTokens: ["PK-2025-448812", "14.11.2026", "599,00 Euro", "Arjun Sharma", "Priya Sharma", "04.02.2019"],
        translation: """
        Muster-Pflegekasse · PO Box 10 20 30 · 10115 Berlin

        File number: PK-2025-448812
        Insured person: Arjun Sharma, born 04.02.2019

        Proof of the advice visit under § 37 (3) SGB XI

        Dear Ms Sharma,

        Since 01.03.2025 your son Arjun has received care allowance for care level 3 of 599,00 Euro per month. People with care level 2 or 3 who only receive care allowance must have an advice visit at home every six months.

        We have not yet received proof for the second half of 2026. Please have the advice visit carried out by an approved care service or a recognised advice centre and send us the proof by 14.11.2026.

        If the advice visit does not take place, we are required by law to reduce the care allowance appropriately and, if it happens again, to withdraw it (§ 37 (6) SGB XI).

        If you have questions, call us on 030 1234 5678.

        Kind regards,
        Your Muster-Pflegekasse
        """
    )

    static let replyIntent = "I already booked the advice visit with the care service for 05.11.2026. I will send the proof right after. Please don't reduce the care allowance."

    static let germanDraft = GermanDraft(
        letterDe: """
        Sehr geehrte Damen und Herren,

        vielen Dank für Ihr Schreiben vom 17.10.2026 zum Aktenzeichen PK-2025-448812.

        Ich habe den Beratungseinsatz für meinen Sohn Arjun Sharma (geb. 04.02.2019) bereits bei einem zugelassenen Pflegedienst für den 05.11.2026 vereinbart. Den Nachweis werde ich Ihnen unmittelbar nach dem Termin und damit vor Ablauf der Frist am 14.11.2026 zusenden.

        Ich bitte Sie daher, von einer Kürzung des Pflegegeldes abzusehen.

        Mit freundlichen Grüßen

        Priya Sharma
        """,
        translation: """
        Dear Sir or Madam,

        thank you for your letter of 17.10.2026 regarding file number PK-2025-448812.

        I have already booked the advice visit for my son Arjun Sharma (born 04.02.2019) with an approved care service for 05.11.2026. I will send you the proof right after the appointment, before the deadline of 14.11.2026.

        I therefore ask you not to reduce the care allowance.

        Kind regards,

        Priya Sharma
        """,
        lockedTokens: ["PK-2025-448812", "14.11.2026", "05.11.2026", "Arjun Sharma", "Priya Sharma", "04.02.2019", "17.10.2026"]
    )

    static let extractedDecision = ExtractedDocument(
        docType: "pflegegrad_bescheid",
        pflegegrad: 3,
        gdb: 50,
        merkzeichen: [],
        validFrom: "01.03.2025",
        fileNumber: "PK-2025-448812",
        childName: "Arjun",
        summary: "Care-level decision: Arjun has care level 3 from 01.03.2025, cared for at home by family. Disability degree 50, no ID marks.",
        confidence: "high"
    )

    static func opportunityExplanation(_ o: Opportunity) -> OpportunityExplanation {
        OpportunityExplanation(
            plainExplanation: o.summary,
            whyBullets: o.reasons.filter(\.met).map(\.label),
            howToSteps: o.howToClaim
        )
    }

    static func cardAnswer(question: String, _ o: Opportunity) -> CardAnswer {
        if question.lowercased().contains("past") {
            return CardAnswer(answer: "Often yes. Tax returns can usually be filed or changed up to 4 years back, as long as they are not final. Care benefits usually start from the month you apply.", citedSource: "§ 169 AO", escalate: false)
        }
        return CardAnswer(answer: "I'm not fully sure about this one. A free counselling service (EUTB) or a Taxfix expert can check your case.", citedSource: o.legalSource, escalate: true)
    }
}
