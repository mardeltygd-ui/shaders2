#include "/lib/common.glsl"

uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float dist;
varying float ndl;
varying float upDot;
varying vec3 shadowPos;
varying vec3 lightCol;   // per-vertex: cheap, the fragment shader only multiplies
varying vec3 ambCol;
varying vec3 fogCol;

void main() {
    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    glcolor  = gl_Color;

    vec3 n = normalize(gl_NormalMatrix * gl_Normal);
    vec4 vp = gl_ModelViewMatrix * gl_Vertex;
    dist = length(vp.xyz);
    ndl   = dot(n, normalize(shadowLightPosition));
    upDot = dot(n, normalize(upPosition));

    lightCol = lightColor() * lightAmount();
    ambCol   = ambientColor();
    fogCol   = lin(skyColor(vp.xyz / max(dist, 0.0001)));

#if defined(SHADOWS) && !defined(NO_SHADOW)
    vec4 wp = gbufferModelViewInverse * vp;
    vec3 wn = mat3(gbufferModelViewInverse) * n;
    wp.xyz += wn * 0.12;
    vec4 sp = shadowProjection * (shadowModelView * wp);
    float d = length(sp.xy);
    sp.xy /= d * 0.85 + 0.15;
    shadowPos = sp.xyz * 0.5 + 0.5;
#else
    shadowPos = vec3(0.0);
#endif
}
