#!/usr/bin/env python3
"""Procedural SFX generator for CRITTER v2 (numpy only, no samples, no licenses). Writes v2/audio/sfx/*.ogg via ffmpeg.
Run: python3 v2/tools/gen/gen_sfx.py"""
import numpy as np, os, subprocess, wave, sys
SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "audio", "sfx")
rng = np.random.default_rng(7)
def t(d): return np.linspace(0, d, int(SR*d), endpoint=False)
def env(n, a=0.005, d=0.1, s=0.0, r=0.1, hold=None):
    x = np.zeros(n); na=int(a*SR); nd=int(d*SR); nr=int(r*SR)
    na=max(na,1); x[:na]=np.linspace(0,1,na)
    nd=min(nd,n-na); x[na:na+nd]=np.linspace(1,s,nd) if nd>0 else 0
    rest=n-na-nd; 
    if rest>0:
        x[na+nd:]=s
        nr=min(nr,rest); x[n-nr:]*=np.linspace(1,0,nr) if nr>0 else 1
    return x
def expenv(n, tau): return np.exp(-np.linspace(0,1,n)*n/SR/tau)
def noise(d): return rng.uniform(-1,1,int(SR*d))
def lp(x, fc):
    a=np.exp(-2*np.pi*fc/SR); y=np.zeros_like(x); p=0.0
    for i in range(len(x)):
        p=(1-a)*x[i]+a*p; y[i]=p
    return y
def lp_fast(x, fc):
    # one-pole via cumulative filter using scipy if available
    try:
        from scipy.signal import lfilter
        a=np.exp(-2*np.pi*fc/SR); return lfilter([1-a],[1,-a],x)
    except Exception: return lp(x,fc)
def hp(x, fc): return x - lp_fast(x, fc)
def bp(x, lo, hi): return lp_fast(hp(x, lo), hi)
def sweep(f0, f1, d, shape="exp"):
    n=int(SR*d); f=np.geomspace(max(f0,1),max(f1,1),n) if shape=="exp" else np.linspace(f0,f1,n)
    return np.sin(2*np.pi*np.cumsum(f)/SR)
def tone(f, d, harm=(1,), amps=None):
    x=0; tt=t(d)
    for i,h in enumerate(harm): x=x+(amps[i] if amps else 1/(i+1))*np.sin(2*np.pi*f*h*tt)
    return x
def sat(x, k=3.0): return np.tanh(x*k)/np.tanh(k)
def mix(*parts):
    n=max(len(p) for p in parts); y=np.zeros(n)
    for p in parts: y[:len(p)]+=p
    return y
def norm(x, peak=0.8):
    m=np.max(np.abs(x))+1e-9; return x/m*peak
def delay(x, ms, g=0.4, rep=3):
    y=x.copy(); n=int(SR*ms/1000)
    for r in range(1,rep+1):
        z=np.zeros(len(x)+n*r); z[n*r:]=x*(g**r)
        y=np.pad(y,(0,max(0,len(z)-len(y)))); y[:len(z)]+=z
    return y
def fm(fc, fmod, idx, d): 
    tt=t(d); return np.sin(2*np.pi*fc*tt+idx*np.sin(2*np.pi*fmod*tt))
def clang(f, d, tau=0.25, bright=1.0):
    ratios=[1,2.76,5.4,8.93]; x=0; n=int(SR*d)
    for i,r in enumerate(ratios): x=x+(1/(i+1))*np.sin(2*np.pi*f*r*t(d))*expenv(n,tau/(i+1)**0.5)
    return x*bright
def impact(low, d, body=1.0, click=0.7):
    n=int(SR*d); thump=sweep(low*2,low*0.5,d)*expenv(n,d/3)
    cl=hp(noise(0.02),2000); cl=np.pad(cl,(0,n-len(cl)))*click
    return thump*body+cl
def whoosh(d, f0, f1, g=1.0):
    n=int(SR*d); x=noise(d); lo=lp_fast(x, f1); band=bp(x,f0,f1)
    return band*np.sin(np.linspace(0,np.pi,n))**1.5*g
def chime(f, d, tau=0.5): return (np.sin(2*np.pi*f*t(d))+0.4*np.sin(2*np.pi*f*2.01*t(d))+0.2*np.sin(2*np.pi*f*3.02*t(d)))*expenv(int(SR*d),tau)
def pluck(f, d): 
    n=int(SR*d); x=noise(1/f); x=np.tile(x,int(n/len(x))+2)[:n]
    return lp_fast(x, f*4)*expenv(n,d/3)
def bubbles(d, k=10):
    y=np.zeros(int(SR*d))
    for _ in range(k):
        s=rng.uniform(0,d-0.1); f=rng.uniform(250,900); L=rng.uniform(0.04,0.09)
        b=sweep(f,f*2.2,L)*expenv(int(SR*L),L/3)*rng.uniform(0.3,0.8); i=int(s*SR); y[i:i+len(b)]+=b
    return y
