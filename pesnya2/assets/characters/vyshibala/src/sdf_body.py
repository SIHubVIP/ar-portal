"""Procedural SDF body for 'Вышибала' (~180 cm, muscular).
Z up, character faces -Y, meters. Outputs high-res meshes (npz) with vertex colors.
"""
import numpy as np
from skimage.measure import marching_cubes
from scipy import ndimage
import sys, time

RES = float(sys.argv[1]) if len(sys.argv) > 1 else 0.004
OUT = sys.argv[2] if len(sys.argv) > 2 else "body_high.npz"
rng = np.random.default_rng(7)

def V(*a):
    return np.array(a, dtype=np.float32)

def nrm(v):
    v = np.asarray(v, dtype=np.float32)
    return v / np.linalg.norm(v)

def frame(z, xhint):
    z = nrm(z)
    x = np.asarray(xhint, np.float32)
    x = nrm(x - z * np.dot(x, z))
    y = np.cross(z, x)
    return np.stack([x, y, z], axis=1)  # columns = local axes

# ---------------- grid ----------------
X0, X1 = 0.0, 0.62
Y0, Y1 = -0.26, 0.22
Z0, Z1 = -0.01, 1.85
xs = np.arange(X0 + RES / 2, X1, RES, dtype=np.float32)  # half grid, mirrored later
ys = np.arange(Y0, Y1, RES, dtype=np.float32)
zs = np.arange(Z0, Z1, RES, dtype=np.float32)
print("grid", len(xs), len(ys), len(zs))


class Field:
    def __init__(self, init=1.0):
        self.d = np.full((len(xs), len(ys), len(zs)), init, dtype=np.float32)

    def sub(self, lo, hi):
        i0 = max(0, np.searchsorted(xs, lo[0])); i1 = np.searchsorted(xs, hi[0])
        j0 = max(0, np.searchsorted(ys, lo[1])); j1 = np.searchsorted(ys, hi[1])
        k0 = max(0, np.searchsorted(zs, lo[2])); k1 = np.searchsorted(zs, hi[2])
        if i1 <= i0 or j1 <= j0 or k1 <= k0:
            return None
        sl = (slice(i0, i1), slice(j0, j1), slice(k0, k1))
        P = np.stack(np.meshgrid(xs[i0:i1], ys[j0:j1], zs[k0:k1], indexing="ij"), -1)
        return sl, P

    def add(self, prim, k=0.02, op="u"):
        lo, hi, fn = prim
        m = k + 0.01
        r = self.sub(lo - m, hi + m)
        if r is None:
            return
        sl, P = r
        b = fn(P)
        a = self.d[sl]
        if op == "u":
            self.d[sl] = smin(a, b, k)
        else:  # smooth subtraction
            self.d[sl] = -smin(-a, b, k)


def smin(a, b, k):
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0, 1)
    return b * (1 - h) + a * h - k * h * (1 - h)


def round_cone(a, b, r1, r2):
    a = V(*a); b = V(*b)
    ba = b - a; l2 = float(np.dot(ba, ba)); rr = r1 - r2; a2 = l2 - rr * rr; il2 = 1.0 / l2
    def fn(P):
        pa = P - a
        y = pa @ ba
        z = y - l2
        q = pa * l2 - y[..., None] * ba
        x2 = np.einsum("...i,...i->...", q, q)
        y2 = y * y * l2; z2 = z * z * l2
        k = np.sign(rr) * rr * rr * x2
        d3 = (np.sqrt(np.maximum(x2 * a2 * il2, 0)) + y * rr) * il2 - r1
        d1 = np.sqrt(x2 + z2) * il2 - r2
        d2 = np.sqrt(x2 + y2) * il2 - r1
        return np.where(np.sign(z) * a2 * z2 > k, d1, np.where(np.sign(y) * a2 * y2 < k, d2, d3)).astype(np.float32)
    rm = max(r1, r2)
    lo = np.minimum(a, b) - rm; hi = np.maximum(a, b) + rm
    return lo, hi, fn


def ellipsoid(c, r, R=None):
    c = V(*c); r = V(*r)
    R = np.eye(3, dtype=np.float32) if R is None else np.asarray(R, np.float32)
    def fn(P):
        q = (P - c) @ R
        k0 = np.linalg.norm(q / r, axis=-1)
        k1 = np.linalg.norm(q / (r * r), axis=-1)
        return (k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)).astype(np.float32)
    rm = float(r.max())
    return c - rm, c + rm, fn


