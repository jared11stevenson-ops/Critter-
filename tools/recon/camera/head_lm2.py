#!/usr/bin/env python3
"""Face-landmark head orientation (horns excluded: model horn directions are known to differ from the art). Scaled-orthographic, rigid 3 DOF + scale + shift.
Starts from the pure-profile hypothesis (camera at his LEFT side) and reports the refined rotation, then writes IoU of the rendered head vs the ref head silhouette."""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from head_lm import *
fw = P['H7_fringe_wing_L'][0]; FRINGE = fw[np.argmin(fw[:, 2])]
LMS = [  # name, model point, hero px, weight
 ('eye',        ctr('H7_eye_L'),      (1017, 636), 1.0),
 ('snout_hook', MAND_TIP,             (815, 782),  1.0),
 ('cupB',       BASE_B,               (920, 580),  0.5),
 ('cupA',       BASE_A,               (885, 640),  0.5),
 ('fringe_rear', FRINGE,              (1440, 640), 0.5),
]
def run(landmarks=LMS, yaw_range=range(60, 125, 15)):
    X = np.array([l[1] for l in landmarks]) - PIV; ref = np.array([l[2] for l in landmarks], float); w = np.array([l[3] for l in landmarks])
    def res(q):
        R = Rot.from_rotvec(q[:3]).as_matrix(); s = np.exp(q[3]); uv = (X @ R.T)[:, :2] * s * np.array([1, -1]) + q[4:6]
        return ((uv - ref) * w[:, None]).ravel()
    # camera at his LEFT looking -X: right axis = -Z, down = -Y, fwd = -X : rows of R (world->cam)
    R0 = np.array([[0, 0, -1], [0, -1, 0], [-1, 0, 0]], float)     # proper rotation? det
    sols = []
    for yaw in yaw_range:
        for pit in (-30, 0, 30):
            for rol in (-30, 0, 30):
                Rr = Rot.from_euler('yxz', [yaw - 90, pit, rol], degrees=True).as_matrix()
                # model->image-camera : image x=cam x ; use R_total = Rr @ (view where model +Z faces screen-left)
                Rv = np.array([[0, 0, -1], [0, 1, 0], [1, 0, 0]], float)          # model +Z -> screen -x (image x = -z ...): x_c = -z, y_c(up)=y, depth=x
                Rt = Rr @ Rv
                q0 = np.concatenate([Rot.from_matrix(Rt).as_rotvec(), [np.log(1800), *ref.mean(0)]])
                r = least_squares(res, q0); sols.append(r)
    sols.sort(key=lambda r: r.cost)
    return sols, res, Rv
if __name__ == '__main__':
    sols, res, Rv = run()
    for r in sols[:6]:
        R = Rot.from_rotvec(r.x[:3]).as_matrix(); Rrel = R @ Rv.T
        print('rms', np.sqrt(r.cost * 2 / 5).round(1), 'scale', np.exp(r.x[3]).round(0), 'euler yxz rel. to pure left-profile (yaw,pitch,roll)', Rot.from_matrix(Rrel).as_euler('yxz', degrees=True).round(1))
