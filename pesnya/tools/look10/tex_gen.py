"""Offline textures for the «Новый облик» yard (all tileable, generated from seeded noise).

usage: python3 tex_gen.py OUT_DIR
"""
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
RNG = np.random.default_rng(7)


def noise(n, beta=2.0, seed=None):
    """Seamless 1/f^beta noise in [0,1]."""
    r = np.random.default_rng(seed) if seed is not None else RNG
    w = r.standard_normal((n, n))
    f = np.fft.fft2(w)
    ky = np.fft.fftfreq(n)[:, None]
    kx = np.fft.fftfreq(n)[None, :]
    k = np.sqrt(kx * kx + ky * ky)
    k[0, 0] = 1.0
    f = f / (k ** (beta / 2.0))
    f[0, 0] = 0
    out = np.real(np.fft.ifft2(f))
    out -= out.min()
    out /= out.max()
    return out


def lerp(a, b, t):
    return a + (b - a) * t


def col(hexs):
    hexs = hexs.lstrip("#")
    return np.array([int(hexs[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float64)


def save(arr, name):
    Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8)).save("%s/%s.png" % (OUT, name))


def wrap_draw(img, fn):
    """Draw with wrap-around: call fn(draw, dx, dy) for the 9 tile offsets."""
    d = ImageDraw.Draw(img)
    w, h = img.size
    for dx in (-w, 0, w):
        for dy in (-h, 0, h):
            fn(d, dx, dy)


# ---------------------------------------------------------------- asphalt (4 m per tile)
def asphalt(n=512):
    base = col("6a6a70")
    lo = noise(n, 1.6, 1)
    hi = noise(n, 0.4, 2)
    g = (lo - 0.5) * 18 + (hi - 0.5) * 34
    img = np.zeros((n, n, 3))
    img[:] = base
    img += g[..., None]
    # aggregate speckles
    r = np.random.default_rng(3)
    sp = r.random((n, n))
    img[sp > 0.985] += 28
    img[sp < 0.012] -= 26
    # repaired patches (darker, smoother)
    pil = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8))
    patch = Image.new("L", (n, n), 0)
    for (x, y, w, h) in [(60, 300, 150, 90), (330, 80, 110, 160), (380, 400, 90, 70)]:
        wrap_draw(patch, lambda d, dx, dy, x=x, y=y, w=w, h=h: d.rectangle([x + dx, y + dy, x + w + dx, y + h + dy], fill=255))
    patch = patch.filter(ImageFilter.GaussianBlur(1.2))
    p = np.asarray(patch, dtype=np.float64)[..., None] / 255.0
    arr = np.asarray(pil, dtype=np.float64)
    darker = arr * 0.9 + (lo[..., None] - 0.5) * 8
    arr = lerp(arr, darker, p)
    # cracks: random walks
    crack = Image.new("L", (n, n), 0)
    rr = np.random.default_rng(11)
    for _ in range(9):
        x, y = rr.random() * n, rr.random() * n
        a = rr.random() * 6.28
        pts = [(x, y)]
        for _ in range(rr.integers(25, 70)):
            a += rr.normal(0, 0.45)
            x += np.cos(a) * 3.0
            y += np.sin(a) * 3.0
            pts.append((x, y))
        wrap_draw(crack, lambda d, dx, dy, pts=pts: d.line([(px + dx, py + dy) for px, py in pts], fill=255, width=1))
    c = np.asarray(crack, dtype=np.float64)[..., None] / 255.0
    arr = lerp(arr, arr * 0.45, c * 0.85)
    save(arr, "t_asphalt")


# ---------------------------------------------------------------- paving tiles (2 m per tile → 4x4 tiles of 0.5 m)
def tiles(n=512):
    base = col("a8a49c")
    arr = np.zeros((n, n, 3))
    arr[:] = base
    lo = noise(n, 1.4, 21)
    arr += (lo[..., None] - 0.5) * 22
    cell = n // 4
    r = np.random.default_rng(5)
    for i in range(4):
        for j in range(4):
            tint = r.normal(0, 2.0, 3) + r.normal(0, 5)
            if (i + j) % 3 == 0:
                tint = tint + np.array([10.0, -2.0, -6.0])
            arr[i * cell:(i + 1) * cell, j * cell:(j + 1) * cell] += tint
    yy, xx = np.mgrid[0:n, 0:n]
    gx = np.minimum(xx % cell, cell - 1 - xx % cell)
    gy = np.minimum(yy % cell, cell - 1 - yy % cell)
    gap = np.minimum(gx, gy)
    arr *= np.where(gap < 2, 0.55, np.where(gap < 4, 0.85, 1.0))[..., None]
    # bevel highlight
    arr += np.where((gap >= 4) & (gap < 7), 6, 0)[..., None]
    hi = noise(n, 0.3, 22)
    arr += (hi[..., None] - 0.5) * 18
    save(arr, "t_tiles")