def ell_on(a, b, t, r, side=(0, 0, 0), xhint=(1, 0, 0)):
    """ellipsoid placed at fraction t along segment a->b, aligned to it (local z along segment)."""
    a = V(*a); b = V(*b)
    c = a + (b - a) * t + V(*side)
    R = frame(b - a, xhint)
    return ellipsoid(c, r, R)

# ---------------- landmarks ----------------
S = V(0.215, 0.005, 1.405)    # shoulder joint
ang = np.radians(17)
E = S + 0.305 * V(np.sin(ang), 0.0, -np.cos(ang))      # elbow
d2 = nrm(V(0.24, -0.12, -0.96))
W = E + 0.265 * d2                                        # wrist
H = V(0.098, 0.0, 0.925)       # hip joint
K = V(0.128, -0.012, 0.505)    # knee
A = V(0.148, 0.025, 0.088)     # ankle

body = Field()
t0 = time.time()
U = lambda prim, k=0.02: body.add(prim, k)

# --- torso ---
U(ellipsoid((0, 0.005, 1.265), (0.158, 0.112, 0.165)), 0.0)
U(ellipsoid((0, 0.045, 1.33), (0.145, 0.075, 0.12)), 0.04)                    # upper back
U(ellipsoid((0.112, 0.035, 1.25), (0.055, 0.045, 0.15), frame((0.45, 0, 1), (1, 0, 0))), 0.05)  # lats
U(ellipsoid((0.074, -0.07, 1.318), (0.095, 0.046, 0.07), frame((0.25, 0, 1), (1, 0, 0))), 0.025)  # pecs
U(ellipsoid((0, -0.012, 1.11), (0.128, 0.092, 0.13)), 0.05)                     # abdomen
for i, z in enumerate((1.185, 1.128, 1.072)):
    U(ellipsoid((0.036, -0.078 + i * 0.002, z), (0.033, 0.027, 0.027)), 0.008)  # abs
U(ellipsoid((0.025, -0.07, 1.012), (0.03, 0.022, 0.035)), 0.02)               # lower abs
U(ellipsoid((0.1, -0.01, 1.04), (0.05, 0.07, 0.085)), 0.04)               # obliques
U(ellipsoid((0.11, -0.055, 1.17), (0.04, 0.03, 0.08), frame((0.3, 0, 1), (1, 0, 0))), 0.02)  # serratus
U(ellipsoid((0, 0.012, 0.94), (0.148, 0.10, 0.10)), 0.05)                      # pelvis
U(ellipsoid((0.068, 0.062, 0.885), (0.078, 0.065, 0.09)), 0.04)               # glutes
U(ellipsoid((0.04, 0.075, 1.15), (0.03, 0.03, 0.13)), 0.03)                    # spinal erectors
U(round_cone((0.0, 0.03, 1.515), (0.17, 0.025, 1.45), 0.066, 0.045), 0.05)    # traps
U(round_cone((0.02, -0.045, 1.455), (0.19, -0.01, 1.455), 0.022, 0.02), 0.03)  # clavicle
U(round_cone((0, 0.005, 1.43), (0, -0.005, 1.585), 0.072, 0.06), 0.04)        # neck
U(round_cone((0.03, -0.045, 1.47), (0.008, -0.055, 1.565), 0.016, 0.014), 0.02)  # sternocleidomastoid

# --- arm ---
U(ellipsoid(S + V(0.024, -0.002, -0.012), (0.07, 0.078, 0.09), frame((0.2, 0, 1), (1, 0, 0))), 0.03)
U(ellipsoid(S + V(0.01, -0.045, -0.02), (0.045, 0.04, 0.075), frame((0.2, 0, 1), (1, 0, 0))), 0.02)  # front delt
U(ellipsoid(S + V(0.01, 0.045, -0.02), (0.045, 0.04, 0.075), frame((0.2, 0, 1), (1, 0, 0))), 0.02)  # rear delt  # deltoid
U(round_cone(S, E, 0.062, 0.047), 0.03)
U(ell_on(S, E, 0.55, (0.056, 0.056, 0.095), side=(0.0, -0.034, 0.0)), 0.015)   # biceps
U(ell_on(S, E, 0.42, (0.054, 0.05, 0.11), side=(0.004, 0.036, 0.0)), 0.015)  # triceps
U(ellipsoid(E, (0.045, 0.045, 0.045)), 0.02)
U(round_cone(E, W, 0.053, 0.035), 0.02)
U(ell_on(E, W, 0.28, (0.06, 0.053, 0.095), side=(0.01, -0.008, 0)), 0.025)    # forearm flexors/brachioradialis

