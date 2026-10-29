#!/usr/bin/env python3
"""Бесшовные текстуры для эталона парковки: мокрая брусчатка и кирпич.

    python3 tools/textures/make_textures.py

Пишет assets/textures/<имя>_albedo.png, _normal.png, _rough.png (1024 × 1024).
Брусчатка: 2 × 2 м на текстуру, камни 25 × 17 см со скруглением, тёмные швы с водой.
Кирпич: 2 × 2 м, кирпич 25 × 7.7 см, перевязка со смещением в полкирпича.
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "textures"
N = 1024
rng = np.random.default_rng(13)


def rounded_cells(cell_w, cell_h, gap, radius, offset_rows):
    """Высота камней (0..1), id камня и маска шва на сетке N × N (бесшовно)."""
    y, x = np.mgrid[0:N, 0:N].astype(np.float32)
    row = np.floor(y / cell_h)
    shift = np.where(row % 2 == 1, cell_w * offset_rows, 0.0)
    xs = (x + shift) % N
    col = np.floor(xs / cell_w)
    lx = xs - col * cell_w - cell_w / 2
    ly = y - row * cell_h - cell_h / 2
    hx, hy = cell_w / 2 - gap, cell_h / 2 - gap
    qx = np.maximum(np.abs(lx) - (hx - radius), 0)
    qy = np.maximum(np.abs(ly) - (hy - radius), 0)
    d = np.sqrt(qx ** 2 + qy ** 2) - radius          # < 0 внутри камня
    inside = np.clip(-d / (radius + 1e-3), 0, 1)
    height = np.sqrt(inside)
    ids = (row * 997 + col).astype(np.int64)
    return height, ids, d


def normal_from(height, strength):
    gx = np.roll(height, -1, 1) - np.roll(height, 1, 1)
    gy = np.roll(height, -1, 0) - np.roll(height, 1, 0)
    nx, ny, nz = -gx * strength, -gy * strength, np.ones_like(height)
    l = np.sqrt(nx ** 2 + ny ** 2 + nz ** 2)
    n = np.stack([nx / l, ny / l, nz / l], -1)
    return Image.fromarray(((n * 0.5 + 0.5) * 255).astype(np.uint8))


def noise(scale, octaves=4):
    """Бесшовный шум 0..1: сумма волн с целыми частотами (повторяется ровно через N)."""
    y, x = np.mgrid[0:N, 0:N].astype(np.float32) * (2 * np.pi / N)
    out = np.zeros((N, N), np.float32)
    amp = 1.0
    for o in range(octaves):
        f = scale * 2 ** o
        for _ in range(12):
            kx, ky = rng.integers(-f, f + 1, 2)
            out += amp * np.cos(kx * x + ky * y + rng.uniform(0, 2 * np.pi)).astype(np.float32)
        amp *= 0.5
    out -= out.min()
    return out / out.max()


def per_id(ids, lo, hi):
    uniq, inv = np.unique(ids, return_inverse=True)
    vals = rng.uniform(lo, hi, len(uniq)).astype(np.float32)
    return vals[inv].reshape(ids.shape)


def save(name, albedo, normal, rough):
    Image.fromarray(np.clip(albedo * 255, 0, 255).astype(np.uint8)).save(OUT / f"{name}_albedo.png")
    normal.save(OUT / f"{name}_normal.png")
    Image.fromarray(np.clip(rough * 255, 0, 255).astype(np.uint8)).save(OUT / f"{name}_rough.png")
    print("texture", name)


def cobble():
    px = N / 2.0                                     # пикселей на метр
    h, ids, d = rounded_cells(0.25 * px, N / 12.0, 0.007 * px, 0.03 * px, 0.5)   # 12 рядов ≈ 16 см
    tone = per_id(ids, 0.75, 1.15)
    warm = per_id(ids, -0.05, 0.06)
    grit = noise(16)
    base = np.stack([0.42 + warm, 0.37 + warm * 0.6, np.full_like(warm, 0.33)], -1) * tone[..., None]
    base *= (0.85 + 0.3 * grit)[..., None]
    joint = np.clip(d / 2.0 + 0.5, 0, 1)[..., None]   # 1 в шве
    mortar = np.array([0.1, 0.095, 0.09])
    albedo = base * (1 - joint) + mortar * joint
    # вода: шов и низины почти зеркальные, верх камня матовее
    puddle = noise(4, 3)
    rough = 0.42 + 0.12 * grit
    rough = rough * (1 - joint[..., 0]) + 0.12 * joint[..., 0]
    rough = np.where(puddle > 0.62, 0.06, rough)
    hh = h * 0.8 + grit * 0.2
    save("cobble", albedo, normal_from(hh, 6.0), rough)


def brick():
    px = N / 2.0
    h, ids, d = rounded_cells(0.25 * px, N / 26.0, 0.006 * px, 0.008 * px, 0.5)   # 26 рядов ≈ 7.7 см
    tone = per_id(ids, 0.7, 1.1)
    hue = per_id(ids, -0.06, 0.06)
    grit = noise(24)
    base = np.stack([0.55 + hue, 0.25 + hue * 0.5, np.full_like(hue, 0.17)], -1) * tone[..., None]
    base *= (0.8 + 0.35 * grit)[..., None]
    joint = np.clip(d / 3.0 + 0.5, 0, 1)[..., None]
    mortar = np.array([0.45, 0.42, 0.38]) * (0.8 + 0.2 * grit[..., None])
    soot = noise(3, 2)[..., None]
    albedo = (base * (1 - joint) + mortar * joint) * (0.75 + 0.25 * soot)
    rough = 0.8 + 0.1 * grit
    save("brick", albedo, normal_from(h * 0.9 + grit * 0.1, 4.0), rough)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    cobble()
    brick()
