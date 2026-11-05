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
varying float dist;
varying float ndl;
varying float upDot;
varying vec3 shadowPos;
varying vec3 lightCol;
varying vec3 ambCol;
varying vec3 fogCol;
varying vec3 grade;

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
    float fade = 1.0 - smoothstep(SHADOW_DIST * 0.75, SHADOW_DIST, dist);
    return mix(1.0, s, fade);
#else
    return 1.0;
#endif
}

void main() {
    vec4 gc = glcolor;
#ifdef ENTITY_STAGE
    if (gc.a < 0.01) gc.a = 1.0;   // never let a zero vertex alpha hide the hand or mobs
#endif
    vec4 col = texture2D(texture, texcoord) * gc;
#ifdef USE_ENTITY_COLOR
    col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
#endif
    if (col.a < 0.1) discard;
    vec3 albedo = col.rgb * col.rgb;

    float skyL = clamp((lmcoord.y - 0.04) * 1.09, 0.0, 1.0);
    float blkL = clamp((lmcoord.x - 0.04) * 1.09, 0.0, 1.0);
#ifdef ENTITY_STAGE
    skyL = max(skyL, 0.45);        // hand and mobs are never pitch black
#endif

    float soft = clamp(ndl * 0.85 + 0.15, 0.0, 1.0);
    float gate = smoothstep(0.35, 0.90, lmcoord.y);
    vec3 direct = lightCol * (soft * gate * shadowTerm());

    vec3 amb = ambCol * ((0.68 + 0.32 * upDot) * skyL * skyL);
    vec3 block = vec3(1.0, 0.60, 0.30) * (blkL * blkL * 1.6);

    vec3 c = albedo * (direct + amb + block + vec3(0.050, 0.055, 0.075));

    float fr = max(far, 64.0);
    float fogAmt = smoothstep(fr * (0.35 - 0.10 * rainStrength), fr, dist) * (0.60 + 0.20 * rainStrength);
    vec3 fogC = fogCol * mix(0.35, 1.0, skyL);
    if (isEyeInWater == 1) {
        fogC = lin(vec3(0.10, 0.34, 0.46)) * (0.25 + 0.75 * dayFactor());
        fogAmt = 1.0 - exp(-dist * 0.07);
    }
    c = mix(c, fogC, fogAmt);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(finish(max(c, vec3(0.0))) * grade, col.a);
}
