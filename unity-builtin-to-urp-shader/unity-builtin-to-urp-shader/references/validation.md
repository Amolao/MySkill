# URP Shader Migration Validation

## Static checks

- No unintended `CGPROGRAM` / `ENDCG` blocks remain.
- No unintended `UnityCG.cginc`, `Lighting.cginc`, or `AutoLight.cginc` dependencies remain.
- No Built-in light globals remain unless deliberately supplied by project code.
- No `#pragma surface` remains.
- No `GrabPass` remains.
- URP pipeline tag is present.
- Forward pass has a suitable URP `LightMode`.
- Material constants are organized for SRP Batcher compatibility where applicable.
- All referenced textures have matching texture/sampler declarations.
- All shader keywords used in conditional code have matching pragma coverage or are intentionally global/runtime keywords.

## Unity compile checks

Test with the actual target Unity + URP package:

1. Import the converted shader with Console clear.
2. Force reimport if needed.
3. Inspect all shader compile errors/warnings.
4. Check Shader Inspector for SRP Batcher compatibility when relevant.
5. Test at least one representative material using every important keyword branch.

## Visual parity matrix

For lit shaders, test:

- Main directional light rotated around the object.
- Main light shadows on/off and cascades if used.
- Point and spot additional lights.
- Additional-light shadows if expected.
- Lightmapped and probe-lit objects when the source supported them.
- Different normal-map strengths and mirrored scale if tangent-space normals are used.

For transparency/VFX, test:

- Over opaque geometry.
- Over other transparent objects.
- With depth texture features enabled/disabled as applicable.
- Camera near/far movement and perspective/orthographic if supported.
- Post-processing enabled.

For vertex animation, test:

- Forward image.
- Cast shadow silhouette.
- Depth-based effects.
- SSAO/decal interaction if relevant.

## Render-state parity

Compare source vs migrated material for:

- Queue.
- Blend mode / premultiplication.
- ZWrite and ZTest.
- Cull mode.
- Stencil protocol.
- ColorMask.
- Alpha clipping threshold.

## Performance sanity

- Review variant count.
- Confirm extra lights are not accidentally evaluated when unnecessary.
- Confirm expensive screen-texture samples are intentional.
- Check overdraw for transparent effects.
- Check SRP Batcher compatibility where valuable.

## Completion language

If the shader was not compiled in Unity, report: “Statically migrated; Unity compilation and visual parity still require project validation.”

If compiled but not visually compared, report compilation success separately from visual parity.
