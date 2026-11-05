#version 120
#include "/lib/common.glsl"

varying vec2 texcoord;
varying vec4 glcolor;
varying float dist;
varying vec3 skyC;
varying vec3 cloudC;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    glcolor = gl_Color;
    vec3 vp = (gl_ModelViewMatrix * gl_Vertex).xyz;
    dist = length(vp);
    skyC = skyColor(vp / max(dist, 0.0001));

    float day = dayFactor();
    float dusk = duskFactor();
    vec3 c = mix(vec3(0.10, 0.12, 0.24), vec3(1.0, 0.96, 0.92), day);
    c = mix(c, vec3(1.0, 0.66, 0.48), dusk * 0.8);
    c *= 1.0 - 0.35 * rainStrength;
    cloudC = c;
}