# ---------------------------------------------------------------- grass (5 m per tile)
def grass(n=512):
    lo = noise(n, 2.2, 31)
    mid = noise(n, 1.2, 32)
    hi = noise(n, 0.2, 33)
    g1 = col("5e8a3a")
    g2 = col("7ea446")
    dry = col("9a9a52")
    dirt = col("7a6a4c")
    arr = lerp(g1, g2, mid[..., None])
    arr = lerp(arr, dry, np.clip((lo[..., None] - 0.62) * 2.2, 0, 0.6))
    arr = lerp(arr, dirt, np.clip((lo[..., None] - 0.82) * 4.0, 0, 0.7))
    arr += (hi[..., None] - 0.5) * 46
    # blades: short vertical strokes
    r = np.random.default_rng(34)
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for _ in range(9000):
        x, y = r.random() * n, r.random() * n
        L = r.random() * 5 + 2
        c = tuple(int(v) for v in np.clip(lerp(g1, g2, r.random()) * (0.75 + r.random() * 0.6), 0, 255))
        d.line([(x, y), (x + r.normal(0, 1), y - L)], fill=c, width=1)
    # a few clover / dandelion dots
    for _ in range(140):
        x, y = r.random() * n, r.random() * n
        c = (245, 220, 60) if r.random() < 0.6 else (250, 250, 245)
        d.ellipse([x - 1.5, y - 1.5, x + 1.5, y + 1.5], fill=c)
    save(np.asarray(img, dtype=np.float64), "t_grass")


# ---------------------------------------------------------------- panel facade atlas: 8x8 cells, each one bay of one floor
CURTAINS = ["f2ead8", "e8d4b0", "c8d8b0", "f0c8c8", "b8c8e8", "e8e0f0", "d8b890", "a8c8b8"]


def facade(cell=128, ncell=8):
    n = cell * ncell
    wall = col("ece6da")
    arr = np.zeros((n, n, 3))
    em = np.zeros((n, n, 3))
    arr[:] = wall
    lo = noise(n, 1.6, 41)
    hi = noise(n, 0.5, 42)
    arr += (lo[..., None] - 0.5) * 16 + (hi[..., None] - 0.5) * 10
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8))
    emi = Image.fromarray(em.astype(np.uint8))
    d = ImageDraw.Draw(img)
    de = ImageDraw.Draw(emi)
    r = np.random.default_rng(43)
    for cy in range(ncell):
        for cx in range(ncell):
            x0, y0 = cx * cell, cy * cell
            # panel joints (sealant) around the cell
            d.rectangle([x0, y0, x0 + cell - 1, y0 + 2], fill=(150, 146, 140))
            d.rectangle([x0, y0, x0 + 2, y0 + cell - 1], fill=(160, 156, 150))
            # rain streaks under the window
            kind = (cy * ncell + cx)
            if cy == 7:
                # last row: special cells (blank panels, stairwell, entrance door)
                if cx < 3:
                    # blank wall panel
                    continue
                if cx in (3, 4):
                    # stairwell window: narrow, set lower (between floors)
                    _window(d, de, x0 + 40, y0 + 46, 48, 60, r, frame=(120, 82, 56), stair=True)
                    continue
                if cx in (5, 6):
                    # entrance door bay: metal door + intercom + number plate
                    dc = [(64, 92, 132), (128, 52, 44)][cx - 5]
                    d.rectangle([x0 + 34, y0 + 30, x0 + 94, y0 + 127], fill=(70, 70, 74))
                    d.rectangle([x0 + 38, y0 + 34, x0 + 90, y0 + 127], fill=dc)
                    d.rectangle([x0 + 42, y0 + 40, x0 + 86, y0 + 80], outline=tuple(int(v * 0.8) for v in dc), width=2)
                    d.rectangle([x0 + 80, y0 + 84, x0 + 86, y0 + 94], fill=(30, 30, 30))
                    d.rectangle([x0 + 98, y0 + 60, x0 + 108, y0 + 76], fill=(40, 40, 46))
                    d.rectangle([x0 + 100, y0 + 63, x0 + 106, y0 + 67], fill=(120, 200, 255))
                    de.rectangle([x0 + 100, y0 + 63, x0 + 106, y0 + 67], fill=(60, 120, 160))
                    continue
                # cx 7: ground floor shop-ish / basement vents
                d.rectangle([x0 + 20, y0 + 90, x0 + 50, y0 + 110], fill=(50, 50, 54))
                d.rectangle([x0 + 78, y0 + 90, x0 + 108, y0 + 110], fill=(50, 50, 54))
                continue
            frame = (248, 248, 246) if r.random() < 0.6 else (130, 88, 58)
            lit = r.random() < 0.22
            _window(d, de, x0 + 22, y0 + 26, 84, 74, r, frame=frame, lit=lit, kind=kind)
            # streak
            s = Image.new("L", (cell, cell), 0)
            for k in range(3):
                sx = int(22 + r.random() * 84)
                ImageDraw.Draw(s).line([(sx, 102), (sx + r.normal(0, 1), 102 + 10 + r.random() * 18)], fill=int(40 + r.random() * 40), width=2)
            s = s.filter(ImageFilter.GaussianBlur(1.5))
            reg = np.asarray(img.crop((x0, y0, x0 + cell, y0 + cell)), dtype=np.float64)
            reg = reg * (1 - np.asarray(s, dtype=np.float64)[..., None] / 255.0 * 0.35)
            img.paste(Image.fromarray(reg.astype(np.uint8)), (x0, y0))
            d = ImageDraw.Draw(img)
    img.save("%s/t_facade.png" % OUT)
    emi.save("%s/t_facade_em.png" % OUT)


