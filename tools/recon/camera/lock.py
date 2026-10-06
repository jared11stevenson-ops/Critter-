#!/usr/bin/env python3
"""Compose design/model_sheets/aruun/recon/camera/LOCKED_CAMERAS.json from the hero body solve (BODY.json, from lock_body_hero.py) and the head face-landmark solve.
usage: lock.py BODY.json OUT.json"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ortho_cams import *
from solve_hero import LM, Ry, make_cam
import head_lm2
from scipy.spatial.transform import Rotation as Rot

bj = json.load(open(sys.argv[1])); p = np.array(bj['p'])
d, h, phi, f, cx, cy, yaw, tw, fl, fr = p
cam_w = make_cam(p, None)                                   # world camera: model rotated by Ry(yaw) (hips) in front of it
HW, HH = 1891, 4096
CROP = (606, 76, 859, 856)                                   # head tile = exact crop of the hero image (matchTemplate score 1.0000 at scale 1.0)
def entry(cam, **kw):
    e = cam.to_dict(); e.update(kw); return e
hero = entry(cam_w, name='HERO', model_T=dict(R=Ry(yaw).tolist(), pivot=[0, 0, 0], t=[0, 0, 0], note='rest model rotated by root yaw about vertical axis through the origin (between the feet) BEFORE the camera; folded into C,R when loaded'),
             target_model=[0, 1.2, 0], landmarks_ref_px={n: list(map(float, px)) for n, g, px, X, w in LM},
             blender_camera=to_blender(Cam(Ry(yaw).T @ cam_w.C, cam_w.R @ Ry(yaw), f, cx, cy, HW, HH)))
cam_h = Cam(cam_w.C, cam_w.R, f, cx - CROP[0], cy - CROP[1], CROP[2], CROP[3])
head_lm = {n: [px[0] - CROP[0], px[1] - CROP[1]] for n, m, px, w in head_lm2.LMS}
head = entry(cam_h, name='HEAD', model_T=hero['model_T'], target_model=head_lm2.PIV.tolist(), landmarks_ref_px=head_lm, crop_of_hero_px=dict(x0=CROP[0], y0=CROP[1], w=CROP[2], h=CROP[3]),
             blender_camera=to_blender(Cam(Ry(yaw).T @ cam_h.C, cam_h.R @ Ry(yaw), f, cx - CROP[0], cy - CROP[1], CROP[2], CROP[3])))
cams = {'HERO': hero, 'HEAD': head}
for v in ('side', 'back', 'front'):
    c = ortho(v); cams[{'side': 'SIDE', 'back': 'BACK', 'front': 'FRONT_ORTHO'}[v]] = entry(c, name=v, target_model=[0, 1.2, 0], blender_camera=to_blender(c),
        note='identical to tools/fidelity/render_model_views.py (PPM 1626.667, ground row 4000); reference window without the 1200 px pad')
for v, W, ax in (('side', 1147, 536.0), ('back', 1659, 759.0)):        # FID_REF=v2 completed tiles
    c = ortho(v); c.W, c.cx = W, ax; cams[v.upper() + '_V2'] = entry(c, name=v + '_v2', target_model=[0, 1.2, 0], blender_camera=to_blender(c), note='creator-approved v2 completed side/back tiles (fid_common.V2)')
# head pose (face landmarks) relative to the torso rest frame
sols, res, Rv = head_lm2.run(); q = sols[0].x
Rt = Rot.from_rotvec(q[:3]).as_matrix()
Rrel = Ry(yaw).T @ Rt                                   # camera-pitch-0 => R_body = diag(1,-1,-1) Ry(yaw+tw)
Rrel_prof = Ry(yaw).T @ Rv
eul = Rot.from_matrix(Rrel).as_euler('yxz', degrees=True)
prof = Rot.from_matrix(Rrel_prof).as_euler('yxz', degrees=True)
L = dict(version=1, frame='model frame: +Y up, character faces +Z, his LEFT = +X, metres; world->cam Xc=R(X-C), OpenCV axes (x right, y down, z fwd). Entries are rest-pose cameras: root yaw already folded in.',
         cameras=cams,
         hero_solution=dict(distance_m=d, cam_height_m=h, pitch_deg=float(np.rad2deg(phi)), roll_deg=0.0, f_px=f, px_per_m_at_target=f / d, principal_point_px=[cx, cy],
                            root_yaw_deg=float(np.rad2deg(yaw)), torso_twist_deg=float(np.rad2deg(tw)), foot_yaw_L_deg=float(np.rad2deg(fl)), foot_yaw_R_deg=float(np.rad2deg(fr)),
                            landmark_rms_px=bj['rms_px'], landmark_rms_pct_fig_height=bj['rms_px'] / 3904 * 100, residuals_px=bj['residuals']),
         head_pose=dict(method='5 face landmarks (eye_L, mandible hook, horn cups x2, fringe rear), scaled-ortho 3-DOF rotation + scale + shift, multi-start from pure left profile',
                        rms_px=float(np.sqrt(sols[0].cost * 2 / 5)), apparent_px_per_m=float(np.exp(q[3])), euler_yxz_deg_rel_torso=dict(yaw=eul[0], pitch=eul[1], roll=eul[2]), pure_profile_euler_rel_torso=dict(yaw=prof[0], pitch=prof[1], roll=prof[2]),
                        R_rel_torso=Rrel.tolist(), pivot_model=head_lm2.PIV.tolist(), pivot_px_target_hero=[float(q[4]), float(q[5])], off_pure_left_profile_euler_yxz_deg=Rot.from_matrix(Rt @ Rv.T).as_euler('yxz', degrees=True).tolist(),
                        scale_sensitivity_note='yaw/pitch/roll rel. torso vs assumed head px/m (rms px): 1626:(-15.3,-2.2,14.5)37.0 | 1700:(-14.2,-2.6,15.1)34.5 | 1800:(-12.7,-3.1,15.9)32.1 | 1946(free):(-10.5,-3.7,17.0)30.7; head is ~42-46 deg OFF pure profile in every case',
                        warning='horns excluded from the fit: the modelled horns (A up+forward, B sideways) do not resemble the art horns (both sweep back/up in the head plane), so silhouette IoU of the horn region is meaningless until the horns are rebuilt'))

DOC = dict(
 summary="HERO and HEAD are ONE camera: design/reference_packs/aruun/head/aruun_head_front.png is an exact 1:1 pixel crop of aruun_front_4096.png at (x0=606,y0=76,859x856) (normalised cross-correlation 1.0000 at scale 1.0). detail_head.png tile 2 is the same crop upscaled for the sheet. So there is no independent head camera; the head pose is a POSE of the hero image.",
 hero_chosen="level pinhole camera (pitch 0, roll 0) at distance 8.0 m, height 0.9 m, f=13644 px on a 1891x4096 frame with lens shift (principal point 1072,2442), i.e. 1705 px/m at the character, hFOV 7.9 deg / vFOV 17.0 deg (a telephoto-ish, mildly perspective view). Character (hips) yaw -38.1 deg: he faces screen-LEFT, camera is on his front-LEFT, his left pauldron is nearest the lens.",
 hero_ambiguity=dict(
   perspective_strength="NOT determined by the body landmarks. Fit rms over camera distance d in {2.5..30 m} and camera height h in {0.3..1.5 m} stays 105-123 px (the cost surface is flat to ~15 %): perspective is a free choice inside that range; d=8 m was chosen as the mid value (limit d>=3.5 m keeps feet/head size ratio sane). Bounded prior f/d in [1400,2100] px/m.",
   elevation="pitch -11..+6 deg across the whole d,h grid; level (0) chosen, framing carried by lens shift (pitch and shift are degenerate for a cropped cut-out). The brief's 'low camera' is NOT supported by the numbers: the near foot sole sits ~150 px lower than the far foot, which needs h*dz/d ~ 0.1..0.2 m, i.e. camera height 0.3-1.5 m is allowed but a strongly upward-looking camera (pitch>+10) fits worse. Treat the low-angle read as unproven.",
   yaw="-20 deg (torso twist -51 deg, belt on torso) .. -38 deg (twist ~+4 deg, belt on hips); hips-yaw -38 / twist 0 chosen (lower, simpler, pauldron error 18 px). Chest in the art reads MORE turned than hips (contrapposto).",
   roll="0 (no evidence of roll; ground contact lines of the far foot are horizontal)"),
 residuals="landmark rms 153.8 px = 3.94 % of figure height (3904 px) over 13 pairs; rigid subset (toe tips, heel, ankles, pauldron, belt buckle, medallion) 100 px = 2.6 %; dominated by pose differences (stance width, torso twist), not by camera. Worst: ankleL 134 px, buckle 119, medallion 136, elbowL 166 (arm pose), footL width 270 (art boots wider than model).",
 rest_pose_render_note="entries are rest-pose cameras: rendering the rest model with HERO gives IoU ~0.56 with the art silhouette; the gap is POSE (arms, neck, torso, stance), plus model neck/horn shapes - not camera. Use --head-pose to apply the solved head orientation.",
 pose_targets=dict(
   hips_yaw_deg=-38.1, note_sign="rotation about +Y; negative = body turned to face screen-left / his right",
   torso_twist_deg="~0 (range -51..+4): chest reads more turned than hips",
   foot_L_yaw_abs_deg="~+20 (toes toward camera, slightly screen-right); fitted rel. hips +59, poor fit",
   foot_R_yaw_abs_deg="-45..-80 (toe points screen-left, foot seen side-on); fitted rel. hips -8, poor fit (toe tip 87 px off)",
   weight_shift="near/left leg (screen-right) planted, knee flexed forward (ref knee row 0.74 m vs model 0.62 m); far/right leg (screen-left) back and out, shin vertical",
   right_arm="abducted ~60 deg from the torso and swung forward, elbow flexed ~70 deg, forearm pointing down-screen-left, hand open/claws at row 2480 x 130 (ref px) - reaches ~0.9 m left of the body axis",
   left_arm="hangs, elbow flexed ~45 deg forward, fist at hip height (row ~2440, 0.96 m); elbow disc at row 1917 (1.28 m)",
   neck="leans: base near x=1050,y=1450 up to head at x~1000,y=700 in the art; art shoulders sit ~100 px (~0.06 m) lower than the rest model, i.e. slight forward slouch/bend of upper spine ~10 deg",
   head="yaw rel. torso -7..-15 deg (towards his right), pitch ~-3, roll ~+15..17 deg (nose-down tilt in the image plane); equivalent to 42-46 deg OFF pure left profile - not a pure profile (second horn visible separately). Art head is ~14 % larger than the model head at the same depth (apparent 1946 vs 1700 px/m) -> head model is under-scaled or the art exaggerates it",
   horns="model horn A/B directions do not match: art horns sweep up then back (big horn tip at hero px 1390,185; small horn tip 780,270) while the model horns go up+forward / sideways"),
 fidelity_tool_bug="tools/fidelity/render_model_views.py drop_mace() deletes legR.001 (1760 faces, min x -0.471 < right_limit -0.46) from this model, so side/back/front sil/clay renders from that tool have no right leg (back IoU 0.92 vs 0.996 with the leg removed in both). render_locked.py never drops anything.",
 ortho_verification="SIDE/BACK ortho cameras re-derived from the tool: render of this model matches the tool's silhouette at IoU 0.989 (side) / 0.996 (back, tool with legR dropped) - remaining diff is the head_v7 swap; vs the reference silhouettes the current model scores IoU 0.888 (side) / 0.892 (back). Conventions: side = camera at his right looking +X, image-right = forward (+Z); back = behind, image-right = his right (-X); both 1626.667 px/m, ground row 4000, axis columns 436 (side) / 659 (back) in the 947 / 1459 px wide reference windows (v2 tiles: 536 / 759 in 1147 / 1659 px).",
 how_to="python3 tools/recon/camera/render_locked.py [MODEL.glb|.blend] --out DIR [--cams HERO HEAD SIDE BACK] [--diag HERO ...] [--head-pose]; per camera: clay_, sil_ (black on white), overlay_ (RGBA), vsref_ (outlines on ref), composite_ , *_info.json (IoU). Diagnostic (+-30 yaw/pitch) cameras write half-res diag_*.png only.",
 no_blender_note="Blender is not installed in this environment; the renders are produced by a numpy/OpenCV painter rasteriser (flat shading). Each camera also carries blender_camera (location, rotation_euler XYZ, lens_mm @36 mm sensor width, shift_x/y or ortho scale) for use inside Blender; the HERO values already include the root-yaw (camera orbit around the un-rotated model). NOT yet verified inside Blender.")
L['documentation'] = DOC
json.dump(L, open(sys.argv[2], 'w'), indent=1); print(json.dumps({k: L[k] for k in ('hero_solution', 'head_pose')}, indent=1)[:3000])
