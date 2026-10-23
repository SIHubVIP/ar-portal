"""Offline generator of the «Новый облик» character bodies.

Smooth SDF sculpt -> marching cubes -> quadric decimation -> skin weights -> binary for Godot.
Coordinates: character root space, faces +Z, Y up, same pivots as Chars.human() (w = 1):
  body (0,0,0) · head (0,1.6,0) · arm A/B (∓0.45,1.2,0) · elbow (0,-0.28,0) local · leg A/B (∓0.17,0.62,0) · knee (0,-0.26,0) local
Side A is x < 0 (arms[0], legs[0]); side B is x > 0.
"""
import struct
import sys

import numpy as np
from skimage import measure

from decimate import decimate

# ---------------------------------------------------------------- bones
BONES = ["body", "head", "arm_a", "elbow_a", "arm_b", "elbow_b", "leg_a", "knee_a", "leg_b", "knee_b"]
B = {n: i for i, n in enumerate(BONES)}

# ---------------------------------------------------------------- regions (colours are picked at runtime)
REGIONS = ["skin", "top", "sleeve", "trim", "detail", "pants", "pants_trim", "shoe", "sole", "lace", "skirt", "cuff"]
R = {n: i for i, n in enumerate(REGIONS)}


# ---------------------------------------------------------------- SDF primitives (vectorised over p: (N,3))
def ellipsoid(p, c, r):
    q = (p - c) / r
    k0 = np.linalg.norm(q, axis=1)
    k1 = np.linalg.norm(q / r, axis=1)
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def round_cone(p, a, b, ra, rb):
    """Capsule with different radii at a and b (good enough approximation)."""
    ba = b - a
    pa = p - a
    t = np.clip((pa @ ba) / (ba @ ba), 0.0, 1.0)
    r = ra + (rb - ra) * t
    return np.linalg.norm(pa - np.outer(t, ba), axis=1) - r


def round_box(p, c, half, rad):
    q = np.abs(p - c) - (half - rad)
    return np.linalg.norm(np.maximum(q, 0.0), axis=1) + np.minimum(np.max(q, axis=1), 0.0) - rad


def ring_y(p, c, rx, rz, r):
    """Elliptical torus around the Y axis (a hem / collar / cuff)."""
    q = p - c
    e = np.sqrt((q[:, 0] / rx) ** 2 + (q[:, 2] / rz) ** 2)
    d_ell = (e - 1.0) * min(rx, rz)
    return np.sqrt(d_ell ** 2 + q[:, 1] ** 2) - r


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b * (1 - h) + a * h - k * h * (1 - h)


