#!/usr/bin/env python3
"""Бесшовные текстуры: мокрая брусчатка и кирпич (эталон парковки), асфальт, плитка
тротуара и земля дворов (район, 0.10).

    python3 tools/textures/make_textures.py

Пишет assets/textures/<имя>_albedo.png, _normal.png, _rough.png (1024 × 1024).
Брусчатка: 2 × 2 м на текстуру, камни 25 × 17 см со скруглением, тёмные швы с водой.
Кирпич: 2 × 2 м, кирпич 25 × 7.7 см, перевязка со смещением в полкирпича.
Асфальт: 4 × 4 м, зерно, трещины, заплатки и лужи (почти зеркальные).
Плитка: 2 × 2 м, плиты 50 × 50 см, у каждой свой тон, часть с трещиной.
Земля: 4 × 4 м, утоптанная земля с пятнами травы и старого асфальта.

0.18, рисованный стиль (D-060): перед записью альбедо проходит «кисть» — мелкое зерно
размыто, контраст сжат к среднему тону, рисунок (швы, плиты, трещины) остаётся читаемым;
нормали вдвое мягче. Без зерна текстура не спорит с ровными заливками моделей.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

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
    strength *= 0.5                                   # 0.18: рисованный стиль — рельеф мягче
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


def painted(albedo, blur=2.5, keep=0.5):
    """Рисованная версия: бесшовное размытие зерна и сжатие контраста к среднему."""
    img = Image.fromarray(np.clip(albedo * 255, 0, 255).astype(np.uint8))
    pad = 16
    wrapped = Image.fromarray(np.pad(np.asarray(img), ((pad, pad), (pad, pad), (0, 0)), mode="wrap"))
    soft = np.asarray(wrapped.filter(ImageFilter.GaussianBlur(blur)), np.float32)[pad:-pad, pad:-pad] / 255.0
    mean = soft.reshape(-1, 3).mean(0)
    return mean + (soft - mean) * keep


def save(name, albedo, normal, rough):
    albedo = painted(albedo)
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


def cracks(count, length, width):
    """Маска трещин 0..1: ломаные из случайных точек, бесшовно (по модулю N)."""
    m = np.zeros((N, N), np.float32)
    for _ in range(count):
        x, y = rng.uniform(0, N, 2)
        ang = rng.uniform(0, 2 * np.pi)
        for _ in range(int(length)):
            ang += rng.normal(0, 0.35)
            x, y = (x + np.cos(ang) * 2) % N, (y + np.sin(ang) * 2) % N
            xi, yi = int(x), int(y)
            for dx in range(-width, width + 1):
                for dy in range(-width, width + 1):
                    m[(yi + dy) % N, (xi + dx) % N] = 1.0
    return m


def asphalt():
    grit = noise(48, 3)
    coarse = noise(6, 3)
    wear = noise(2, 2)
    tone = 0.13 + 0.05 * grit + 0.02 * coarse
    albedo = np.stack([tone, tone, tone * 1.06], -1)
    # заплатки: прямоугольники посветлее
    patch = np.zeros((N, N), np.float32)
    for _ in range(5):
        x0, y0 = rng.integers(0, N, 2)
        w, h = rng.integers(80, 260, 2)
        yy, xx = np.ogrid[0:N, 0:N]
        patch = np.maximum(patch, ((((xx - x0) % N) < w) & (((yy - y0) % N) < h)).astype(np.float32))
    albedo = albedo * (1 - patch[..., None] * 0.35) + patch[..., None] * np.array([0.2, 0.2, 0.21]) * 0.35
    cr = cracks(26, 140, 1)
    albedo *= (1 - cr * 0.6)[..., None]
    albedo *= (0.92 + 0.12 * wear)[..., None]
    puddle = noise(3, 3)
    wet = np.clip((puddle - 0.66) * 8.0, 0, 1)
    albedo *= (1 - wet * 0.15)[..., None]
    rough = (0.55 + 0.2 * grit) * (1 - wet) + 0.05 * wet
    rough = np.maximum(rough, cr * 0.9)
    save("asphalt", albedo, normal_from(grit * 0.6 - cr * 0.8 - wet * 0.2, 3.0), rough)


def slabs():
    px = N / 2.0
    h, ids, d = rounded_cells(0.5 * px, 0.5 * px, 0.006 * px, 0.01 * px, 0.0)
    tone = per_id(ids, 0.8, 1.12)
    grit = noise(20, 3)
    base = np.stack([0.5, 0.48, 0.45], -1) * tone[..., None] * (0.82 + 0.3 * grit)[..., None]
    joint = np.clip(d / 2.0 + 0.5, 0, 1)
    cr = cracks(18, 90, 1)
    dirt = noise(4, 2)
    albedo = base * (1 - joint[..., None] * 0.7) * (1 - cr * 0.5)[..., None] * (0.8 + 0.25 * dirt)[..., None]
    wet = np.clip((noise(3, 2) - 0.62) * 6.0, 0, 1)
    rough = (0.7 + 0.15 * grit) * (1 - wet) + 0.12 * wet
    rough = rough * (1 - joint) + 0.3 * joint
    save("slabs", albedo, normal_from(h * 0.6 + grit * 0.2 - cr * 0.5, 4.0), rough)


def dirt():
    grit = noise(40, 3)
    blotch = noise(5, 3)
    grass = np.clip((noise(10, 3) - 0.45) * 2.2, 0, 1) * 0.85
    old = np.clip((noise(3, 2) - 0.74) * 6.0, 0, 1)
    earth = np.stack([0.24, 0.2, 0.16], -1) * (0.75 + 0.4 * grit)[..., None] * (0.9 + 0.15 * blotch)[..., None]
    green = np.stack([0.12, 0.17, 0.08], -1) * (0.7 + 0.5 * grit)[..., None]
    tar = np.stack([0.13, 0.13, 0.14], -1) * (0.85 + 0.2 * grit)[..., None]
    albedo = earth * (1 - grass[..., None]) + green * grass[..., None]
    albedo = albedo * (1 - old[..., None]) + tar * old[..., None]
    rough = 0.9 - 0.25 * old
    save("dirt", albedo, normal_from(grit * 0.5 + grass * 0.2, 3.0), rough)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    cobble()
    brick()
    asphalt()
    slabs()
    dirt()
