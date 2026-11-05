#include "/lib/settings.glsl"

// Uniforms shared by all stages. Declared ONLY here, never again in other files.
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform vec3 shadowLightPosition;
uniform float rainStrength;

// Colours below are authored in "display" space; buffers hold linear-ish (c*c).
vec3 lin(vec3 c) { return c * c; }

float sunHeight() { return dot(normalize(sunPosition), normalize(upPosition)); }
float dayFactor()  { return smoothstep(-0.18, 0.22, sunHeight()); }
float duskFactor() { float h = sunHeight(); return exp(-h * h * 14.0); }

// Sky gradient for a view-space direction (day / sunset / night, sun + moon glow)
vec3 skyColor(vec3 dir) {
    vec3 up = normalize(upPosition);
    float h = dot(dir, up);
    float sh = sunHeight();
    float day = dayFactor();
    float dusk = duskFactor();

    vec3 dayZ   = vec3(0.30, 0.52, 0.92);
    vec3 dayH   = vec3(0.93, 0.88, 0.80);
    vec3 duskZ  = vec3(0.28, 0.30, 0.58);
    vec3 duskH  = vec3(1.00, 0.58, 0.34);
    vec3 nightZ = vec3(0.015, 0.025, 0.075);
    vec3 nightH = vec3(0.07, 0.09, 0.18);

    vec3 zen = mix(nightZ, dayZ, day);
    vec3 hor = mix(nightH, dayH, day);
    zen = mix(zen, duskZ, dusk * 0.6);
    hor = mix(hor, duskH, dusk);

    vec3 sd = normalize(sunPosition);
    float sa = max(dot(dir, sd), 0.0);
    hor = mix(hor, vec3(1.0, 0.62, 0.36), dusk * sa * sa * 0.5);

    float t = exp(-max(h, 0.0) * 3.0);
    vec3 col = mix(zen, hor, t);

    float sunVis = smoothstep(-0.12, 0.08, sh);
    col += vec3(1.0, 0.72, 0.42) * (pow(sa, 6.0) * 0.25 + pow(sa, 48.0) * 0.45) * sunVis * (0.6 + 0.4 * dusk);

    vec3 md = normalize(moonPosition);
    float ma = max(dot(dir, md), 0.0);
    float moonVis = smoothstep(0.08, -0.12, sh);
    col += vec3(0.45, 0.55, 0.90) * (pow(ma, 8.0) * 0.10 + pow(ma, 64.0) * 0.18) * moonVis;

    float l = dot(col, vec3(0.333));
    col = mix(col, vec3(l) * vec3(0.80, 0.84, 0.92), rainStrength * 0.8);
    return col;
}

// Colour of the shadow-casting light (sun by day, moon by night)
vec3 lightColor() {
    float sunSel = smoothstep(-0.03, 0.03, sunHeight());
    float dusk = duskFactor();
    vec3 sunC  = mix(vec3(1.08, 0.94, 0.74), vec3(1.15, 0.62, 0.30), dusk);
    vec3 moonC = vec3(0.17, 0.22, 0.45);
    return mix(moonC, sunC, sunSel);
}

// Fades to zero when the shadow light touches the horizon, so the sun->moon switch never pops
float lightAmount() {
    float lh = dot(normalize(shadowLightPosition), normalize(upPosition));
    return smoothstep(0.0, 0.28, lh) * (1.0 - rainStrength * 0.75);
}

// Soft ambient light (cool lifted shadows by day, deep blue at night)
vec3 ambientColor() {
    float day = dayFactor();
    float dusk = duskFactor();
    vec3 a = mix(vec3(0.050, 0.065, 0.140), vec3(0.50, 0.57, 0.72), day);
    a = mix(a, vec3(0.55, 0.42, 0.48), dusk * 0.5);
    float l = dot(a, vec3(0.333));
    a = mix(a, vec3(l), rainStrength * 0.5) * (1.0 - 0.25 * rainStrength);
    return a;
}