# ---------------------------------------------------------------- the body
def prims(skirt: bool):
    """Returns list of (name, group, side, fn). group decides region + skinning chain."""
    P = []
    v = np.array

    def add(name, group, side, fn):
        P.append((name, group, side, fn))

    # torso (hoodie) + pelvis (pants)
    add("chest", "torso", 0, lambda p: ellipsoid(p, v([0, 1.05, 0.0]), v([0.33, 0.22, 0.225])))
    add("belly", "torso", 0, lambda p: ellipsoid(p, v([0, 0.85, 0.012]), v([0.305, 0.2, 0.218])))
    add("pelvis", "torso", 0, lambda p: ellipsoid(p, v([0, 0.665, -0.005]), v([0.285, 0.15, 0.2])))
    add("hem", "hem", 0, lambda p: ring_y(p, v([0, 0.715, 0.008]), 0.292, 0.207, 0.028))
    add("pocket", "pocket", 0, lambda p: pocket_sdf(p))
    add("collar", "collar", 0, lambda p: ring_y(p, v([0, 1.245, -0.005]), 0.115, 0.105, 0.034))
    add("neck", "neck", 0, lambda p: round_cone(p, v([0, 1.16, -0.01]), v([0, 1.37, 0.0]), 0.085, 0.08))
    for s, side in ((-1, 1), (1, 2)):
        x = 0.45 * s
        add("shoulder", "shoulder", side, lambda p, x=x: ellipsoid(p, v([x * 0.8, 1.155, 0.0]), v([0.138, 0.122, 0.13])))
        add("upperarm", "upperarm", side, lambda p, x=x: round_cone(p, v([x, 1.17, 0]), v([x * 1.01, 0.92, -0.005]), 0.108, 0.094))
        add("forearm", "forearm", side, lambda p, x=x: round_cone(p, v([x * 1.01, 0.92, -0.005]), v([x * 1.02, 0.715, 0.01]), 0.09, 0.078))
        add("cuff", "cuff", side, lambda p, x=x: round_cone(p, v([x * 1.02, 0.745, 0.008]), v([x * 1.02, 0.705, 0.01]), 0.089, 0.087))
        add("palm", "hand", side, lambda p, x=x: ellipsoid(p, v([x * 1.025, 0.615, 0.015]), v([0.06, 0.085, 0.074])))
        add("thumb", "hand", side, lambda p, x=x: round_cone(p, v([x * 1.025 - s * 0.03, 0.645, 0.05]), v([x * 1.025 - s * 0.045, 0.6, 0.088]), 0.03, 0.026))
        lx = 0.17 * s
        add("thigh", "thigh", side, lambda p, lx=lx: round_cone(p, v([lx * 0.97, 0.64, 0]), v([lx * 0.95, 0.36, 0.01]), 0.142, 0.118))
        add("shin", "shin", side, lambda p, lx=lx: round_cone(p, v([lx * 0.95, 0.36, 0.01]), v([lx * 0.95, 0.15, -0.01]), 0.113, 0.098))
        add("pcuff", "pcuff", side, lambda p, lx=lx: round_cone(p, v([lx * 0.95, 0.185, -0.008]), v([lx * 0.95, 0.15, -0.01]), 0.108, 0.107))
        add("shoe", "shoe", side, lambda p, lx=lx: round_box(p, v([lx * 0.95, 0.085, 0.055]), v([0.112, 0.07, 0.19]), 0.06))
        add("toe", "shoe", side, lambda p, lx=lx: ellipsoid(p, v([lx * 0.95, 0.075, 0.17]), v([0.11, 0.075, 0.1])))
        add("sole", "sole", side, lambda p, lx=lx: round_box(p, v([lx * 0.95, 0.022, 0.06]), v([0.122, 0.022, 0.205]), 0.018))
    # head
    add("skull", "head", 0, lambda p: ellipsoid(p, v([0, 1.6, 0]), v([0.35, 0.34, 0.33])))
    add("cheeks", "head", 0, lambda p: ellipsoid(p, v([0, 1.5, 0.06]), v([0.28, 0.2, 0.26])))
    add("nose", "nose", 0, lambda p: ellipsoid(p, v([0, 1.555, 0.335]), v([0.05, 0.045, 0.042])))
    for s, side in ((-1, 1), (1, 2)):
        add("ear", "head", side, lambda p, s=s: ellipsoid(p, v([0.335 * s, 1.6, -0.01]), v([0.045, 0.075, 0.06])))
    if skirt:
        add("skirt", "skirt", 0, lambda p: skirt_sdf(p))
    return P


def pocket_sdf(p):
    """Kangaroo pocket: a 1.2 cm raised patch on the belly (front only)."""
    v = np.array
    torso = smin(ellipsoid(p, v([0, 1.05, 0.0]), v([0.33, 0.22, 0.225])), ellipsoid(p, v([0, 0.85, 0.012]), v([0.305, 0.2, 0.218])), 0.12)
    shell = torso - 0.012
    qx = np.abs(p[:, 0]) - 0.15 + (p[:, 1] - 0.76) * 0.25
    qy = np.abs(p[:, 1] - 0.815) - 0.062
    q = np.stack([qx, qy], axis=1)
    rect = np.linalg.norm(np.maximum(q, 0.0), axis=1) + np.minimum(np.max(q, axis=1), 0.0) - 0.012
    front = 0.06 - p[:, 2]
    return np.maximum(np.maximum(shell, rect), front)


def skirt_sdf(p):
    """A flared skirt: cone from the waist (y 0.76) to the hem (y 0.16)."""
    y0, y1 = 0.78, 0.16
    t = np.clip((y0 - p[:, 1]) / (y0 - y1), 0.0, 1.0)
    rx = 0.3 + t * 0.14
    rz = 0.215 + t * 0.12
    e = np.sqrt((p[:, 0] / rx) ** 2 + ((p[:, 2] + 0.01) / rz) ** 2)
    d_side = (e - 1.0) * np.minimum(rx, rz) - 0.0
    d_cap = np.maximum(p[:, 1] - y0, y1 - p[:, 1])
    d = np.maximum(d_side, d_cap)
    return d - 0.012