# --- hand ---
n = nrm(V(-1, 0, 0) - d2 * np.dot(V(-1, 0, 0), d2))  # palm normal (toward thigh)
f = np.cross(d2, n); f = f if f[1] < 0 else -f        # forward (thumb side)
R = np.stack([n, f, d2], 1)
U(ellipsoid(W + d2 * 0.055 - n * 0.002, (0.02, 0.043, 0.052), R), 0.012)
for off, L1, L2 in ((0.029, 0.047, 0.04), (0.010, 0.052, 0.044), (-0.010, 0.049, 0.04), (-0.028, 0.04, 0.032)):
    kn = W + d2 * 0.1 + f * off
    mid = kn + d2 * L1 + n * 0.012
    tip = mid + d2 * L2 * 0.6 + n * L2 * 0.75
    U(round_cone(kn, mid, 0.011, 0.0095), 0.006)
    U(round_cone(mid, tip, 0.0095, 0.0078), 0.004)
tb = W + f * 0.03 + n * 0.006 + d2 * 0.02
tm = W + d2 * 0.065 + f * 0.05 + n * 0.018
tt = tm + d2 * 0.035 + f * 0.005 + n * 0.012
U(round_cone(tb, tm, 0.016, 0.011), 0.012)
U(round_cone(tm, tt, 0.011, 0.0085), 0.004)

# --- leg ---
U(round_cone(H, K, 0.108, 0.062), 0.05)
U(ell_on(H, K, 0.45, (0.086, 0.074, 0.2), side=(0.01, -0.04, 0)), 0.025)          # quads
U(ellipsoid(K + V(-0.028, -0.032, 0.085), (0.044, 0.04, 0.06)), 0.025)              # vastus medialis
U(ellipsoid(K + V(0.04, -0.005, 0.17), (0.044, 0.05, 0.13)), 0.03)                  # vastus lateralis
U(ell_on(H, K, 0.5, (0.06, 0.055, 0.16), side=(0.0, 0.035, 0)), 0.03)              # hamstrings
U(ellipsoid(H + V(-0.045, 0.0, -0.06), (0.05, 0.06, 0.1)), 0.04)                    # adductors
U(ellipsoid(K + V(0, -0.012, 0), (0.05, 0.048, 0.05)), 0.02)                        # knee
U(round_cone(K, A, 0.05, 0.032), 0.02)
for sx, zz in ((-0.019, 0.38), (0.019, 0.40)):
    U(ellipsoid(K + (A - K) * 0.28 + V(sx, 0.03, 0.0), (0.046, 0.056, 0.105)), 0.02)  # gastrocnemius
U(ellipsoid(A + V(0, 0, 0), (0.034, 0.034, 0.034)), 0.015)
U(ellipsoid(A + V(0, 0.022, -0.05), (0.034, 0.042, 0.037)), 0.02)                    # heel
U(ellipsoid(A + V(0.004, -0.07, -0.058), (0.046, 0.105, 0.032), frame((0, 0, 1), (1, 0, 0))), 0.025)
for i, (ox, oy, r) in enumerate(((-0.022, -0.183, 0.0125), (-0.004, -0.178, 0.009), (0.011, -0.172, 0.0085),
                                  (0.024, -0.164, 0.008), (0.035, -0.153, 0.0075))):
    U(round_cone(A + V(ox, oy + 0.03, -0.067), A + V(ox * 1.05, oy, -0.075), r * 1.05, r), 0.006)

