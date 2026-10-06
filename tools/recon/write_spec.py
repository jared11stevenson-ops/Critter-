import json,sys
sys.path.insert(0,'tools/recon')
from head_data import LM,L,ORIGIN,norm
OUT='design/model_sheets/aruun/recon/analyst/'
neg=json.load(open(OUT+'head_negative_space.json'))['gaps']
hero=json.load(open(OUT+'hero_landmarks.json'));hn=json.load(open(OUT+'hero_negative_space.json'))['pockets']
M=json.load(open(OUT+'head_measurements.json'))
lt='\n'.join('| %d | %s | (%d, %d) | (%.3f, %.3f) | %s | %s |'%(i,n,p[0],p[1],*norm(p),k,nt) for i,n,p,k,nt in LM)
nt='\n'.join('| %s | %s | %d | %.4f | %.3f x %.3f | %.3f |'%(g['id'],g['name'],g['area_px'],g['area_L2'],g['bbox_norm_w'],g['bbox_norm_h'],g['mean_width_L']) for g in neg)
ht='\n'.join('| %d | %s | (%d, %d) | (%.3f, %.3f) | %s |'%(l['id'],l['name'],l['src'][0],l['src'][1],l['norm'][0],l['norm'][1],l['kind']) for l in hero['landmarks'])
hp='\n'.join('| %s | %d | %.4f | %s |'%(p['label'],p['area_px'],p['area_H2'],p['bbox_src']) for p in hn)
md=open('tools/recon/spec_template.md').read().replace('@@LM@@',lt).replace('@@NEG@@',nt).replace('@@HLM@@',ht).replace('@@HNEG@@',hp)
open(OUT+'REFERENCE_SPEC.md','w').write(md)
