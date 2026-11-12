// NatureVision Universal
// Vertex shader for legacy Bedrock renderer

// __multiversion__

#include "vertexVersionCentroid.h"
#include "uniformWorldConstants.h"
#include "uniformPerFrameConstants.h"
#include "uniformRenderChunkConstants.h"

uniform highp float TOTAL_REAL_WORLD_TIME;

attribute POS4 POSITION;
attribute vec4 COLOR;
attribute vec2 TEXCOORD_0;
attribute vec2 TEXCOORD_1;

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

highp float nv_hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    POS4 worldPos;

    #ifndef BYPASS_PIXEL_SHADER
    uv0 = TEXCOORD_0;
    uv1 = TEXCOORD_1;
    vertexColor = COLOR;
    #endif

    worldPos.xyz =
        POSITION.xyz * CHUNK_ORIGIN_AND_SCALE.w +
        CHUNK_ORIGIN_AND_SCALE.xyz;

    worldPos.w = 1.0;

    float time = TOTAL_REAL_WORLD_TIME;

    float plant = 0.0;
    float water = 0.0;

    // Detect likely foliage/grass vertices.
    if (COLOR.g > COLOR.r * 1.08 &&
        COLOR.g > COLOR.b * 1.03 &&
        COLOR.a > 0.05) {
        plant = 1.0;
    }

    // Detect partially transparent terrain.
    if (COLOR.a > 0.05 && COLOR.a < 0.95) {
        water = 1.0;
    }

    vec2 worldXZ = worldPos.xz;

    float windPhase =
        dot(worldXZ, vec2(0.17, 0.13)) +
        time * 1.35;

    float wind =
        sin(windPhase) * 0.65 +
        sin(windPhase * 1.7 + 1.2) * 0.35;

    float randomFactor = nv_hash(floor(worldXZ));

    // Keep the base of plants stable.
    float heightFactor = fract(POSITION.y);

    float windStrength = 0.055;

    worldPos.x +=
        wind * randomFactor *
        heightFactor * plant * windStrength;

    worldPos.z +=
        cos(windPhase * 0.8) *
        randomFactor *
        heightFactor * plant * windStrength * 0.45;

    // Very subtle water vertex movement.
    float wave =
        sin(worldXZ.x * 0.35 + time * 1.2) *
        cos(worldXZ.y * 0.28 + time * 0.9);

    worldPos.y += wave * water * 0.012;

    #ifndef BYPASS_PIXEL_SHADER
    plantMotion = plant;
    waterMotion = water;
    #endif

    POS4 viewPos = WORLDVIEW * worldPos;
    gl_Position = PROJ * viewPos;

    #ifdef FOG
    float cameraDistance = length(viewPos.xyz);
    float fogAmount = cameraDistance / RENDER_DISTANCE;

    fog = clamp(
        (fogAmount - FOG_CONTROL.x) /
        max(FOG_CONTROL.y - FOG_CONTROL.x, 0.001),
        0.0,
        1.0
    );
    #endif
}
