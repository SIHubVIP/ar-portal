extends Node
## Состояние героя: класс, уровень, ресурсы, флаги, инвентарь и журнал начислений.
## Каждое начисление идёт через grant() со стабильным ключом и не повторяется.

const POCKET_SLOTS := 4
const BACKPACK_SLOTS := 24

var class_id := ""
var level := 1
var xp := 0
var babki := 0
var reputation := 0
var kukukha := 0
var max_hp := 100.0
var hp := 100.0
var flags: Dictionary = {}
## idempotency_key -> true: что уже начислено
var granted: Dictionary = {}
## Журнал причин всех изменений ресурсов
var ledger: Array = []
## Карманы, ранец и экипировка независимы; хранилище базы отдельно.
var pockets: Dictionary = {}
var backpack: Dictionary = {}
var equipment: Dictionary = {}
var storage: Dictionary = {}
## Где герой был в мире (для возврата с базы и после загрузки)
var world_scene := ""
var world_position := Vector3.ZERO
var playtime := 0.0


func reset(new_class := "") -> void:
	class_id = new_class
	level = 1
	xp = 0
	babki = 0
	reputation = 0
	kukukha = 0
	max_hp = 100.0
	hp = max_hp
	flags.clear()
	granted.clear()
	ledger.clear()
	pockets.clear()
	backpack.clear()
	equipment.clear()
	storage.clear()
	world_scene = ""
	world_position = Vector3.ZERO
	playtime = 0.0
	_emit_all()


## Опыт, нужный для перехода с уровня l на l+1 (черновая кривая, см. docs/decisions.log).
static func xp_to_next(l: int) -> int:
	return 40 + 45 * l


## Атомарное начисление. Возвращает false, если ключ уже использован.
func grant(key: String, reason: String, delta: Dictionary) -> bool:
	if granted.has(key):
		return false
	var d_babki := int(delta.get("babki", 0))
	if babki + d_babki < 0:
		return false
	granted[key] = true
	babki += d_babki
	reputation += int(delta.get("reputation", 0))
	kukukha = clampi(kukukha + int(delta.get("kukukha", 0)), 0, 100)
	ledger.append({"key": key, "reason": reason, "delta": delta, "t": playtime})
	for item_id in delta.get("items", {}):
		add_item(item_id, int(delta.items[item_id]))
	EventBus.resources_changed.emit(babki, reputation, kukukha)
	_add_xp(int(delta.get("xp", 0)))
	return true


func _add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while level < GameData.max_level and xp >= total_xp_for(level + 1):
		level += 1
		max_hp = 100.0 + 12.0 * (level - 1)
		hp = max_hp
		EventBus.level_up.emit(level)
		EventBus.player_hp_changed.emit(hp, max_hp)
	_emit_xp()


static func total_xp_for(l: int) -> int:
	var total := 0
	for i in range(1, l):
		total += xp_to_next(i)
	return total


func set_flag(flag: String) -> void:
	if flags.has(flag):
		return
	flags[flag] = true
	EventBus.flag_set.emit(flag)


func has_flag(flag: String) -> bool:
	return flags.has(flag)


## Квестовые предметы и мелочь — в карманы, пока есть место, остальное — в ранец.
func add_item(item_id: String, count := 1) -> void:
	var bag := backpack
	var type: String = GameData.item_by_id.get(item_id, {}).get("type", "")
	if (type == "quest" or type == "key") and (pockets.has(item_id) or pockets.size() < POCKET_SLOTS):
		bag = pockets
	bag[item_id] = int(bag.get(item_id, 0)) + count
	EventBus.item_added.emit(item_id, count)


func item_count(item_id: String) -> int:
	return int(pockets.get(item_id, 0)) + int(backpack.get(item_id, 0))


func remove_item(item_id: String, count := 1) -> bool:
	if item_count(item_id) < count:
		return false
	for bag in [pockets, backpack]:
		var take := mini(count, int(bag.get(item_id, 0)))
		if take > 0:
			bag[item_id] = int(bag[item_id]) - take
			if bag[item_id] == 0:
				bag.erase(item_id)
			count -= take
	return true


## Всё, кроме квестовых предметов, переносится из ранца в хранилище базы.
func stash_backpack() -> int:
	var moved := 0
	for item_id in backpack.keys():
		if GameData.item_by_id.get(item_id, {}).get("type", "") == "quest":
			continue
		storage[item_id] = int(storage.get(item_id, 0)) + int(backpack[item_id])
		moved += int(backpack[item_id])
		backpack.erase(item_id)
	return moved


func damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	EventBus.player_hp_changed.emit(hp, max_hp)


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	EventBus.player_hp_changed.emit(hp, max_hp)


func to_dict() -> Dictionary:
	return {"class_id": class_id, "level": level, "xp": xp, "babki": babki, "reputation": reputation,
			"kukukha": kukukha, "hp": hp, "flags": flags.keys(), "granted": granted.keys(), "ledger": ledger,
			"pockets": pockets, "backpack": backpack, "equipment": equipment, "storage": storage,
			"world_scene": world_scene, "world_position": [world_position.x, world_position.y, world_position.z],
			"playtime": playtime}


func from_dict(d: Dictionary) -> void:
	class_id = d.get("class_id", "")
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	babki = int(d.get("babki", 0))
	reputation = int(d.get("reputation", 0))
	kukukha = int(d.get("kukukha", 0))
	max_hp = 100.0 + 12.0 * (level - 1)
	hp = clampf(float(d.get("hp", max_hp)), 1.0, max_hp)
	flags.clear()
	for f in d.get("flags", []):
		flags[f] = true
	granted.clear()
	for k in d.get("granted", []):
		granted[k] = true
	ledger = d.get("ledger", [])
	pockets = _int_dict(d.get("pockets", {}))
	backpack = _int_dict(d.get("backpack", {}))
	equipment = d.get("equipment", {})
	storage = _int_dict(d.get("storage", {}))
	world_scene = d.get("world_scene", "")
	var p: Array = d.get("world_position", [0, 0, 0])
	world_position = Vector3(p[0], p[1], p[2])
	playtime = float(d.get("playtime", 0.0))
	_emit_all()


func _int_dict(src: Dictionary) -> Dictionary:
	var out := {}
	for k in src:
		out[k] = int(src[k])
	return out


func _emit_all() -> void:
	EventBus.resources_changed.emit(babki, reputation, kukukha)
	EventBus.player_hp_changed.emit(hp, max_hp)
	_emit_xp()


func _emit_xp() -> void:
	var base := total_xp_for(level)
	EventBus.xp_changed.emit(xp, level, xp - base, xp_to_next(level))
