
// NatureVision Universal
// Legacy Bedrock GLSL fragment shader

// __multiversion__

#include "fragmentVersionCentroid.h"

#if __VERSION__ >= 300
    #ifndef BYPASS_PIXEL_SHADER
        _centroid in vec2 uv0;
        _centroid in vec2 uv1;
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

#include "uniformPerFrameConstants.h"

uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;
uniform HM float TOTAL_REAL_WORLD_TIME;

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;
LAYOUT_BINDING(2) uniform sampler2D TEXTURE_2;

vec3 nv_tonemap(vec3 c) {
    c = max(c, vec3(0.0));
    return c / (vec3(1.0) + c * 0.12);
}

void main() {

#ifdef BYPASS_PIXEL_SHADER
    gl_FragColor = vec4(0.0);
    return;
#else

    // Read original Minecraft textures.
    vec4 texColor = texture2D(TEXTURE_0, uv0);

    #ifdef SEASONS_FAR
        texColor.a = 1.0;
    #endif

    // Alpha test for cutout materials.
    #if defined(ALPHA_TEST) || defined(USE_ALPHA_TEST)
        if (texColor.a < 0.5) {
            discard;
        }
    #endif

    vec4 result = texColor;

    // Apply vertex color.
    #ifndef SEASONS
        result.rgb *= color.rgb;
    #else
        vec2 seasonUV = color.xy;
        vec3 seasonTexture = texture2D(TEXTURE_2, seasonUV).rgb;
        result.rgb *= mix(
            vec3(1.0),
            seasonTexture * 2.0,
            color.b
        );
    #endif

    // Preserve original alpha for opaque and cutout materials.
    #ifdef BLEND
        result.a *= color.a;
    #else
        result.a = texColor.a;
    #endif

    // Minecraft lightmap.
    vec4 lightMap = texture2D(TEXTURE_1, uv1);

    #ifndef ALWAYS_LIT
        result.rgb *= lightMap.rgb;
    #endif

    // Daylight.
    float daylight = clamp(uv1.y, 0.0, 1.0);

    vec3 nightTint = vec3(0.78, 0.82, 0.96);
    vec3 dayTint = vec3(1.0, 0.99, 0.94);

    vec3 ambient = mix(
        nightTint,
        dayTint,
        smoothstep(0.15, 0.90, daylight)
    );

    result.rgb *= ambient;

    // Warm sunlight.
    float sunlight = smoothstep(0.72, 0.98, daylight);

    result.rgb +=
        result.rgb *
        vec3(0.045, 0.025, 0.008) *
        sunlight;

    // Gentle foliage enhancement.
    float greenMask = clamp(
        color.g - max(color.r, color.b),
        0.0,
        1.0
    );

    result.rgb += vec3(0.0, 0.018, 0.004) * greenMask;

    // Water appearance.
    #ifdef FANCY
    if (wf > 0.5) {

        float waveA = sin(
            uv0.x * 30.0 +
            TOTAL_REAL_WORLD_TIME * 1.2
        );

        float waveB = cos(
            uv0.y * 25.0 -
            TOTAL_REAL_WORLD_TIME * 0.8
        );

        float wavePattern = waveA * waveB;

        vec3 waterColor = vec3(0.14, 0.39, 0.53);
        vec3 waterLight = vec3(0.25, 0.53, 0.64);

        vec3 animatedWater = mix(
            waterColor,
            waterLight,
            0.12 + 0.07 * wavePattern
        );

        result.rgb = mix(
            result.rgb,
            animatedWater,
            0.22
        );
    }
    #endif

    // Subtle color correction.
    result.rgb = nv_tonemap(result.rgb * 1.08);

    // Fog.
    #ifdef FOG
        result.rgb = mix(
            result.rgb,
            FOG_COLOR.rgb,
            clamp(fog, 0.0, 1.0)
        );
    #endif

    // Keep alpha intact.
    gl_FragColor = result;

#endif
}
