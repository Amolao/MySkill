---
name: unity-builtin-to-urp-shader
description: Convert custom Unity Built-in Render Pipeline shaders to URP HLSL while preserving material properties and visual behavior. Use when a user provides .shader/.cginc/.hlsl code or a Unity project and asks to migrate custom shaders, Surface Shaders, lighting, shadows, GrabPass effects, transparent shaders, stencil/multi-pass shaders, or related Built-in rendering code to the Universal Render Pipeline.
---

# Unity Built-in Shader → URP Migration

Use this skill for custom shader migration from Unity's Built-in Render Pipeline to URP. Treat migration as a rendering-behavior port, not a blind text replacement.

## Goal

Produce a URP-compatible shader that preserves the source shader's intended appearance and material-facing API as closely as practical, and clearly identify any behavior that requires project-side URP configuration or a Renderer Feature.

## Inputs

Prefer these inputs when available:

- Source `.shader` file.
- Any referenced custom `.cginc` / `.hlsl` files.
- Target Unity version and URP package version.
- Material screenshots or a description of expected appearance.
- Relevant renderer settings if the shader uses screen color, depth, decals, custom passes, or Renderer Features.

Do not block on missing version information. If the project files are available, inspect `Packages/manifest.json` and `Packages/packages-lock.json`. Otherwise produce a version-tolerant implementation and call out any version-sensitive API.

## Workflow

### 1. Inventory before editing

Read the entire source shader and all custom includes it depends on. Build a short migration inventory containing:

- Shader type: vertex/fragment, Surface Shader, fixed-function, ShaderLab-only, geometry/tessellation, or hybrid.
- Queue/render type: opaque, alpha test, transparent, overlay, custom queue.
- Every Pass and its `LightMode`, blend, depth, cull, color mask, stencil, offset, and target level.
- Built-in includes and macros.
- Textures, samplers, material properties, keywords, and multi_compile/shader_feature variants.
- Lighting model, GI/lightmap/probe usage, fog, shadows, vertex lights, additional lights.
- Screen/depth dependencies such as `GrabPass`, `_CameraDepthTexture`, `_GrabTexture`, command buffers, or camera callbacks.
- Custom editor, fallback, dependencies, and project scripts that set global shader values.

If scripts are available, run `scripts/scan_shader.py` on each source shader and use the report as a checklist, not as a substitute for reading the code.

### 2. Choose a migration strategy

Classify the shader into one of these paths:

**A. Direct HLSL port**
Use for conventional vertex/fragment shaders, unlit effects, custom Lambert/specular/toon/rim/dissolve effects, and shaders whose behavior can be represented by URP shader-library functions.

**B. Rebuild the lighting surface in URP**
Use for Built-in Surface Shaders (`#pragma surface`). URP does not execute the Built-in Surface Shader compiler. Preserve the material properties and reconstruct the vertex/fragment stages explicitly, or use URP's lighting data/functions where appropriate.

**C. Rendering architecture change**
Use when the source depends on `GrabPass`, custom camera command buffers, legacy deferred passes, special image effects, or other Built-in-only rendering hooks. Port shader logic and separately describe required URP renderer configuration or a `ScriptableRendererFeature`/`ScriptableRenderPass`.

Do not claim a one-to-one conversion when the rendering architecture changed.

### 3. Preserve the material contract

Unless the user explicitly requests cleanup:

- Keep the shader `Properties` names and semantics stable so existing materials can survive migration.
- Preserve keywords that are referenced by materials or scripts.
- Preserve render state: `Blend`, `BlendOp`, `ZWrite`, `ZTest`, `Cull`, `ColorMask`, `Stencil`, `Offset`, queue, and render type.
- Preserve custom inspector behavior when possible; call out any editor code that also needs updating.

### 4. Convert the shader skeleton

For a standard URP HLSL pass:

- Use `HLSLPROGRAM` / `ENDHLSL`.
- Add the URP pipeline tag at SubShader level:
  `"RenderPipeline"="UniversalPipeline"`.
- Use an appropriate Pass `LightMode`, commonly `UniversalForward` or `UniversalForwardOnly` for the forward color pass.
- Include URP shader libraries rather than Built-in `.cginc` files.
- Put material constants in `CBUFFER_START(UnityPerMaterial)` / `CBUFFER_END` when compatible with the shader design.

Read `references/api-mapping.md` for common replacements.

### 5. Convert data flow and sampling

Prefer URP helpers instead of reconstructing matrices manually:

- Object → clip: `TransformObjectToHClip` or `GetVertexPositionInputs`.
- Object → world position: `TransformObjectToWorld` / `GetVertexPositionInputs`.
- Object → world normal: `TransformObjectToWorldNormal` or `GetVertexNormalInputs`.
- View direction: use URP helpers from world-space position rather than Built-in globals when practical.
- Textures: use `TEXTURE2D`, `SAMPLER`, and `SAMPLE_TEXTURE2D` families.