# --- head ---
U(ellipsoid((0, 0.008, 1.70), (0.081, 0.097, 0.10)), 0.03)                       # cranium
U(ellipsoid((0, -0.03, 1.628), (0.07, 0.068, 0.06)), 0.03)                      # face mass
U(ellipsoid((0.056, -0.008, 1.598), (0.024, 0.036, 0.026)), 0.025)               # jaw angle
U(ellipsoid((0, -0.082, 1.585), (0.032, 0.022, 0.024)), 0.02)                    # chin
U(round_cone((0, -0.088, 1.708), (0, -0.107, 1.65), 0.009, 0.014), 0.01)        # nose bridge/tip
U(ellipsoid((0.013, -0.1, 1.648), (0.011, 0.01, 0.009)), 0.006)                  # nostril wing
U(round_cone((0.012, -0.088, 1.722), (0.052, -0.08, 1.722), 0.015, 0.012), 0.01)  # brow ridge
U(ellipsoid((0.045, -0.072, 1.672), (0.024, 0.02, 0.016)), 0.015)                # cheekbone
U(ellipsoid((0, -0.096, 1.616), (0.024, 0.011, 0.009)), 0.008)                   # lips
U(ellipsoid((0.079, 0.014, 1.68), (0.008, 0.022, 0.031), frame((0, 0.25, 1), (1, 0, 0))), 0.006)                 # ears
body.add(ellipsoid((0.031, -0.093, 1.693), (0.019, 0.013, 0.011)), 0.008, op="s")  # eye sockets
body.add(ellipsoid((0.0, -0.103, 1.6045), (0.02, 0.006, 0.0015)), 0.003, op="s")    # mouth line

# floor clip
Zg = zs[None, None, :]
body.d = np.maximum(body.d, -Zg + 0.0005)
print("body field %.1fs" % (time.time() - t0))

# ---------------- shorts ----------------
def coords():
    return np.meshgrid(xs, ys, zs, indexing="ij")

Xg, Yg, Zg3 = coords()
band = np.clip((Zg3 - 0.955) / 0.01, 0, 1)
sh = body.d - 0.0075 - 0.004 * band
sh = np.maximum(sh, Zg3 - 0.995)
cut = 0.745 + 0.02 * np.clip((Xg - 0.05) / 0.12, 0, 1) - Zg3   # leg opening
sh = np.maximum(sh, cut)
sh = np.maximum(sh, Xg - 0.255)
# fill crotch gap between legs
gap = ellipsoid((0, -0.01, 0.83), (0.05, 0.085, 0.06))[2](np.stack([Xg, Yg, Zg3], -1))
sh = np.minimum(sh, np.maximum(gap, cut))
sh = np.maximum(sh, Xg - 0.255)

# ---------------- hair ----------------
cr = ellipsoid((0, 0.008, 1.70), (0.081, 0.097, 0.10))[2]
P = np.stack([Xg, Yg, Zg3], -1)
skull = cr(P)
hl = 1.705 + 0.04 * np.clip((-Yg - 0.0) / 0.07, 0, 1) - 0.03 * np.clip((Yg - 0.03) / 0.05, 0, 1)        # hairline height (front higher)
top = np.clip((Zg3 - 1.70) / 0.04, 0, 1)
thick = 0.003 + 0.015 * top * np.clip((0.07 - Yg) / 0.1, 0.35, 1)
thick = thick * np.clip((Zg3 - hl) / 0.02, 0.15, 1)
# spiky noise: sample low-freq noise
hm = (np.abs(Zg3 - 1.73) < 0.12) & (np.abs(Yg) < 0.13) & (Xg < 0.12)
nz = np.zeros_like(skull)
fine = ndimage.gaussian_filter(rng.standard_normal((70, 70, 105)).astype(np.float32), 0.7) * 2.2
idx = np.stack([Xg[hm] / 0.12 * 69, (Yg[hm] + 0.13) / 0.26 * 69, (Zg3[hm] - 1.61) / 0.24 * 104])
nz[hm] = ndimage.map_coordinates(fine, idx, order=1, mode="nearest")
hair = np.maximum(body.d, skull - 0.004) - thick - 0.005 * np.clip(nz, -1.2, 2) * top * np.clip((Zg3 - hl) / 0.02, 0, 1)
hair = np.maximum(hair, hl - Zg3)
hair = np.maximum(hair, -(np.maximum(body.d, skull - 0.004)) - 0.001)  # no inner shell
hair = np.maximum(hair, Yg * 0 + (-0.085 - Yg) * 1.0 - 0.02 + 0.0)  # keep off forehead
del P

