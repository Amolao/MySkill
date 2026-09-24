# Special Cases for Built-in → URP Migration

## Surface Shaders

Trigger: `#pragma surface`.

URP does not use the Built-in Surface Shader code-generation path. Reconstruct the shader explicitly:

1. List every field written by the source `surf` function: Albedo, Normal, Emission, Metallic/Specular, Smoothness/Gloss, Alpha, Occlusion, custom fields.
2. List vertex modification (`vertex:`), final color hooks, addshadow/fullforwardshadows, decal modes, alpha modes, and custom lighting functions.
3. Rebuild vertex-to-fragment data flow.
4. Reimplement the lighting model with URP lighting APIs or an appropriate URP surface-data/input-data flow.
5. Recreate required ShadowCaster/Depth/Meta behavior.

Do not simply remove `#pragma surface` and copy `surf` into a fragment function.

## GrabPass

Trigger: `GrabPass`, `_GrabTexture`, screen refraction/distortion sampling.

URP has no direct `GrabPass` equivalent.

Choose based on semantics:

- If the effect needs the opaque scene color before transparents, enable URP Opaque Texture and sample `_CameraOpaqueTexture` using normalized screen UVs.
- If it needs a different render timing, transparent content, a custom buffer, downsampled copy, or per-object capture semantics, use a `ScriptableRendererFeature`/`ScriptableRenderPass` to copy the required target and expose it to the shader.

State the renderer-side requirement in the migration report.

## Built-in main light globals

Trigger: `_WorldSpaceLightPos0`, `_LightColor0`, `UNITY_LIGHTMODEL_AMBIENT`.

Do not map these as magic global values. Determine whether the source assumes directional-only light, positional light, attenuation, ambient light, SH, or vertex lights, then reproduce those semantics with URP APIs.

## ForwardAdd

Trigger: `Tags { "LightMode"="ForwardAdd" }`, additive blending for per-light passes.

URP typically evaluates additional lights in the forward pass. Port the lighting contribution rather than retaining the legacy per-light pass architecture.

If the source uses the additional pass for a non-lighting special effect, preserve that behavior as a custom pass only after confirming why the pass exists.

## Shadows

### Receiving shadows

Use the URP main/additional light shadow APIs appropriate to the installed version. Preserve whether the source intentionally ignores shadows for some terms such as emission or rim lighting.

### Casting shadows

A custom forward pass does not guarantee correct shadow casting. Add or port a `ShadowCaster` pass when the material must cast shadows. For alpha-clipped shaders, reproduce the exact clip condition and relevant UV/property transforms in the shadow pass.

## Alpha clip / cutout

Keep `_Cutoff`-style property names when existing materials use them. Apply the same clipping rule in forward, shadow, depth, depth-normals, and meta passes where needed.

## Transparent shaders

Preserve:

- `Queue` and `RenderType`.
- Blend factors and blend operations.
- `ZWrite` / `ZTest`.
- Premultiplied vs straight alpha semantics.
- Alpha-to-coverage if used.
- Refraction source requirements.

Do not change `ZWrite Off`/blend mode merely to match URP Lit defaults.

## Stencil

Copy stencil state deliberately into every pass that participates in the intended stencil protocol. If another shader/render feature depends on the same reference/read/write masks, inspect that counterpart too.

## Depth and depth normals

If the project relies on camera depth texture, SSAO, decals, screen-space effects, or features that need normals, determine whether the custom shader must contribute via `DepthOnly` and/or `DepthNormals`/`DepthNormalsOnly` passes.

## Meta / lightmapping

If the source is baked-lit or contributes albedo/emission to lightmapping, preserve an appropriate Meta pass or equivalent supported URP path. Unlit/transient VFX usually do not need one.

## Lightmaps, probes, baked GI

Do not replace baked lighting with a constant ambient color. Track:

- lightmap UVs,
- dynamic lightmap UVs if used,
- spherical harmonics/probes,
- shadow masks/mixed lighting where relevant.

Use the APIs available in the target URP package.

## Normal maps / tangent space

Preserve tangent handedness and tangent-to-world construction. Validate mirrored UVs and negative object scale. Use URP helpers when they match the source semantics.

## Vertex animation

Replicate vertex displacement in every pass that must match the visible geometry, especially ShadowCaster, DepthOnly, and DepthNormals. A common migration bug is animating only the forward pass.

## Geometry / tessellation

Support depends on graphics API, shader model, and URP version. Preserve only if the target project/platform supports it; otherwise redesign or state the limitation.

## Custom includes

Never guess what a custom `.cginc` does. Port it separately or inline/replace its behavior only after reading the file. Shared Built-in assumptions inside custom includes are often the real migration blocker.
