extends Node
## Состояние героя: класс, уровень, ресурсы, флаги, инвентарь и журнал начислений.
## Каждое начисление идёт через grant() со стабильным ключом и не повторяется.

const POCKET_SLOTS := 4
const BACKPACK_SLOTS := 24
const STORAGE_SLOTS := 24

var class_id := ""
## Пол героя: "m" или "f". Меняет модель, портрет и обращения в разговорах.
var gender := "m"
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
## Порядок клеток в сумках: имя сумки → [id или "" для пустой клетки]. Счёт вещей — в самих сумках,
## здесь только где что лежит (игрок перекладывает вещи пальцем).
var layout: Dictionary = {}
## Сколько раз герой отвечал каждым тоном (green, orange, cyan, purple): из этого складывается характер.
var tones: Dictionary = {}
## Где герой был в мире (для возврата с базы и после загрузки)
var world_scene := ""
var world_position := Vector3.ZERO
var playtime := 0.0


func reset(new_class := "") -> void:
	class_id = new_class
	gender = "m"
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
	layout.clear()
	tones.clear()
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


## Опыт за уличный бой: без записи в журнал наград, иначе сохранение пухнет от каждого слизня.
func add_combat_xp(amount: int) -> void:
	_add_xp(amount)


func _add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while level < GameData.max_level and xp >= total_xp_for(level + 1):
		level += 1
		recalc_max_hp()
		hp = max_hp
		EventBus.level_up.emit(level)
		EventBus.player_hp_changed.emit(hp, max_hp)
	_emit_xp()


static func total_xp_for(l: int) -> int:
	var total := 0
	for i in range(1, l):
		total += xp_to_next(i)
	return total


const TONE_TITLES := {"green": "Законник", "orange": "Барыга", "cyan": "Умник", "purple": "Отморозок"}


func add_tone(tone: String) -> void:
	if TONE_TITLES.has(tone):
		tones[tone] = int(tones.get(tone, 0)) + 1


## Характер героя по тому, как он чаще разговаривает. Пока ответов мало — «Тёмная лошадка».
func character_title() -> String:
	var best := ""
	var best_n := 1
	for t in tones:
		if int(tones[t]) > best_n:
			best_n = int(tones[t])
			best = t
	return TONE_TITLES.get(best, "Тёмная лошадка")


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
	EventBus.inventory_changed.emit()


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
	EventBus.inventory_changed.emit()
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
	EventBus.inventory_changed.emit()
	return moved


## Перенос между героем и сундуком базы. Квестовые предметы всегда при себе.
func to_storage(item_id: String, count := 1) -> bool:
	if GameData.item_by_id.get(item_id, {}).get("type", "") == "quest" or not remove_item(item_id, count):
		return false
	storage[item_id] = int(storage.get(item_id, 0)) + count
	EventBus.inventory_changed.emit()
	return true


func from_storage(item_id: String, count := 1) -> bool:
	if int(storage.get(item_id, 0)) < count:
		return false
	storage[item_id] = int(storage[item_id]) - count
	if storage[item_id] == 0:
		storage.erase(item_id)
	add_item(item_id, count)
	return true


# ---------- клетки сумок: перенос из клетки в клетку ----------

func _bag(name: String) -> Dictionary:
	match name:
		"pockets":
			return pockets
		"backpack":
			return backpack
		"storage":
			return storage
	return {}


func bag_slots(name: String) -> int:
	return {"pockets": POCKET_SLOTS, "backpack": BACKPACK_SLOTS, "storage": STORAGE_SLOTS}.get(name, 0)


## Клетки сумки по порядку: пропавшие вещи освобождают клетку, новые встают в первую свободную.
func bag_cells(name: String) -> Array:
	var bag := _bag(name)
	var cells: Array = []
	for id in layout.get(name, []):
		cells.append(id if id != "" and bag.has(id) and not cells.has(id) else "")
	for id in bag:
		if not cells.has(id):
			var free := cells.find("")
			if free < 0:
				cells.append(id)
			else:
				cells[free] = id
	while cells.size() < bag_slots(name):
		cells.append("")
	layout[name] = cells
	return cells


## Можно ли положить вещь в сумку: квестовое не уходит в сундук, в сумке есть место для новой стопки.
func can_put(item_id: String, name: String) -> bool:
	if name == "storage" and GameData.item_by_id.get(item_id, {}).get("type", "") == "quest":
		return false
	var bag := _bag(name)
	return bag.has(item_id) or bag.size() < bag_slots(name)


## Перенести всю стопку item_id из сумки from в клетку to_index сумки to.
## Если клетка занята другой вещью — вещи меняются местами. Возвращает "" или причину отказа.
func move_item(from: String, item_id: String, to: String, to_index: int) -> String:
	var src := _bag(from)
	var dst := _bag(to)
	if not src.has(item_id) or to_index < 0:
		return "Нечего переносить"
	var src_cells := bag_cells(from)
	var dst_cells := bag_cells(to)
	if to_index >= dst_cells.size():
		return "Нет такой клетки"
	var src_index := src_cells.find(item_id)
	var other: String = dst_cells[to_index]
	if from == to:
		dst_cells[to_index] = item_id
		dst_cells[src_index] = other
		EventBus.inventory_changed.emit()
		return ""
	if other == item_id:
		other = ""
	if to == "storage" and GameData.item_by_id.get(item_id, {}).get("type", "") == "quest":
		return "Квестовое всегда при себе"
	if other != "" and from == "storage" and GameData.item_by_id.get(other, {}).get("type", "") == "quest":
		return "Квестовое всегда при себе"
	if other == "" and not dst.has(item_id) and dst.size() >= bag_slots(to):
		return "Места нет"
	var count := int(src[item_id])
	src.erase(item_id)
	var merged := dst.has(item_id)
	dst[item_id] = int(dst.get(item_id, 0)) + count
	if not merged:
		var old := dst_cells.find(item_id)
		if old >= 0:
			dst_cells[old] = ""
		dst_cells[to_index] = item_id
	src_cells[src_index] = ""
	if other != "" and not merged:
		var back := int(dst[other])
		dst.erase(other)
		src[other] = int(src.get(other, 0)) + back
		src_cells[src_index] = other
	EventBus.inventory_changed.emit()
	return ""


