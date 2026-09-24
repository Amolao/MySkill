#!/usr/bin/env python3
"""Static feature scanner for Unity Built-in custom shaders.

Usage:
  python scan_shader.py path/to/MyShader.shader [more.shader ...]

Prints JSON. This is a migration inventory helper, not a compiler/parser.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

FEATURES = {
    "surface_shader": r"#\s*pragma\s+surface\b",
    "grabpass": r"\bGrabPass\b|\b_GrabTexture\b",
    "unitycg": r"UnityCG\.cginc",
    "lighting_cginc": r"Lighting\.cginc",
    "autolight": r"AutoLight\.cginc",
    "forward_base": r'"LightMode"\s*=\s*"ForwardBase"',
    "forward_add": r'"LightMode"\s*=\s*"ForwardAdd"',
    "shadow_caster": r'"LightMode"\s*=\s*"ShadowCaster"',
    "meta_pass": r'"LightMode"\s*=\s*"Meta"',
    "geometry": r"#\s*pragma\s+geometry\b",
    "tessellation": r"#\s*pragma\s+(?:hull|domain)\b|\btessellate\s*:",
    "legacy_light_globals": r"\b(?:_WorldSpaceLightPos0|_LightColor0|UNITY_LIGHTMODEL_AMBIENT)\b",
    "legacy_shadow_macros": r"\b(?:TRANSFER_SHADOW|SHADOW_ATTENUATION|UNITY_LIGHT_ATTENUATION|LIGHTING_COORDS|TRANSFER_VERTEX_TO_FRAGMENT)\b",
    "legacy_tex2d": r"\btex2D(?:lod|grad|proj)?\s*\(",
    "object_to_clip": r"\bUnityObjectToClipPos\s*\(",
    "fog_macros": r"\b(?:UNITY_FOG_COORDS|UNITY_TRANSFER_FOG|UNITY_APPLY_FOG)\b",
    "instancing": r"#\s*pragma\s+multi_compile_instancing|UNITY_INSTANCING_",
    "stencil": r"\bStencil\s*\{",
    "blend": r"\bBlend\s+",
    "alpha_clip": r"\bclip\s*\(|\bAlphaTest\b|\b_Cutoff\b",
    "camera_depth": r"\b_CameraDepthTexture\b|\bSAMPLE_DEPTH_TEXTURE\b",
    "custom_include": r'#\s*include\s+["<](?!UnityCG\.cginc|Lighting\.cginc|AutoLight\.cginc)([^">]+)[">]',
}


def find_passes(text: str) -> list[dict]:
    """Best-effort inventory, not a full ShaderLab parser."""
    out = []
    for m in re.finditer(r"\bPass\s*\{", text):
        start = m.start()
        snippet = text[start:start + 1800]
        name = re.search(r'\bName\s+"([^"]+)"', snippet)
        light = re.search(r'"LightMode"\s*=\s*"([^"]+)"', snippet)
        out.append({
            "offset": start,
            "name": name.group(1) if name else None,
            "light_mode": light.group(1) if light else None,
        })
    return out


def find_properties(text: str) -> list[str]:
    # Heuristic only. Stop at first SubShader to avoid over-scanning.
    m = re.search(r"\bProperties\s*\{", text)
    if not m:
        return []
    end = text.find("SubShader", m.end())
    chunk = text[m.end(): end if end != -1 else m.end() + 16000]
    return [
        x.group(1)
        for x in re.finditer(r"(?m)^\s*(?:\[[^\]]+\]\s*)*([_A-Za-z][_A-Za-z0-9]*)\s*\(", chunk)
    ]


def scan(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    features: dict[str, object] = {}
    for name, pattern in FEATURES.items():
        matches = list(re.finditer(pattern, text, re.I | re.M))
        if not matches:
            continue
        if name == "custom_include":
            features[name] = sorted({m.group(1) for m in matches if m.groups()})
        else:
            features[name] = len(matches)

    score = 0
    for key, weight in {
        "surface_shader": 4,
        "grabpass": 4,
        "forward_add": 2,
        "autolight": 2,
        "geometry": 3,
        "tessellation": 4,
        "custom_include": 2,
        "stencil": 1,
        "camera_depth": 1,
    }.items():
        if key in features:
            score += weight
    risk = "high" if score >= 6 else "medium" if score >= 2 else "low"

    return {
        "file": str(path),
        "risk": risk,
        "features": features,
        "properties": find_properties(text),
        "passes": find_passes(text),
    }


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: scan_shader.py <shader> [shader ...]", file=sys.stderr)
        return 2
    reports = []
    for arg in sys.argv[1:]:
        p = Path(arg)
        if not p.exists():
            reports.append({"file": str(p), "error": "not found"})
            continue
        try:
            reports.append(scan(p))
        except Exception as exc:
            reports.append({"file": str(p), "error": str(exc)})
    print(json.dumps(reports, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
