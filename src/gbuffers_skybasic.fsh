#version 120
#include "/lib/common.glsl"

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

varying vec4 glcolor;

// Fan of soft beams around a light direction (cheap: only runs near the light)
vec3 skyRays(vec3 dir, vec3 ld, vec3 tint, float amount) {
    float a = dot(dir, ld);
    if (a < 0.55 || amount < 0.01) return vec3(0.0);
    vec3 up = safeNorm(upPosition);
    vec3 tt = safeNorm(cross(ld, up));
    vec3 bb = cross(ld, tt);
    float ang = atan(dot(dir, bb), dot(dir, tt));
    float beam = 0.5 + 0.5 * sin(ang * 12.0 + 0.8 * sin(ang * 5.0));
    float k = (a - 0.55) / 0.45;
    return tint * (beam * k * k * amount);
}

void main() {
    vec4 p = gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
    vec3 dir = normalize(p.xyz / p.w);

    // vanilla stars are drawn as grey quads; the sky dome is never exactly grey
    bool star = glcolor.r == glcolor.g && glcolor.g == glcolor.b && glcolor.r > 0.0;

    vec4 outCol;
    if (star) {
        float vis = (1.0 - dayFactor()) * (1.0 - rainStrength);
        outCol = vec4(vec3(1.0, 0.96, 0.88), glcolor.a * vis);
    } else {
        vec3 col = skyColor(dir);
#ifdef SKY_RAYS
        float sh = sunHeight();
        float calm = 1.0 - rainStrength;
        col += skyRays(dir, safeNorm(sunPosition), vec3(1.0, 0.74, 0.46),
                       0.30 * smoothstep(-0.12, 0.08, sh) * (0.6 + 0.8 * duskFactor()) * calm);
        col += skyRays(dir, safeNorm(moonPosition), vec3(0.45, 0.55, 0.9),
                       0.10 * smoothstep(0.08, -0.12, sh) * calm);
#endif
        outCol = vec4(col, 1.0);
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = outCol;
}
