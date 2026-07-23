#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - <<'PY' "$ROOT_DIR"
from html.parser import HTMLParser
from pathlib import Path
import json
import sys

root_dir = Path(sys.argv[1])
websites_dir = root_dir / "WebSites"
support_email = "mobilesecure.feedback@gmail.com"
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


def read_project_id(host_dir):
    firebaserc = host_dir / ".firebaserc"
    assert firebaserc.exists(), f"{host_dir}: missing .firebaserc"
    data = json.loads(firebaserc.read_text(encoding="utf-8"))
    project_id = data["projects"]["default"]
    assert project_id == host_dir.name, f"{host_dir}: .firebaserc does not match host folder"
    return project_id


checked = 0
for html_dir in sorted(websites_dir.glob("*/*/*/HTML")):
    app_dir = html_dir.parent
    if app_dir.relative_to(websites_dir).parts[0] == "TestAccount":
        continue
    app_name = app_dir.name
    host_dir = app_dir.parent
    project_id = read_project_id(host_dir)
    expected_contact_url = f"https://{project_id}.web.app/{app_name}/contact"
    expected_contact_href = f'href="/{app_name}/contact"'

    for name in ("contact.html", "privacy.html", "term.html"):
        html_file = html_dir / name
        assert html_file.exists(), f"{app_dir}: missing HTML/{name}"
        html = html_file.read_text(encoding="utf-8")
        text = visible_text(html)
        assert support_email not in text, f"{html_file}: support email is visible in page text"
        assert "mailto:" not in html, f"{html_file}: mailto link should not be present"
        assert old_company_name not in text, f"{html_file}: old company name is still visible"
        assert f"https://{project_id}.web.app/contact" not in html, f"{html_file}: old unprefixed contact URL is still present"

    combined_html = "\n".join((html_dir / name).read_text(encoding="utf-8") for name in ("contact.html", "privacy.html", "term.html"))
    assert expected_contact_url in combined_html, f"{app_dir}: missing app-prefixed contact URL"
    assert expected_contact_href in combined_html, f"{app_dir}: missing app-prefixed contact href"
    assert f"https://formsubmit.co/ajax/{support_email}" in (html_dir / "contact.html").read_text(encoding="utf-8"), f"{app_dir}: FormSubmit endpoint changed or missing"
    checked += 1

assert checked > 0, "No app HTML folders were checked"
print(f"Support HTML content checks passed for {checked} app folders.")
PY
