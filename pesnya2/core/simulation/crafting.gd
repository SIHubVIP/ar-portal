class_name Crafting
extends RefCounted
## Верстак гаража №13 (0.16): рецепты из того, что падает с дронов, мусора и боссов.
## Материалы берутся сначала из сумок, потом из сундука базы — таскать их с собой не нужно.

const RECIPES := [
	{"id": "R_FOIL_HAT", "out": "ITEM_P2_FOIL_HAT", "needs": {"ITEM_P1_SCRAP": 3},
		"text": "Обломки дрона, фольга от шаурмы и вера в соседа"},
	{"id": "R_PIPE", "out": "ITEM_P2_PIPE", "needs": {"ITEM_P1_SCRAP": 4, "ITEM_P1_GRATITUDE_CHIP": 1},
		"text": "Труба, обмотанная проводом от чипа благодарности"},
	{"id": "R_BANNER_VEST", "out": "ITEM_P3_BANNER_VEST", "needs": {"ITEM_P1_SCRAP": 5, "ITEM_P1_GRATITUDE_CHIP": 2},
		"text": "Баннер с рекламной тумбы на каркасе из дрона"},
	{"id": "R_MIC_BAT", "out": "ITEM_P3_MIC_BAT", "needs": {"ITEM_P3_MUTE_CORE": 1, "ITEM_P1_SCRAP": 3},
		"text": "Ядро глушилки Люси в рукояти из обломков"},
]


static func recipe(id: String) -> Dictionary:
	for r in RECIPES:
		if r.id == id:
			return r
	return {}


## Сколько вещи есть у героя всего: сумки и сундук.
static func have(item_id: String) -> int:
	return GameState.item_count(item_id) + int(GameState.storage.get(item_id, 0))


static func can_craft(id: String) -> bool:
	var r := recipe(id)
	if r.is_empty():
		return false
	for item_id in r.needs:
		if have(item_id) < int(r.needs[item_id]):
			return false
	return true


## Чего не хватает, строкой для подсказки: «Обломок ×2, Чип ×1». Пусто — всё есть.
static func missing(id: String) -> String:
	var r := recipe(id)
	var out := PackedStringArray()
	for item_id in r.get("needs", {}):
		var lack := int(r.needs[item_id]) - have(item_id)
		if lack > 0:
			out.append("%s ×%d" % [GameData.item_name(item_id), lack])
	return ", ".join(out)


static func needs_text(id: String) -> String:
	var r := recipe(id)
	var out := PackedStringArray()
	for item_id in r.get("needs", {}):
		out.append("%s ×%d" % [GameData.item_name(item_id), int(r.needs[item_id])])
	return ", ".join(out)


## Собирает вещь: списывает материалы (сумки, потом сундук) и кладёт результат в ранец.
static func craft(id: String) -> bool:
	if not can_craft(id):
		return false
	var r := recipe(id)
	for item_id in r.needs:
		var left := int(r.needs[item_id])
		var from_bags := mini(left, GameState.item_count(item_id))
		if from_bags > 0:
			GameState.remove_item(item_id, from_bags)
			left -= from_bags
		if left > 0:
			GameState.storage[item_id] = int(GameState.storage[item_id]) - left
			if GameState.storage[item_id] <= 0:
				GameState.storage.erase(item_id)
	GameState.ledger.append({"key": "craft:%s:%d" % [id, GameState.ledger.size()], "reason": "Верстак", "delta": r.needs,
			"t": GameState.playtime})
	GameState.add_item(String(r.out))
	return true


## Трофеи боссов: ключи наград boss:BOSS_xx, по порядку боссов в данных.
static func trophies() -> Array:
	var out: Array = []
	for b in GameData.bosses:
		if GameState.granted.has("boss:%s" % b.id):
			out.append(b)
	return out
