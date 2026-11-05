#include "/lib/settings.glsl"

// Uniforms shared by all stages. Declared ONLY here, never again in other files.
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform float rainStrength;

// normalize() that never produces NaN when a uniform is zero
vec3 safeNorm(vec3 v) { return v / max(length(v), 0.0001); }

// Colours below are authored in "display" space; buffers hold linear-ish (c*c).
vec3 lin(vec3 c) { return c * c; }

float sunHeight() { return dot(safeNorm(sunPosition), safeNorm(upPosition)); }
float dayFactor()  { return smoothstep(-0.18, 0.22, sunHeight()); }
float duskFactor() { float h = sunHeight(); return exp(-h * h * 14.0); }

// Sky gradient for a view-space direction (day / sunset / night, sun + moon glow)
vec3 skyColor(vec3 dir) {
    vec3 up = safeNorm(upPosition);
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

    vec3 sd = safeNorm(sunPosition);
    float sa = max(dot(dir, sd), 0.0);
    hor = mix(hor, vec3(1.0, 0.62, 0.36), dusk * sa * sa * 0.5);

    float t = exp(-max(h, 0.0) * 3.0);
    vec3 col = mix(zen, hor, t);

    float sunVis = smoothstep(-0.12, 0.08, sh);
    float sa2 = sa * sa; float sa4 = sa2 * sa2; float sa6 = sa4 * sa2;
    float sa12 = sa6 * sa6; float sa24 = sa12 * sa12; float sa48 = sa24 * sa24;
    col += vec3(1.0, 0.72, 0.42) * (sa6 * 0.10 + sa48 * 0.35) * sunVis * (0.6 + 0.4 * dusk);

    vec3 md = safeNorm(moonPosition);
    float ma = max(dot(dir, md), 0.0);
    float moonVis = smoothstep(0.08, -0.12, sh);
    float ma2 = ma * ma; float ma4 = ma2 * ma2; float ma8 = ma4 * ma4;
    float ma16 = ma8 * ma8; float ma32 = ma16 * ma16; float ma64 = ma32 * ma32;
    col += vec3(0.45, 0.55, 0.90) * (ma8 * 0.10 + ma64 * 0.18) * moonVis;

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
    return smoothstep(0.0, 0.28, abs(sunHeight())) * (1.0 - rainStrength * 0.75);
}

// View-space direction TO the shadow-casting light: sun by day, moon by night
vec3 lightDirView() {
    return safeNorm(mix(moonPosition, sunPosition, step(0.0, sunHeight())));
}

// Soft ambient light (cool lifted shadows by day, deep blue at night)
vec3 ambientColor() {
    float day = dayFactor();
    float dusk = duskFactor();
    vec3 a = mix(vec3(0.120, 0.150, 0.300), vec3(0.50, 0.57, 0.72), day);
    a = mix(a, vec3(0.55, 0.42, 0.48), dusk * 0.5);
    float l = dot(a, vec3(0.333));
    a = mix(a, vec3(l), rainStrength * 0.5) * (1.0 - 0.25 * rainStrength);
    return a;
}

// Time-of-day colour grade: warm by day, cool at night
vec3 gradeColor() {
    return mix(vec3(0.96, 0.99, 1.06), vec3(1.0) + vec3(0.04, 0.0, -0.07) * WARMTH, dayFactor());
}

// Soft tonemap + back to display space (done here, so no full-screen pass is needed)
vec3 finish(vec3 c) {
    c = c * 1.4 / (c * 1.4 + 0.5);
    return sqrt(c);
}
