#!/usr/bin/env python3
"""Новая карта Погуляя по утверждённому концепт-пакету «Рубин» (29.10.2026).

    python3 tools/importers/import_rubin_layout.py

Источник — docs/source/rubin/geometry_PG_district.json: сцена PG_district из пакета
(метры, Z вверх, район X = план X, Y = 3000 − план Y). Из неё берутся без изменений:
улицы (коллектор 20 м, местные 10 м, кольца переулков 4 м, дорожки 4 м), объёмы домов
с высотой и материалом, деревья и рощи, центральные площадки и ориентиры секторов.

Задание пакета (AI_BRIEF_RU.txt): «промежутки наполнять дворами, мастерскими, огородами,
проходами, малыми сценами», «между точками нужны петли, короткие дворовые пути».
Это наполнение строится здесь же, детерминированно (seed 29102026), и помечается fill:
- переулки 5 м по свободным линиям сетки секторов (петли между домами);
- у каждого дома двор: сараи, гаражи, огороды, детская площадка, бельё;
- в больших пустотах — частные дома в 2 этажа с огородом и мастерские.
Наполнение не заходит на дома, улицы, кроны, точки реестра, арены боссов и три площадки.

Запись: data/pogulyay_layout.json. Точки реестра остаются в data/district_pogulyay.json;
здесь же поправляются названия секторов и две точки мобов, которые попали в новые дома.
"""
import json
import math
import random
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "source" / "rubin" / "geometry_PG_district.json"
OUT = ROOT / "data" / "pogulyay_layout.json"
DISTRICT = ROOT / "data" / "district_pogulyay.json"
SEED = 29102026
SIZE = 3000.0

# Площадки 250 × 250 м (центры по rubin-layout.json): их строят модули сцены, наполнение не лезет.
CORES = {"start": (360, 2640), "market": (1500, 2600), "square": (1500, 1500)}
CORE_HALF = 125.0
# Ориентиры секторов: объект пакета → модуль сцены (DistrictSites)
SITE_OF = {
    "PG_A1_": "park", "PG_A2_theatre": "theatre", "PG_A3_": "showcase", "PG_B1_main": "workshops",
    "PG_B3_": "tv", "PG_C3_": "boiler", "PG_C1_": "start", "PG_C2_": "market", "PG_B2_": "square",
}
SECTOR_NAMES = {
    "A1": "Парк чужого счастья", "A2": "Театр и клубные переулки", "A3": "Показательный квартал",
    "B1": "Старые дворы", "B2": "Площадь с тарелкой", "B3": "Тридцать лайков",
    "C1": "Похмельная", "C2": "Сытый конец", "C3": "Служебный задворок",
}
# Точки мобов, которые новые объёмы накрыли: сдвиг на ближайшее свободное место перед домом.
POINT_MOVES = {"M5-1": [1500, 548], "M10-2": [2400, 2690]}
# Павел у «НЛО напрокат» в новом дворе (разбитый киоск пакета стоит в 398…406 × 2667…2673)
PAVEL_YARD = [396, 2679]


def bbox(o):
    v = o["vertices"]
    xs = [p[0] for p in v]
    ys = [SIZE - p[1] for p in v]
    zs = [p[2] for p in v]
    return min(xs), min(ys), max(xs), max(ys), min(zs), max(zs)


def site_of(name):
    for prefix, site in SITE_OF.items():
        if name.startswith(prefix):
            return site
    return ""


def rect_hit(a, b, pad=0.0):
    return a[0] - pad < b[2] and a[2] + pad > b[0] and a[1] - pad < b[3] and a[3] + pad > b[1]


def seg_dist(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / max(dx * dx + dy * dy, 1e-6)))
    return math.hypot(px - (ax + dx * t), py - (ay + dy * t))


