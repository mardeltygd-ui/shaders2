#version 120
#include "/lib/common.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    vec4 t = texture2D(texture, texcoord);
    if (t.a < 0.05) discard;
    vec3 c = mix(vec3(0.40, 0.45, 0.60), vec3(0.85, 0.88, 0.95), dayFactor());

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(c, t.a * glcolor.a * 0.55);
}
