#version 120

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 glcolor;

// Sun and moon discs: keep the vanilla texture, soften and warm it a little
void main() {
    vec4 c = texture2D(texture, texcoord) * glcolor;
    c.rgb = c.rgb * vec3(1.0, 0.97, 0.92);

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = c;
}
