import sys,json,numpy as np
sys.path.insert(0,'tools/recon')
from head_data import *
def fit_circle(pts):
    p=np.array(pts,float);A=np.c_[2*p[:,0],2*p[:,1],np.ones(len(p))];b=(p**2).sum(1)
    s=np.linalg.lstsq(A,b,rcond=None)[0];cx,cy=s[:2];r=np.sqrt(s[2]+cx*cx+cy*cy);return cx,cy,r
def ang(a,b): return float(np.degrees(np.arctan2(-(b[1]-a[1]),b[0]-a[0])))  # deg CCW from +x (screen right), up positive
def d(a,b): return float(np.hypot(b[0]-a[0],b[1]-a[1]))
M={}
# horn A
ua=POLY['horn_A_upper_arc'][3:12]; cx,cy,r=fit_circle(ua); M['horn_A_upper_arc_circle']=dict(centre_src=[round(cx),round(cy)],radius_px=round(r),radius_L=round(r/L,3))
ub=POLY['horn_A_underside_arc'][2:12]; cx,cy,r=fit_circle(ub); M['horn_A_underside_arc_circle']=dict(centre_src=[round(cx),round(cy)],radius_px=round(r),radius_L=round(r/L,3))
M['horn_A_shaft']=dict(width_px=87,width_L=round(87/L,3),left_edge_x=[860,858],axis_deg_from_vertical='left edge x 846@y250 -> 866@y518 (leans ~4 deg: top further LEFT); right edge x 945 vertical y356-444',length_px=round(d((885,533),(870,215))),length_L=round(d((885,533),(870,215))/L,3),base_to_elbow='knob (885,533) to elbow (870,215)')
M['horn_A_arm']=dict(chord_elbow_to_topknob_px=round(d((870,215),(1138,96))),angle_deg_up=round(ang((870,215),(1138,96)),1),chord_L=round(d((870,215),(1138,96))/L,3))
M['horn_A_distal']=dict(chord_knob_to_claw_px=round(d((1138,96),(1394,191))),angle_deg=round(ang((1138,96),(1394,191)),1),chord_L=round(d((1138,96),(1394,191))/L,3),segment_thickness_px=30)
M['horn_A_total_extent']=dict(span_x_L=round((1394-846)/L,3),span_y_L=round((544-96)/L,3),total_height_above_crown_L=round((544-96)/L,3))
M['horn_A_spur']=dict(length_px=round(d((1000,250),(1081,300))),tip=(1081,300),angle_deg=round(ang((1000,250),(1081,300)),1))
# horn B
M['horn_B_outer_arc_circle']=dict(zip(['cx','cy','r_px'],[round(v) for v in fit_circle(POLY['horn_B_outer'][3:17])]))
M['horn_B']=dict(shaft_width_px=42,shaft_width_L=round(42/L,3),top_knob=(766,259),elbow_left=(626,493),height_span_L=round((641-259)/L,3),left_extreme_L_from_origin=round((626-811)/L,3),
  upper_shaft_direction_deg=round(ang((714,454),(756,307)),1),lower_arm_direction_deg=round(ang((746,641),(660,545)),1),
  elbow_to_root_chord_px=round(d((628,500),(880,610))),)
# crown, blade D
M['blade_D']=dict(base=(1131,543),apex=(1241,429),length_px=round(d((1131,543),(1241,429))),length_L=round(d((1131,543),(1241,429))/L,3),angle_deg=round(ang((1131,543),(1241,429)),1))
M['stub_E']=dict(root=(1255,480),tip=(1319,480),length_L=round(64/L,3),thickness_px=28)
M['spike_C']=dict(height_px=round(541-488),width_px=25,tip=(1025,488),lean='near vertical, slight right lean')
M['blade_F']=dict(tip=(773,704),root=(866,690),length_px=round(d((773,704),(866,690))),length_L=round(d((773,704),(866,690))/L,3),angle_deg=round(ang((866,690),(773,704)),1),thickness_px_at_mid=22,note='tip droops slightly below root: points left and ~8 deg DOWN')
# snout
M['snout']=dict(tip_to_eye_px=round(d((811,780),(1022,638))),tip_to_eye_L=round(d((811,780),(1022,638))/L,3),tip_to_eye_angle_deg=round(ang((811,780),(1022,638)),1),
  snout_tip_to_gape_apex_px=round(d((811,780),(1009,746))),ventral_edge_angle_deg=round(ang((854,822),(1009,746)),1),
  ventral_edge_mean_slope_deg_hook_bottom_to_apex=round(ang((854,822),(1009,746)),1),
  hook_height_px=round(822-775),hook_height_L=round((822-775)/L,3),hook_length_px=round(906-811),
  dorsal_edge_vertical_step_px=round(740-705),
  hook_underside_circle=dict(zip(['cx','cy','r_px'],[round(v) for v in fit_circle([(813,787),(821,794),(830,809),(841,819),(854,822),(869,813)])])))
M['head_extents']=dict(L_px=L,eye_to_tip_u=round((1022-811)/L,3),eye_centre_norm=norm((1022,638)),crown_top_v=round((780-544)/L,3),eye_above_tip_v=round((780-638)/L,3),
  head_core_height_L=round((879-544)/L,3),horn_A_top_v=round((780-96)/L,3),fringe_tip_u=1.0,blade_D_apex_norm=norm((1241,429)),horn_B_top_norm=norm((766,259)),claw_tip_norm=norm((1394,191)),horn_B_left_norm=norm((626,493)),horn_A_elbow_norm=norm((846,235)))
M['neck']=dict(front_edge_at_y=dict(y850=[1036,1256],y879=[1048,1260]),width_at_y850_px=220,width_L=round(220/L,3),axis='near vertical; front edge slants x 1047->1035->1048; back edge x 1242->1256->1260 (leans/widens downward-right)',attach='neck column (red 88/74) meets head under cream fringe strands at y~745-766; throat gape apex at (1009,746)')
M['fringe']=dict(long_streak_angle_deg=round(ang((1262,609),(1444,626)),1),long_streak_len_L=round(d((1262,612),(1444,630))/L,3),upper_strand_tip=(1301,594),lock_tip=(1410,686),lower_lobe_tip=(1295,745),cream_strands_angle_deg=round(ang((1130,640),(1215,745)),1))
M['cheek_black_mass']=dict(bbox_src=[1030,711,1169,789],note='black mass sits BELOW red plate (region 4/71 lower edge) between throat gape and red neck column; continues down as neck dark side')
print(json.dumps(M,indent=1,default=str)); json.dump(M,open('design/model_sheets/aruun/recon/analyst/head_measurements.json','w'),indent=1,default=str)
