#version 120

uniform sampler2D texture;
uniform float far;

varying vec2 texcoord;
varying vec4 glcolor;
varying float dist;
varying vec3 skyC;
varying vec3 cloudC;

void main() {
    vec4 t = texture2D(texture, texcoord) * glcolor;
    if (t.a < 0.1) discard;
    float shade = dot(glcolor.rgb, vec3(0.333));
    vec3 c = cloudC * (0.65 + 0.35 * shade);
    c = mix(c, skyC, smoothstep(far * 0.8, far * 2.0, dist));

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = vec4(c, t.a);
}
