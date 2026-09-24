#!/usr/bin/env python3
"""Static post-migration checks for a URP shader.

Usage:
  python validate_urp_shader.py path/to/Converted.shader [more.shader ...]

Returns non-zero if high-confidence Built-in leftovers are found.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ERROR_RULES = {
    "surface_shader_remaining": r"#\s*pragma\s+surface\b",
    "grabpass_remaining": r"\bGrabPass\b",
    "unitycg_remaining": r"UnityCG\.cginc",
    "lighting_cginc_remaining": r"Lighting\.cginc",
    "autolight_remaining": r"AutoLight\.cginc",
    "cgprogram_remaining": r"\bCGPROGRAM\b|\bENDCG\b",
    "builtin_light_global_remaining": r"\b(?:_WorldSpaceLightPos0|_LightColor0)\b",
    "builtin_shadow_macro_remaining": r"\b(?:TRANSFER_SHADOW|SHADOW_ATTENUATION|UNITY_LIGHT_ATTENUATION)\b",
    "unity_object_to_clip_remaining": r"\bUnityObjectToClipPos\s*\(",
}

WARN_RULES = {
    "legacy_tex2d_call": r"\btex2D(?:lod|grad|proj)?\s*\(",
    "legacy_forward_tag": r'"LightMode"\s*=\s*"(?:ForwardBase|ForwardAdd)"',
    "possible_material_uniform_outside_cbuffer": r"(?m)^\s*(?:float|half|fixed)(?:[1-4x]*)\s+_[A-Za-z0-9_]+\s*;",
}


def line_numbers(text: str, pattern: str) -> list[int]:
    lines = []
    for m in re.finditer(pattern, text, re.I | re.M):
        lines.append(text.count("\n", 0, m.start()) + 1)
    return lines[:20]


def validate(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    errors = []
    warnings = []

    for name, pattern in ERROR_RULES.items():
        lines = line_numbers(text, pattern)
        if lines:
            errors.append({"rule": name, "lines": lines})

    if not re.search(r'"RenderPipeline"\s*=\s*"UniversalPipeline"', text):
        warnings.append({"rule": "no_universal_pipeline_tag"})
    if not re.search(r"\bHLSLPROGRAM\b", text):
        warnings.append({"rule": "no_hlslprogram"})

    for name, pattern in WARN_RULES.items():
        lines = line_numbers(text, pattern)
        if lines:
            warnings.append({"rule": name, "lines": lines})

    return {"file": str(path), "errors": errors, "warnings": warnings}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: validate_urp_shader.py <shader> [shader ...]", file=sys.stderr)
        return 2
    reports = []
    failed = False
    for arg in sys.argv[1:]:
        p = Path(arg)
        if not p.exists():
            reports.append({"file": str(p), "errors": [{"rule": "not_found"}], "warnings": []})
            failed = True
            continue
        report = validate(p)
        failed = failed or bool(report["errors"])
        reports.append(report)
    print(json.dumps(reports, ensure_ascii=False, indent=2))
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
