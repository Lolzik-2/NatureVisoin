
// NatureVision Universal
// Minecraft Bedrock 1.16.40
// Legacy GLSL terrain fragment shader

// __multiversion__

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300
    #ifndef BYPASS_PIXEL_SHADER
        #if defined(TEXEL_AA) && defined(TEXEL_AA_FEATURE)
            _centroid in highp vec2 uv0;
            _centroid in highp vec2 uv1;
        #else
            _centroid in vec2 uv0;
            _centroid in vec2 uv1;
        #endif
    #endif
#else
    #ifndef BYPASS_PIXEL_SHADER
        varying vec2 uv0;
        varying vec2 uv1;
    #endif
#endif

varying vec4 color;

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

uniform HM float TOTAL_REAL_WORLD_TIME;

uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;


// NatureVision water animation.
// Only RGB is changed. Alpha is preserved.
vec3 natureWater(vec3 baseColor)
{
    float time = TOTAL_REAL_WORLD_TIME;

    float wave1 = sin(
        cPos.x * 0.22 +
        cPos.z * 0.18 +
        time * 1.1
    );

    float wave2 = sin(
        cPos.x * 0.13 -
        cPos.z * 0.24 +
        time * 0.75
    );

    float wave = (wave1 + wave2) * 0.5;

    vec3 waterTint = vec3(
        0.90,
        0.97,
        1.04
    );

    return baseColor * waterTint *
        (1.0 + wave * 0.018);
}


void main()
{
#ifdef BYPASS_PIXEL_SHADER

    gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
    return;

#else

    // Original Minecraft texture sampling.
#if USE_TEXEL_AA
    HM vec4 diffuse = texture2D_AA(TEXTURE_0, uv0);
#else
    HM vec4 diffuse = texture2D(TEXTURE_0, uv0);
#endif

#ifdef SEASONS_FAR
    diffuse.a = 1.0;
#endif

    // Alpha-tested blocks.
#if USE_ALPHA_TEST

#ifdef ALPHA_TO_COVERAGE
    #define ALPHA_THRESHOLD 0.05
#else
    #define ALPHA_THRESHOLD 0.52
#endif

    if (diffuse.a < ALPHA_THRESHOLD)
    {
        discard;
    }

#endif

    vec4 inColor = color;

#ifdef BLEND
    diffuse.a *= inColor.a;
#endif

    // Minecraft lightmap.
    vec4 tex1 = texture2D(TEXTURE_1, uv1);

#ifndef ALWAYS_LIT
    diffuse *= tex1;
#endif

#ifndef SEASONS

#if !USE_ALPHA_TEST && !defined(BLEND)
    diffuse.a = inColor.a;
#endif

    diffuse.rgb *= inColor.rgb;

#else

    vec2 seasonUV = inColor.xy;

    diffuse.rgb *= mix(
        vec3(1.0),
        texture2D(TEXTURE_2, seasonUV).rgb * 2.0,
        inColor.b
    );

    diffuse.rgb *= inColor.aaa;
    diffuse.a = 1.0;

#endif

    // NatureVision subtle ambient lighting.
    float daylight = clamp(tex1.g, 0.0, 1.0);

    vec3 dayTint = vec3(
        1.015,
        1.020,
        1.025
    );

    vec3 nightTint = vec3(
        0.92,
        0.94,
        1.02
    );

    vec3 ambientTint = mix(
        nightTint,
        dayTint,
        daylight
    );

    diffuse.rgb *= ambientTint;

    // Preserve vanilla-style torch lighting.
#ifndef BLEND

    float torchLight = max(uv1.x - 0.5, 0.0);

    diffuse.rgb +=
        torchLight *
        (1.0 - diffuse.rgb * diffuse.rgb) *
        vec3(1.0, 0.65, 0.3);

#endif

    // Water animation.
#ifdef FANCY
#ifndef SEASONS

    if (wf > 0.5)
    {
        diffuse.rgb = natureWater(diffuse.rgb);
    }

#endif
#endif

    // Standard fog.
#ifdef FOG

    diffuse.rgb = mix(
        diffuse.rgb,
        FOG_COLOR.rgb,
        clamp(fog, 0.0, 1.0)
    );

#endif

    gl_FragColor = diffuse;

#endif
}
