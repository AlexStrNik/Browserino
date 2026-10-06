#!/usr/bin/env python3
"""Check UI string coverage and complete translations without requiring Xcode."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'Browserino/Localizable.xcstrings').read_text())
strings = catalog['strings']
languages = {'en', 'ru', 'de', 'fr', 'es', 'pt-BR', 'it', 'ja', 'ko', 'zh-Hans'}
for key, entry in strings.items():
    assert re.fullmatch(r'[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+', key), f'Non-semantic localization key: {key}'
    assert set(entry['localizations']) == languages, f'Missing language: {key}'
    for language, localization in entry['localizations'].items():
        unit = localization['stringUnit']
        assert unit['state'] == 'translated' and unit['value'].strip(), (key, language)
        assert unit['value'].count('%@') == entry['localizations']['en']['stringUnit']['value'].count('%@'), (key, language)

for path in (root / 'Browserino').rglob('*.swift'):
    source = path.read_text()
    for key in re.findall(r'(?:Text|Label|TextField|LabeledContent|NSLocalizedString|L10n.text|L10n.format|fail)\(\s*"([^"\n]*)"', source):
        if not key or '\\(' in key or key.startswith('https://'):
            continue
        assert key in strings, f'Untranslated UI string {key!r} in {path.name}'
assert 'browsers.private_argument.placeholder' in strings
print(f'{len(strings)} strings complete in {len(languages)} languages; UI coverage passed')
