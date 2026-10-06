"""Lineup of all head views on the shared landmark rows (<=2400 px wide)."""
from PIL import Image, ImageDraw
OUT='design/reference_gen/aruun/'
names=['profile_left','front_straighton','rage_straighton','focused_34','aggressive_34','side','back']
import place
CW=1300; crop=(100,150,1400,2300)
tiles=[Image.open(OUT+f'head/aruun_head_{n}.png').crop(crop) for n in names]
S=Image.new('RGB',(CW*len(tiles),crop[3]-crop[1]),place.CREAM); d=ImageDraw.Draw(S)
for i,t in enumerate(tiles): S.paste(t,(i*CW,0))
for k in place.M:
    y=place.row(k)-crop[1]; d.line([(0,y),(S.width,y)],fill=place.COL[k],width=3); d.text((8,y-14),f'{k} {place.M[k]:.3f} m',fill=place.COL[k])
for i,n in enumerate(names): d.text((i*CW+20,20),n,fill=(30,20,20))
f=2400/S.width; S=S.resize((2400,int(S.height*f)),Image.LANCZOS); S.save(OUT+'head/aruun_head_lineup_landmarks.png'); print(S.size)
