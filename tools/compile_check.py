import re, sys, glob, os, json
from playwright.sync_api import sync_playwright
ROOT = sys.argv[1]
def expand(path, seen=()):
    out = []
    for line in open(path, encoding='utf-8').read().split('\n'):
        m = re.match(r'\s*#include\s+"(/[^"]+)"', line)
        if m: out.append(expand(ROOT + m.group(1)))
        elif line.startswith('#version'): continue
        else: out.append(line)
    return '\n'.join(out)
VS = """precision highp float;
attribute vec4 a_Vertex; attribute vec4 a_Color; attribute vec3 a_Normal;
attribute vec4 a_MT0; attribute vec4 a_MT1;
uniform mat4 u_MV; uniform mat3 u_NM; uniform mat4 u_TM[2]; uniform mat4 u_MVP;
#define gl_Vertex a_Vertex
#define gl_Color a_Color
#define gl_Normal a_Normal
#define gl_MultiTexCoord0 a_MT0
#define gl_MultiTexCoord1 a_MT1
#define gl_ModelViewMatrix u_MV
#define gl_NormalMatrix u_NM
#define gl_TextureMatrix u_TM
vec4 ftransform(){ return u_MVP * a_Vertex; }
"""
FS = "precision highp float;\n"
items = []
for f in sorted(glob.glob(ROOT + '/*.vsh') + glob.glob(ROOT + '/*.fsh')):
    src = expand(f)
    src = src.replace('mat3(gbufferModelViewInverse)', 'mat3(gbufferModelViewInverse[0].xyz, gbufferModelViewInverse[1].xyz, gbufferModelViewInverse[2].xyz)')
    isv = f.endswith('.vsh')
    items.append({'name': os.path.basename(f), 'vs': isv, 'src': (VS if isv else FS) + src})
with sync_playwright() as p:
    b = p.chromium.launch(args=['--use-gl=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg = b.new_page()
    pg.set_content('<canvas id=c></canvas>')
    res = pg.evaluate("""(items)=>{
      const gl=document.getElementById('c').getContext('webgl'); if(!gl) return 'NO WEBGL';
      return items.map(it=>{const s=gl.createShader(it.vs?gl.VERTEX_SHADER:gl.FRAGMENT_SHADER);
        gl.shaderSource(s,it.src); gl.compileShader(s);
        return [it.name, gl.getShaderParameter(s,gl.COMPILE_STATUS), gl.getShaderInfoLog(s)];});}""", items)
    b.close()
if isinstance(res, str): print(res); sys.exit(1)
bad = 0
for n, ok, log in res:
    print(('OK   ' if ok else 'FAIL ') + n)
    if not ok: bad += 1; print('   ', log.strip().replace('\n', '\n    '))
print('failed:', bad)
