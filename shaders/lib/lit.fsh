#include "/lib/common.glsl"

uniform sampler2D texture;
uniform sampler2D shadowtex1;
uniform float far;
uniform int isEyeInWater;
#ifdef USE_ENTITY_COLOR
uniform vec4 entityColor;
#endif

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec3 viewPos;
varying float ndl;
varying float upDot;
varying vec3 shadowPos;

// Soft shadow: 5 taps on a small rotated cross, one texture lookup each
float shadowTerm() {
#if defined(SHADOWS) && !defined(NO_SHADOW)
    vec3 sp = shadowPos;
    if (sp.x < 0.0 || sp.x > 1.0 || sp.y < 0.0 || sp.y > 1.0 || sp.z > 1.0) return 1.0;
    float z = sp.z - 0.0009;
    float s;
  #if SHADOW_QUALITY == 0
    s = step(z, texture2D(shadowtex1, sp.xy).r);
  #else
    float px = 1.2 / float(shadowMapResolution);
    s  = step(z, texture2D(shadowtex1, sp.xy).r);
    s += step(z, texture2D(shadowtex1, sp.xy + vec2( 0.5,  1.5) * px).r);
    s += step(z, texture2D(shadowtex1, sp.xy + vec2(-1.5,  0.5) * px).r);
    s += step(z, texture2D(shadowtex1, sp.xy + vec2(-0.5, -1.5) * px).r);
    s += step(z, texture2D(shadowtex1, sp.xy + vec2( 1.5, -0.5) * px).r);
    s *= 0.2;
  #endif
    float fade = 1.0 - smoothstep(SHADOW_DIST * 0.75, SHADOW_DIST, length(viewPos));
    return mix(1.0, s, fade);
#else
    return 1.0;
#endif
}

void main() {
    vec4 col = texture2D(texture, texcoord) * glcolor;
#ifdef USE_ENTITY_COLOR
    col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
#endif
    if (col.a < 0.1) discard;
    vec3 albedo = col.rgb * col.rgb;

    float skyL = clamp((lmcoord.y - 0.04) / 0.92, 0.0, 1.0);
    float blkL = clamp((lmcoord.x - 0.04) / 0.92, 0.0, 1.0);

    // direct light: soft half-lambert * shadow map, gated by sky light to stop cave leaks
    float soft = clamp(ndl * 0.65 + 0.35, 0.0, 1.0);
    float gate = smoothstep(0.35, 0.90, lmcoord.y);
    vec3 direct = lightColor() * lightAmount() * soft * shadowTerm() * gate;

    // ambient: lifted, slightly brighter on upward faces
    vec3 amb = ambientColor() * (0.78 + 0.22 * upDot) * pow(skyL, 1.6);

    // warm torchlight
    vec3 block = vec3(1.0, 0.60, 0.30) * pow(blkL, 2.2) * 1.6;

    vec3 minAmb = vec3(0.030, 0.034, 0.050);
    vec3 c = albedo * (direct + amb + block + minAmb);

    // fog blends into the sky colour
    float dist = length(viewPos);
    vec3 vdir = viewPos / max(dist, 0.0001);
    float fogAmt = smoothstep(far * (0.55 - 0.2 * rainStrength), far * 0.98, dist);
    vec3 fogC = lin(skyColor(vdir)) * mix(0.3, 1.0, skyL);
    if (isEyeInWater == 1) {
        fogC = lin(vec3(0.10, 0.34, 0.46)) * (0.25 + 0.75 * dayFactor());
        fogAmt = 1.0 - exp(-dist * 0.07);
    }
    c = mix(c, fogC, fogAmt);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(c, col.a);
}
