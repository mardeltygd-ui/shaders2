#version 120
#include "/lib/settings.glsl"

varying vec2 texcoord;
varying vec4 glcolor;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
#ifdef SHADOWS
    gl_Position = ftransform();
    float d = length(gl_Position.xy);
    gl_Position.xy /= d * 0.85 + 0.15;   // more shadow resolution near the player
#else
    gl_Position = vec4(10.0);            // shadows off: everything is clipped, pass is free
#endif
}
