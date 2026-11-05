#version 120
#include "/lib/common.glsl"

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform float aspectRatio;

varying vec2 texcoord;
varying vec3 lightScreen;
varying vec3 rayCol;

void main() {
    vec3 c = texture2D(colortex0, texcoord).rgb;
    float noise = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

#ifdef GODRAYS
    // light shafts: RAY_SAMPLES depth taps marching toward the light, sky = light gets through
    if (lightScreen.z > 0.5 && dot(rayCol, vec3(1.0)) > 0.01) {
        vec2 delta = lightScreen.xy - texcoord;
        float distL = length(delta * vec2(aspectRatio, 1.0));
        float fall = clamp(1.0 - distL * 0.9, 0.0, 1.0);
        fall *= fall;
        if (fall > 0.0) {
            float acc = 0.0;
            for (int i = 0; i < RAY_SAMPLES; i++) {
                float f = (float(i) + noise) / float(RAY_SAMPLES);
                vec2 p = texcoord + delta * f * 0.85;
                float inside = step(0.0, p.x) * step(p.x, 1.0) * step(0.0, p.y) * step(p.y, 1.0);
                acc += step(0.9999, texture2D(depthtex0, p).r) * inside;
            }
            c += rayCol * (acc / float(RAY_SAMPLES)) * fall;
        }
    }
#endif

    // gentle tonemap, then back to display space
    c = vec3(1.0) - exp(-c * 1.5);
    c = sqrt(c);

    // slightly richer colours, warm by day and cool at night, lifted soft blacks
    float l = dot(c, vec3(0.299, 0.587, 0.114));
    c = mix(vec3(l), c, 1.06);
    float day = dayFactor();
    c *= mix(vec3(0.96, 0.99, 1.06), vec3(1.0) + vec3(0.04, 0.0, -0.07) * WARMTH, day);
    c = c * 0.96 + vec3(0.018, 0.019, 0.024);

#ifdef VIGNETTE
    float v = length((texcoord - 0.5) * vec2(aspectRatio, 1.0));
    c *= 1.0 - 0.22 * smoothstep(0.35, 1.0, v);
#endif

    c += (noise - 0.5) / 255.0;   // hides banding in the smooth sky

    gl_FragData[0] = vec4(c, 1.0);
}
