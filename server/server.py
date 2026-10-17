"""Tiny backend for Family Support Check.

Keeps the Anthropic API key off the phone. Standard library only:
    python3 server/server.py
"""

import json
import os
import urllib.error
import urllib.request
from datetime import date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "prompts"
PORT = int(os.environ.get("PORT", "8787"))


def load_env():
    env_file = ROOT / ".env"
    if not env_file.exists():
        return
    for line in env_file.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


load_env()
API_KEY = os.environ.get("ANTHROPIC_API_KEY", "")
MODEL = os.environ.get("ANTHROPIC_MODEL", "claude-sonnet-5-5")

LANGUAGE_NAMES = {
    "en": "English", "de": "German", "tr": "Turkish", "ar": "Arabic",
    "uk": "Ukrainian", "ru": "Russian", "pl": "Polish", "es": "Spanish",
}


def prompt(name, **values):
    text = (PROMPTS / f"{name}.md").read_text()
    for key, value in values.items():
        text = text.replace("{" + key + "}", str(value))
    return text


def call_claude(user_text, image=None, max_tokens=2000):
    if not API_KEY:
        raise RuntimeError("ANTHROPIC_API_KEY is missing. Put it in .env")
    content = []
    if image:
        content.append({
            "type": "image",
            "source": {"type": "base64", "media_type": image.get("mediaType", "image/jpeg"), "data": image["data"]},
        })
    content.append({"type": "text", "text": user_text})
    body = {
        "model": MODEL,
        "max_tokens": max_tokens,
        "system": (PROMPTS / "system.md").read_text(),
        "messages": [{"role": "user", "content": content}],
    }
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(body).encode(),
        headers={
            "x-api-key": API_KEY,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=90) as resp:
        data = json.loads(resp.read())
    text = "".join(block.get("text", "") for block in data.get("content", []))
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end == -1:
        raise ValueError("Claude did not return JSON")
    return json.loads(text[start:end + 1])


def language_name(payload):
    return LANGUAGE_NAMES.get(payload.get("language", "en"), "English")


def image_of(payload):
    if payload.get("imageBase64"):
        return {"data": payload["imageBase64"], "mediaType": payload.get("mediaType", "image/jpeg")}
    return None


def explain_letter(p):
    text = p.get("text") or "(see the attached image)"
    return call_claude(prompt("explain_letter", language=language_name(p), letter=text), image_of(p), 3000)


def draft_letter(p):
    return call_claude(prompt(
        "draft_letter",
        language=language_name(p),
        intent=p.get("intent", ""),
        context=p.get("context", ""),
        profile=json.dumps(p.get("profile", {}), ensure_ascii=False),
        lockedTokens=", ".join(p.get("lockedTokens", [])) or "(none)",
        today=date.today().strftime("%d.%m.%Y"),
    ), max_tokens=3000)


def explain_opportunity(p):
    return call_claude(prompt(
        "explain_opportunity", language=language_name(p),
        rule=json.dumps(p.get("rule", {}), ensure_ascii=False),
    ))


def answer_on_card(p):
    return call_claude(prompt(
        "answer_on_card", language=language_name(p),
        rule=json.dumps(p.get("rule", {}), ensure_ascii=False),
        question=p.get("question", ""),
    ))


def extract_document(p):
    text = p.get("text") or "(see the attached image)"
    return call_claude(prompt("extract_document", language=language_name(p), document=text), image_of(p))


def translate_ui(p):
    keys = p.get("keys", [])
    out = {}
    for i in range(0, len(keys), 60):
        batch = keys[i:i + 60]
        result = call_claude(prompt(
            "translate_ui", language=language_name(p),
            strings=json.dumps(batch, ensure_ascii=False),
        ), max_tokens=8000)
        out.update(result.get("translations", {}))
    return {"translations": out}


ROUTES = {
    "/api/translate-ui": translate_ui,
    "/api/explain-letter": explain_letter,
    "/api/draft-letter": draft_letter,
    "/api/explain-opportunity": explain_opportunity,
    "/api/answer-on-card": answer_on_card,
    "/api/extract-document": extract_document,
}


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("content-type", "application/json; charset=utf-8")
        self.send_header("content-length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"ok": True, "model": MODEL, "hasKey": bool(API_KEY)})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        handler = ROUTES.get(self.path)
        if not handler:
            self._send(404, {"error": "not found"})
            return
        try:
            length = int(self.headers.get("content-length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            self._send(200, handler(payload))
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")[:500]
            print(f"Anthropic API error {e.code}: {detail}")
            self._send(502, {"error": f"Claude API error {e.code}"})
        except Exception as e:  # noqa: BLE001 - show a friendly error to the app
            print(f"Error on {self.path}: {e}")
            self._send(500, {"error": str(e)})

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} {fmt % args}")


if __name__ == "__main__":
    print(f"Family Support Check backend on http://127.0.0.1:{PORT}  model={MODEL}  key={'yes' if API_KEY else 'MISSING'}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
