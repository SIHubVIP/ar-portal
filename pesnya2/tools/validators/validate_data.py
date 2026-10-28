#!/usr/bin/env python3
"""Валидатор канона: блокирует сборку при нарушении количеств, ID и графа зависимостей.

    python3 tools/validators/validate_data.py

Ошибки (exit 1): количества 127/20/99/8, 33 NPC, 15 боссов, 21 способность, 543 этапа,
дубликаты ID, неизвестные ссылки, циклы, побочные зависимости у MAIN.
Предупреждения (не блокируют): известные расхождения исходного баланса, см. docs/CANON_DIFF.md.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"


def load(name, key):
    return json.loads((DATA / name).read_text(encoding="utf-8"))[key]


def main():
    quests = load("quests.json", "quests")
    npcs = load("npcs.json", "npcs")
    bosses = load("bosses.json", "bosses")
    abilities = load("abilities.json", "abilities")
    classes = load("abilities.json", "classes")
    items = load("items.json", "items")
    errors, warnings = [], []

    def expect(name, actual, wanted):
        if actual != wanted:
            errors.append(f"{name}: ожидалось {wanted}, найдено {actual}")

    kinds = [q["kind"] for q in quests]
    expect("квестов", len(quests), 127)
    expect("MAIN", kinds.count("main"), 20)
    expect("NPC-квестов", kinds.count("npc"), 99)
    expect("DUO (соло)", kinds.count("solo_activity"), 8)
    expect("квестодателей", len(npcs), 33)
    expect("боссов", len(bosses), 15)
    expect("способностей", len(abilities), 21)
    expect("классов", len(classes), 3)
    expect("этапов", sum(len(q["stages"]) for q in quests), 543)

    for label, rows in (("quest", quests), ("npc", npcs), ("boss", bosses), ("ability", abilities), ("item", items)):
        ids = [r["id"] for r in rows]
        dups = {i for i in ids if ids.count(i) > 1}
        if dups:
            errors.append(f"дубликаты {label}: {sorted(dups)}")
    stage_ids = [s["id"] for q in quests for s in q["stages"]]
    if len(stage_ids) != len(set(stage_ids)):
        errors.append("дубликаты stage_id")

    by_id = {q["id"]: q for q in quests}
    npc_ids = {n["id"] for n in npcs}
    for q in quests:
        for dep in q["requires"]:
            if dep not in by_id:
                errors.append(f"{q['id']}: неизвестная зависимость {dep}")
            elif q["kind"] == "main" and not dep.startswith("MAIN_"):
                errors.append(f"{q['id']}: главный путь зависит от побочного {dep}")
        if q["npc_id"] and q["npc_id"] not in npc_ids:
            errors.append(f"{q['id']}: неизвестный NPC {q['npc_id']}")
        if set(q["choices"]) != {"A", "B"} or q["choices"]["A"]["flag"] == q["choices"]["B"]["flag"]:
            errors.append(f"{q['id']}: нужны два разных выбора A/B")
    for n in npcs:
        want = [f"{n['id']}_{i}" for i in (1, 2, 3)]
        if n["quests"] != want:
            errors.append(f"{n['id']}: цепочка {n['quests']} вместо {want}")
    for c in classes:
        if len(c["abilities"]) != 7:
            errors.append(f"{c['id']}: {len(c['abilities'])} способностей вместо 7")

    # циклы
    state = {}

    def visit(qid, path):
        if state.get(qid) == 1:
            errors.append("цикл зависимостей: " + " → ".join(path + [qid]))
            return
        if state.get(qid) == 2:
            return
        state[qid] = 1
        for dep in by_id[qid]["requires"]:
            if dep in by_id:
                visit(dep, path + [qid])
        state[qid] = 2

    for qid in by_id:
        visit(qid, [])

    # достижимость финала только по MAIN
    done = set()
    changed = True
    while changed:
        changed = False
        for q in quests:
            if q["kind"] == "main" and q["id"] not in done and all(d in done for d in q["requires"]):
                done.add(q["id"])
                changed = True
    if "MAIN_020" not in done:
        errors.append("MAIN_020 недостижим без побочных заданий")

    for b in bosses:
        q = by_id.get(b["quest_id"])
        if q is None:
            errors.append(f"{b['id']}: неизвестный квест {b['quest_id']}")
        elif abs(q["min_level"] - b["source_level"]) >= 10:
            warnings.append(f"{b['id']} (ур. {b['source_level']}) привязан к {q['id']} (ур. {q['min_level']}): "
                            "нужна перестройка доступности, ID сохраняются")

    for w in warnings:
        print("ПРЕДУПРЕЖДЕНИЕ:", w)
    for e in errors:
        print("ОШИБКА:", e)
    print(f"Итого: {len(errors)} ошибок, {len(warnings)} предупреждений")
    sys.exit(1 if errors else 0)


if __name__ == "__main__":
    main()