Keep interpolators minimal and normalize interpolated directions/normals in fragment code where required.

### 6. Port lighting deliberately

For custom lit shaders, include URP `Lighting.hlsl` and reconstruct the source lighting behavior.

Check separately:

- Main light direction and color.
- Main light distance attenuation.
- Main light shadow attenuation.
- Additional lights and their attenuation/shadows.
- Baked GI/lightmaps and probes if the original shader used them.
- Mixed lighting expectations.
- Emission and ambient contribution.

Do not silently drop additional lights, baked lighting, or shadows if they were part of the source behavior. If exact parity is out of scope, state the difference in the migration report.

### 7. Port shadows

If the shader receives shadows, use URP shadow coordinates/functions and compile the relevant main-light shadow variants. If it casts shadows, ensure a compatible `ShadowCaster` pass exists.

Do not assume a forward color pass automatically provides correct shadow casting.

### 8. Recreate required passes

Decide whether the shader needs these URP passes based on its role:

- `UniversalForward` / `UniversalForwardOnly`
- `ShadowCaster`
- `DepthOnly`
- `DepthNormals` or `DepthNormalsOnly` when the active URP features require normals/depth
- `Meta` for lightmapping/baking when applicable

Preserve stencil/depth behavior in each relevant pass rather than only in the forward pass.

Avoid adding passes that are unnecessary for the user's renderer configuration.

### 9. Handle Built-in-only features

Use `references/special-cases.md`.

Key rules:

- `#pragma surface`: rewrite; do not mechanically rename it.
- `GrabPass`: no direct URP equivalent. Usually use `_CameraOpaqueTexture` when the effect only needs opaque scene color, or a Renderer Feature/custom pass when the timing/source buffer differs.
- `ForwardAdd`: URP normally handles additional lights within the forward pass rather than a Built-in additive pass.
- `AutoLight.cginc` shadow macros: replace with URP lighting/shadow APIs.
- Legacy deferred/prepass LightModes: redesign for the target URP renderer rather than preserving obsolete pass tags.

### 10. Preserve fog, instancing, stereo, and platform behavior

If present in the source or required by the project:

- Port fog using URP fog helpers/keywords.
- Keep GPU instancing pragmas/macros where applicable.
- Preserve XR/stereo macros when the project uses XR.
- Retain required `#pragma target` and platform exclusions only when still necessary.

### 11. Validate the result

Before completion, inspect the generated shader for:

- Remaining Built-in includes/macros.
- `CGPROGRAM`, `ENDCG`, `UnityCG.cginc`, `Lighting.cginc`, `AutoLight.cginc`.
- `UnityObjectToClipPos`, `_WorldSpaceLightPos0`, `_LightColor0`, `tex2D`, `GrabPass`, `#pragma surface`, or legacy `ForwardBase`/`ForwardAdd` assumptions.
- Material properties declared outside the `UnityPerMaterial` CBUFFER without a deliberate reason.
- Missing Pass tags.
- Missing shadow/depth passes required by the intended effect.

If scripts are available, run `scripts/validate_urp_shader.py` as an additional static check.

Compilation in the target Unity project is the final authority. Static analysis cannot prove rendering parity.

### 12. Output format

When converting one shader, return:

1. **Migration assessment** — source type, difficulty, and special cases.
2. **Converted shader** — complete `.shader` source, not partial snippets, unless the user explicitly asks for a patch.
3. **Project-side steps** — only when needed, for example enabling Opaque Texture/Depth Texture or installing a Renderer Feature.
4. **Parity notes** — anything intentionally changed, approximated, or not verifiable without Unity.
5. **Validation checklist** — concise test cases for the material in Unity.

When converting multiple shaders, process them one at a time and additionally provide a summary table: source file, strategy, status, unresolved dependencies.

## Quality rules

- Prefer correctness over minimal diffs.
- Never invent custom include contents. Request/read them if they affect behavior.
- Never delete an unfamiliar macro merely to make the shader compile; first determine what behavior it provides.
- Preserve property names and render state by default.
- Do not claim visual parity unless the result was actually tested in Unity with representative materials/scenes.
- If Unity compilation is unavailable, clearly label the result as statically migrated and provide exact verification steps.
- For version-sensitive URP APIs, inspect the project's installed URP package when possible.

## Supporting files

- `references/api-mapping.md` — Built-in → URP API and macro mapping.
- `references/special-cases.md` — Surface Shader, GrabPass, lighting, shadows, transparency, stencil, multi-pass, GI, and Renderer Feature guidance.
- `references/validation.md` — compilation and visual validation checklist.
- `scripts/scan_shader.py` — static source feature scanner.
- `scripts/validate_urp_shader.py` — static checks for common migration mistakes.
- `assets/migration-report-template.md` — reusable report format.
