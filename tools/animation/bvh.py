"""Minimal BVH reader + numpy forward kinematics (no Blender needed).

Coordinates are converted on load from BVH (Y up, actor faces +Z, actor's left = +X) to the CRITTER rig frame
(Blender armature space: Z up, character faces -Y, character's left = +X): (x, y, z) -> (x, -z, y).
"""
import numpy as np

# BVH -> rig frame (proper rotation, +90 deg about X)
C = np.array([[1, 0, 0], [0, 0, -1], [0, 1, 0]], dtype=np.float64)


def _rot(axis, ang):
    c, s = np.cos(ang), np.sin(ang)
    n = len(ang)
    R = np.zeros((n, 3, 3))
    i = "XYZ".index(axis)
    j, k = [(1, 2), (2, 0), (0, 1)][i]
    R[:, i, i] = 1
    R[:, j, j] = c
    R[:, k, k] = c
    R[:, j, k] = -s
    R[:, k, j] = s
    return R


class BVH:
    def __init__(self, path):
        self.names, self.parent, self.offset, self.channels, self.end = [], [], [], [], {}
        with open(path) as f:
            tok = f.read().split()
        i = 0
        stack = []
        cur = -1
        while tok[i] != "MOTION":
            t = tok[i]
            if t in ("ROOT", "JOINT"):
                self.names.append(tok[i + 1])
                self.parent.append(stack[-1] if stack else -1)
                self.offset.append([0, 0, 0])
                self.channels.append([])
                cur = len(self.names) - 1
                i += 2
            elif t == "End":
                cur = ("end", stack[-1])
                i += 2
            elif t == "{":
                stack.append(cur)
                i += 1
            elif t == "}":
                stack.pop()
                i += 1
            elif t == "OFFSET":
                o = [float(x) for x in tok[i + 1:i + 4]]
                if isinstance(stack[-1], tuple):
                    self.end[stack[-1][1]] = o
                else:
                    self.offset[stack[-1]] = o
                i += 4
            elif t == "CHANNELS":
                n = int(tok[i + 1])
                self.channels[stack[-1]] = tok[i + 2:i + 2 + n]
                i += 2 + n
            else:
                i += 1
        n_frames = int(tok[i + 2])
        self.dt = float(tok[i + 5])
        data = np.array(tok[i + 6:], dtype=np.float64)
        nch = sum(len(c) for c in self.channels)
        self.data = data[: n_frames * nch].reshape(n_frames, nch)
        self.offset = np.array(self.offset)
        self.index = {n: k for k, n in enumerate(self.names)}

    @property
    def fps(self):
        return 1.0 / self.dt

    def fk(self, frames=None, scale=1.0):
        """Global rotations (F,J,3,3) and positions (F,J,3) in the rig frame (metres if scale is m/unit)."""
        D = self.data if frames is None else self.data[frames]
        F, J = len(D), len(self.names)
        Rg = np.zeros((F, J, 3, 3))
        Pg = np.zeros((F, J, 3))
        col = 0
        for j in range(J):
            R = np.tile(np.eye(3), (F, 1, 1))
            pos = np.tile(self.offset[j], (F, 1)).astype(np.float64)
            for ch in self.channels[j]:
                v = D[:, col]
                col += 1
                if ch.endswith("rotation"):
                    R = R @ _rot(ch[0], np.radians(v))
                else:
                    pos[:, "XYZ".index(ch[0])] = v + (0 if self.parent[j] == -1 else 0)
            p = self.parent[j]
            if p < 0:
                Rg[:, j] = R
                Pg[:, j] = pos
            else:
                Rg[:, j] = Rg[:, p] @ R
                Pg[:, j] = Pg[:, p] + np.einsum("fij,fj->fi", Rg[:, p], pos)
        # convert frame: positions p' = C p ; rotations R' = C R C^T
        Pg = np.einsum("ij,fkj->fki", C, Pg) * scale
        Rg = np.einsum("ij,fkjl,ml->fkim", C, Rg, C)
        return Rg, Pg

    def end_offset(self, name):
        return C @ np.array(self.end.get(self.index[name], [0, 0, 0]))

    def resample(self, fps_out=30):
        """Return a copy resampled to fps_out (nearest frame; mocap at 120 fps -> every 4th frame)."""
        step = self.fps / fps_out
        idx = np.round(np.arange(0, len(self.data) - 1e-6, step)).astype(int)
        idx = idx[idx < len(self.data)]
        out = object.__new__(BVH)
        out.__dict__.update(self.__dict__)
        out.data = self.data[idx]
        out.dt = 1.0 / fps_out
        return out

    def write(self, path, frames, src_path):
        """Write a trimmed copy (header copied verbatim from src_path)."""
        with open(src_path) as f:
            txt = f.read()
        head = txt[: txt.index("MOTION")]
        with open(path, "w") as f:
            f.write(head)
            f.write("MOTION\nFrames: %d\nFrame Time: %.7f\n" % (len(frames), self.dt))
            for r in self.data[frames]:
                f.write(" ".join("%.4f" % x for x in r) + "\n")
