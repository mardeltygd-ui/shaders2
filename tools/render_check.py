import re, sys, os, json
from playwright.sync_api import sync_playwright
ROOT = sys.argv[1]
def rd(n):
    s = open(os.path.join(ROOT, n), encoding='utf-8').read()
    s = s.replace('mat3(gbufferModelViewInverse)', 'mat3(gbufferModelViewInverse[0].xyz, gbufferModelViewInverse[1].xyz, gbufferModelViewInverse[2].xyz)')
    return re.sub(r'#version.*\n', '', s)
VS = """precision highp float;
attribute vec4 a_Vertex; attribute vec4 a_Color; attribute vec3 a_Normal; attribute vec4 a_MT0; attribute vec4 a_MT1;
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
progs = {n: (VS + rd(n + '.vsh'), FS + rd(n + '.fsh')) for n in ('gbuffers_terrain', 'gbuffers_entities', 'gbuffers_hand', 'gbuffers_skybasic')}
JS = r"""
(args)=>{
 const [progs, tests] = args;
 const c=document.createElement('canvas'); c.width=c.height=4; document.body.appendChild(c);
 const gl=c.getContext('webgl',{preserveDrawingBuffer:true});
 function mk(t,src){const s=gl.createShader(t);gl.shaderSource(s,src);gl.compileShader(s);if(!gl.getShaderParameter(s,gl.COMPILE_STATUS))throw gl.getShaderInfoLog(s);return s;}
 const cache={};
 function prog(n){ if(cache[n])return cache[n]; const p=gl.createProgram();
   gl.attachShader(p,mk(gl.VERTEX_SHADER,progs[n][0])); gl.attachShader(p,mk(gl.FRAGMENT_SHADER,progs[n][1]));
   gl.bindAttribLocation(p,0,'a_Vertex'); gl.linkProgram(p);
   if(!gl.getProgramParameter(p,gl.LINK_STATUS))throw n+' link: '+gl.getProgramInfoLog(p); return cache[n]=p;}
 function tex(unit,rgba){const t=gl.createTexture();gl.activeTexture(gl.TEXTURE0+unit);gl.bindTexture(gl.TEXTURE_2D,t);
   gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,new Uint8Array(rgba));
   gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.NEAREST);gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.NEAREST);}
 tex(0,[128,128,128,255]); tex(1,[255,255,255,255]);
 const buf=gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER,buf);
 gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,0, 3,-1,0, -1,3,0]),gl.STATIC_DRAW);
 gl.enableVertexAttribArray(0); gl.vertexAttribPointer(0,3,gl.FLOAT,false,0,0);
 const I4=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1], I3=[1,0,0,0,1,0,0,0,1];
 const out=[];
 for(const t of tests){
   const p=prog(t.prog); gl.useProgram(p);
   const U=(n,f)=>{const l=gl.getUniformLocation(p,n); if(l!==null)f(l);};
   const MV=I4.slice(); MV[14]=-20;
   U('u_MV',l=>gl.uniformMatrix4fv(l,false,MV)); U('u_MVP',l=>gl.uniformMatrix4fv(l,false,I4));
   U('u_NM',l=>gl.uniformMatrix3fv(l,false,I3)); U('u_TM[0]',l=>gl.uniformMatrix4fv(l,false,I4)); U('u_TM[1]',l=>gl.uniformMatrix4fv(l,false,I4));
   for(const m of ['gbufferModelViewInverse','shadowModelView','shadowProjection']) U(m,l=>gl.uniformMatrix4fv(l,false,I4));
   const a=t.sunAngle*Math.PI/180, s=[0,100*Math.sin(a),-100*Math.cos(a)];
   U('sunPosition',l=>gl.uniform3f(l,...s)); U('moonPosition',l=>gl.uniform3f(l,-s[0],-s[1],-s[2])); U('upPosition',l=>gl.uniform3f(l,0,100,0));
   U('rainStrength',l=>gl.uniform1f(l,t.rain||0)); U('far',l=>gl.uniform1f(l,t.far||256)); U('isEyeInWater',l=>gl.uniform1i(l,0));
   U('entityColor',l=>gl.uniform4f(l,0,0,0,0)); U('texture',l=>gl.uniform1i(l,0)); U('shadowtex1',l=>gl.uniform1i(l,1));
   U('viewWidth',l=>gl.uniform1f(l,4)); U('viewHeight',l=>gl.uniform1f(l,4));
   if(t.dir){ const d=t.dir, n=Math.hypot(...d), M=[0,0,0,0, 0,0,0,0, d[0]/n,d[1]/n,d[2]/n,0, 0,0,0,1];
     U('gbufferProjectionInverse',l=>gl.uniformMatrix4fv(l,false,M)); }
   gl.vertexAttrib4f(1,...(t.color||[1,1,1,1])); gl.vertexAttrib3f(2,...(t.normal||[0,1,0]));
   gl.vertexAttrib4f(3,0.5,0.5,0,1); gl.vertexAttrib4f(4,t.lm[0],t.lm[1],0,1);
   gl.viewport(0,0,4,4); gl.clearColor(1,0,1,1); gl.clear(gl.COLOR_BUFFER_BIT); gl.disable(gl.BLEND);
   gl.drawArrays(gl.TRIANGLES,0,3);
   const px=new Uint8Array(4); gl.readPixels(2,2,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);
   out.push(Array.from(px));
 }
 return out;
}"""
tests=[]; labels=[]
def add(label, **k): labels.append(label); tests.append(k)
for ang,name in ((-40,'night'),(-8,'dusk-night'),(0,'sunrise/sunset'),(12,'morning'),(35,'day'),(80,'noon')):
    add(f'{name:15} terrain top  sky-lit', prog='gbuffers_terrain', sunAngle=ang, lm=[0,0.97])
    add(f'{name:15} terrain side sky-lit', prog='gbuffers_terrain', sunAngle=ang, lm=[0,0.97], normal=[1,0,0])
for ang,name in ((-40,'night'),(35,'day')):
    add(f'{name:15} terrain CAVE lm=0   ', prog='gbuffers_terrain', sunAngle=ang, lm=[0,0])
    add(f'{name:15} hand/mob   lm=0     ', prog='gbuffers_hand', sunAngle=ang, lm=[0,0])
    add(f'{name:15} mob alpha=0 vertex  ', prog='gbuffers_entities', sunAngle=ang, lm=[0,0], color=[1,1,1,0])
for ang,name in ((-40,'night'),(0,'sunrise'),(35,'day')):
    add(f'{name:15} SKY zenith', prog='gbuffers_skybasic', sunAngle=ang, lm=[0,0], dir=[0,1,0.01], color=[.3,.5,.9,1])
    add(f'{name:15} SKY horizon', prog='gbuffers_skybasic', sunAngle=ang, lm=[0,0], dir=[0,0.02,-1], color=[.3,.5,.9,1])
    add(f'{name:15} SKY on the sun', prog='gbuffers_skybasic', sunAngle=ang, lm=[0,0], dir=[0,max(0.001,__import__('math').sin(ang*3.14159/180)),-__import__('math').cos(ang*3.14159/180)], color=[.3,.5,.9,1])
with sync_playwright() as p:
    b = p.chromium.launch(args=['--use-gl=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'])
    pg = b.new_page()
    res = pg.evaluate(JS, [progs, tests])
    b.close()
for l, r in zip(labels, res):
    flag = '  <-- BLACK/INVISIBLE' if (sum(r[:3]) < 45 or r[3] == 0 or r[:3] == [255, 0, 255]) and 'SKY' not in l and 'night' not in l else ''
    print(f'{l}  rgb={r[0]:3d},{r[1]:3d},{r[2]:3d} a={r[3]:3d}{flag}')
