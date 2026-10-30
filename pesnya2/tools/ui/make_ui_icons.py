#!/usr/bin/env python3
"""Рисованные значки интерфейса (0.20): кнопки HUD, валюты, управление и 21 способность.

Стиль — мультяшный, как у карты-диорамы: плоская заливка, толстый тёмный контур,
светлый блик сверху-слева и тень снизу-справа. Рисуется в 4× и уменьшается.
Запуск: python3 tools/ui/make_ui_icons.py  → assets/ui/*.png (128 × 128).
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "ui")
N = 512                     # холст в 4×
FINAL = 128
INK = (43, 27, 22, 255)
LINE = 22                   # толщина контура в 4×


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def mix(c, k):
    """k > 0 — светлее, k < 0 — темнее."""
    if k >= 0:
        return tuple(int(v + (255 - v) * k) for v in c[:3]) + (255,)
    return tuple(int(v * (1 + k)) for v in c[:3]) + (255,)


class Icon:
    def __init__(self):
        self.img = Image.new("RGBA", (N, N), (0, 0, 0, 0))

    def part(self, draw_fn, color, line=LINE, shade=True):
        """Нарисовать деталь: контур, заливка, блик и тень по маске."""
        m = Image.new("L", (N, N), 0)
        draw_fn(ImageDraw.Draw(m))
        if line > 0:
            out = m.filter(ImageFilter.MaxFilter(line | 1))
            self.img.paste(INK, (0, 0), out)
        self.img.paste(color, (0, 0), m)
        if shade:
            s = 18
            dark = ImageChops.subtract(m, ImageChops.offset(m, -s, -s))
            self.img.paste(mix(color, -0.22), (0, 0), dark)
            self.img.paste(mix(color, 0.35), (0, 0), ImageChops.subtract(m, ImageChops.offset(m, s // 2, s // 2)))
        return m

    def ink(self, draw_fn):
        """Тёмные линии поверх (детали, швы)."""
        m = Image.new("L", (N, N), 0)
        draw_fn(ImageDraw.Draw(m))
        self.img.paste(INK, (0, 0), m)

    def paint(self, draw_fn, color):
        m = Image.new("L", (N, N), 0)
        draw_fn(ImageDraw.Draw(m))
        self.img.paste(color, (0, 0), m)

    def save(self, name):
        # мягкая тень под значком — читается на любом фоне
        a = self.img.split()[3]
        sh = Image.new("RGBA", (N, N), (0, 0, 0, 0))
        sh.paste((0, 0, 0, 110), (0, 0), ImageChops.offset(a, 0, 14).filter(ImageFilter.GaussianBlur(10)))
        out = Image.alpha_composite(sh, self.img)
        out = out.resize((FINAL, FINAL), Image.LANCZOS)
        out.save(os.path.join(OUT, name + ".png"))


def poly(pts):
    return lambda d: d.polygon(pts, fill=255)


def ell(box):
    return lambda d: d.ellipse(box, fill=255)


def rr(box, r):
    return lambda d: d.rounded_rectangle(box, r, fill=255)


def thick(pts, w, joint=True):
    def f(d):
        d.line(pts, fill=255, width=w, joint="curve" if joint else None)
        for p in (pts[0], pts[-1]):
            d.ellipse((p[0] - w / 2, p[1] - w / 2, p[0] + w / 2, p[1] + w / 2), fill=255)
    return f


def star_pts(cx, cy, r1, r2, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        r = r1 if i % 2 == 0 else r2
        a = math.radians(rot + i * 180 / n)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def arc_pts(cx, cy, r, a0, a1, n=24):
    return [(cx + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def burst(cx, cy, r1, r2, n=9):
    return star_pts(cx, cy, r1, r2, n, rot=-90)


# ---------- HUD ----------

def bag():
    i = Icon()
    i.part(thick(arc_pts(256, 190, 70, 180, 360), 30), rgb("8a5a2b"), shade=False)
    i.part(rr((110, 170, 402, 440), 60), rgb("d9893b"))
    i.part(rr((130, 250, 382, 330), 30), rgb("b8692a"))
    i.part(rr((226, 270, 286, 320), 12), rgb("ffd34d"))
    i.save("bag")


def quests():
    i = Icon()
    i.part(rr((130, 90, 382, 430), 30), rgb("f6e2b3"))
    i.part(rr((100, 70, 412, 130), 30), rgb("e2c48a"))
    i.part(rr((100, 400, 412, 460), 30), rgb("e2c48a"))
    for y in (180, 245, 310):
        i.ink(rr((170, y, 340 if y != 310 else 290, y + 22), 10))
    i.part(lambda d: d.polygon(star_pts(350, 340, 70, 30), fill=255), rgb("ff5a3c"))
    i.save("quests")


def menu():
    i = Icon()
    for y in (130, 228, 326):
        i.part(rr((110, y, 402, y + 64), 32), rgb("fff3d6"))
    i.save("menu")


def map_icon():
    i = Icon()
    i.part(poly([(80, 140), (200, 100), (312, 140), (432, 100), (432, 380), (312, 420), (200, 380), (80, 420)]),
           rgb("8fd16a"))
    i.paint(poly([(200, 100), (312, 140), (312, 420), (200, 380)]), rgb("6fb64c"))
    i.ink(thick([(130, 330), (190, 260), (260, 300), (330, 220)], 14))
    i.part(lambda d: d.polygon([(330, 290), (290, 210), (370, 210)], fill=255), rgb("ff5a3c"), line=16)
    i.part(ell((290, 150, 370, 230)), rgb("ff5a3c"), line=16)
    i.paint(ell((314, 174, 346, 206)), rgb("fff3d6"))
    i.save("map")


def heart():
    i = Icon()
    def h(d):
        d.ellipse((90, 120, 270, 300), fill=255)
        d.ellipse((242, 120, 422, 300), fill=255)
        d.polygon([(100, 250), (412, 250), (256, 430)], fill=255)
    i.part(h, rgb("ff4a5a"))
    i.paint(ell((140, 160, 200, 210)), (255, 255, 255, 200))
    i.save("heart")


def coin():
    i = Icon()
    i.part(ell((96, 120, 416, 440)), rgb("c98a1a"), shade=False)
    i.part(ell((96, 90, 416, 410)), rgb("ffcc33"))
    i.part(ell((150, 144, 362, 356)), rgb("f2b31f"), line=12)
    # «Б» — бабки
    i.ink(lambda d: (d.rectangle((215, 180, 245, 320), fill=255), d.rectangle((215, 180, 305, 205), fill=255),
                     d.rounded_rectangle((215, 245, 310, 320), 30, fill=255)))
    i.paint(rr((245, 268, 285, 297), 12), rgb("f2b31f"))
    i.save("coin")


def rep():
    i = Icon()
    i.part(lambda d: d.polygon(star_pts(256, 270, 190, 85), fill=255), rgb("6fd3ff"))
    i.paint(ell((200, 200, 240, 240)), (255, 255, 255, 170))
    i.save("rep")


def kukukha():
    i = Icon()
    def cloud(d):
        for b in ((90, 200, 250, 360), (170, 120, 350, 300), (270, 190, 430, 350), (130, 250, 390, 400)):
            d.ellipse(b, fill=255)
    i.part(cloud, rgb("d6a8ff"))
    pts = []
    for k in range(70):
        a = k * 0.32
        r = 8 + k * 1.6
        pts.append((260 + r * math.cos(a), 270 + r * math.sin(a)))
    i.ink(thick(pts, 16))
    i.save("kukukha")


def close():
    i = Icon()
    i.part(ell((70, 70, 442, 442)), rgb("ff6a4a"))
    i.paint(thick([(180, 180), (332, 332)], 44), rgb("fff3d6"))
    i.paint(thick([(332, 180), (180, 332)], 44), rgb("fff3d6"))
    i.save("close")


def lock():
    i = Icon()
    i.part(thick(arc_pts(256, 220, 80, 180, 360) + [(336, 260)], 34), rgb("9aa3ad"), shade=False)
    i.ink(lambda d: None)
    i.part(rr((130, 220, 382, 430), 40), rgb("ffc23d"))
    i.ink(ell((236, 290, 276, 330)))
    i.ink(rr((248, 310, 264, 370), 6))
    i.save("lock")


# ---------- управление ----------

def fist():
    i = Icon()
    i.part(rr((120, 200, 380, 420), 70), rgb("ffcfa0"))
    for k in range(4):
        x = 130 + k * 62
        i.part(rr((x, 130, x + 68, 260), 34), rgb("ffcfa0"))
    i.part(rr((90, 270, 220, 350), 40), rgb("ffbf8a"))
    i.part(rr((150, 400, 360, 470), 20), rgb("e04a3a"))
    i.save("fist")


def dodge():
    i = Icon()
    for k, y in enumerate((180, 260, 340)):
        i.part(rr((60 + k * 20, y, 220 + k * 10, y + 30), 15), rgb("bfefff"), line=14, shade=False)
    i.part(lambda d: (d.rounded_rectangle((230, 260, 450, 380), 50, fill=255),
                      d.rounded_rectangle((240, 170, 340, 330), 40, fill=255)), rgb("ff5a3c"))
    i.part(rr((220, 370, 460, 420), 24), rgb("fff3d6"))
    i.ink(thick([(260, 230), (310, 260)], 10))
    i.ink(thick([(260, 270), (320, 300)], 10))
    i.save("dodge")


def hand():
    i = Icon()
    i.part(rr((150, 230, 370, 440), 70), rgb("ffcfa0"))
    for k, h in enumerate((150, 100, 110, 160)):
        x = 160 + k * 52
        i.part(rr((x, h, x + 50, 300), 25), rgb("ffcfa0"))
    i.part(lambda d: d.rounded_rectangle((90, 250, 150, 400), 30, fill=255), rgb("ffcfa0"))
    i.save("hand")


def rot(name, flip):
    i = Icon()
    a = arc_pts(256, 266, 140, 200, 470) if not flip else arc_pts(256, 266, 140, 70, -200)
    i.part(thick(a, 46), rgb("fff3d6"))
    end = a[-1]
    prev = a[-4]
    ang = math.atan2(end[1] - prev[1], end[0] - prev[0])
    tip = (end[0] + 70 * math.cos(ang), end[1] + 70 * math.sin(ang))
    l = (end[0] + 70 * math.cos(ang + 2.2), end[1] + 70 * math.sin(ang + 2.2))
    r = (end[0] + 70 * math.cos(ang - 2.2), end[1] + 70 * math.sin(ang - 2.2))
    i.part(poly([tip, l, r]), rgb("fff3d6"))
    i.save(name)


# ---------- способности: что на значке, тем и бьёт ----------

def paper(i, box, color="fff7e0", tilt=0):
    x0, y0, x1, y1 = box
    c = ((x0 + x1) / 2, (y0 + y1) / 2)
    def rp(p):
        a = math.radians(tilt)
        dx, dy = p[0] - c[0], p[1] - c[1]
        return (c[0] + dx * math.cos(a) - dy * math.sin(a), c[1] + dx * math.sin(a) + dy * math.cos(a))
    pts = [rp(p) for p in [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]]
    i.part(poly(pts), rgb(color))
    for k in range(3):
        yy = y0 + (y1 - y0) * (0.3 + 0.2 * k)
        i.ink(thick([rp((x0 + 30, yy)), rp((x1 - 30 - (40 if k == 2 else 0), yy))], 12))


def abl(name, fn):
    i = Icon()
    fn(i)
    i.save(name)


def a11(i):   # Квитанция в лоб
    paper(i, (150, 90, 360, 400), tilt=-14)
    i.part(lambda d: d.polygon(burst(330, 360, 110, 60, 8), fill=255), rgb("ffcc33"))
    i.paint(ell((310, 340, 350, 380)), rgb("ff5a3c"))


def a12(i):   # Рывок по знакомству
    for k, y in enumerate((170, 250, 330)):
        i.part(rr((50, y, 260 - k * 30, y + 34), 17), rgb("bfefff"), line=14, shade=False)
    i.part(ell((240, 150, 450, 360)), rgb("ff8a3d"))
    i.ink(thick([(300, 240), (360, 255), (300, 280)], 18))


def a13(i):   # Стол — это щит
    i.part(rr((90, 150, 422, 230), 20), rgb("b5753e"))
    i.part(rr((120, 230, 170, 430), 16), rgb("8d5a2c"))
    i.part(rr((342, 230, 392, 430), 16), rgb("8d5a2c"))
    i.part(lambda d: d.polygon([(256, 250), (330, 280), (320, 370), (256, 420), (192, 370), (182, 280)], fill=255),
           rgb("6fd3ff"), line=16)


def a14(i):   # Групповая жалоба — мегафон
    i.part(poly([(140, 220), (360, 110), (360, 410), (140, 300)]), rgb("ff5a3c"))
    i.part(rr((90, 210, 160, 310), 20), rgb("fff3d6"))
    i.part(rr((180, 290, 230, 400), 18), rgb("8d5a2c"))
    for k in range(3):
        i.ink(thick(arc_pts(370, 260, 60 + k * 40, -35, 35, 8), 12))


def a15(i):   # Ой, простите — пузырь и звёздочка удара
    i.part(lambda d: (d.ellipse((70, 90, 400, 330), fill=255), d.polygon([(150, 300), (120, 400), (230, 320)], fill=255)),
           rgb("fff3d6"))
    i.ink(lambda d: d.text((150, 130), "ОЙ", fill=255, font=_font(140)))
    i.part(lambda d: d.polygon(burst(380, 380, 100, 50, 7), fill=255), rgb("ffcc33"))


def a16(i):   # По регламенту — печать
    i.part(ell((90, 330, 422, 450)), rgb("ff5a3c"), shade=False)
    i.part(rr((200, 90, 312, 260), 40), rgb("b5753e"))
    i.part(rr((130, 250, 382, 350), 26), rgb("6b4a35"))
    i.paint(rr((150, 360, 362, 420), 16), rgb("ffd0c0"))


def a17(i):   # Финальная разборка — большой взрыв-кулак
    i.part(lambda d: d.polygon(burst(256, 256, 220, 120, 11), fill=255), rgb("ffcc33"))
    i.part(lambda d: d.polygon(burst(256, 256, 140, 80, 9), fill=255), rgb("ff5a3c"))
    i.part(rr((196, 196, 316, 316), 40), rgb("ffcfa0"))


def a21(i):   # Карманная правда — рогатка
    i.part(thick([(256, 450), (256, 300), (170, 150)], 40), rgb("8d5a2c"))
    i.part(thick([(256, 300), (342, 150)], 40), rgb("8d5a2c"))
    i.ink(thick([(170, 160), (256, 230), (342, 160)], 12))
    i.part(ell((220, 190, 292, 262)), rgb("ffcc33"))


def a22(i):   # Не моя смена — часы
    i.part(ell((90, 90, 422, 422)), rgb("fff3d6"))
    i.ink(thick([(256, 256), (256, 150)], 22))
    i.ink(thick([(256, 256), (330, 300)], 22))
    i.part(lambda d: d.polygon([(330, 60), (450, 60), (390, 140)], fill=255), rgb("6fd3ff"), line=14)


def a23(i):   # Скидка за спину — ценник
    i.part(poly([(120, 220), (260, 90), (430, 90), (430, 260), (290, 400)]), rgb("ffcc33"))
    i.paint(ell((360, 130, 400, 170)), INK)
    i.ink(lambda d: d.text((190, 190), "%", fill=255, font=_font(160)))


def a24(i):   # Ложный талон
    i.part(rr((80, 160, 432, 360), 30), rgb("8fd16a"))
    i.ink(lambda d: [d.ellipse((60, 230, 110, 290), fill=0), d.ellipse((402, 230, 452, 290), fill=0)])
    i.paint(ell((60, 235, 105, 285)), (0, 0, 0, 0))
    i.ink(lambda d: d.text((160, 180), "?", fill=255, font=_font(160)))
    i.ink(thick([(280, 220), (380, 220)], 14))
    i.ink(thick([(280, 290), (360, 290)], 14))


def a25(i):   # Тихий скандал — палец у губ
    i.part(ell((100, 130, 412, 440)), rgb("ff8a8a"))
    i.paint(rr((180, 300, 332, 330), 14), INK)
    i.part(rr((236, 70, 290, 380), 26), rgb("ffcfa0"))


def a26(i):   # Штраф без подписи — веер квитанций
    for t, dx in ((-24, -60), (0, 0), (24, 60)):
        paper(i, (170 + dx, 100, 340 + dx, 400), tilt=t)


def a27(i):   # Испарился из чата — облачко пара
    i.part(lambda d: [d.ellipse(b, fill=255) for b in ((80, 220, 240, 380), (170, 120, 350, 300),
                                                       (280, 200, 440, 360), (150, 260, 380, 420))], rgb("e8f4ff"))
    i.ink(lambda d: d.text((190, 200), "...", fill=255, font=_font(120)))


def a31(i):   # Пинг Вселенной — антенна и волны
    i.part(poly([(256, 200), (330, 440), (182, 440)]), rgb("9aa3ad"))
    i.part(ell((216, 150, 296, 230)), rgb("6fd3ff"))
    for k in range(2):
        i.ink(thick(arc_pts(256, 190, 100 + k * 60, -150, -30, 10), 16))


def a32(i):   # Роутер в сердцах
    i.part(thick([(170, 250), (130, 90)], 22), rgb("3a3a44"))
    i.part(thick([(342, 250), (382, 90)], 22), rgb("3a3a44"))
    i.part(rr((80, 240, 432, 380), 34), rgb("4f5a6a"))
    for k in range(4):
        i.paint(ell((130 + k * 60, 295, 160 + k * 60, 325)), rgb("6fff9a"))
    i.part(lambda d: (d.ellipse((330, 330, 400, 400), fill=255), d.ellipse((380, 330, 450, 400), fill=255),
                      d.polygon([(334, 380), (446, 380), (390, 450)], fill=255)), rgb("ff4a5a"), line=14)


def a33(i):   # Кукуха в облаке
    kuk = Icon()
    i.part(lambda d: [d.ellipse(b, fill=255) for b in ((70, 200, 230, 360), (160, 100, 360, 300), (280, 190, 440, 350),
                                                       (120, 250, 400, 400))], rgb("bfe3ff"))
    pts = [(256 + (6 + k * 1.5) * math.cos(k * 0.33), 260 + (6 + k * 1.5) * math.sin(k * 0.33)) for k in range(60)]
    i.ink(thick(pts, 14))


def a34(i):   # Перенос розетки
    i.part(rr((110, 110, 402, 402), 60), rgb("fff3d6"))
    i.part(ell((150, 150, 362, 362)), rgb("e2e2dc"), line=14)
    i.paint(rr((200, 220, 225, 290), 10), INK)
    i.paint(rr((287, 220, 312, 290), 10), INK)
    i.part(poly([(300, 40), (230, 200), (290, 200), (240, 330), (360, 160), (300, 160), (350, 40)]), rgb("ffcc33"), line=14)


def a35(i):   # Файрвол по-братски
    i.part(lambda d: d.polygon([(130, 260), (180, 140), (210, 200), (256, 70), (300, 200), (330, 140), (382, 260)],
                               fill=255), rgb("ff8a3d"))
    i.part(rr((90, 250, 422, 440), 16), rgb("c75b3a"))
    for y in (300, 360):
        i.ink(thick([(100, y), (412, y)], 10))
    for x, y0 in ((200, 250), (310, 250), (150, 300), (256, 300), (360, 300), (200, 360), (310, 360)):
        i.ink(thick([(x, y0 + 6), (x, y0 + 54)], 10))


def a36(i):   # Бесплатная молодость — таблетка
    i.part(lambda d: d.rounded_rectangle((110, 190, 402, 322), 66, fill=255), rgb("fff3d6"))
    i.paint(lambda d: d.rounded_rectangle((256, 196, 396, 316), 60, fill=255), rgb("ff6ab0"))
    i.paint(rr((256, 196, 300, 316), 0), rgb("ff6ab0"))
    i.part(lambda d: d.polygon(star_pts(380, 140, 70, 30, 4, rot=-90), fill=255), rgb("ffcc33"), line=12)


def a37(i):   # Обновление без согласия
    i.part(ell((80, 80, 432, 432)), rgb("6fd3ff"))
    i.paint(thick(arc_pts(256, 256, 110, -60, 220, 20), 34), rgb("fff3d6"))
    end = (256 + 110 * math.cos(math.radians(-60)), 256 + 110 * math.sin(math.radians(-60)))
    i.paint(poly([(end[0] + 50, end[1] - 10), (end[0] - 40, end[1] - 40), (end[0] - 5, end[1] + 55)]), rgb("fff3d6"))
    i.paint(poly([(256, 220), (300, 290), (212, 290)]), rgb("fff3d6"))


_FONTS = {}


def _font(size):
    from PIL import ImageFont
    if size not in _FONTS:
        p = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "fonts", "RussoOne-Regular.ttf")
        _FONTS[size] = ImageFont.truetype(p, size)
    return _FONTS[size]


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for f in (bag, quests, menu, map_icon, heart, coin, rep, kukukha, close, lock, fist, dodge, hand):
        f()
    rot("rot_right", False)
    rot("rot_left", True)
    for name, fn in (("ABL_1_1", a11), ("ABL_1_2", a12), ("ABL_1_3", a13), ("ABL_1_4", a14), ("ABL_1_5", a15),
                     ("ABL_1_6", a16), ("ABL_1_7", a17), ("ABL_2_1", a21), ("ABL_2_2", a22), ("ABL_2_3", a23),
                     ("ABL_2_4", a24), ("ABL_2_5", a25), ("ABL_2_6", a26), ("ABL_2_7", a27), ("ABL_3_1", a31),
                     ("ABL_3_2", a32), ("ABL_3_3", a33), ("ABL_3_4", a34), ("ABL_3_5", a35), ("ABL_3_6", a36),
                     ("ABL_3_7", a37)):
        abl(name, fn)
    print("значков:", len([f for f in os.listdir(OUT) if f.endswith(".png")]))
