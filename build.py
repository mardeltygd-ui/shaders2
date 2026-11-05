#!/usr/bin/env python3
"""Flattens src/ (no #include left, safest for every Iris/OptiFine version) and builds the zips.
   shaders2.zip       - low defaults: tiny soft shadows, no rays
   shaders2-lite.zip  - no shadow pass at all (files removed), for the weakest PCs"""
import os, re, shutil, zipfile
ROOT = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(ROOT, 'src')

def expand(path):
    out = []
    for line in open(path, encoding='utf-8').read().split('\n'):
        m = re.match(r'\s*#include\s+"(/[^"]+)"', line)
        if m:
            out.append(expand(SRC + m.group(1)))
        else:
            out.append(line)
    return '\n'.join(out)

def build(name, zipname, tweak, skip_shadow=False):
    dest = os.path.join(ROOT, 'dist', name, 'shaders')
    shutil.rmtree(os.path.join(ROOT, 'dist', name), ignore_errors=True)
    os.makedirs(dest)
    for f in sorted(os.listdir(SRC)):
        p = os.path.join(SRC, f)
        if f == 'lib' or (skip_shadow and f.startswith('shadow.')): continue
        if f == 'lang':
            shutil.copytree(p, os.path.join(dest, 'lang')); continue
        txt = expand(p) if f.endswith(('.vsh', '.fsh')) else open(p, encoding='utf-8').read()
        if f.endswith(('.vsh', '.fsh')): txt = tweak(txt)
        open(os.path.join(dest, f), 'w', encoding='utf-8', newline='\n').write(txt)
    zp = os.path.join(ROOT, zipname)
    if os.path.exists(zp): os.remove(zp)
    with zipfile.ZipFile(zp, 'w', zipfile.ZIP_DEFLATED) as z:
        for r, _, fs in os.walk(dest):
            for f in sorted(fs):
                full = os.path.join(r, f)
                z.write(full, os.path.relpath(full, os.path.dirname(dest)))
    print('built', zipname)

def lite(t):
    t = t.replace('#define SHADOWS ', '//#define SHADOWS ')
    t = t.replace('//#define LITE', '#define LITE')
    return t.replace('#define SHADOW_RES 512', '#define SHADOW_RES 128')

build('full', 'shaders2.zip', lambda t: t)
build('lite', 'shaders2-lite.zip', lite, skip_shadow=True)
