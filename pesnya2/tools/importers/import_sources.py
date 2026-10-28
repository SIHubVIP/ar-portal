#!/usr/bin/env python3
"""Импорт канона «Песни» из трёх PDF в JSON-данные игры.

Источники лежат в docs/source/. Скрипт вызывает pdftotext (poppler-utils),
разбирает карточки и пишет data/*.json и docs/SOURCE_MANIFEST.json.

    python3 tools/importers/import_sources.py

Ничего не выдумывает: если в карточке поле не найдено, скрипт падает,
а не подставляет значение.
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "source"
DATA = ROOT / "data"
SCHEMA_VERSION = 1

TZ_PDF = SRC / "01_TZ_PROMPT_GODOT.pdf"
STORY_PDF = SRC / "02_SYUZHET_PESNYA.pdf"
SCRIPT_PDF = SRC / "03_SCENARIY_127_KVESTOV.pdf"

DISTRICTS = {"Погуляй": "DIST_POGULYAY", "Деловой": "DIST_DELOVOY", "До свидания": "DIST_DOSVIDANIYA"}


def pdf_lines(path):
    out = subprocess.run(["pdftotext", "-layout", str(path), "-"], check=True,
                         capture_output=True, text=True).stdout
    lines = []
    for ln in out.splitlines():
        s = ln.strip()
        # колонтитулы страниц
        if s.startswith("Рабочая редакция •") or s == "AOLOVO / ПЕСНЯ / ДОКУМЕНТАЦИЯ ДЛЯ ИИ":
            continue
        lines.append(ln.rstrip().replace("\f", ""))
    return lines


# строки, которые всегда начинают новый абзац, даже без пустой строки перед ними
BREAKS = re.compile(r"^(Район: |СЦЕНА\.|Линия: |Начальный конфликт: |• ABL_)")


def paragraphs(lines):
    """Склеивает перенесённые строки в абзацы (абзацы разделены пустой строкой)."""
    paras, cur = [], []
    for ln in lines:
        if ln.strip() and BREAKS.match(ln.strip()) and cur:
            paras.append(" ".join(cur))
            cur = [ln.strip()]
        elif ln.strip():
            cur.append(ln.strip())
        elif cur:
            paras.append(" ".join(cur))
            cur = []
    if cur:
        paras.append(" ".join(cur))
    return paras


def die(msg):
    sys.exit("IMPORT ERROR: " + msg)


def need(m, what, qid):
    if not m:
        die(f"{qid}: не найдено поле {what}")
    return m


# ---------- квесты ----------

CARD_RE = re.compile(r"^ (MAIN_\d{3}|NPC_\d{2}_\d|DUO_\d{2}) — (.+)$")


def parse_quests(lines):
    start = next(i for i, l in enumerate(lines) if l.strip().startswith("Раздел A."))
    end = next(i for i, l in enumerate(lines) if l.strip().startswith("Часть III."))
    body = lines[start:end]
    heads = [i for i, l in enumerate(body) if CARD_RE.match(l)]
    quests = []
    for n, h in enumerate(heads):
        chunk = body[h:heads[n + 1] if n + 1 < len(heads) else len(body)]
        # строки разделов вида «Линия …», «АКТ 2», «Раздел Б» в хвосте карточки не нужны
        chunk = [l for l in chunk if not re.match(r"^ (АКТ \d|Раздел [АБВ]\.|Линия [^:]+$)", l)]
        qid, title = CARD_RE.match(chunk[0]).groups()
        paras = paragraphs(chunk[1:])
        quests.append(parse_card(qid, title.strip(), paras))
    return quests


def parse_card(qid, title, paras):
    head = need(next((p for p in paras if p.startswith("Линия:")), None), "Линия", qid)
    m = need(re.match(r"Линия: (.+?) \| Акт: (\d) \| Район: (.+?) \| Мин\. уровень: (\d+) \| Квестодатель: (.+)$",
                      head), "шапка", qid)
    line_kind, act, district, min_level, giver = m.groups()
    q = {
        "id": qid,
        "title": title,
        "kind": {"MAIN": "main", "NPC": "npc", "DUO": "solo_activity"}[qid.split("_")[0]],
        "act": int(act),
        "district": district,
        "district_id": DISTRICTS.get(district) or die(f"{qid}: неизвестный район {district}"),
        "min_level": int(min_level),
        "giver": giver,
        "npc_id": qid[:6] if qid.startswith("NPC_") else None,
        "source_line": line_kind,
    }
    sections = {"ЛОКАЦИЯ.": "location", "ЗАВЯЗКА.": "setup", "ПОВОРОТ.": "twist",
                "ОДИНОЧНЫЙ ВАРИАНТ.": "solo_variant"}
    stages, choices, lines_ = [], {}, []
    in_lines = False
    for p in paras:
        for key, field in sections.items():
            if p.startswith(key):
                q[field] = p[len(key):].strip()
                in_lines = False
        sm = re.match(r"^(\d+)\. \[([a-z_]+)\] (.+?) • цель: (\d+)( • checkpoint)?$", p)
        if sm:
            num, typ, text, target, cp = sm.groups()
            stages.append({"id": f"{qid}_S{int(num):02d}", "index": int(num), "type": typ,
                           "text": text, "target": int(target), "checkpoint": bool(cp)})
            continue
        cm = re.match(r"^ВЫБОР ([AB])\. (.+?) → (.+?) \| FLAG: (\S+)$", p)
        if cm:
            key, text, result, flag = cm.groups()
            choices[key] = {"text": text, "result": result, "flag": flag}
            continue
        if p.startswith("КЛЮЧЕВЫЕ РЕПЛИКИ."):
            in_lines = True
            continue
        if p.startswith("НАГРАДА"):
            in_lines = False
            rm = need(re.match(r"НАГРАДА \(дизайн\): XP (\d+); Бабки (\d+); Репутация (-?\d+); Кукуха (-?\d+)\. "
                               r"Время карточки: (\d+) мин", p), "НАГРАДА", qid)
            xp, babki, rep, kuk, minutes = map(int, rm.groups())
            q["reward"] = {"xp": xp, "babki": babki, "reputation": rep, "kukukha": kuk}
            q["design_minutes"] = minutes
            continue
        if p.startswith("ЗАВИСИМОСТИ."):
            dm = need(re.match(r"ЗАВИСИМОСТИ\. (.*?)\. ВОССТАНОВЛЕНИЕ\. (.+)$", p), "ЗАВИСИМОСТИ", qid)
            deps, rec = dm.groups()
            q["requires"] = [] if deps.strip() == "нет" else [d.strip() for d in deps.split(",")]
            q["recovery"] = rec.strip()
            continue
        if in_lines:
            lm = re.match(r"^(.+?): (.+)$", p)
            if lm:
                speaker, text = lm.groups()
                text = text.strip()
                if text[:1] in "«'" and text.rstrip(".")[-1:] in "»'":
                    text = text.rstrip(".")[1:-1]
                lines_.append({"speaker": speaker, "text": text})
    q["stages"] = stages
    if set(choices) != {"A", "B"}:
        die(f"{qid}: ожидались выборы A и B, найдено {sorted(choices)}")
    q["choices"] = choices
    q["key_lines"] = lines_
    for f in ("location", "setup", "twist", "reward", "requires", "recovery"):
        if f not in q:
            die(f"{qid}: не найдено поле {f}")
    if not stages or [s["index"] for s in stages] != list(range(1, len(stages) + 1)):
        die(f"{qid}: нарушена нумерация этапов")
    return q


# ---------- постановочные сцены ----------

def parse_scenes(lines):
    start = next(i for i, l in enumerate(lines) if l.strip().startswith("Часть I."))
    end = next(i for i, l in enumerate(lines) if l.strip().startswith("Часть II."))
    paras = paragraphs(lines[start:end])
    scenes, cur = [], None
    for p in paras:
        m = re.match(r"^(SCENE_\d{2}) / (MAIN_\d{3}(?:—\d{3})?) — (.+)$", p)
        if m:
            sid, main, title = m.groups()
            if main.count("—"):
                a, b = main.split("—")
                mains = [a, "MAIN_" + b]
            else:
                mains = [main]
            cur = {"id": sid, "quests": mains, "title": title, "setting": "", "lines": [], "integration": "",
                   "status": "WRITTEN"}
            scenes.append(cur)
            continue
        if cur is None:
            continue
        if p.startswith("СЦЕНА."):
            cur["setting"] = p[len("СЦЕНА."):].strip()
        elif p.startswith("ПОСТАНОВКА / ИНТЕГРАЦИЯ."):
            cur["integration"] = p[len("ПОСТАНОВКА / ИНТЕГРАЦИЯ."):].strip()
        else:
            lm = re.match(r"^([А-ЯЁA-Z0-9 \-]+): (.+)$", p)
            if lm:
                cur["lines"].append({"speaker": lm.group(1).strip(), "text": lm.group(2)})
            elif not cur["lines"]:
                # заголовок сцены перенесён на вторую строку
                cur["title"] += " " + p
    return scenes


# ---------- боссы ----------

def parse_bosses(lines):
    start = next(i for i, l in enumerate(lines) if l.strip().startswith("Часть III."))
    end = next(i for i, l in enumerate(lines) if l.strip().startswith("Часть IV."))
    paras = paragraphs(lines[start:end])
    bosses, cur = [], None
    for p in paras:
        m = re.match(r"^(BOSS_\d{2}) — (.+)$", p)
        if m:
            cur = {"id": m.group(1), "name": m.group(2), "phases": []}
            bosses.append(cur)
            continue
        if cur is None:
            continue
        hm = re.match(r"^Район: (.+?) \| Арена: (ARENA_\d+) \| Локация: (LOC_\d+) \| Уровень исходного проекта: (\d+)$", p)
        if hm:
            d, arena, loc, lvl = hm.groups()
            cur.update({"district": d, "district_id": DISTRICTS[d], "arena_id": arena, "location_id": loc,
                        "source_level": int(lvl)})
            continue
        qm = re.match(r"^«(.+?)», — объявляет .+?, пытаясь наладить (.+?)\.$", p)
        if qm:
            cur["taunt"] = qm.group(1)
            cur["arena_theme"] = qm.group(2)
            continue
        fm = re.match(r"^Фаза (\d), HP \[(\d+), (\d+)\]: (.+?)\. Предупреждение ([\d.]+) с; опасность — (.+?)\. "
                      r"Противодействие: (.+)$", p)
        if fm:
            n, hi, lo, name, warn, danger, counter = fm.groups()
            cur["phases"].append({"index": int(n), "hp_from": int(hi), "hp_to": int(lo), "attack": name,
                                  "telegraph_s": float(warn), "danger": danger, "counter": counter})
            continue
        cm = re.match(r"^Укрытия: (.+?); квестовая привязка: (.+?)\.$", p)
        if cm:
            cur["cover"] = cm.group(1)
            cur["quest_title"] = cm.group(2)
    return bosses


def link_bosses(bosses, quests):
    by_title = {q["title"]: q["id"] for q in quests}
    for b in bosses:
        b["quest_id"] = by_title.get(b["quest_title"]) or die(f"{b['id']}: нет квеста «{b['quest_title']}»")
    for b in bosses:
        for f in ("arena_id", "location_id", "taunt", "cover", "quest_title"):
            if f not in b:
                die(f"{b['id']}: не найдено поле {f}")
        if len(b["phases"]) != 3:
            die(f"{b['id']}: ожидалось 3 фазы")
    return bosses


# ---------- способности (ТЗ, раздел 10) ----------

CLASSES = [("CLASS_1", "Вышибала"), ("CLASS_2", "Проныра"), ("CLASS_3", "Техношаман")]


def parse_abilities(lines):
    paras = paragraphs(lines)
    abilities = []
    for p in paras:
        m = re.match(r"^• (ABL_(\d)_(\d)) — (.+?) \((.+?); исходные кулдаун ([\d.]+) с и дальность ([\d.]+) м", p)
        if m:
            aid, c, _, name, kind, cd, rng = m.groups()
            abilities.append({"id": aid, "class_id": f"CLASS_{c}", "name": name, "kind": kind,
                              "cooldown_s": float(cd), "range_m": float(rng), "balance_status": "source_only"})
    classes = [{"id": cid, "name": name, "abilities": [a["id"] for a in abilities if a["class_id"] == cid]}
               for cid, name in CLASSES]
    return classes, abilities


# ---------- NPC (сюжетная библия, раздел 8) ----------

def parse_npcs(lines, quests):
    start = next(i for i, l in enumerate(lines) if "8. Все 33 квестодателя" in l)
    end = next(i for i, l in enumerate(lines) if "9. Система городских отношений" in l)
    paras = paragraphs(lines[start:end])
    npcs, cur = [], None
    for p in paras:
        m = re.match(r"^(NPC_\d{2}) — (.+)$", p)
        if m:
            name, _, chain = m.group(2).partition(f" {m.group(1)}_1:")
            cur = {"id": m.group(1), "name": name.strip()}
            npcs.append(cur)
            continue
        if cur and p.startswith("Начальный конфликт:"):
            cm = re.match(r"^Начальный конфликт: (.+?) Конечная точка линии: (.+)$", p)
            cur["opening_conflict"], cur["line_endpoint"] = cm.groups()
    by_npc = {}
    for q in quests:
        if q["npc_id"]:
            by_npc.setdefault(q["npc_id"], []).append(q)
    for n in npcs:
        qs = by_npc.get(n["id"], [])
        n["quests"] = [q["id"] for q in qs]
        n["district"] = qs[0]["district"] if qs else None
        n["district_id"] = qs[0]["district_id"] if qs else None
        if qs and qs[0]["giver"] != n["name"]:
            die(f"{n['id']}: имя в сюжете «{n['name']}» не совпадает с квестодателем «{qs[0]['giver']}»")
    return npcs


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(name, payload):
    path = DATA / name
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"  {path.relative_to(ROOT)}")


def main():
    script = pdf_lines(SCRIPT_PDF)
    story = pdf_lines(STORY_PDF)
    tz = pdf_lines(TZ_PDF)

    quests = parse_quests(script)
    scenes = parse_scenes(script)
    bosses = parse_bosses(script)
    classes, abilities = parse_abilities(tz)
    npcs = parse_npcs(story, quests)
    link_bosses(bosses, quests)

    meta = {"schema_version": SCHEMA_VERSION, "source": "03_SCENARIY_127_KVESTOV.pdf",
            "source_sha256": sha256(SCRIPT_PDF)}
    DATA.mkdir(exist_ok=True)
    print("Записано:")
    write("quests.json", {**meta, "quests": quests})
    write("scenes.json", {**meta, "scenes": scenes})
    write("bosses.json", {**meta, "bosses": bosses})
    write("abilities.json", {**meta, "source": "01_TZ_PROMPT_GODOT.pdf", "source_sha256": sha256(TZ_PDF),
                             "max_level": 55, "classes": classes, "abilities": abilities})
    write("npcs.json", {**meta, "source": "02_SYUZHET_PESNYA.pdf", "source_sha256": sha256(STORY_PDF),
                        "npcs": npcs})

    manifest = {"generated_by": "tools/importers/import_sources.py",
                "sources": [{"file": f"docs/source/{p.name}", "sha256": sha256(p), "bytes": p.stat().st_size}
                            for p in (TZ_PDF, STORY_PDF, SCRIPT_PDF)],
                "counts": {"quests": len(quests), "stages": sum(len(q["stages"]) for q in quests),
                           "npcs": len(npcs), "bosses": len(bosses), "abilities": len(abilities),
                           "scenes": len(scenes)},
                "v4_archive": "NOT_AVAILABLE"}
    (ROOT / "docs" / "SOURCE_MANIFEST.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(json.dumps(manifest["counts"], ensure_ascii=False))


if __name__ == "__main__":
    main()
