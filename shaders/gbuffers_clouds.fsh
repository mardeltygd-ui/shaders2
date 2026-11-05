#version 120
#include "/lib/common.glsl"

uniform sampler2D texture;
uniform float far;

varying vec2 texcoord;
varying vec4 glcolor;
varying vec3 viewPos;

// Clouds catch the colour of the time of day: white, peach at sunset, deep blue at night
void main() {
    vec4 t = texture2D(texture, texcoord) * glcolor;
    if (t.a < 0.1) discard;

    float day = dayFactor();
    float dusk = duskFactor();
    vec3 c = mix(vec3(0.10, 0.12, 0.24), vec3(1.0, 0.96, 0.92), day);
    c = mix(c, vec3(1.0, 0.66, 0.48), dusk * 0.8);
    c *= 1.0 - 0.35 * rainStrength;

    float shade = dot(glcolor.rgb, vec3(0.333));
    c = lin(c) * (0.65 + 0.35 * shade);

    float dist = length(viewPos);
    vec3 skyC = lin(skyColor(viewPos / max(dist, 0.0001)));
    c = mix(c, skyC, smoothstep(far * 0.8, far * 2.0, dist));

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(c, t.a);
}