def _window(d, de, x, y, w, h, r, frame=(248, 248, 246), lit=False, kind=0, stair=False):
    # sill + frame
    d.rectangle([x - 4, y + h, x + w + 4, y + h + 5], fill=(190, 190, 192))
    d.rectangle([x, y, x + w, y + h], fill=frame)
    fw = 4
    gx0, gy0, gx1, gy1 = x + fw, y + fw, x + w - fw, y + h - fw
    # glass: sky reflection gradient
    for yy in range(gy0, gy1 + 1):
        t = (yy - gy0) / max(1, gy1 - gy0)
        c = (int(lerp(150, 70, t)), int(lerp(180, 92, t)), int(lerp(214, 120, t)))
        d.line([(gx0, yy), (gx1, yy)], fill=c)
    if not stair:
        # curtains / blinds / plants
        cur = r.integers(0, 10)
        cc = tuple(int(v) for v in col(CURTAINS[r.integers(0, len(CURTAINS))]))
        if lit:
            warm = (255, 214, 150)
            d.rectangle([gx0, gy0, gx1, gy1], fill=(236, 196, 130))
            de.rectangle([gx0, gy0, gx1, gy1], fill=(200, 150, 80))
            cc = tuple(int(v * 0.95) for v in warm)
        if cur < 4:
            d.rectangle([gx0, gy0, gx0 + (gx1 - gx0) * 0.3, gy1], fill=cc)
            d.rectangle([gx1 - (gx1 - gx0) * 0.3, gy0, gx1, gy1], fill=cc)
        elif cur < 6:
            for yy in range(gy0, int(gy0 + (gy1 - gy0) * (0.4 + r.random() * 0.5)), 3):
                d.line([(gx0, yy), (gx1, yy)], fill=tuple(int(v * 0.9) for v in cc))
        elif cur < 8:
            d.rectangle([gx0, gy0, gx1, gy0 + 8], fill=cc)
        # plants on the sill
        if r.random() < 0.3:
            for k in range(r.integers(1, 3)):
                px = gx0 + 8 + r.random() * (gx1 - gx0 - 16)
                d.rectangle([px - 4, gy1 - 8, px + 4, gy1], fill=(170, 90, 60))
                d.ellipse([px - 7, gy1 - 20, px + 7, gy1 - 6], fill=(70, 130, 60))
        # mullions: a fixed pane and an opening pane
        mx = x + int(w * (0.5 if r.random() < 0.5 else 0.62))
        d.rectangle([mx - 2, y, mx + 2, y + h], fill=frame)
        if r.random() < 0.4:
            d.rectangle([x, y + int(h * 0.3) - 2, x + w, y + int(h * 0.3) + 2], fill=frame)
    else:
        d.rectangle([x + w // 2 - 2, y, x + w // 2 + 2, y + h], fill=frame)


# ---------------------------------------------------------------- birch bark (tiles vertically)
def bark(w=128, h=512):
    r = np.random.default_rng(51)
    base = np.zeros((h, w, 3))
    base[:] = col("eeebe2")
    lo = noise(512, 1.2, 52)[:h, :w]
    base += (lo[..., None] - 0.5) * 22
    img = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    for _ in range(70):
        x = r.random() * w
        y = r.random() * h
        L = r.random() * 34 + 6
        t = r.random() * 3 + 1
        c = (int(30 + r.random() * 40),) * 3
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                d.ellipse([x - L / 2 + dx, y - t / 2 + dy, x + L / 2 + dx, y + t / 2 + dy], fill=c)
    for _ in range(26):
        x = r.random() * w
        y = r.random() * h
        for dx in (-w, 0, w):
            for dy in (-h, 0, h):
                d.polygon([(x + dx - 9, y + dy), (x + dx, y + dy - 4), (x + dx + 9, y + dy), (x + dx, y + dy + 6)], fill=(46, 42, 40))
    img.save("%s/t_bark.png" % OUT)


# ---------------------------------------------------------------- garage doors atlas (2x2 variants, 256 each)
def garage(cell=256):
    n = cell * 2
    img = Image.new("RGB", (n, n))
    r = np.random.default_rng(61)
    paints = ["8a4a3a", "4f6478", "7a6a42", "4a5e48", "6a4a5a", "8a7a5a"]
    for k in range(4):
        x0, y0 = (k % 2) * cell, (k // 2) * cell
        c = col(paints[k])
        lo = noise(cell, 1.4, 62 + k)
        hi = noise(cell, 0.5, 66 + k)
        a = np.zeros((cell, cell, 3))
        a[:] = c
        a += (lo[..., None] - 0.5) * 26 + (hi[..., None] - 0.5) * 14
        # rust blooms
        rust = np.clip((noise(cell, 1.8, 70 + k) - 0.62) * 3.0, 0, 1)
        a = lerp(a, col("8a5232") * (0.8 + hi[..., None] * 0.4), rust[..., None] * 0.85)
        # vertical corrugation
        xx = np.arange(cell)
        a *= (1.0 + 0.06 * np.sin(xx / cell * 6.283 * 14))[None, :, None]
        # two leaves + frame
        a[:, cell // 2 - 2:cell // 2 + 2] *= 0.55
        a[:6] *= 0.6
        a[:, :6] *= 0.6
        a[:, -6:] *= 0.6
        tile = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))
        d = ImageDraw.Draw(tile)
        # handle + lock
        d.rectangle([cell // 2 + 10, cell // 2, cell // 2 + 18, cell // 2 + 30], fill=(40, 40, 40))
        # painted number
        num = str([13, 42, 7, 66][k])
        d.text((24, 24), num, fill=(240, 236, 220))
        # a little graffiti on some
        if k in (1, 2):
            for s in range(3):
                pts = [(40 + s * 30 + r.random() * 20, 150 + r.random() * 60) for _ in range(6)]
                d.line(pts, fill=[(255, 90, 160), (90, 220, 255), (255, 220, 60)][s], width=5)
        img.paste(tile, (x0, y0))
    img.save("%s/t_garage.png" % OUT)


def simple(name, base, beta, amp, seed, n=256, speck=0.0):
    lo = noise(n, beta, seed)
    hi = noise(n, 0.3, seed + 1)
    a = np.zeros((n, n, 3))
    a[:] = col(base)
    a += (lo[..., None] - 0.5) * amp + (hi[..., None] - 0.5) * amp * 0.6
    if speck:
        r = np.random.default_rng(seed + 2)
        s = r.random((n, n))
        a[s > 1 - speck] += 30
        a[s < speck] -= 30
    save(a, name)


def planks(n=256):
    a = np.zeros((n, n, 3))
    a[:] = col("a8744a")
    lo = noise(n, 1.0, 81)
    grain = np.sin(np.arange(n)[:, None] / n * 6.283 * 40 + lo * 8)
    a += grain[..., None] * 10 + (lo[..., None] - 0.5) * 20
    for k in range(4):
        a[k * 64:k * 64 + 3] *= 0.5
    save(a, "t_wood")


def rubber(n=256):
    r = np.random.default_rng(91)
    a = np.zeros((n, n, 3))
    a[:] = col("b8503c")
    s = r.random((n, n))
    a[s > 0.7] = col("c86048")
    a[s < 0.15] = col("8a3a2c")
    a += (noise(n, 1.4, 92)[..., None] - 0.5) * 20
    save(a, "t_rubber")


if __name__ == "__main__":
    asphalt()
    tiles()
    grass()
    facade()
    bark()
    garage()
    simple("t_concrete", "b4afa6", 1.3, 26, 101, speck=0.01)
    simple("t_sand", "dcc48a", 1.0, 30, 111, speck=0.03)
    simple("t_roof", "4a4648", 1.2, 18, 121, speck=0.01)
    planks()
    rubber()
    print("ok")
