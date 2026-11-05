#version 120
#include "/lib/common.glsl"

uniform mat4 gbufferProjection;

varying vec2 texcoord;
varying vec3 lightScreen;   // xy = light position on screen, z = 1 when in front of the camera
varying vec3 rayCol;        // god-ray colour * strength (zero when there is no light)

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

    vec4 lp = gbufferProjection * vec4(shadowLightPosition, 1.0);
    lightScreen = vec3(lp.xy / lp.w * 0.5 + 0.5, lp.w > 0.0 ? 1.0 : 0.0);

    // stronger at sunrise and sunset, bluish and weak at night
    rayCol = lightColor() * lightAmount() * (0.6 + 0.9 * duskFactor()) * GODRAY_STRENGTH;
}