# ---------------- mesh extraction ----------------
def mesh_from(half):
    full = np.concatenate([half[::-1], half], axis=0)
    xf = np.concatenate([-xs[::-1], xs])
    v, fcs, nrms, _ = marching_cubes(full, 0.0, spacing=(RES, RES, RES), allow_degenerate=False)
    v = v + V(xf[0], ys[0], zs[0])
    return v.astype(np.float32), fcs.astype(np.int32), -nrms.astype(np.float32)

bv, bf, bn = mesh_from(body.d)
sv, sf, sn = mesh_from(sh)
hv, hf, hn = mesh_from(hair)
print("verts body", len(bv), "shorts", len(sv), "hair", len(hv), "%.1fs" % (time.time() - t0))

# ---------------- vertex colors & scars ----------------
def seg_dist(P, a, b):
    a = V(*a); b = V(*b); ba = b - a
    t = np.clip(((P - a) @ ba) / np.dot(ba, ba), 0, 1)
    return np.linalg.norm(P - a - t[:, None] * ba, axis=1), t

def polyline_dist(P, pts):
    d = np.full(len(P), 9.0, np.float32)
    for a, b in zip(pts[:-1], pts[1:]):
        d = np.minimum(d, seg_dist(P, a, b)[0])
    return d

def vnoise(P, scale, seed):
    g = np.random.default_rng(seed).standard_normal((64, 64, 64)).astype(np.float32)
    g = ndimage.gaussian_filter(g, 1.0, mode="wrap")
    q = (P * scale) % 64
    return ndimage.map_coordinates(g, q.T, order=1, mode="wrap") / 0.5

P = bv
skin = np.array([0.66, 0.46, 0.35], np.float32)
col = np.tile(skin, (len(P), 1))
n1 = vnoise(P, 40, 1); n2 = vnoise(P, 160, 2)
col *= (1 + 0.05 * n1 + 0.025 * n2)[:, None]
ax = np.abs(P[:, 0])
def blob(c, r, mirror=True):
    c = V(*c)
    Q = P.copy()
    if mirror:
        Q[:, 0] = ax
    return np.exp(-np.sum((Q - c) ** 2, 1) / (r * r))
red = V(0.80, 0.45, 0.38)
for c, r, w in (((E[0], E[1] + 0.04, E[2]), 0.04, 0.4), ((K[0], K[1] - 0.05, K[2]), 0.05, 0.35),
                ((W[0], W[1], W[2]) + d2 * 0.1, 0.04, 0.35), ((0.07, -0.15, 1.65), 0.03, 0.2),
                ((0.0, -0.11, 1.655), 0.012, 0.3)):
    b = blob(c, r) * w
    col = col * (1 - b[:, None]) + red * b[:, None]
# nipples
b = blob((0.098, -0.118, 1.29), 0.011)
b = np.clip(b * 1.4, 0, 1)
col = col * (1 - b[:, None]) + V(0.55, 0.33, 0.28) * b[:, None]
# lips
b = blob((0.0, -0.105, 1.614), 0.016, False) * 0.6
col = col * (1 - b[:, None]) + V(0.62, 0.36, 0.32) * b[:, None]
# stubble (jaw, chin, upper lip, cheeks)
head = (P[:, 2] > 1.55) & (P[:, 2] < 1.67) & (P[:, 1] < 0.02)
face_line = 1.655 - 0.03 * np.clip(ax / 0.06, 0, 1)
st = head & (P[:, 2] < face_line) & (np.abs(P[:, 2] - 1.614) > 0.007)
stw = np.where(head, 0.5 * np.clip((face_line - P[:, 2]) / 0.02, 0, 1) * np.clip((P[:, 2] - 1.55) / 0.03, 0, 1) * np.clip((0.035 - P[:, 1]) / 0.03, 0, 1), 0)
stw *= np.clip(np.abs(P[:, 2] - 1.614) / 0.008, 0, 1)
stw *= np.clip(0.7 + 0.5 * vnoise(P, 900, 3), 0, 1.2)
stw = np.clip(stw, 0, 1)
col = col * (1 - stw[:, None]) + V(0.22, 0.17, 0.14) * stw[:, None]
# eyebrows
eb = np.minimum(seg_dist(np.c_[ax, P[:, 1:]], (0.014, -0.096, 1.716), (0.052, -0.087, 1.72))[0], 1)
ebw = np.clip(1 - (eb - 0.003) / 0.005, 0, 1) * 0.85
col = col * (1 - ebw[:, None]) + V(0.12, 0.09, 0.07) * ebw[:, None]
# faded hair on sides/back of head
zlow = 1.672 - 0.075 * np.clip((P[:, 1] - 0.0) / 0.07, 0, 1)
ear = (ax > 0.07) & (np.abs(P[:, 2] - 1.68) < 0.036) & (np.abs(P[:, 1] - 0.014) < 0.028)
fw = np.clip((P[:, 2] - zlow) / 0.03, 0, 1) * (P[:, 1] > -0.072) * (P[:, 2] > 1.58) * ~ear
fw *= 0.75 * np.clip(0.75 + 0.4 * vnoise(P, 1200, 11), 0, 1)
col = col * (1 - fw[:, None]) + V(0.11, 0.085, 0.07) * fw[:, None]
# body hair (chest, belly line), subtle
ch = blob((0.0, -0.1, 1.28), 0.07, False) * 0.25 + np.exp(-(ax / 0.02) ** 2) * (np.abs(P[:, 2] - 1.03) < 0.08) * (P[:, 1] < 0) * 0.3
ch *= np.clip(vnoise(P, 600, 5) * 0.5 + 0.6, 0, 1)
col = col * (1 - ch[:, None] * 0.5) + V(0.3, 0.22, 0.17) * ch[:, None] * 0.5

