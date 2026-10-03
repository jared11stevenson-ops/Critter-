"""4x upscale with Real-ESRGAN anime_6B (pure torch CPU, no basicsr). usage: esrgan_upscale.py weights.pth in out"""
import sys, torch, torch.nn as nn, torch.nn.functional as F, numpy as np
from PIL import Image
class RDB(nn.Module):
    def __init__(s, f=64, g=32):
        super().__init__()
        for i in range(5): setattr(s, f'conv{i+1}', nn.Conv2d(f+i*g, g if i<4 else f, 3, 1, 1))
        s.l = nn.LeakyReLU(0.2, True)
    def forward(s, x):
        xs=[x]
        for i in range(4): xs.append(s.l(getattr(s,f'conv{i+1}')(torch.cat(xs,1))))
        return s.conv5(torch.cat(xs,1))*0.2+x
class RRDB(nn.Module):
    def __init__(s):
        super().__init__(); s.rdb1,s.rdb2,s.rdb3=RDB(),RDB(),RDB()
    def forward(s,x): return s.rdb3(s.rdb2(s.rdb1(x)))*0.2+x
class Net(nn.Module):
    def __init__(s,nb=6):
        super().__init__()
        s.conv_first=nn.Conv2d(3,64,3,1,1); s.body=nn.Sequential(*[RRDB() for _ in range(nb)])
        s.conv_body=nn.Conv2d(64,64,3,1,1); s.conv_up1=nn.Conv2d(64,64,3,1,1); s.conv_up2=nn.Conv2d(64,64,3,1,1)
        s.conv_hr=nn.Conv2d(64,64,3,1,1); s.conv_last=nn.Conv2d(64,3,3,1,1); s.l=nn.LeakyReLU(0.2,True)
    def forward(s,x):
        f=s.conv_first(x); f=f+s.conv_body(s.body(f))
        f=s.l(s.conv_up1(F.interpolate(f,scale_factor=2,mode='nearest')))
        f=s.l(s.conv_up2(F.interpolate(f,scale_factor=2,mode='nearest')))
        return s.conv_last(s.l(s.conv_hr(f)))
def upscale(w, src, dst, tile=256, pad=16):
    net=Net(); sd=torch.load(w,map_location='cpu'); net.load_state_dict(sd.get('params_ema',sd)); net.eval()
    img=np.asarray(Image.open(src).convert('RGB')).astype(np.float32)/255
    H,W,_=img.shape; out=np.zeros((H*4,W*4,3),np.float32)
    t=torch.from_numpy(img).permute(2,0,1)[None]
    with torch.no_grad():
        for y in range(0,H,tile):
            for x in range(0,W,tile):
                y0,x0=max(y-pad,0),max(x-pad,0); y1,x1=min(y+tile+pad,H),min(x+tile+pad,W)
                o=net(t[:,:,y0:y1,x0:x1])[0].permute(1,2,0).numpy()
                ty,tx=min(tile,H-y),min(tile,W-x)
                out[y*4:(y+ty)*4,x*4:(x+tx)*4]=o[(y-y0)*4:(y-y0+ty)*4,(x-x0)*4:(x-x0+tx)*4]
    Image.fromarray((out.clip(0,1)*255+0.5).astype(np.uint8)).save(dst)
if __name__=='__main__': upscale(*sys.argv[1:4])
