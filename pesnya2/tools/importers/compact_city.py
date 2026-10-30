#!/usr/bin/env python3
"""Компактный город (0.17, D-059): каждый район 3 × 3 км ужимается до 1 × 1 км.

    python3 tools/importers/compact_city.py

Запускать после import_rubin_layout.py и import_pogulyay_map.py: правит их выходы
data/pogulyay_layout.json и data/district_pogulyay.json на месте. Повторный запуск ничего
не делает (в макете есть ключ "compact").

Дома, дороги и площадки не масштабируются: из каждого сектора 1000 × 1000 м берётся окно
W = 333.3 м вокруг его площадки (рынок, площадь, базар, двор старта), остальное вырезается.
Окна встают вплотную, по стыкам окон проходят новые улицы (местные 10 м, в Погуляе одна —
коллектор). Окно — чистый сдвиг, поэтому площадки и двор старта остаются целыми:
  * дома, огороды и деревья — новые координаты плана (сдвиг окна), всё, что не влезло
    в окно с отступом от стыковой улицы, выброшено;
  * улицы обрезаны по окну;
  * площадки хранят исходные координаты и свой сдвиг "shift" (код площадок не меняется,
    переводит точки через District.site_to_world);
  * точки реестра вне окон переносятся пропорционально внутрь окна и отодвигаются от домов;
    радиусы безопасных зон, спавна и арены боссов ужаты вместе с городом.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LAYOUT = ROOT / "data" / "pogulyay_layout.json"
DISTRICT = ROOT / "data" / "district_pogulyay.json"

K = 3.0                       # во сколько раз ужимается сторона района
SECTOR = 1000.0
W = SECTOR / K                # окно сектора в новом плане
SEAM_W = 10.0                 # стыковая улица
COLLECTOR_W = 16.0
CHUNK = 250.0
SOURCE_ORIGIN = (360.0, 2690.0)
RADIUS_K = {"safe": 0.5, "mob": 0.6}
SITES = []
ARENA_K = 0.65


def rect_of(r):
    """[x, y, w, h] → (x0, y0, x1, y1)."""
    return (r[0], r[1], r[0] + r[2], r[1] + r[3])


def inside(a, b, m=0.0):
    return a[0] >= b[0] + m and a[1] >= b[1] + m and a[2] <= b[2] - m and a[3] <= b[3] - m


def overlaps(a, b, m=0.0):
    return a[0] < b[2] + m and a[2] > b[0] - m and a[1] < b[3] + m and a[3] > b[1] - m


def clip(a, b, r):
    """Отрезок a–b внутри прямоугольника r (Лян — Барски) или None."""
    t0, t1 = 0.0, 1.0
    dx, dy = b[0] - a[0], b[1] - a[1]
    for p, q in ((-dx, a[0] - r[0]), (dx, r[2] - a[0]), (-dy, a[1] - r[1]), (dy, r[3] - a[1])):
        if p == 0:
            if q < 0:
                return None
            continue
        t = q / p
        if p < 0:
            t0 = max(t0, t)
        else:
            t1 = min(t1, t)
        if t0 > t1:
            return None
    return ([a[0] + dx * t0, a[1] + dy * t0], [a[0] + dx * t1, a[1] + dy * t1])


def r2(v):
    return round(v, 2)


def best_window(sx, sy, inner, buildings):
    """Окно сектора: площадка целиком внутри, а вокруг — как можно больше пятиэтажек и застройки.
    Пятиэтажки весят 10, остальные дома 1: без этого окно вокруг площади попадало на пустырь."""
    m = SEAM_W / 2 + 3.0
    near = [rect_of(b["r"]) + (10 if b["kind"] == "house" else 1,) for b in buildings
            if sx - 50 <= b["r"][0] < sx + SECTOR + 50 and sy - 50 <= b["r"][1] < sy + SECTOR + 50]
    site = max(inner, key=lambda s: (s["r"][2] - s["r"][0]) * (s["r"][3] - s["r"][1]))["r"] if inner else None
    best = (-1, sx + (SECTOR - W) / 2, sy + (SECTOR - W) / 2)
    for wx in range(int(sx), int(sx + SECTOR - W) + 1, 10):
        if site and not (wx + m <= site[0] and site[2] <= wx + W - m):
            continue
        for wy in range(int(sy), int(sy + SECTOR - W) + 1, 10):
            if site and not (wy + m + 3 <= site[1] and site[3] <= wy + W - m - 3):
                continue
            score = sum(b[4] for b in near if b[0] >= wx + m and b[1] >= wy + m and b[2] <= wx + W - m and b[3] <= wy + W - m)
            if score > best[0]:
                best = (score, wx, wy)
    return best[1], best[2]


def cosy_fill(windows, buildings, plots, trees, streets, site_rects, yard, points):
    """Уют на пустырях (0.17): где после вырезки остался голый газон, сажаем деревья, огороды,
    бельевые верёвки и детские площадки — двор, а не поле. Детерминированно, сетка 14 м."""
    import random
    rnd = random.Random(17)
    cell = 10.0
    grid = {}
    for b in buildings + plots:
        x0, y0, x1, y1 = rect_of(b["r"])
        for gx in range(int(x0 // 50), int(x1 // 50) + 1):
            for gy in range(int(y0 // 50), int(y1 // 50) + 1):
                grid.setdefault((gx, gy), []).append((x0, y0, x1, y1))
    arenas = []
    for p in points:
        if p["type"] == "boss":
            x, y = p["plan_position_m"]
            sx, sy = p["arena_size_m"]
            arenas.append((x - sx / 2 - 4, y - sy / 2 - 4, x + sx / 2 + 4, y + sy / 2 + 4))
    # большие площадки (250 м) — это в основном газон вокруг ядра: закрываем ядро (60 % площадки)
    # и каждый объект пакета, по краям площадки можно сажать
    blocked = [yard] + arenas
    for s in SITES:
        if s["id"] == "start":
            continue                  # 0.18: двор старта закрыт целиком (yard), кольцо газона вокруг — сажаем
        dx, dy = s["shift"]
        x0, y0, x1, y1 = s["r"][0] + dx, s["r"][1] + dy, s["r"][2] + dx, s["r"][3] + dy
        if x1 - x0 < 150:
            blocked.append((x0, y0, x1, y1))
            continue
        cx, cy, hx, hy = (x0 + x1) / 2, (y0 + y1) / 2, (x1 - x0) * 0.3, (y1 - y0) * 0.3
        blocked.append((cx - hx, cy - hy, cx + hx, cy + hy))
        for o in s.get("objects", []):
            r = o.get("r")
            if r:
                blocked.append((r[0] + dx - 4, r[1] + dy - 4, r[0] + r[2] + dx + 4, r[1] + r[3] + dy + 4))

    def seg_dist(px, py, a, b):
        dx, dy = b[0] - a[0], b[1] - a[1]
        L = dx * dx + dy * dy
        t = 0.0 if L == 0 else max(0.0, min(1.0, ((px - a[0]) * dx + (py - a[1]) * dy) / L))
        return math.hypot(px - a[0] - dx * t, py - a[1] - dy * t)

    added_t = added_p = added_b = 0
    sgrid = {}
    for st in streets:
        (ax, ay), (bx, by) = st["a"], st["b"]
        for gx in range(int(min(ax, bx) // 50) - 1, int(max(ax, bx) // 50) + 2):
            for gy in range(int(min(ay, by) // 50) - 1, int(max(ay, by) // 50) + 2):
                sgrid.setdefault((gx, gy), []).append(st)

    def streets_near(px, py):
        return sgrid.get((int(px // 50), int(py // 50)), [])
    for w in windows:
        nx0, ny0, nx1, ny1 = w["new"]
        roads = [s for s in streets if seg_dist((nx0 + nx1) / 2, (ny0 + ny1) / 2, s["a"], s["b"]) < W]
        y = ny0 + 8
        while y < ny1 - 8:
            x = nx0 + 8
            while x < nx1 - 8:
                box = (x - cell / 2, y - cell / 2, x + cell / 2, y + cell / 2)
                near = grid.get((int(x // 50), int(y // 50)), [])
                ok = not any(overlaps(box, r, 1.0) for r in near) and not any(overlaps(box, r, 2.0) for r in blocked)
                ok = ok and all(seg_dist(x, y, s["a"], s["b"]) > s["w"] / 2 + cell / 2 + (2.5 if s["kind"] in ("local", "collector") else 0.5)
                                for s in roads)
                if ok:
                    roll = rnd.random()
                    if roll < 0.07:
                        plots.append({"r": [r2(x - 5), r2(y - 3), 10, 6], "kind": "garden", "cosy": True})
                        added_p += 1
                    elif roll < 0.10:
                        plots.append({"r": [r2(x - 5), r2(y - 0.75), 10, 1.5], "kind": "laundry", "cosy": True})
                        added_p += 1
                    elif roll < 0.115:
                        plots.append({"r": [r2(x - 7), r2(y - 5), 14, 10], "kind": "playground", "cosy": True})
                        added_p += 1
                    elif roll < 0.45:
                        jx, jy = rnd.uniform(-2.5, 2.5), rnd.uniform(-2.5, 2.5)
                        trees.append([r2(x + jx), r2(y + jy), r2(rnd.uniform(3.5, 6.0)), r2(rnd.uniform(7.0, 12.0)), "tree"])
                        added_t += 1
                    elif roll < 0.78:
                        # 0.18: кусты и замшелые валуны — газон в рисованном стиле не бывает голым
                        jx, jy = rnd.uniform(-3, 3), rnd.uniform(-3, 3)
                        kind = "rock" if rnd.random() < 0.18 else "bush"
                        trees.append([r2(x + jx), r2(y + jy), r2(rnd.uniform(1.2, 2.6)), r2(rnd.uniform(0.8, 1.8)), kind])
                        added_b += 1
                x += cell
            y += cell
    # живая изгородь вдоль стен домов: куст через 4 м в 1.6 м от стены, где рядом газон
    hedge = 0
    for b in buildings:
        if rnd.random() < 0.3:
            continue
        x0, y0, x1, y1 = rect_of(b["r"])
        for (ax, ay, bx, by, nx, ny) in ((x0, y0, x1, y0, 0, -1), (x0, y1, x1, y1, 0, 1), (x0, y0, x0, y1, -1, 0), (x1, y0, x1, y1, 1, 0)):
            L = math.hypot(bx - ax, by - ay)
            t = 2.0
            while t < L - 2.0:
                px = ax + (bx - ax) * t / L + nx * 1.6
                py = ay + (by - ay) * t / L + ny * 1.6
                t += rnd.uniform(3.0, 5.0)
                if rnd.random() < 0.35:
                    continue
                box = (px - 1, py - 1, px + 1, py + 1)
                near = grid.get((int(px // 50), int(py // 50)), [])
                if any(overlaps(box, r, 0.3) for r in near) or any(overlaps(box, r, 1.0) for r in blocked):
                    continue
                if any(seg_dist(px, py, s["a"], s["b"]) < s["w"] / 2 + 1.8 for s in streets_near(px, py)):
                    continue
                trees.append([r2(px), r2(py), r2(rnd.uniform(0.9, 1.5)), r2(rnd.uniform(0.9, 1.6)), "bush"])
                hedge += 1
    print(f"уют: деревьев +{added_t}, кустов и камней +{added_b}, изгородь +{hedge}, дворовых участков +{added_p}")
    return plots, trees


def main():
    layout = json.loads(LAYOUT.read_text(encoding="utf-8"))
    district = json.loads(DISTRICT.read_text(encoding="utf-8"))
    if layout.get("compact"):
        print("уже компактный, пропуск")
        return
    sites = layout["sites"]

    # окна секторов: (исходный прямоугольник окна, сдвиг, новый прямоугольник, район)
    windows = []
    new_districts = []
    for d in layout["districts"]:
        x0, y0, x1, y1 = d["r"]
        nd = dict(d)
        nd["r"] = [x0 / K, y0 / K, x1 / K, y1 / K]
        nd["source_r"] = d["r"]
        new_districts.append(nd)
        for j in range(3):
            for i in range(3):
                sx, sy = x0 + i * SECTOR, y0 + j * SECTOR
                inner = [s for s in sites if sx <= (s["r"][0] + s["r"][2]) / 2 < sx + SECTOR
                         and sy <= (s["r"][1] + s["r"][3]) / 2 < sy + SECTOR]
                wx, wy = best_window(sx, sy, inner, layout["buildings"])
                nx, ny = x0 / K + i * W, y0 / K + j * W
                windows.append({"src": (wx, wy, wx + W, wy + W), "shift": (nx - wx, ny - wy),
                                "new": (nx, ny, nx + W, ny + W), "district": d["id"], "ij": (i, j),
                                "sector_src": (sx, sy, sx + SECTOR, sy + SECTOR)})

    def window_at(x, y):
        for w in windows:
            s = w["sector_src"]
            if s[0] <= x < s[2] and s[1] <= y < s[3]:
                return w
        return None

    # стыковые улицы в новом плане
    seams = []
    for nd in new_districts:
        x0, y0, x1, y1 = nd["r"]
        for k in (1, 2):
            seams.append({"a": [r2(x0 + k * W), y0], "b": [r2(x0 + k * W), y1], "w": SEAM_W, "kind": "local"})
            collector = nd["id"] == "PG" and k == 2           # бывший коллектор y = 2000
            seams.append({"a": [x0, r2(y0 + k * W)], "b": [x1, r2(y0 + k * W)],
                          "w": COLLECTOR_W if collector else SEAM_W, "kind": "collector" if collector else "local"})
    # стыки районов: Погуляй | Деловой и «До свидания» / Деловой
    seams.append({"a": [1000.0, 0.0], "b": [1000.0, 1000.0], "w": SEAM_W, "kind": "local"})
    seams.append({"a": [1000.0, 0.0], "b": [2000.0, 0.0], "w": SEAM_W, "kind": "local"})

    def margin_box(w):
        """Окно в исходных координатах с отступом от стыковых улиц (и края города)."""
        m = SEAM_W / 2 + 3.0
        mc = COLLECTOR_W / 2 + 3.0
        x0, y0, x1, y1 = w["src"]
        top = mc if (w["district"] == "PG" and w["ij"][1] == 2) else m
        bottom = mc if (w["district"] == "PG" and w["ij"][1] == 1) else m
        return (x0 + m, y0 + top, x1 - m, y1 - bottom)

    def move(r, w):
        dx, dy = w["shift"]
        return [r2(r[0] + dx), r2(r[1] + dy)] + list(r[2:])

    kept_b = []
    for b in layout["buildings"]:
        x0, y0, x1, y1 = rect_of(b["r"])
        w = window_at((x0 + x1) / 2, (y0 + y1) / 2)
        if w and inside((x0, y0, x1, y1), margin_box(w)):
            nb = dict(b)
            nb["r"] = move(b["r"], w)
            kept_b.append(nb)
    kept_p = []
    for p in layout["plots"]:
        x0, y0, x1, y1 = rect_of(p["r"])
        w = window_at((x0 + x1) / 2, (y0 + y1) / 2)
        if w and inside((x0, y0, x1, y1), margin_box(w)):
            np_ = dict(p)
            np_["r"] = move(p["r"], w)
            kept_p.append(np_)
    kept_t = []
    for t in layout["trees"]:
        w = window_at(t[0], t[1])
        if w and inside((t[0] - 1, t[1] - 1, t[0] + 1, t[1] + 1), margin_box(w)):
            kept_t.append([r2(t[0] + w["shift"][0]), r2(t[1] + w["shift"][1])] + t[2:])
    kept_s = []
    for s in layout["streets"]:
        # отрезок может пересекать несколько секторов: режем по окну каждого
        for w in windows:
            c = clip(s["a"], s["b"], w["src"])
            if c is None:
                continue
            a, b = c
            if math.dist(a, b) < 4.0:
                continue
            ns = dict(s)
            ns["a"] = [r2(a[0] + w["shift"][0]), r2(a[1] + w["shift"][1])]
            ns["b"] = [r2(b[0] + w["shift"][0]), r2(b[1] + w["shift"][1])]
            kept_s.append(ns)
    kept_s += seams
    for s in sites:
        w = window_at((s["r"][0] + s["r"][2]) / 2, (s["r"][1] + s["r"][3]) / 2)
        assert inside(tuple(s["r"]), w["src"]), f"площадка {s['id']} не влезла в окно"
        s["shift"] = [r2(w["shift"][0]), r2(w["shift"][1])]
    start_shift = next(s["shift"] for s in sites if s["id"] == "start")
    origin = [r2(SOURCE_ORIGIN[0] + start_shift[0]), r2(SOURCE_ORIGIN[1] + start_shift[1])]
    for z in layout.get("sectors", []):
        w = window_at(z["bounds_plan_m"][0] + 1, z["bounds_plan_m"][1] + 1)
        z["bounds_plan_m"] = [r2(v) for v in w["new"]]
    cores = layout.get("cores", {})
    for key, r in cores.items():
        w = window_at(r[0] + r[2] / 2, r[1] + r[3] / 2)
        cores[key] = move(r, w)

    # точки реестра: внутри окна — сдвиг, вне — пропорционально внутрь и прочь от домов
    houses = [rect_of(b["r"]) for b in kept_b]
    site_rects = [(s["r"][0] + s["shift"][0], s["r"][1] + s["shift"][1], s["r"][2] + s["shift"][0],
                   s["r"][3] + s["shift"][1]) for s in sites]

    # двор старта собран вручную (StartYard): точки реестра в него не ставим
    sy0 = (248 + start_shift[0], 2536 + start_shift[1])
    yard = (sy0[0], sy0[1], sy0[0] + 222, sy0[1] + 208)

    def free(x, y, m):
        return not overlaps((x, y, x, y), yard, 6.0) and not any(overlaps((x, y, x, y), h, m) for h in houses)

    def place(x, y, keep_free=True):
        w = window_at(x, y)
        mb = margin_box(w)
        if inside((x - 1, y - 1, x + 1, y + 1), mb):
            nx, ny = x + w["shift"][0], y + w["shift"][1]
        else:
            sx, sy = w["sector_src"][0], w["sector_src"][1]
            tx, ty = (x - sx) / SECTOR, (y - sy) / SECTOR
            m = SEAM_W / 2 + 8.0
            nx = w["new"][0] + m + tx * (W - 2 * m)
            ny = w["new"][1] + m + ty * (W - 2 * m)
        if keep_free and not free(nx, ny, 2.0):
            nx, ny = place_free(nx, ny, w["new"])
        return [r2(nx), r2(ny)]

    def place_free(nx, ny, nwin):
        for rad in range(2, 80, 2):
            for a in range(0, 360, 15):
                qx, qy = nx + rad * math.cos(math.radians(a)), ny + rad * math.sin(math.radians(a))
                if nwin[0] + 6 < qx < nwin[2] - 6 and nwin[1] + 6 < qy < nwin[3] - 6 and free(qx, qy, 2.0):
                    return qx, qy
        return nx, ny

    def window_at_new(x, y):
        for w in windows:
            n = w["new"]
            if n[0] <= x < n[2] and n[1] <= y < n[3]:
                return n
        return windows[0]["new"]

    dropped = set()
    for p in district["points"]:
        x, y = p["plan_position_m"]
        if p["type"] == "boss":
            # арена: площадь ужата, дома на ней снесены (кроме корпусов площадок)
            sz = [round(v * ARENA_K) for v in p.get("arena_size_m", [80, 60])]
            p["arena_size_m"] = sz
            nx, ny = place(x, y, keep_free=False)
            w = window_at(x, y)
            half = (sz[0] / 2 + 3, sz[1] / 2 + 3)
            nwin = w["new"]
            nx = min(max(nx, nwin[0] + half[0] + 6), nwin[2] - half[0] - 6)
            ny = min(max(ny, nwin[1] + half[1] + 6), nwin[3] - half[1] - 6)
            arena = (nx - half[0], ny - half[1], nx + half[0], ny + half[1])
            for sr in site_rects:
                if overlaps(arena, sr):
                    # отодвинуть от площадки по вертикали в свободную половину окна
                    ny = (nwin[1] + half[1] + 6) if (sr[1] + sr[3]) / 2 > ny else (nwin[3] - half[1] - 6)
                    arena = (nx - half[0], ny - half[1], nx + half[0], ny + half[1])
            for i, h in enumerate(houses):
                if overlaps(arena, h) and kept_b[i]["kind"] != "site":
                    dropped.add(i)
            kept_p = [q for q in kept_p if not overlaps(rect_of(q["r"]), arena)]
            kept_t = [t for t in kept_t if not overlaps((t[0], t[1], t[0], t[1]), arena, 2.0)]
            p["plan_position_m"] = [r2(nx), r2(ny)]
        else:
            p["plan_position_m"] = place(x, y)
        if p["type"] in RADIUS_K and "radius_m" in p:
            p["radius_m"] = round(p["radius_m"] * RADIUS_K[p["type"]])
        nx, ny = p["plan_position_m"]
        p["godot_position_m"] = [r2(nx - origin[0]), 0, r2(ny - origin[1])]
        p["chunk"] = [math.floor(nx / CHUNK), math.floor(ny / CHUNK)]
    # спавн мобов не в зоне отдыха: зоны ужаты, точки сдвинуты — отодвигаем моба от зоны
    safe = [p for p in district["points"] if p["type"] == "safe"]
    for p in district["points"]:
        if p["type"] != "mob":
            continue
        for z in safe:
            dx = p["plan_position_m"][0] - z["plan_position_m"][0]
            dy = p["plan_position_m"][1] - z["plan_position_m"][1]
            dd = math.hypot(dx, dy)
            if dd <= z["radius_m"] + 5:
                k = (z["radius_m"] + 8) / max(dd, 0.1)
                nx, ny = z["plan_position_m"][0] + dx * k, z["plan_position_m"][1] + dy * k
                if not free(nx, ny, 2.0):
                    nx, ny = place_free(nx, ny, window_at_new(nx, ny))
                p["plan_position_m"] = [r2(nx), r2(ny)]
                p["godot_position_m"] = [r2(nx - origin[0]), 0, r2(ny - origin[1])]
                p["chunk"] = [math.floor(nx / CHUNK), math.floor(ny / CHUNK)]
    kept_b = [b for i, b in enumerate(kept_b) if i not in dropped]
    for o in district.get("npc_position_overrides", []):
        o["plan_position_m"] = place(*o["plan_position_m"])
        if "yard_plan_position_m" in o:
            x, y = o["yard_plan_position_m"]
            w = window_at(x, y)
            o["yard_plan_position_m"] = [r2(x + w["shift"][0]), r2(y + w["shift"][1])]
    for z in district.get("sectors", []):
        w = window_at(z["bounds_plan_m"][0] + 1, z["bounds_plan_m"][1] + 1)
        z["bounds_plan_m"] = [r2(v) for v in w["new"]]
    district["dimensions_m"] = [round(SECTOR * 3 / K), round(SECTOR * 3 / K)]
    district["compact"] = {"k": K, "note": "см. tools/importers/compact_city.py, D-059"}
    for key in ("road_centerlines", "houses_plan_m", "chunks"):
        district.pop(key, None)       # исходная схема PDF, в компактном городе не совпадает

    global SITES
    SITES = sites
    kept_p, kept_t = cosy_fill(windows, kept_b, kept_p, kept_t, kept_s, site_rects, yard, district["points"])

    layout["districts"] = new_districts
    layout["buildings"] = kept_b
    layout["plots"] = kept_p
    layout["trees"] = kept_t
    layout["streets"] = kept_s
    layout["origin_m"] = origin
    layout["compact"] = {"k": K, "window_m": r2(W), "seam_m": SEAM_W,
                         "windows": [{"district": w["district"], "sector": list(w["ij"]), "src": [r2(v) for v in w["src"]],
                                      "shift": [r2(v) for v in w["shift"]]} for w in windows]}
    layout["coordinates"] = layout.get("coordinates", "") + "; компактный город k = 3 (D-059)"
    LAYOUT.write_text(json.dumps(layout, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    DISTRICT.write_text(json.dumps(district, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"дома {len(kept_b)}, огороды {len(kept_p)}, деревья {len(kept_t)}, улицы {len(kept_s)}, "
          f"начало координат {origin}, снесено под арены {len(dropped)}")


if __name__ == "__main__":
    main()