## Снять вещь прямо в выбранную клетку сумки. Снятое попадает в ранец, оттуда — в нужную клетку;
## если туда нельзя, вещь остаётся в ранце. Возвращает "" или причину.
func unequip_to(slot: String, to: String, to_index: int) -> String:
	if not equipment.has(slot):
		return "Слот пуст"
	if to == "storage":
		return "Сначала сними, потом в сундук"
	var item_id: String = equipment[slot]
	unequip(slot)
	return move_item("backpack", item_id, to, to_index)


## Бонус характеристики от надетого: damage, armor, max_hp.
func stat(name: String) -> float:
	var total := 0.0
	for slot in equipment:
		total += float(GameData.item_by_id.get(equipment[slot], {}).get("stats", {}).get(name, 0.0))
	return total


func recalc_max_hp() -> void:
	max_hp = 100.0 + 12.0 * (level - 1) + stat("max_hp")
	hp = minf(hp, max_hp)
	EventBus.player_hp_changed.emit(hp, max_hp)


## Надеть вещь из сумок. Прежняя вещь из того же слота возвращается в ранец.
func equip(item_id: String) -> bool:
	var slot: String = GameData.item_by_id.get(item_id, {}).get("slot", "")
	if slot == "" or not remove_item(item_id):
		return false
	if equipment.has(slot):
		backpack[equipment[slot]] = int(backpack.get(equipment[slot], 0)) + 1
	equipment[slot] = item_id
	recalc_max_hp()
	EventBus.inventory_changed.emit()
	return true


func unequip(slot: String) -> bool:
	if not equipment.has(slot):
		return false
	var item_id: String = equipment[slot]
	equipment.erase(slot)
	backpack[item_id] = int(backpack.get(item_id, 0)) + 1
	recalc_max_hp()
	EventBus.inventory_changed.emit()
	return true


## Расходник: лечит и двигает кукуху. Возвращает текст для всплывашки или "".
func use_item(item_id: String) -> String:
	var use: Dictionary = GameData.item_by_id.get(item_id, {}).get("use", {})
	if use.is_empty() or not remove_item(item_id):
		return ""
	heal(float(use.get("heal", 0)))
	kukukha = clampi(kukukha + int(use.get("kukukha", 0)), 0, 100)
	ledger.append({"key": "use:%s" % item_id, "reason": "Использован предмет", "delta": use, "t": playtime})
	EventBus.resources_changed.emit(babki, reputation, kukukha)
	return "%s: +%d здоровья" % [GameData.item_name(item_id), int(use.get("heal", 0))]


## Стартовый набор нового героя: оружие класса, треники, кепка, пиво и шаурма. Надевается сразу.
func give_starter_kit() -> void:
	if not grant("start:kit", "Стартовый набор", {}):
		return
	for it in GameData.items:
		var start: String = it.get("start", "")
		if start == "all" or start == class_id:
			add_item(it.id, int(it.get("start_count", 1)))
			if it.has("slot"):
				equip(it.id)
	hp = max_hp
	EventBus.player_hp_changed.emit(hp, max_hp)


## Случайный трофей из таблицы data/items.json -> loot_tables. roll в [0, 1).
static func roll_loot(table: String, roll: float) -> String:
	var rows: Array = GameData.loot_tables.get(table, [])
	var total := 0.0
	for r in rows:
		total += float(r[1])
	var acc := 0.0
	for r in rows:
		acc += float(r[1]) / total
		if roll < acc:
			return r[0]
	return "" if rows.is_empty() else rows[-1][0]


func damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	EventBus.player_hp_changed.emit(hp, max_hp)


func heal(amount: float) -> void:
	hp = minf(max_hp, hp + amount)
	EventBus.player_hp_changed.emit(hp, max_hp)


func to_dict() -> Dictionary:
	return {"class_id": class_id, "gender": gender, "level": level, "xp": xp, "babki": babki, "reputation": reputation,
			"kukukha": kukukha, "hp": hp, "flags": flags.keys(), "granted": granted.keys(), "ledger": ledger,
			"pockets": pockets, "backpack": backpack, "equipment": equipment, "storage": storage, "layout": layout, "tones": tones,
			"world_scene": world_scene, "world_position": [world_position.x, world_position.y, world_position.z],
			"playtime": playtime}


func from_dict(d: Dictionary) -> void:
	class_id = d.get("class_id", "")
	gender = d.get("gender", "m")
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	babki = int(d.get("babki", 0))
	reputation = int(d.get("reputation", 0))
	kukukha = int(d.get("kukukha", 0))
	equipment = d.get("equipment", {})
	recalc_max_hp()
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
	storage = _int_dict(d.get("storage", {}))
	layout = d.get("layout", {})
	tones = _int_dict(d.get("tones", {}))
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
