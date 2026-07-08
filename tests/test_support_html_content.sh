#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HTML_DIR="$ROOT_DIR/WebSites/Miracast_v6/tvcast-studio/HTML"

python3 - <<'PY' "$HTML_DIR"
from html.parser import HTMLParser
from pathlib import Path
import sys

html_dir = Path(sys.argv[1])
support_email = "mobilesecure.feedback@gmail.com"
app_name = "Miracast_v6"
company_name = "TVCast Studio Co,.Ltd"
old_company_name = "Smart Mobile Casting Co., Ltd"


class VisibleTextParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.hidden_depth = 0
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if tag in {"script", "style", "template"}:
            self.hidden_depth += 1

    def handle_endtag(self, tag):
        if tag in {"script", "style", "template"} and self.hidden_depth:
            self.hidden_depth -= 1

    def handle_data(self, data):
        if not self.hidden_depth:
            self.parts.append(data)


def visible_text(html):
    parser = VisibleTextParser()
    parser.feed(html)
    return " ".join(part.strip() for part in parser.parts if part.strip())


for name in ("contact.html", "privacy.html", "term.html"):
    html = (html_dir / name).read_text(encoding="utf-8")
    text = visible_text(html)
    assert support_email not in text, f"{name}: support email is visible in page text"
    assert "mailto:" not in html, f"{name}: mailto link should not be present"
    assert old_company_name not in text, f"{name}: old company name is still visible"
    assert company_name in text, f"{name}: company name should be {company_name}"

contact = (html_dir / "contact.html").read_text(encoding="utf-8")
assert f"https://formsubmit.co/ajax/{support_email}" in contact, "contact.html: FormSubmit endpoint changed or missing"
assert f'name="App Name" value="{app_name}"' in contact, "contact.html: missing hidden App Name field"

print("Support HTML content checks passed.")
PY