def body_field(P, p, return_all=False):
    d = {}
    for name, group, side, fn in P:
        key = (name, side)
        d[key] = fn(p)
    g = lambda n, s=0: d[(n, s)]
    torso = smin(smin(g("chest"), g("belly"), 0.12), g("pelvis"), 0.1)
    torso = smin(torso, g("hem"), 0.012)
    torso = np.minimum(torso, g("pocket"))
    torso = smin(torso, g("neck"), 0.06)
    torso = smin(torso, g("collar"), 0.014)
    head = smin(g("skull"), g("cheeks"), 0.08)
    head = smin(head, g("nose"), 0.03)
    head = smin(head, g("ear", 1), 0.03)
    head = smin(head, g("ear", 2), 0.03)
    total = smin(torso, head, 0.05)
    for side in (1, 2):
        sh = g("shoulder", side)
        arm = smin(sh, g("upperarm", side), 0.05)
        arm = smin(arm, g("forearm", side), 0.04)
        arm = smin(arm, g("cuff", side), 0.01)
        hand = smin(g("palm", side), g("thumb", side), 0.02)
        arm = smin(arm, hand, 0.03)
        total = smin(total, sh, 0.07)        # the shoulder melts into the chest
        total = np.minimum(total, arm)       # the rest of the arm stays apart from the torso
        leg = smin(g("thigh", side), g("shin", side), 0.04)
        leg = smin(leg, g("pcuff", side), 0.01)
        shoe = smin(smin(g("shoe", side), g("toe", side), 0.05), g("sole", side), 0.012)
        leg = smin(leg, shoe, 0.03)
        hip = smin(torso, g("thigh", side), 0.05)
        total = np.minimum(total, hip)
        total = np.minimum(total, leg)
    if ("skirt", 0) in d:
        total = smin(total, g("skirt"), 0.02)
    if return_all:
        return total, d
    return total


# ---------------------------------------------------------------- mesh
def build(skirt: bool, h: float, target_tris: int):
    P = prims(skirt)
    lo = np.array([-0.62, -0.03, -0.5])
    hi = np.array([0.62, 2.0, 0.5])
    n = np.ceil((hi - lo) / h).astype(int) + 1
    xs = [lo[i] + np.arange(n[i]) * h for i in range(3)]
    X, Y, Z = np.meshgrid(*xs, indexing="ij")
    pts = np.stack([X.ravel(), Y.ravel(), Z.ravel()], axis=1)
    vol = np.empty(len(pts))
    for i in range(0, len(pts), 400000):
        vol[i:i + 400000] = body_field(P, pts[i:i + 400000])
    vol = vol.reshape(n)
    verts, faces, _, _ = measure.marching_cubes(vol, 0.0, spacing=(h, h, h), allow_degenerate=False)
    verts = verts + lo
    print("mc", len(verts), len(faces), file=sys.stderr)
    pre_region, _, _, _ = classify(P, verts)
    verts, faces = decimate(verts, faces, target_tris, pre_region)
    print("decimated", len(verts), len(faces), file=sys.stderr)
    # project vertices back onto the surface (a couple of Newton steps) and get smooth normals
    e = 1e-3
    for _ in range(2):
        f0 = body_field(P, verts)
        gr = grad(P, verts, e)
        verts = verts - gr * f0[:, None]
    nrm = grad(P, verts, e)
    nrm /= np.maximum(np.linalg.norm(nrm, axis=1, keepdims=True), 1e-9)
    # Godot: clockwise = front. Make every triangle agree with the outward normal.
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    avg_n = nrm[faces[:, 0]] + nrm[faces[:, 1]] + nrm[faces[:, 2]]
    flip = np.einsum("ij,ij->i", fn, avg_n) > 0
    faces[flip] = faces[flip][:, [0, 2, 1]]
    return P, verts, nrm, faces


def grad(P, p, e):
    out = np.zeros_like(p)
    for i in range(3):
        dp = np.zeros(3)
        dp[i] = e
        out[:, i] = (body_field(P, p + dp) - body_field(P, p - dp)) / (2 * e)
    return out


