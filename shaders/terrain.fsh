// NatureVision Universal
// Fragment shader for legacy Bedrock renderer

// __multiversion__

#include "fragmentVersionCentroid.h"

#ifndef BYPASS_PIXEL_SHADER
varying vec2 uv0;
varying vec2 uv1;
varying vec4 vertexColor;
varying float plantMotion;
varying float waterMotion;
#endif

#ifdef FOG
varying float fog;
#endif

uniform vec4 FOG_COLOR;
uniform vec2 FOG_CONTROL;

LAYOUT_BINDING(0) uniform sampler2D TEXTURE_0;
LAYOUT_BINDING(1) uniform sampler2D TEXTURE_1;

uniform highp float TOTAL_REAL_WORLD_TIME;

vec3 nv_tonemap(vec3 color) {
    color = max(color, vec3(0.0));

    return color / (vec3(1.0) + color * 0.18);
}

void main() {
    #ifdef BYPASS_PIXEL_SHADER
    gl_FragColor = vec4(0.0);
    return;
    #else

    vec4 texColor = texture2D(TEXTURE_0, uv0);
    vec4 lightMap = texture2D(TEXTURE_1, uv1);

    vec4 result = texColor;

    // Preserve texture transparency.
    result.a *= vertexColor.a;

    #ifdef ALPHA_TEST
    if (result.a < 0.5) {
        discard;
    }
    #endif

    // Base block lighting.
    result.rgb *= vertexColor.rgb;
    result.rgb *= lightMap.rgb;

    float daylight = clamp(uv1.y, 0.0, 1.0);

    // Soft ambient lighting.
    vec3 nightTint = vec3(0.66, 0.72, 0.92);
    vec3 dayTint = vec3(1.0, 0.98, 0.91);

    vec3 ambient = mix(
        nightTint,
        dayTint,
        smoothstep(0.15, 0.9, daylight)
    );

    result.rgb *= ambient;

    // Slight warm sunlight.
    float sunlight = smoothstep(0.72, 0.98, daylight);

    result.rgb +=
        vec3(0.055, 0.035, 0.012) *
        sunlight *
        result.rgb;

    // Gentle foliage color enhancement.
    float greenMask = clamp(
        vertexColor.g - max(vertexColor.r, vertexColor.b),
        0.0,
        1.0
    );

    result.rgb +=
        vec3(0.0, 0.025, 0.006) *
        greenMask;

    // Water color and subtle animated highlights.
    if (waterMotion > 0.5) {
        float waveA = sin(
            uv0.x * 35.0 +
            TOTAL_REAL_WORLD_TIME * 1.4
        );

        float waveB = cos(
            uv0.y * 28.0 -
            TOTAL_REAL_WORLD_TIME * 0.9
        );

        float wavePattern = waveA * waveB;

        vec3 waterColor = vec3(
            0.16,
            0.43,
            0.58
        );

        vec3 waterHighlight = vec3(
            0.30,
            0.58,
            0.69
        );

        vec3 animatedWater = mix(
            waterColor,
            waterHighlight,
            0.12 + 0.08 * wavePattern
        );

        result.rgb = mix(
            result.rgb,
            animatedWater,
            0.28
        );
    }

    // Lightweight color correction.
    result.rgb = nv_tonemap(result.rgb * 1.08);

    #ifdef FOG
    result.rgb = mix(
        result.rgb,
        FOG_COLOR.rgb,
        clamp(fog, 0.0, 1.0)
    );
    #endif

    gl_FragColor = result;

    #endif
}
