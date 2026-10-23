"""Quadric error metric edge-collapse decimation (Garland & Heckbert), pure Python + numpy.

Closed meshes only (marching cubes output). Rejects collapses that flip triangles.
"""
import heapq

import numpy as np


def _plane_quadrics(V, F):
    a, b, c = V[F[:, 0]], V[F[:, 1]], V[F[:, 2]]
    n = np.cross(b - a, c - a)
    area = np.linalg.norm(n, axis=1)
    n = n / np.maximum(area, 1e-12)[:, None]
    d = -np.einsum("ij,ij->i", n, a)
    p = np.concatenate([n, d[:, None]], axis=1)          # (F,4)
    K = np.einsum("fi,fj->fij", p, p) * area[:, None, None]
    return K


def decimate(V, F, target, vreg=None):
    V = np.asarray(V, dtype=np.float64).copy()
    F = np.asarray(F, dtype=np.int64).copy()
    nv = len(V)
    Kf = _plane_quadrics(V, F)
    Q = np.zeros((nv, 4, 4))
    for k in range(3):
        np.add.at(Q, F[:, k], Kf)
    vf = [set() for _ in range(nv)]
    for fi, (a, b, c) in enumerate(F):
        vf[a].add(fi)
        vf[b].add(fi)
        vf[c].add(fi)
    alive_f = np.ones(len(F), dtype=bool)
    alive_v = np.ones(nv, dtype=bool)
    ver = np.zeros(nv, dtype=np.int64)
    nf = len(F)

    def best(a, b):
        q = Q[a] + Q[b]
        m = q.copy()
        m[3] = [0, 0, 0, 1]
        try:
            if abs(np.linalg.det(m)) > 1e-12:
                x = np.linalg.solve(m, [0, 0, 0, 1.0])
                # keep the solution near the edge (avoid spikes on flat areas)
                mid = (V[a] + V[b]) * 0.5
                if np.linalg.norm(x[:3] - mid) < np.linalg.norm(V[a] - V[b]) * 1.5:
                    return float(x @ q @ x), x[:3]
        except np.linalg.LinAlgError:
            pass
        cands = [V[a], V[b], (V[a] + V[b]) * 0.5]
        bc, bp = None, None
        for p in cands:
            x = np.append(p, 1.0)
            c = float(x @ q @ x)
            if bc is None or c < bc:
                bc, bp = c, p
        return bc, bp

    heap = []

    def push(a, b):
        if a > b:
            a, b = b, a
        c, p = best(a, b)
        heapq.heappush(heap, (c, a, b, ver[a], ver[b], tuple(p)))

    edges = set()
    for a, b, c in F:
        for u, w in ((a, b), (b, c), (c, a)):
            edges.add((min(u, w), max(u, w)))
    for a, b in edges:
        push(a, b)

    def neighbours(v):
        out = set()
        for fi in vf[v]:
            for u in F[fi]:
                if u != v:
                    out.add(int(u))
        return out

    while nf > target and heap:
        c, a, b, va, vb, p = heapq.heappop(heap)
        if not (alive_v[a] and alive_v[b]) or ver[a] != va or ver[b] != vb:
            continue
        if vreg is not None and vreg[a] != vreg[b]:
            continue
        p = np.array(p)
        shared = vf[a] & vf[b]
        if len(shared) != 2:
            continue
        # link condition: common neighbours must be exactly the two opposite vertices
        na, nb = neighbours(a), neighbours(b)
        if len(na & nb) != 2:
            continue
        # flip test
        bad = False
        for v, other in ((a, b), (b, a)):
            for fi in vf[v]:
                if fi in shared:
                    continue
                tri = F[fi]
                pts_old = V[tri]
                pts_new = pts_old.copy()
                for k in range(3):
                    if tri[k] == v:
                        pts_new[k] = p
                n0 = np.cross(pts_old[1] - pts_old[0], pts_old[2] - pts_old[0])
                n1 = np.cross(pts_new[1] - pts_new[0], pts_new[2] - pts_new[0])
                l1 = np.linalg.norm(n1)
                if l1 < 1e-14 or np.dot(n0, n1) / (np.linalg.norm(n0) * l1 + 1e-18) < 0.3:
                    bad = True
                    break
                # avoid needle triangles
                e = [np.linalg.norm(pts_new[k] - pts_new[(k + 1) % 3]) for k in range(3)]
                if l1 / (max(e) ** 2 + 1e-18) < 0.08:
                    bad = True
                    break
            if bad:
                break
        if bad:
            continue
        # collapse b into a
        V[a] = p
        Q[a] = Q[a] + Q[b]
        alive_v[b] = False
        for fi in shared:
            alive_f[fi] = False
            for u in F[fi]:
                vf[u].discard(fi)
            nf -= 1
        for fi in list(vf[b]):
            tri = F[fi]
            for k in range(3):
                if tri[k] == b:
                    tri[k] = a
            vf[a].add(fi)
        vf[b] = set()
        ver[a] += 1
        for u in neighbours(a):
            push(a, u)
    # compact
    keep = np.where(alive_v)[0]
    remap = -np.ones(nv, dtype=np.int64)
    remap[keep] = np.arange(len(keep))
    F2 = remap[F[alive_f]]
    return V[keep], F2
