#version 120
#include "/lib/common.glsl"

uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

varying vec4 glcolor;

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
        outCol = vec4(skyColor(dir), 1.0);
    }

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = outCol;
}