def main():
    geo = json.loads(SRC.read_text())["scenes"]["PG_district"]
    district = json.loads(DISTRICT.read_text())
    points = district["points"]
    arenas = []
    for p in points:
        if p["type"] == "boss":
            (x, y), (w, h) = p["plan_position_m"], p["arena_size_m"]
            arenas.append((x - w / 2, y - h / 2, x + w / 2, y + h / 2))
    cores = [(cx - CORE_HALF, cy - CORE_HALF, cx + CORE_HALF, cy + CORE_HALF) for cx, cy in CORES.values()]

    streets, buildings, trees, sites = [], [], [], {}
    for o in geo:
        n = o["name"]
        x0, y0, x1, y1, z0, z1 = bbox(o)
        site = site_of(n)
        if n in ("collector_pavement", "local") or n.endswith("south_local_street") \
                or re.match(r"^[ABC]\d_(alley|footpath)$", n):
            w, h = x1 - x0, y1 - y0
            kind = {"collector_pavement": "collector", "local": "local"}.get(n, "local" if "street" in n else
                                                                             ("alley" if "alley" in n else "path"))
            if kind != "collector" and site in ("start", "market", "square") and "street" in n:
                kind = "local"
            if w >= h:
                streets.append({"a": [x0, (y0 + y1) / 2], "b": [x1, (y0 + y1) / 2], "w": round(h, 1), "kind": kind})
            else:
                streets.append({"a": [(x0 + x1) / 2, y0], "b": [(x0 + x1) / 2, y1], "w": round(w, 1), "kind": kind})
        elif re.match(r"^[ABC]\d_mass$", n):
            r = (x0, y0, x1, y1)
            if any(rect_hit(r, a, 4) for a in arenas):
                continue          # арена босса — канон, дом пакета на ней не ставится
            buildings.append({"r": [x0, y0, x1 - x0, y1 - y0], "h": z1, "mat": o["material"], "kind": "house",
                              "sector": n[:2]})
        elif re.match(r"^[ABC]\d_(tree|grove)_crown$", n) or n.endswith("tree_crown"):
            if site in ("start", "market", "square"):
                continue          # деревья площадок сажает их модуль
            trees.append([round((x0 + x1) / 2, 1), round((y0 + y1) / 2, 1), round((x1 - x0) / 2, 1), round(z1, 1),
                          "grove" if "grove" in n else "tree"])
        if site:
            s = sites.setdefault(site, {"id": site, "r": [x0, y0, x1, y1], "objects": []})
            s["r"] = [min(s["r"][0], x0), min(s["r"][1], y0), max(s["r"][2], x1), max(s["r"][3], y1)]
            if "window" not in n:
                s["objects"].append({"name": n, "r": [round(x0, 2), round(y0, 2), round(x1 - x0, 2), round(y1 - y0, 2)],
                                     "z": [round(z0, 2), round(z1, 2)], "mat": o["material"]})
    # корпуса площадок и ориентиров тоже дома: коллизия, карта, проверка доступности
    for site in sites.values():
        for ob in site["objects"]:
            n = ob["name"]
            if ob["mat"] in ("brick", "plaster", "teal") and not re.search(r"(roof|door|stall|kiosk|ground|paving|street|plaza|sign|gate|bench)", n) \
                    and ob["z"][1] >= 4.5:
                x, y, w, h = ob["r"]
                buildings.append({"r": [x, y, w, h], "h": ob["z"][1], "mat": ob["mat"], "kind": "site", "site": site["id"],
                                  "name": n})
            elif n.startswith("PG_C1_garage_") and not n.endswith("roof"):
                x, y, w, h = ob["r"]
                buildings.append({"r": [x, y, w, h], "h": ob["z"][1], "mat": "metal", "kind": "site", "site": "start",
                                  "name": n})

    rng = random.Random(SEED)
    solid = [(b["r"][0], b["r"][1], b["r"][0] + b["r"][2], b["r"][1] + b["r"][3]) for b in buildings]
    point_xy = [(POINT_MOVES.get(p["id"], p["plan_position_m"])) for p in points]

    def free(r, pad=3.0, street_pad=3.0, tree_pad=1.0):
        if r[0] < 30 or r[1] < 30 or r[2] > SIZE - 30 or r[3] > SIZE - 30:
            return False
        if any(rect_hit(r, s, pad) for s in solid) or any(rect_hit(r, a, 6) for a in arenas) \
                or any(rect_hit(r, c, 4) for c in cores):
            return False
        cx, cy = (r[0] + r[2]) / 2, (r[1] + r[3]) / 2
        half = math.hypot(r[2] - r[0], r[3] - r[1]) / 2
        for s in streets:
            if seg_dist(cx, cy, *s["a"], *s["b"]) < s["w"] / 2 + half + street_pad:
                return False
        for t in trees:
            if math.hypot(cx - t[0], cy - t[1]) < t[2] + half + tree_pad:
                return False
        for px, py in point_xy:
            if math.hypot(cx - px, cy - py) < half + 10:
                return False
        return True

    # 1. переулки 5 м по свободным линиям сетки (дома пакета стоят рядами через 140 м)
    lanes = []
    for sx in range(3):
        for sy in range(3):
            ox, oy = sx * 1000, sy * 1000
            for k in range(6):
                for vertical in (True, False):
                    c = (ox if vertical else oy) + 170 + 140 * k
                    lo, hi = (oy if vertical else ox) + 40, (oy if vertical else ox) + 960
                    run = []
                    t = lo
                    while t <= hi:
                        x, y = (c, t) if vertical else (t, c)
                        probe = (x - 4, y - 4, x + 4, y + 4)
                        ok = not any(rect_hit(probe, s, 1.5) for s in solid) and \
                            not any(rect_hit(probe, cc, 2) for cc in cores) and \
                            not any(math.hypot(x - tr[0], y - tr[1]) < tr[2] * 0.6 + 2 for tr in trees)
                        if ok:
                            run.append(t)
                        if (not ok or t + 4 > hi) and run:
                            if run[-1] - run[0] >= 60:
                                a = (c, run[0]) if vertical else (run[0], c)
                                b = (c, run[-1]) if vertical else (run[-1], c)
                                lanes.append({"a": list(a), "b": list(b), "w": 5.0, "kind": "lane", "fill": True})
                            run = []
                        t += 4
    streets.extend(lanes)

    # 2. дворы у домов пакета: сараи, гаражи, огороды, площадки, бельё
    fill, plots = [], []

    def put_box(cx, cy, w, d, h, kind, mat, street_pad=3.0):
        r = (cx - w / 2, cy - d / 2, cx + w / 2, cy + d / 2)
        if not free(r, street_pad=street_pad):
            return False
        solid.append(r)
        fill.append({"r": [round(r[0], 1), round(r[1], 1), w, d], "h": h, "mat": mat, "kind": kind, "fill": True})
        return True

    def put_plot(cx, cy, w, d, kind):
        r = (cx - w / 2, cy - d / 2, cx + w / 2, cy + d / 2)
        if not free(r, pad=2.0, street_pad=2.0):
            return False
        solid.append(r)          # огород не топчут: на нём не строят и не сажают
        plots.append({"r": [round(r[0], 1), round(r[1], 1), w, d], "kind": kind})
        return True

    for b in list(buildings):
        if b["kind"] != "house":
            continue
        x, y, w, d = b["r"]
        cx, cy = x + w / 2, y + d / 2
        # двор — южная сторона до дорожки (+35 м) и северная
        for _ in range(rng.randint(2, 4)):
            side = rng.choice((-1, 1, 1))
            px = cx + rng.uniform(-w / 2 - 10, w / 2 + 10)
            py = cy + side * rng.uniform(d / 2 + 9, d / 2 + 26)
            roll = rng.random()
            if roll < 0.35:
                put_plot(px, py, rng.choice((8, 10, 12)), rng.choice((6, 8)), "garden")
            elif roll < 0.55:
                put_box(px, py, rng.choice((3, 4, 5)), rng.choice((3, 4)), 2.6, "shed", "wood")
            elif roll < 0.72:
                n = rng.randint(2, 5)
                gx = px - n * 2.0
                for i in range(n):
                    put_box(gx + i * 4.0 + 2.0, py, 3.8, 6.0, 2.8, "garage", "metal")
            elif roll < 0.86:
                put_plot(px, py, 14, 10, "playground")
            else:
                put_plot(px, py, 10, 1.5, "laundry")

    # 3. частный сектор вдоль переулков и местных улиц: дома лицом к проходу, огород за домом
    for st in streets:
        if st["kind"] not in ("lane", "local", "alley"):
            continue
        ax, ay = st["a"]
        bx, by = st["b"]
        length = math.hypot(bx - ax, by - ay)
        if length < 20:
            continue
        ux, uy = (bx - ax) / length, (by - ay) / length
        nx, ny = -uy, ux
        for side in (-1, 1):
            t = rng.uniform(6, 14)
            while t < length - 6:
                roll = rng.random()
                w, d = rng.choice((8, 9, 10, 12)), rng.choice((8, 9, 10))
                off = st["w"] / 2 + 4.5 + d / 2
                cx, cy = ax + ux * t + nx * side * off, ay + uy * t + ny * side * off
                if roll < 0.5:
                    if put_box(cx, cy, w if abs(ux) > 0.5 else d, d if abs(ux) > 0.5 else w,
                               rng.choice((3.0, 6.0, 6.0)), "cottage", rng.choice(("plaster", "plaster", "brick", "wood")),
                               street_pad=-3.0):
                        back = off + d / 2 + 6
                        put_plot(ax + ux * t + nx * side * back, ay + uy * t + ny * side * back,
                                 9 if abs(ux) > 0.5 else 8, 8 if abs(ux) > 0.5 else 9, "garden")
                elif roll < 0.72:
                    put_box(cx, cy, 16 if abs(ux) > 0.5 else 11, 11 if abs(ux) > 0.5 else 16,
                            rng.choice((4.5, 6.0)), "workshop", rng.choice(("brick", "metal")), street_pad=-4.0)
                elif roll < 0.76:
                    n = rng.randint(3, 5)
                    for i in range(n):
                        gx, gy = cx + ux * (i - n / 2) * 4.0, cy + uy * (i - n / 2) * 4.0
                        put_box(gx, gy, 3.8 if abs(ux) > 0.5 else 6.0, 6.0 if abs(ux) > 0.5 else 3.8, 2.8, "garage", "metal",
                                street_pad=-1.0)
                    t += n * 4.0
                t += w + rng.uniform(6, 16)

    # 4. редкие мастерские и сараи в глубине кварталов
    for gy in range(60, 2960, 40):
        for gx in range(60, 2960, 40):
            if rng.random() > 0.14:
                continue
            cx, cy = gx + rng.uniform(-10, 10), gy + rng.uniform(-10, 10)
            if rng.random() < 0.5:
                put_box(cx, cy, rng.choice((14, 18)), rng.choice((10, 12)), rng.choice((4.5, 6.0)), "workshop",
                        rng.choice(("brick", "metal")))
            else:
                put_box(cx, cy, rng.choice((3, 4)), rng.choice((3, 4)), 2.6, "shed", "wood")

    buildings.extend(fill)
    # переулки, аллеи и тропы свободны: заполнение на них убираем, дом макета, задевший ось
    # аллеи краем, ужимаем до её обочины (в пакете дома местами начинаются прямо на оси)
    narrow = [st for st in streets if st["kind"] not in ("collector", "local")]
    kept = []
    for b in buildings:
        x, y, w, d = b["r"]
        ok = True
        for st in narrow:
            (ax, ay), (bx, by) = st["a"], st["b"]
            hw = st["w"] / 2.0
            lane = (min(ax, bx) - hw, min(ay, by) - hw, max(ax, bx) + hw, max(ay, by) + hw)
            if not rect_hit((x, y, x + w, y + d), lane):
                continue
            if b.get("fill"):
                ok = False
                break
            if ax == bx:
                if x + w / 2.0 >= ax:
                    w, x = x + w - lane[2] - 0.5, lane[2] + 0.5
                else:
                    w = lane[0] - 0.5 - x
            elif ay == by:
                if y + d / 2.0 >= ay:
                    d, y = y + d - lane[3] - 0.5, lane[3] + 0.5
                else:
                    d = lane[1] - 0.5 - y
            if w < 6.0 or d < 6.0:
                ok = False
                break
        if ok:
            b["r"] = [x, y, w, d]
            kept.append(b)
    buildings = kept
    for b in buildings:
        b["r"] = [round(v, 2) for v in b["r"]]
        b["h"] = round(b["h"], 1)
    layout = {
        "schema": "pogulyay-layout/1.0",
        "source": "docs/source/rubin/geometry_PG_district.json (концепт-пакет «Рубин», 29.10.2026)",
        "coordinates": "метры плана района: X — восток, Y — юг, начало в северо-западном углу",
        "cores": {k: [v[0] - CORE_HALF, v[1] - CORE_HALF, CORE_HALF * 2, CORE_HALF * 2] for k, v in CORES.items()},
        "streets": streets,
        "buildings": buildings,
        "trees": trees,
        "plots": plots,
        "sites": list(sites.values()),
    }
    OUT.write_text(json.dumps(layout, ensure_ascii=False, separators=(",", ":")))

    for s in district["sectors"]:
        s["name"] = SECTOR_NAMES[s["id"]]
    for p in points:
        if p["id"] in POINT_MOVES:
            p["plan_position_m"] = POINT_MOVES[p["id"]]
            x, y = POINT_MOVES[p["id"]]
            p["godot_position_m"] = [x - 1500, 0, y - 1500]      # формула манифеста: центр района — ноль
            p["chunk"] = [int(x // 250), int(y // 250)]
            p["placement_note"] = "0.11: сдвинута с объёма нового макета «Рубин» на свободное место рядом"
    for o in district["npc_position_overrides"]:
        if o["npc_id"] == "N07":
            o["yard_plan_position_m"] = PAVEL_YARD
            o["yard_note"] = "Двор «Похмельной» по макету «Рубин»: у разбитого киоска «НЛО напрокат» (D-051)."
    district["revision_notes"]["layout"] = "0.11: улицы, дома и площадки — data/pogulyay_layout.json (пакет «Рубин»)"
    DISTRICT.write_text(json.dumps(district, ensure_ascii=False, indent=1))
    kinds = {}
    for b in buildings:
        kinds[b["kind"]] = kinds.get(b["kind"], 0) + 1
    print("улиц %d (переулков %d), домов %s, деревьев %d, участков %d, площадок %s" % (
        len(streets), len(lanes), kinds, len(trees), len(plots), sorted(sites)))


if __name__ == "__main__":
    main()
