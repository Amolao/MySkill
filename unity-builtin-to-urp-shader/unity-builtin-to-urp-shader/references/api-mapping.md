# Built-in → URP Shader API Mapping

Use this as a migration reference, not a blind replacement table. Function signatures and recommended paths can vary by URP version.

## Program blocks and includes

| Built-in | URP direction |
|---|---|
| `CGPROGRAM` / `ENDCG` | `HLSLPROGRAM` / `ENDHLSL` |
| `UnityCG.cginc` | `Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl` |
| `Lighting.cginc` | `Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl` |
| `AutoLight.cginc` | URP lighting/shadow APIs, usually via `Lighting.hlsl` |

## Positions and normals

| Built-in | URP direction |
|---|---|
| `UnityObjectToClipPos(v.vertex)` | `TransformObjectToHClip(v.positionOS.xyz)` or `GetVertexPositionInputs(...)` |
| `mul(unity_ObjectToWorld, v.vertex)` | `TransformObjectToWorld(...)` or `GetVertexPositionInputs(...)` |
| `UnityObjectToWorldNormal(n)` | `TransformObjectToWorldNormal(n)` or `GetVertexNormalInputs(...)` |
| `WorldSpaceViewDir(...)` | derive view direction from world position using URP helpers |

## Texture declarations and sampling

Typical 2D texture form:

```hlsl
TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
```

Sampling:

```hlsl
half4 c = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
```

Common Built-in calls such as `tex2D`, `tex2Dlod`, and projected sampling need the matching URP/HLSL texture macro or method. Choose the correct sampling macro for LOD/gradient/array/cube/shadow semantics.

## Material constants

Prefer:

```hlsl
CBUFFER_START(UnityPerMaterial)
    float4 _MainTex_ST;
    half4 _BaseColor;
    float _Cutoff;
CBUFFER_END
```

Texture/sampler objects are declared outside the material constant buffer.

## Main light

Built-in globals such as `_WorldSpaceLightPos0` and `_LightColor0` should not be ported as globals. Use URP lighting APIs, for example a `Light` returned by `GetMainLight(...)`, then read fields such as direction, color, distance attenuation, and shadow attenuation as appropriate for the target URP version.

## Additional lights

Built-in `ForwardAdd` is not normally reproduced as one additive pass per light. In URP forward rendering, evaluate supported additional lights in the forward shader path using URP's additional-light APIs and the corresponding shader variants/keywords.

## Shadows

Legacy macros such as `TRANSFER_SHADOW`, `SHADOW_ATTENUATION`, and Built-in `AutoLight.cginc` logic should be replaced with URP shadow-coordinate and light-query functions.

Typical direction:

```hlsl
float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
Light mainLight = GetMainLight(shadowCoord);
half shadow = mainLight.shadowAttenuation;
```

Exact keyword sets vary across URP versions, so inspect package shaders when targeting a specific project.

## Fog

Replace Built-in fog macros with the URP fog helpers and keywords from `Core.hlsl`. Preserve whether fog was vertex-computed or fragment-applied.

## Pass LightMode mapping

These are conceptual directions, not guaranteed one-to-one mappings:

| Built-in | URP direction |
|---|---|
| `ForwardBase` | usually `UniversalForward` / `UniversalForwardOnly` |
| `ForwardAdd` | usually fold additional lights into forward pass |
| `ShadowCaster` | `ShadowCaster` |
| legacy deferred/prepass tags | redesign for target URP renderer |

## RenderPipeline tag

At `SubShader` level:

```shaderlab
Tags
{
    "RenderPipeline" = "UniversalPipeline"
}
```

Keep `Queue`, `RenderType`, and other material behavior tags from the source unless there is a reason to change them.