# scars: (polyline, width) — the right side of the character is -X
scars = [
    ([(0.105, 0.115, 1.385), (0.04, 0.125, 1.30), (-0.03, 0.12, 1.21), (-0.085, 0.10, 1.13)], 0.0085),  # back diagonal
    ([(0.036, -0.097, 1.735), (0.032, -0.098, 1.718), (0.03, -0.096, 1.705)], 0.0022),                   # eyebrow (left)
    ([(-0.045, -0.088, 1.668), (-0.052, -0.083, 1.648), (-0.054, -0.078, 1.63)], 0.0022),               # cheek (right)
    ([(0.06, -0.105, 1.355), (0.09, -0.11, 1.34)], 0.0035),                                               # chest
    ([(-0.08, -0.07, 1.115), (-0.06, -0.085, 1.10)], 0.003),                                              # belly
    ([(-0.17, -0.085, 0.70), (-0.15, -0.095, 0.66), (-0.135, -0.093, 0.63)], 0.004),                     # right thigh
    ([(E[0] + 0.02, E[1] - 0.04, E[2] - 0.06), (E[0] + 0.035, E[1] - 0.045, E[2] - 0.12)], 0.003),       # left forearm
    ([(-0.26, -0.03, 1.43), (-0.25, -0.06, 1.39)], 0.003),                                                # right shoulder
]
disp = np.zeros(len(P), np.float32)
for pts, w in scars:
    d = polyline_dist(P, [V(*p) for p in pts])
    core = np.clip(1 - d / w, 0, 1)
    rim = np.clip(1 - np.abs(d - w * 1.6) / w, 0, 1)
    c = V(0.80, 0.40, 0.40) * (1 - 0.15 * core[:, None])
    col = col * (1 - core[:, None] * 0.9) + c * core[:, None] * 0.9
    col = col * (1 - rim[:, None] * 0.35) + V(0.72, 0.38, 0.33) * rim[:, None] * 0.35
    disp += -0.0009 * core + 0.0006 * rim
bv = bv + bn * disp[:, None]
bc = np.clip(col, 0, 1)

sc = np.tile(V(0.36, 0.36, 0.37), (len(sv), 1)) * (1 + 0.04 * vnoise(sv, 300, 9))[:, None]
sc[sv[:, 2] > 0.955] = V(0.13, 0.13, 0.14)
hc = np.tile(V(0.09, 0.07, 0.055), (len(hv), 1))

np.savez_compressed(OUT, bv=bv, bf=bf, bc=bc, sv=sv, sf=sf, sc=np.clip(sc, 0, 1), hv=hv, hf=hf, hc=hc,
                    eyes=np.array([[0.031, -0.082, 1.693], [-0.031, -0.082, 1.693]], np.float32),
                    joints=np.stack([S, E, W, H, K, A]))
print("saved", OUT, "%.1fs" % (time.time() - t0))