def crackle(d, k=20, hi=True):
    y=np.zeros(int(SR*d))
    for _ in range(k):
        s=rng.uniform(0,d-0.03); b=hp(noise(0.015),3000 if hi else 600)*rng.uniform(0.3,1); i=int(s*SR); y[i:i+len(b)]+=b
    return y
def rattle(d, hz, f=900):
    y=np.zeros(int(SR*d)); step=1/hz; s=0
    while s<d-0.04:
        b=hp(noise(0.03),f)*expenv(int(SR*0.03),0.01); i=int(s*SR); y[i:i+len(b)]+=b; s+=step
    return y
S={}
# ---- UI
S["ui_tap"]=chime(1400,0.08,0.03)*0.6
S["ui_confirm"]=mix(chime(880,0.25,0.12),np.pad(chime(1320,0.25,0.12),(int(SR*0.07),0)))
S["ui_back"]=chime(520,0.14,0.05)*0.7
# ---- generic combat
S["hit_light"]=mix(impact(160,0.14,1.0,0.9),whoosh(0.06,2000,8000,0.4))
S["hit_heavy"]=mix(impact(70,0.32,1.5,0.8),sat(sweep(180,50,0.3),2)*expenv(int(SR*0.3),0.1),delay(hp(noise(0.12),1500)*expenv(int(SR*0.12),0.03),40,0.3,2))
S["hit_crit"]=mix(S["hit_heavy"],clang(900,0.4,0.2,0.5))
S["block"]=mix(clang(520,0.22,0.08,0.7),impact(220,0.07,0.6,0.5))
S["parry"]=mix(clang(1250,0.6,0.35,1.0),chime(2400,0.5,0.25)*0.5,hp(noise(0.03),4000)*0.8)
S["clash"]=mix(clang(700,0.35,0.2),clang(940,0.35,0.2),impact(110,0.18,0.9,0.7))
S["grab"]=mix(whoosh(0.12,500,3000,0.8),np.pad(impact(90,0.22,1.1,0.4),(int(SR*0.09),0)))
S["dodge"]=whoosh(0.2,900,6500,1.0)
S["stagger"]=mix(sweep(300,90,0.25)*expenv(int(SR*0.25),0.1),hp(noise(0.12),600)*expenv(int(SR*0.12),0.05))
S["ko"]=mix(sat(sweep(140,38,0.9),2.5)*expenv(int(SR*0.9),0.35),impact(55,0.6,1.2,0.4),delay(chime(220,0.9,0.5)*0.3,120,0.4,2))
S["ringout"]=mix(sweep(900,120,0.9)*expenv(int(SR*0.9),0.5),whoosh(0.9,300,2500,0.7))
S["tell"]=chime(1700,0.06,0.025)*0.5
S["tell_heavy"]=mix(sweep(300,900,0.25,"lin")*expenv(int(SR*0.25),0.2)*0.5,chime(1000,0.25,0.12)*0.4)
S["heartbeat"]=np.pad(mix(sweep(90,50,0.14)*expenv(int(SR*0.14),0.05),np.pad(sweep(80,45,0.16)*expenv(int(SR*0.16),0.06)*0.8,(int(SR*0.18),0))),(0,int(SR*0.1)))
S["last_stand"]=mix(sat(fm(80,40,6,1.4),3)*expenv(int(SR*1.4),0.7),sweep(100,800,1.0)*expenv(int(SR*1.0),0.5)*0.4,noise(1.2)*0.1*np.sin(np.linspace(0,np.pi,int(SR*1.2))))
S["yield"]=mix(chime(660,0.7,0.35),np.pad(chime(495,0.8,0.4),(int(SR*0.12),0)))
S["win"]=mix(chime(523,0.8,0.4),np.pad(chime(659,0.8,0.4),(int(SR*0.12),0)),np.pad(chime(784,1.0,0.5),(int(SR*0.24),0)))
S["bell_start"]=clang(440,1.2,0.6,0.9)
# ---- Aruun
S["aruun_reaching_strike"]=mix(whoosh(0.35,150,2500,1.0),np.pad(mix(impact(65,0.3,1.4,0.6),crackle(0.25,30,False)*0.5),(int(SR*0.18),0)))
S["aruun_gravity_pull"]=mix(sweep(900,60,0.8)*expenv(int(SR*0.8),0.5)*0.9,sat(fm(55,27,4,0.9),2)*0.5*expenv(int(SR*0.9),0.6),np.pad(impact(45,0.5,1.5,0.3),(int(SR*0.5),0)))
S["aruun_beetle_rage"]=mix(sat(fm(70,35,9,1.1)+0.5*sweep(55,110,1.1),4)*env(int(SR*1.1),0.05,0.2,0.7,0.5),hp(noise(1.1),800)*0.08)
S["aruun_carry_the_bridge"]=mix(clang(110,1.8,0.9,0.9),sat(sweep(60,45,1.6),2)*expenv(int(SR*1.6),0.8),chime(220,1.6,0.8)*0.3)
S["aruun_morrow_first"]=mix(whoosh(0.15,1200,6000,0.6),impact(120,0.15,0.8,0.8))
# ---- Cigarra
S["cigarra_premonition"]=mix(*[np.pad(chime(f,0.5,0.25)*0.5,(int(SR*i*0.07),0)) for i,f in enumerate([1760,1397,1175,880,660])])[::-1]*0.9
S["cigarra_false_memory"]=mix(chime(740,0.7,0.4),chime(748,0.7,0.4))*np.sin(2*np.pi*5*t(0.7))**2*0.5+np.pad(chime(1480,0.6,0.3)*0.2,(0,int(SR*0.1)))
S["cigarra_puppet_thought"]=mix(pluck(330,0.6),pluck(497,0.6)*0.6,delay(fm(1200,300,3,0.4)*expenv(int(SR*0.4),0.15)*0.3,60,0.5,2))
S["cigarra_future_touched"]=mix(*[np.pad(chime(f,1.2,0.6)*0.45,(int(SR*i*0.1),0)) for i,f in enumerate([392,494,587,784,988])])
S["cigarra_brain_skip"]=mix(sweep(1500,200,0.18)*expenv(int(SR*0.18),0.06),np.pad(sweep(200,1500,0.12)*0.6,(int(SR*0.18),0)))*0.8
S["cigarra_bad_thought"]=mix(fm(900,310,4,0.2)*expenv(int(SR*0.2),0.07),whoosh(0.18,1500,7000,0.4))
# ---- Bramvex
S["bramvex_ghost"]=mix(bp(noise(0.9),300,2500)*env(int(SR*0.9),0.3,0.3,0.4,0.4)*0.9,sweep(220,110,0.9)*0.15)
S["bramvex_ground_prep"]=mix(*[np.pad(mix(impact(140,0.1,1.0,0.8),crackle(0.08,6,True)*0.6),(int(SR*i*0.1),0)) for i in range(3)])
S["bramvex_detain"]=mix(whoosh(0.12,700,3500,0.7),np.pad(mix(clang(310,0.3,0.1,0.6),impact(100,0.15,0.9,0.6)),(int(SR*0.1),0)))
S["bramvex_day_20"]=mix(rattle(0.9,22,1200),sat(sweep(100,300,0.9,"lin"),2)*0.25*expenv(int(SR*0.9),0.8),clang(500,0.5,0.2,0.4))
S["bramvex_diplomacy"]=mix(whoosh(0.2,300,3000,0.9),np.pad(impact(95,0.18,1.1,0.7),(int(SR*0.12),0)))
S["bramvex_cigarra_hole"]=whoosh(0.15,1200,7000,0.8)
# ---- Scarlith
S["scarlith_ferment"]=mix(bubbles(1.0,14)*0.9,lp_fast(noise(1.0),600)*0.15)
S["scarlith_decompose"]=mix(hp(noise(0.9),3500)*env(int(SR*0.9),0.05,0.4,0.4,0.3)*0.5,bubbles(0.9,6)*0.4)
S["scarlith_cultivate"]=mix(sweep(120,420,0.5)*expenv(int(SR*0.5),0.25)*0.8,bubbles(0.5,6)*0.6,crackle(0.5,10,False)*0.3)
S["scarlith_aged_to_perfection"]=mix(sweep(200,900,0.5,"lin")*0.5*expenv(int(SR*0.5),0.4),np.pad(mix(impact(85,0.5,1.5,0.8),hp(noise(0.3),600)*expenv(int(SR*0.3),0.1)),(int(SR*0.5),0)))
S["scarlith_barter"]=mix(chime(1760,0.15,0.05),np.pad(chime(2349,0.25,0.1),(int(SR*0.08),0)),whoosh(0.1,800,4000,0.4))
S["scarlith_culture_jab"]=mix(impact(180,0.1,0.8,0.7),bubbles(0.15,2)*0.6)
# ---- Mollusk
S["mollusk_inertia_field"]=mix(sat(sweep(220,70,1.4),2)*env(int(SR*1.4),0.1,0.3,0.6,0.7)*0.6,lp_fast(noise(1.4),300)*0.25)
S["mollusk_borrowed_seconds"]=mix(*[np.pad(chime(1500-i*80,0.08,0.03)*0.6,(int(SR*i*0.12),0)) for i in range(5)],np.pad(chime(330,0.9,0.45),(int(SR*0.55),0)))
S["mollusk_lift"]=mix(sweep(180,420,0.5,"lin")*0.3*env(int(SR*0.5),0.05,0.2,0.6,0.2),np.pad(impact(80,0.25,1.2,0.6),(int(SR*0.5),0)))
S["mollusk_everything_arrives"]=mix(*[np.pad(impact(60+i*8,0.3,1.4,0.6),(int(SR*i*0.07),0)) for i in range(6)],sat(sweep(80,35,1.0),2)*0.6*expenv(int(SR*1.0),0.5))
S["mollusk_shove"]=mix(impact(75,0.3,1.4,0.5),whoosh(0.2,200,1500,0.5))
# ---- Zephyr
S["zephyr_gust"]=mix(whoosh(0.7,250,3500,1.2),bp(noise(0.7),600,1200)*np.sin(np.linspace(0,3*np.pi,int(SR*0.7)))**2*0.5)
S["zephyr_pollen"]=mix(hp(noise(0.5),3000)*env(int(SR*0.5),0.02,0.3,0.3,0.2)*0.5,*[np.pad(chime(f,0.3,0.15)*0.3,(int(SR*i*0.06),0)) for i,f in enumerate([2093,2637,3136,2349])])
S["zephyr_promise"]=mix(chime(988,0.9,0.5),np.pad(chime(1319,1.0,0.55),(int(SR*0.18),0)))
S["zephyr_promise_attack"]=S["zephyr_promise"]
S["zephyr_a_promise_kept"]=mix(*[np.pad(chime(1175+i*120,0.35,0.12)*0.55,(int(SR*i*0.09),0)) for i in range(8)],whoosh(0.8,800,6000,0.4))
S["zephyr_flutter"]=mix(whoosh(0.09,2500,9000,0.6),chime(2400,0.05,0.02)*0.3)
# ---- Nyxaris
S["nyxaris_boundary"]=mix(crackle(0.7,40,True)*0.8,sweep(3000,900,0.5)*expenv(int(SR*0.5),0.3)*0.3,lp_fast(noise(0.7),500)*0.1)
S["nyxaris_venom_fang"]=mix(whoosh(0.1,1500,7000,0.7),np.pad(mix(impact(140,0.1,0.8,0.9),hp(noise(0.5),4000)*env(int(SR*0.5),0.02,0.3,0.2,0.2)*0.3,bubbles(0.4,3)*0.5),(int(SR*0.08),0)))
S["nyxaris_cocoon"]=mix(bp(noise(0.8),1500,6000)*env(int(SR*0.8),0.02,0.4,0.5,0.3)*0.7,np.pad(mix(crackle(0.4,25,True)*0.7,chime(2800,0.5,0.25)*0.3),(int(SR*0.35),0)))
S["nyxaris_cold_archive"]=mix(*[np.pad(chime(f,1.6,0.8)*0.4,(int(SR*i*0.08),0)) for i,f in enumerate([523,659,784,1047,1319])],crackle(1.2,50,True)*0.3)
S["nyxaris_silk_lash"]=mix(whoosh(0.18,2500,10000,0.8),chime(3200,0.06,0.02)*0.3)
S["swing_light"]=whoosh(0.1,1200,7000,0.7)
S["swing_heavy"]=mix(whoosh(0.28,200,3500,1.0),sweep(160,70,0.28)*0.25*expenv(int(SR*0.28),0.15))
S["jump"]=mix(sweep(200,500,0.15,"lin")*0.3*expenv(int(SR*0.15),0.08),whoosh(0.12,600,3000,0.4))
# ---- ambience (loop-ish)
n=int(SR*10); w=lp_fast(noise(10),500)*0.5
w=w*(0.6+0.4*np.sin(2*np.pi*0.13*t(10))); S["amb_arena"]=mix(w,sat(sweep(55,55.5,10,"lin"),1)*0.08)
os.makedirs(OUT,exist_ok=True)
tmp=os.path.join(OUT,"_t.wav"); total=0
for k,v in S.items():
    x=np.asarray(v,dtype=float); x=norm(x, 0.85 if not k.startswith("amb") else 0.4)
    # soft fades to avoid clicks
    f=min(len(x)//10,int(SR*0.01)); x[:f]*=np.linspace(0,1,f); x[-f:]*=np.linspace(1,0,f)
    pcm=(x*32767).astype(np.int16)
    with wave.open(tmp,"wb") as wf: wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(SR); wf.writeframes(pcm.tobytes())
    out=os.path.join(OUT,k+".ogg")
    subprocess.run(["ffmpeg","-y","-loglevel","error","-i",tmp,"-c:a","libvorbis","-q:a","3",out],check=True)
    total+=os.path.getsize(out)
os.remove(tmp); print(len(S),"sounds",total//1024,"KB")
