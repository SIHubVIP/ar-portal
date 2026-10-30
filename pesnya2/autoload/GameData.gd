extends Node
## Канонические данные игры из data/*.json (генерируются tools/importers/import_sources.py).
## Только чтение: изменяемое состояние живёт в GameState и QuestService.

const EXPECTED := {"quests": 127, "main": 20, "npc_quests": 99, "solo": 8, "npcs": 33,
		"bosses": 15, "abilities": 21, "classes": 3, "stages": 543}

var quests: Array = []
var quest_by_id: Dictionary = {}
var npcs: Array = []
var npc_by_id: Dictionary = {}
var bosses: Array = []
var boss_by_id: Dictionary = {}
var classes: Array = []
var class_by_id: Dictionary = {}
var abilities: Array = []
var ability_by_id: Dictionary = {}
var scenes: Array = []
var scene_by_id: Dictionary = {}
var items: Array = []
var item_by_id: Dictionary = {}
## Поручения жителей Погуляя (0.21, data/errands.json): первые задания 15 NPC.
var errands: Array = []
var errand_by_quest: Dictionary = {}
var loot_tables: Dictionary = {}
var max_level := 55
## Редакторские описания способностей и уровни открытия
var ability_flavor: Dictionary = {}
## Диалоги: id -> граф узлов (data/dialogues.json)
var dialogues: Dictionary = {}
var dialogues_speakers: Dictionary = {}


func _ready() -> void:
	load_all()


func load_all() -> void:
	quests = _read("res://data/quests.json").get("quests", [])
	npcs = _read("res://data/npcs.json").get("npcs", [])
	bosses = _read("res://data/bosses.json").get("bosses", [])
	var abl := _read("res://data/abilities.json")
	classes = abl.get("classes", [])
	abilities = abl.get("abilities", [])
	max_level = int(abl.get("max_level", 55))
	scenes = _read("res://data/scenes.json").get("scenes", [])
	var it := _read("res://data/items.json")
	items = it.get("items", [])
	loot_tables = it.get("loot_tables", {})
	ability_flavor = _read("res://data/ability_flavor.json")
	var dlg := _read("res://data/dialogues.json")
	dialogues = dlg.get("dialogues", {})
	dialogues_speakers = dlg.get("speakers", {})
	quest_by_id = _index(quests)
	npc_by_id = _index(npcs)
	boss_by_id = _index(bosses)
	class_by_id = _index(classes)
	ability_by_id = _index(abilities)
	scene_by_id = _index(scenes)
	# вещи поручений и портреты жителей — из errands.json, чтобы сохранения находили их сразу
	errands = _read("res://data/errands.json").get("errands", [])
	errand_by_quest.clear()
	for e in errands:
		errand_by_quest[e.quest] = e
		for part in [e.elite, e.stack, e.craft]:
			items.append(part.item)
		dialogues_speakers[e.speaker] = {"name": e.name, "portrait": e.portrait}
	item_by_id = _index(items)


func quest(id: String) -> Dictionary:
	return quest_by_id.get(id, {})


func item_name(id: String) -> String:
	return item_by_id.get(id, {}).get("name", id)


func class_abilities(class_id: String) -> Array:
	var out: Array = []
	for id in class_by_id.get(class_id, {}).get("abilities", []):
		out.append(ability_by_id[id])
	return out


## Список нарушений канона: пустой массив означает, что данные целы.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var count_kind := func(kind: String) -> int:
		return quests.filter(func(q): return q.kind == kind).size()
	var stages := 0
	for q in quests:
		stages += q.stages.size()
	var actual := {"quests": quests.size(), "main": count_kind.call("main"),
			"npc_quests": count_kind.call("npc"), "solo": count_kind.call("solo_activity"),
			"npcs": npcs.size(), "bosses": bosses.size(), "abilities": abilities.size(),
			"classes": classes.size(), "stages": stages}
	for key in EXPECTED:
		if actual[key] != EXPECTED[key]:
			errors.append("%s: ожидалось %d, найдено %d" % [key, EXPECTED[key], actual[key]])
	for pair in [[quests, quest_by_id, "quest"], [npcs, npc_by_id, "npc"], [bosses, boss_by_id, "boss"],
			[abilities, ability_by_id, "ability"], [items, item_by_id, "item"]]:
		if pair[0].size() != pair[1].size():
			errors.append("дубликаты ID среди %s" % pair[2])
	for q in quests:
		for dep in q.requires:
			if not quest_by_id.has(dep):
				errors.append("%s зависит от неизвестного %s" % [q.id, dep])
		if q.npc_id != null and not npc_by_id.has(q.npc_id):
			errors.append("%s: неизвестный NPC %s" % [q.id, q.npc_id])
	for b in bosses:
		if not quest_by_id.has(b.quest_id):
			errors.append("%s: неизвестный квест %s" % [b.id, b.quest_id])
	for c in classes:
		if c.abilities.size() != 7:
			errors.append("%s: способностей %d вместо 7" % [c.id, c.abilities.size()])
	return errors


func _index(arr: Array) -> Dictionary:
	var d := {}
	for e in arr:
		d[e.id] = e
	return d


func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("GameData: не открыть %s" % path)
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		push_error("GameData: битый JSON %s" % path)
		return {}
	return parsed
