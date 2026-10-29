#!/usr/bin/env python3
"""Район «Погуляй» в data/district_pogulyay.json.

    python3 tools/importers/import_pogulyay_map.py

Главный источник — манифест владельца docs/source/pogulyay-map.json (точки, дороги, участки,
составы групп, переопределение позиции N07): он копируется в данные без изменений.
К нему добавляются силуэты домов из векторной схемы docs/source/POGULYAY_MAP.pdf
(в манифесте их нет; по ТЗ это плотность застройки, не обмерный план).
Проверки: координаты всех точек манифеста совпадают с реестром ТЗ
(docs/source/POGULYAY_GODOT_TZ.pdf) и с кругами схемы не дальше 15 м; числа точек по ТЗ.
Нужны pdfplumber и pdftotext.
"""
import subprocess
import json
import re
import sys
from pathlib import Path

import pdfplumber

ROOT = Path(__file__).resolve().parents[2]
PDF = ROOT / "docs" / "source" / "POGULYAY_MAP.pdf"
TZ = ROOT / "docs" / "source" / "POGULYAY_GODOT_TZ.pdf"
OUT = ROOT / "data" / "district_pogulyay.json"
MANIFEST = ROOT / "docs" / "source" / "pogulyay-map.json"
YARD_N07 = [352, 2675]                  # ParkingReference.PAVEL_POS в метрах плана
# Сетка карты в PDF: левый верхний угол района и 1000 м в пунктах (прямоугольники кварталов 226.67 pt).
X0, Y0, PT_PER_KM = 48.0, 83.89, 226.6667

def to_m(x, y, step=10):
    k = 1000.0 / PT_PER_KM
    return [round((x - X0) * k / step) * step, round((y - Y0) * k / step) * step]


def registry():
    """Приложение ТЗ: «N01  Тёма «Три Миллиона»  2110  1400»."""
    text = subprocess.run(["pdftotext", "-layout", str(TZ), "-"], capture_output=True, text=True, check=True).stdout
    text = text[text.index("Координатный реестр"):]
    rows = {}
    for m in re.finditer(r"^\s*(N\d\d|B\d|M\d{1,2}-\d|P\d{1,2}|S\d|U\d)\s{2,}(.+?)\s{2,}(\d{1,4})\s+(\d{1,4})\s*$",
                         text, re.M):
        rows[m.group(1)] = {"name": m.group(2).strip(), "m": [int(m.group(3)), int(m.group(4))]}
    return rows


def circles(page):
    words = page.extract_words()
    out = []
    for cv in page.curves:
        w = cv["x1"] - cv["x0"]
        if w > 60:
            continue
        cx, cy = (cv["x0"] + cv["x1"]) / 2, (cv["top"] + cv["bottom"]) / 2
        label = None
        best = 1e9
        for wd in words:
            if cx <= wd["x0"] <= cx + 40 and abs(wd["bottom"] - cy) <= 18:
                d = (wd["x0"] - cx) ** 2 + (wd["bottom"] - cy) ** 2
                if d < best:
                    best, label = d, wd["text"]
        out.append({"label": label, "m": to_m(cx, cy), "d_m": round(w * 1000 / PT_PER_KM)})
    return out


def main():
    pdf = pdfplumber.open(PDF)
    routes, spawns = pdf.pages
    # Арены: имена «B1 Люся …» идут после «ТРИ АРЕНЫ», координаты «[x, y] м · [w, h] м» — в том же порядке
    # (строки в тексте PDF перемешаны с подписями карты, поэтому сопоставляем по порядку).
    text = routes.extract_text(layout=False)
    tail = text[text.index("ТРИ АРЕНЫ"):text.index("ПОДЗЕМНЫЕ ВХОДЫ") + 200]
    arena_names = re.findall(r"^(B\d) (.+?)$", tail, re.M)[:3]
    arena_nums = re.findall(r"\[(\d+), (\d+)\] м · \[(\d+), (\d+)\] м", tail)
    arenas = [(code, name, *nums) for (code, name), nums in zip(arena_names, arena_nums)]
    reg = registry()
    drawn = {c["label"]: c["m"] for c in circles(routes) + circles(spawns) if c["label"]}
    for code, name, x, y, w, h in arenas:
        drawn[code] = [int(x), int(y)]
    man = json.loads(MANIFEST.read_text())
    errors = []
    for p in man["points"]:
        pm = p["plan_position_m"]
        # места P0..P17 в схеме не нарисованы кругами — для них сверка только с реестром ТЗ
        for src, table in (("реестр ТЗ", {k: v["m"] for k, v in reg.items()}), ("схема PDF", drawn)):
            if p["id"] not in table:
                if src == "реестр ТЗ":
                    errors.append("%s нет в: %s" % (p["id"], src))
            elif max(abs(pm[0] - table[p["id"]][0]), abs(pm[1] - table[p["id"]][1])) > 15:
                errors.append("%s: манифест %s, %s %s" % (p["id"], pm, src, table[p["id"]]))
        g = p["godot_position_m"]
        if [pm[0] - 1500, pm[1] - 1500] != [g[0], g[2]]:
            errors.append("%s: godot_position_m не по формуле" % p["id"])
    kinds = {}
    for p in man["points"]:
        kinds[p["type"]] = kinds.get(p["type"], 0) + 1
    expect = {"npc": 15, "boss": 3, "mob": 30, "place": 18, "safe": 5, "underground": 4}
    if kinds != expect:
        errors.append("точек %s, ожидалось %s" % (kinds, expect))
    if len(man["chunks"]) != 144:
        errors.append("участков %d, ожидалось 144" % len(man["chunks"]))
    if errors:
        sys.exit("\n".join(errors))
    houses = [[*to_m(r["x0"], r["top"], 1), round(r["width"] * 1000 / PT_PER_KM), round(r["height"] * 1000 / PT_PER_KM)]
              for r in routes.rects if r["width"] < 40 and r["x0"] < 48 + 3 * PT_PER_KM]
    # N07 по манифесту (430, 2590) стоит на перекрёстке магистрали h12 и улицы v2 — за аркой,
    # куда до конца MAIN_001 не пройти. Временный киоск «НЛО напрокат» стоит во дворе старта;
    # позиция манифеста сохраняется, рядом — фактическая точка во дворе (решение D-031).
    for o in man["npc_position_overrides"]:
        if o["npc_id"] == "N07":
            o["yard_plan_position_m"] = YARD_N07
            o["yard_note"] = "Фактическая точка в Godot: двор «Похмельной» у киоска «НЛО напрокат» (D-031)."
    man["houses_plan_m"] = houses
    man["houses_note"] = "Силуэты домов со схемы POGULYAY_MAP.pdf: [x, y, ширина, глубина] в метрах плана; плотность, не коллизии."
    OUT.write_text(json.dumps(man, ensure_ascii=False, indent=1))
    print("district_pogulyay:", kinds, "дорог", len(man["road_centerlines"]), "домов", len(houses),
          "участков", len(man["chunks"]))


if __name__ == "__main__":
    main()
