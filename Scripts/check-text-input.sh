#!/usr/bin/env bash
# 文本输入零旁路门禁：Features/Design 的 TextField 必须挂 PlatformTextInput API；
# Features 禁止手写键盘字典；键盘约定只允许出现在 PlatformTextInputChrome.swift。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export ROOT

python3 - <<'PY'
from __future__ import annotations

import os
import re
from pathlib import Path

ROOT = Path(os.environ["ROOT"])
APP = ROOT / "坐标系"
FEATURES = APP / "Features"
DESIGN = APP / "Design"
CHROME = DESIGN / "PlatformTextInputChrome.swift"

FAILED = 0
LOOKAHEAD = 16

TEXT_FIELD_RE = re.compile(r"\bTextField\s*\(")
TEXT_EDITOR_RE = re.compile(r"\bTextEditor\s*\(")
SECURE_FIELD_RE = re.compile(r"\bSecureField\s*\(")
PLATFORM_INPUT_RE = re.compile(
    r"\.(platformFormTextInput|platformCredentialTextInput|platformMessageComposerTextInput)\s*\("
)

# Features 禁止的键盘 / 输入皮旁路（须进 PlatformTextInputChrome kind）。
FEATURES_BYPASS_RES = [
    (re.compile(r"\.keyboardType\s*\("), "keyboardType"),
    (re.compile(r"\.textInputAutocapitalization\s*\("), "textInputAutocapitalization"),
    (re.compile(r"\.autocorrectionDisabled\s*\("), "autocorrectionDisabled"),
    (re.compile(r"\.textContentType\s*\("), "textContentType"),
    (re.compile(r"\.textFieldStyle\s*\("), "textFieldStyle"),
    (re.compile(r"\.submitLabel\s*\("), "submitLabel"),
]

# Design 除真源外，也禁止再写键盘字典（Composer 只调 platformMessageComposerTextInput）。
DESIGN_BYPASS_RES = FEATURES_BYPASS_RES


def fail(msg: str) -> None:
    global FAILED
    FAILED = 1
    print(f"  ✗ {msg}")


def swift_files(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(p for p in root.rglob("*.swift") if p.is_file())


def check_text_fields(path: Path) -> None:
    rel = path.relative_to(ROOT)
    lines = path.read_text(encoding="utf-8").splitlines()
    for i, line in enumerate(lines):
        if TEXT_EDITOR_RE.search(line):
            fail(f"{rel}:{i + 1}: 禁止 TextEditor；用 Form TextField + platformFormTextInput")
            continue
        if SECURE_FIELD_RE.search(line):
            fail(f"{rel}:{i + 1}: 禁止裸 SecureField；先扩展 PlatformTextInput surface")
            continue
        if not TEXT_FIELD_RE.search(line):
            continue
        window = "\n".join(lines[i : i + LOOKAHEAD])
        if not PLATFORM_INPUT_RE.search(window):
            fail(
                f"{rel}:{i + 1}: TextField 未在随后 {LOOKAHEAD} 行内挂 "
                "platformFormTextInput / platformCredentialTextInput / "
                "platformMessageComposerTextInput"
            )


def check_bypasses(path: Path, patterns: list[tuple[re.Pattern[str], str]]) -> None:
    rel = path.relative_to(ROOT)
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        # 注释里提到 API 名不算旁路
        code = line.split("//", 1)[0]
        for pattern, name in patterns:
            if pattern.search(code):
                fail(f"{rel}:{i}: Features/Design 旁路 .{name}（应收进 PlatformTextInputChrome）")


print("→ TextField 须挂 PlatformTextInput API（Features + Design，真源除外）")
for path in swift_files(FEATURES) + swift_files(DESIGN):
    if path.resolve() == CHROME.resolve():
        continue
    check_text_fields(path)

print("→ Features/ 禁止手写键盘 / 输入皮字典")
for path in swift_files(FEATURES):
    check_bypasses(path, FEATURES_BYPASS_RES)

print("→ Design/ 键盘字典仅允许 PlatformTextInputChrome.swift")
for path in swift_files(DESIGN):
    if path.resolve() == CHROME.resolve():
        continue
    check_bypasses(path, DESIGN_BYPASS_RES)

if FAILED:
    print("")
    print("Text input boundary check failed.")
    raise SystemExit(1)

print("Text input boundaries OK.")
PY