def classify(P, verts):
    """Nearest primitive -> group/side; then region and bone weights."""
    _, d = body_field(P, verts, return_all=True)
    keys = list(d.keys())
    D = np.stack([np.abs(d[k]) for k in keys], axis=1)
    near = np.argmin(D, axis=1)
    meta = {}
    for name, group, side, fn in P:
        meta[(name, side)] = (group, side)
    n = len(verts)
    region = np.zeros(n, dtype=np.int32)
    bones = np.zeros((n, 4), dtype=np.int32)
    weights = np.zeros((n, 4), dtype=np.float32)
    chain = np.zeros(n, dtype=np.int32)   # 0 torso/head, 1 arm A, 2 arm B, 3 leg A, 4 leg B (used for width at runtime)

    def ss(e0, e1, x):
        t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
        return t * t * (3 - 2 * t)

    for i in range(n):
        x, y, z = verts[i]
        group, side = meta[keys[near[i]]]
        w = {}
        reg = "top"
        sa = "a" if x < 0 else "b"
        if side == 1:
            sa = "a"
        elif side == 2:
            sa = "b"
        if group in ("torso", "hem", "collar", "pocket"):
            w["body"] = 1.0
            reg = "top"
            if group in ("hem", "collar"):
                reg = "trim"
            if y < 0.705 and group == "torso":
                reg = "pants"
                if y > 0.665:
                    reg = "pants_trim"
            if group == "pocket":
                reg = "detail"
            if y < 0.69 and abs(x) > 0.03:
                wl = float(ss(0.69, 0.55, y)) * 0.6 * float(ss(0.03, 0.14, abs(x)))
                w["body"] = 1.0 - wl
                w["leg_" + sa] = wl
            chain[i] = 0
        elif group == "neck":
            wh = float(ss(1.25, 1.36, y))
            w["head"] = wh
            w["body"] = 1.0 - wh
            reg = "skin"
        elif group in ("head", "nose"):
            w["head"] = 1.0
            reg = "skin"
            if group == "nose":
                reg = "skin"
        elif group == "shoulder":
            wa = float(ss(0.3, 0.43, abs(x)))
            w["arm_" + sa] = wa
            w["body"] = 1.0 - wa
            reg = "sleeve"
            chain[i] = 1 if sa == "a" else 2
        elif group == "upperarm":
            t = (1.2 - y) / 0.28
            wb = 0.45 * float(ss(0.12, -0.08, t))
            we = float(ss(0.8, 1.12, t))
            w["body"] = wb
            w["elbow_" + sa] = we
            w["arm_" + sa] = 1.0 - wb - we
            reg = "sleeve"
            chain[i] = 1 if sa == "a" else 2
        elif group in ("forearm", "cuff", "hand"):
            wa = 0.5 * float(ss(0.86, 0.96, y))
            w["arm_" + sa] = wa
            w["elbow_" + sa] = 1.0 - wa
            reg = {"forearm": "sleeve", "cuff": "cuff", "hand": "skin"}[group]
            chain[i] = 1 if sa == "a" else 2
        elif group == "thigh":
            t = (0.62 - y) / 0.26
            wb = 0.5 * float(ss(0.08, -0.2, t))
            wk = float(ss(0.8, 1.12, t))
            w["body"] = wb
            w["knee_" + sa] = wk
            w["leg_" + sa] = 1.0 - wb - wk
            reg = "pants"
            chain[i] = 3 if sa == "a" else 4
        elif group in ("shin", "pcuff", "shoe", "sole"):
            wl = 0.5 * float(ss(0.32, 0.4, y))
            w["leg_" + sa] = wl
            w["knee_" + sa] = 1.0 - wl
            reg = {"shin": "pants", "pcuff": "pants_trim", "shoe": "shoe", "sole": "sole"}[group]
            if group == "shoe" and y < 0.04:
                reg = "sole"
            chain[i] = 3 if sa == "a" else 4
        elif group == "skirt":
            wl = float(ss(0.62, 0.2, y)) * 0.55
            lean = float(ss(-0.12, 0.12, x))
            w["body"] = 1.0 - wl
            w["leg_b"] = wl * lean
            w["leg_a"] = wl * (1.0 - lean)
            reg = "skirt"
            if y < 0.2:
                reg = "pants_trim" if False else "skirt"
        items = sorted([(k, v) for k, v in w.items() if v > 1e-4], key=lambda kv: -kv[1])[:4]
        tot = sum(v for _, v in items)
        for j, (k, v) in enumerate(items):
            bones[i, j] = B[k]
            weights[i, j] = v / tot
        region[i] = R[reg]
    return region, chain, bones, weights


def write(path, verts, nrm, faces, region, chain, bones, weights):
    with open(path, "wb") as f:
        f.write(b"PSB1")
        f.write(struct.pack("<ii", len(verts), len(faces)))
        f.write(verts.astype("<f4").tobytes())
        f.write(nrm.astype("<f4").tobytes())
        f.write(region.astype("<i4").tobytes())
        f.write(chain.astype("<i4").tobytes())
        f.write(bones.astype("<i4").tobytes())
        f.write(weights.astype("<f4").tobytes())
        f.write(faces.astype("<i4").tobytes())


if __name__ == "__main__":
    out = sys.argv[1]
    h = float(sys.argv[2]) if len(sys.argv) > 2 else 0.018
    tris = int(sys.argv[3]) if len(sys.argv) > 3 else 5200
    for variant in ("pants", "skirt"):
        P, verts, nrm, faces = build(variant == "skirt", h, tris)
        region, chain, bones, weights = classify(P, verts)
        write("%s/body_%s.bin" % (out, variant), verts, nrm, faces, region, chain, bones, weights)
        print(variant, len(verts), len(faces), np.bincount(region, minlength=len(REGIONS)), file=sys.stderr)
