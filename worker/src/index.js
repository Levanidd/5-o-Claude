// Taxability backend on Cloudflare Workers. Same API as server/server.py.
// Keeps the Anthropic API key off the phone.

import system from "../../prompts/system.md";
import explainLetter from "../../prompts/explain_letter.md";
import draftLetter from "../../prompts/draft_letter.md";
import explainOpportunity from "../../prompts/explain_opportunity.md";
import answerOnCard from "../../prompts/answer_on_card.md";
import extractDocument from "../../prompts/extract_document.md";
import translateUi from "../../prompts/translate_ui.md";

const PROMPTS = {
  explain_letter: explainLetter,
  draft_letter: draftLetter,
  explain_opportunity: explainOpportunity,
  answer_on_card: answerOnCard,
  extract_document: extractDocument,
  translate_ui: translateUi,
};

const LANGUAGE_NAMES = {
  en: "English", de: "German", tr: "Turkish", ar: "Arabic",
  uk: "Ukrainian", ru: "Russian", pl: "Polish", es: "Spanish",
};

class ClaudeError extends Error {
  constructor(status) {
    super(`Claude API error ${status}`);
    this.status = status;
  }
}

function prompt(name, values) {
  let text = PROMPTS[name];
  for (const [key, value] of Object.entries(values)) {
    text = text.split(`{${key}}`).join(String(value));
  }
  return text;
}

async function callClaude(env, userText, { image = null, maxTokens = 2000 } = {}) {
  if (!env.ANTHROPIC_API_KEY) throw new Error("ANTHROPIC_API_KEY is missing");
  const content = [];
  if (image) {
    content.push({ type: "image", source: { type: "base64", media_type: image.mediaType, data: image.data } });
  }
  content.push({ type: "text", text: userText });

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": env.ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: env.ANTHROPIC_MODEL,
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content }],
    }),
  });
  if (!res.ok) {
    const detail = (await res.text()).slice(0, 500);
    console.error(JSON.stringify({ message: "Anthropic API error", status: res.status, detail }));
    throw new ClaudeError(res.status);
  }

  const data = await res.json();
  const text = (data.content ?? []).map((block) => block.text ?? "").join("");
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start === -1 || end === -1) throw new Error("Claude did not return JSON");
  return JSON.parse(text.slice(start, end + 1));
}

const languageName = (p) => LANGUAGE_NAMES[p.language ?? "en"] ?? "English";

const imageOf = (p) =>
  p.imageBase64 ? { data: p.imageBase64, mediaType: p.mediaType ?? "image/jpeg" } : null;

const todayInBerlin = () =>
  new Intl.DateTimeFormat("de-DE", { timeZone: "Europe/Berlin", day: "2-digit", month: "2-digit", year: "numeric" })
    .format(new Date());

const ROUTES = {
  "/api/explain-letter": (p, env) =>
    callClaude(env, prompt("explain_letter", {
      language: languageName(p),
      letter: p.text || "(see the attached image)",
    }), { image: imageOf(p), maxTokens: 3000 }),

  "/api/draft-letter": (p, env) =>
    callClaude(env, prompt("draft_letter", {
      language: languageName(p),
      intent: p.intent ?? "",
      context: p.context ?? "",
      profile: JSON.stringify(p.profile ?? {}),
      lockedTokens: (p.lockedTokens ?? []).join(", ") || "(none)",
      today: todayInBerlin(),
    }), { maxTokens: 3000 }),

  "/api/explain-opportunity": (p, env) =>
    callClaude(env, prompt("explain_opportunity", {
      language: languageName(p),
      rule: JSON.stringify(p.rule ?? {}),
    })),

  "/api/answer-on-card": (p, env) =>
    callClaude(env, prompt("answer_on_card", {
      language: languageName(p),
      rule: JSON.stringify(p.rule ?? {}),
      question: p.question ?? "",
    })),

  "/api/extract-document": (p, env) =>
    callClaude(env, prompt("extract_document", {
      language: languageName(p),
      document: p.text || "(see the attached image)",
    }), { image: imageOf(p) }),

  "/api/translate-ui": async (p, env) => {
    const keys = p.keys ?? [];
    const batches = [];
    for (let i = 0; i < keys.length; i += 60) batches.push(keys.slice(i, i + 60));
    const results = await Promise.all(batches.map((batch) =>
      callClaude(env, prompt("translate_ui", {
        language: languageName(p),
        strings: JSON.stringify(batch),
      }), { maxTokens: 8000 })));
    return { translations: Object.assign({}, ...results.map((r) => r.translations ?? {})) };
  },
};

const json = (payload, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);

    if (request.method === "GET" && pathname === "/health") {
      return json({ ok: true, model: env.ANTHROPIC_MODEL, hasKey: Boolean(env.ANTHROPIC_API_KEY) });
    }

    const handler = request.method === "POST" ? ROUTES[pathname] : undefined;
    if (!handler) return json({ error: "not found" }, 404);

    try {
      const payload = await request.json().catch(() => ({}));
      return json(await handler(payload, env));
    } catch (error) {
      if (error instanceof ClaudeError) return json({ error: error.message }, 502);
      console.error(JSON.stringify({ message: "Request failed", path: pathname, error: String(error) }));
      return json({ error: String(error.message ?? error) }, 500);
    }
  },
};
