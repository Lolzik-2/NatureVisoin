
// NatureVision Universal
// Minecraft Bedrock 1.16.40
// Legacy GLSL terrain vertex shader

// __multiversion__

#include "vertexVersionCentroid.h"

#if __VERSION__ >= 300
    #ifndef BYPASS_PIXEL_SHADER
        _centroid out vec2 uv0;
        _centroid out vec2 uv1;
    #endif
#else
    #ifndef BYPASS_PIXEL_SHADER
        varying vec2 uv0;
        varying vec2 uv1;
    #endif
#endif

#ifndef BYPASS_PIXEL_SHADER
    varying vec4 color;
#endif

#ifdef FOG
    varying float fog;
#endif

#ifdef GL_FRAGMENT_PRECISION_HIGH
    #define HM highp
#else
    #define HM mediump
#endif

varying HM vec3 cPos;
varying HM vec3 wPos;
varying float wf;

#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"
#include "uniformRenderChunkConstants.h"

uniform highp float TOTAL_REAL_WORLD_TIME;

attribute POS4 POSITION;
attribute vec4 COLOR;
attribute vec2 TEXCOORD_0;
attribute vec2 TEXCOORD_1;

highp float hash11(highp float p)
{
    p = fract(p * 0.1031);
    p *= p + 33.33;
    return fract((p + p) * p);
}

highp float randomValue(highp float p)
{
    p = p / 3.0 + TOTAL_REAL_WORLD_TIME;

    return mix(
        hash11(floor(p)),
        hash11(ceil(p)),
        smoothstep(0.0, 1.0, fract(p))
    ) * 2.0;
}

void main()
{
    wf = 0.0;

    POS4 worldPos;
    POS4 pos;

#ifndef BYPASS_PIXEL_SHADER
    uv0 = TEXCOORD_0;
    uv1 = TEXCOORD_1;
    color = COLOR;
#endif

#ifdef AS_ENTITY_RENDERER

    pos = WORLDVIEWPROJ * POSITION;
    worldPos = pos;

#else

    worldPos.xyz =
        POSITION.xyz * CHUNK_ORIGIN_AND_SCALE.w +
        CHUNK_ORIGIN_AND_SCALE.xyz;

    worldPos.w = 1.0;

#ifndef BYPASS_PIXEL_SHADER

    // NatureVision vegetation wind.
    float foliageMask = 0.0;

    if (COLOR.a > 0.05 && COLOR.g > COLOR.r)
    {
        foliageMask = 1.0;
    }

    vec3 localPosition = POSITION.xyz;

    float windRandom = randomValue(
        localPosition.x +
        localPosition.y +
        localPosition.z
    );

    float windWave = sin(
        TOTAL_REAL_WORLD_TIME * 2.0 +
        localPosition.x * 1.7 +
        localPosition.z * 1.4
    );

    float windWave2 = sin(
        TOTAL_REAL_WORLD_TIME * 1.3 +
        localPosition.z * 1.1 -
        localPosition.x * 0.8
    );

    float heightMask = clamp(
        fract(localPosition.y),
        0.0,
        1.0
    );

    float distanceFade = clamp(
        1.0 - length(worldPos.xyz) /
        FAR_CHUNKS_DISTANCE,
        0.0,
        1.0
    );

    worldPos.x +=
        windWave *
        0.025 *
        foliageMask *
        heightMask *
        windRandom *
        distanceFade;

    worldPos.z +=
        windWave2 *
        0.012 *
        foliageMask *
        heightMask *
        distanceFade;

    // Water detection.
#ifndef SEASONS
    if (COLOR.a > 0.05 && COLOR.a < 0.95)
    {
        wf = 1.0;
    }
#endif

#endif

    // Standard Bedrock transformation.
    POS4 viewPos = WORLDVIEW * worldPos;
    pos = PROJ * viewPos;

#endif

    gl_Position = pos;

    cPos = POSITION.xyz;
    wPos = worldPos.xyz;

#ifdef FOG

    float cameraDepth = length(-worldPos.xyz);

    float len = cameraDepth / max(RENDER_DISTANCE, 0.001);

#ifdef ALLOW_FADE
    len += RENDER_CHUNK_FOG_ALPHA;
#endif

    fog = clamp(
        (len - FOG_CONTROL.x) /
        max(FOG_CONTROL.y - FOG_CONTROL.x, 0.001),
        0.0,
        1.0
    );

#endif

#ifndef BYPASS_PIXEL_SHADER
#ifndef FOG
    color.rgb += FOG_COLOR.rgb * 0.000001;
#endif
#endif
}
