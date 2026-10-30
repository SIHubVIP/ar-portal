class_name NpcErrands
extends Node3D
## Жители Погуляя и их первые поручения (0.21, D-063). До 0.21 пятнадцать NPC района были
## только метками на карте. Теперь каждый стоит на своей точке, говорит своими репликами
## (data/errands.json) и даёт задание NPC_XX_1, которое проходится целиком:
##   S01 принять — разговор и «Берусь»;
##   S02 именной враг — появляется в 18–32 м от жителя, с него падает уникальная вещь;
##   S03 сбор — группа уличных мобов, трофей падает в 70 % случаев (третья неудача подряд
##       — гарантированно), нужно N штук;
##   S04–S05 сборка и сдача — у жителя: вещи списываются, предмет собирается и отдаётся.
## Одно поручение за раз: карманов для вещей заданий четыре.

const NPC_RADIUS := 2.8
const SPAWN_MIN := 18.0
const SPAWN_MAX := 32.0
const ELITE_HP := 3.0
const ELITE_SCALE := 1.3
const PITY := 2

var world: Node3D            # сцена района: hud, player, _interactables, _person()
var _npcs: Dictionary = {}   # quest_id -> Node3D
var _marks: Dictionary = {}  # quest_id -> Label3D «!»/«?»
var _bubbles: Dictionary = {}
var _spots: Dictionary = {}  # quest_id -> [точка врага, точка группы] (мир)
var _elite: EnemyDrone
var _group: Array = []
var _misses := 0
var _tick := 0.0
var _bubble_tick := 0.0


func _ready() -> void:
	name = "NpcErrands"
	set_meta("map_skip", true)
	EventBus.item_added.connect(_on_item)
	EventBus.quest_state_changed.connect(func(_q, _s) -> void: _refresh_marks())
	EventBus.quest_stage_changed.connect(func(_q, _s) -> void: _refresh_marks())


static func errand(qid: String) -> Dictionary:
	return GameData.errand_by_quest.get(qid, {})


## Поручение, которое сейчас в работе (одно за раз), или "".
static func active() -> String:
	for e in GameData.errands:
		if QuestService.state_of(e.quest) in [QuestService.ACTIVE, QuestService.TURN_IN_READY]:
			return e.quest
	return ""


static func stage_type(qid: String) -> String:
	if QuestService.state_of(qid) == QuestService.TURN_IN_READY:
		return "deliver"
	return String(QuestService.current_stage(qid).get("type", ""))


func build() -> void:
	for e in GameData.errands:
		var p := District.point(e.point)
		if p.is_empty():
			continue
		var at := District.to_world(District.pos(p))
		var look := {"style": e.body.get("style", "short"), "skirt": e.body.get("skirt", false)}
		var top := Color.from_string(String(e.body.get("top", "")), Color(0.5, 0.5, 0.5))
		var npc: Node3D = world._person(at, top, e.name, look)
		npc.name = "Errand_" + e.npc
		npc.add_to_group("map_npc")
		_npcs[e.quest] = npc
		var mark := Kit.label(npc, "!", Vector3(0, 3.0, 0), 110, UiSkin.GOLD)
		mark.outline_size = 14
		var tw := mark.create_tween().set_loops()
		tw.tween_property(mark, "position:y", 3.25, 0.5).set_trans(Tween.TRANS_SINE)
		tw.tween_property(mark, "position:y", 3.0, 0.5).set_trans(Tween.TRANS_SINE)
		_marks[e.quest] = mark
		var bubble := Kit.label(npc, "", Vector3(0, 3.75, 0), 30, Color(1, 0.97, 0.88))
		bubble.width = 520
		bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		bubble.visible = false
		_bubbles[e.quest] = bubble
		_spots[e.quest] = _pick_spots(District.pos(p))
		var qid: String = e.quest
		world._interactables.append({"pos": at, "radius": NPC_RADIUS, "label": "Говорить", "face": npc,
				"cb": func() -> void: talk(qid), "enabled": func() -> bool: return npc.visible})
	_refresh_marks()


## Точки врага и группы: проходимые, вне двора старта, по разные стороны от жителя.
func _pick_spots(center: Vector2) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(center)
	var out: Array = []
	for want in 2:
		var found := Vector2.INF
		for attempt in 60:
			var q := center + Vector2.from_angle(rng.randf() * TAU + want * PI) * rng.randf_range(SPAWN_MIN, SPAWN_MAX)
			if District.walkable(q) and not District.start_area().grow(10.0).has_point(q) \
					and District.safe_zone_at(q).is_empty():
				found = q
				break
		if found == Vector2.INF:
			found = center + Vector2(SPAWN_MIN, 0).rotated(want * PI)
		out.append(District.to_world(found))
	return out


# ---------- разговор ----------

func talk(qid: String) -> void:
	var e := errand(qid)
	var hud: Hud = world.hud
	var sp: String = e.speaker
	var st := QuestService.state_of(qid)
	GameState.set_flag("offered:" + qid)
	if st == QuestService.COMPLETED:
		hud.play_dialog([{"speaker": sp, "text": e.lines.after}])
		return
	if st == QuestService.AVAILABLE:
		var other := active()
		if other != "":
			hud.play_dialog([{"speaker": sp, "text": "Вижу, ты уже бегаешь по делам: %s. Одно поручение за раз — у нас не многозадачность, у нас Погуляй." % errand(other).name}])
			return
		var lines: Array = []
		for t in e.lines.hello:
			lines.append({"speaker": sp, "text": t})
		var q := GameData.quest(qid)
		var lvl := int(q.min_level)
		var warn := "" if GameState.level >= lvl - 2 else " (рекомендуемый уровень %d — будет больно)" % lvl
		hud.play_dialog(lines, func() -> void:
			hud.ask_from(sp, e.lines.ask, [
				{"text": "Берусь%s" % warn, "tone": "green", "cb": func() -> void: _accept(qid)},
				{"text": "Не сейчас", "tone": "plain", "cb": func() -> void:
					hud.play_dialog([{"speaker": sp, "text": "Понимаю. Я тоже не сейчас. Я вообще с прошлого вторника не сейчас."}])}]))
		return
	match stage_type(qid):
		"collect_unique":
			hud.play_dialog([{"speaker": sp, "text": "«%s» бродит тут неподалёку — стрелка покажет. Я бы сам(а), но у меня лапки." % e.elite.name}])
		"collect_stack":
			hud.play_dialog([{"speaker": sp, "text": "%s Собрано %d из %d." % [e.lines.stack, GameState.item_count(e.stack.item.id), int(e.stack.count)]}])
		"craft", "deliver":
			_finish(qid)


func _accept(qid: String) -> void:
	if not QuestService.accept(qid):
		return
	QuestService.advance(qid, qid + "_S01")
	var e := errand(qid)
	world.hud.show_banner("Поручение принято", "«%s» · %s" % [GameData.quest(qid).title, e.name])
	_ensure_spawns()


## Сборка и сдача прямо у жителя: вещи списываются, предмет собирается и тут же отдаётся.
func _finish(qid: String) -> void:
	var e := errand(qid)
	var sp: String = e.speaker
	var u: String = e.elite.item.id
	var s: String = e.stack.item.id
	var c: String = e.craft.item.id
	if stage_type(qid) == "craft":
		if GameState.item_count(u) < 1 or GameState.item_count(s) < int(e.stack.count):
			world.hud.play_dialog([{"speaker": sp, "text": "Чего-то не хватает. Я, конечно, творческая личность, но из воздуха не собираю."}])
			return
		GameState.remove_item(u, 1)
		GameState.remove_item(s, int(e.stack.count))
		GameState.add_item(c, 1)
		QuestService.advance(qid, qid + "_S04")
	var lines: Array = [{"speaker": sp, "text": "Давай сюда. Сейчас соберу «%s» — смотри и не дыши." % e.craft.item.name},
			{"speaker": "journal", "text": "Собрано по рецепту %s: «%s»." % [e.craft.recipe, e.craft.item.name]}]
	for t in e.lines.done:
		lines.append({"speaker": sp, "text": t})
	world.hud.play_dialog(lines, func() -> void:
		GameState.remove_item(c, 1)
		QuestService.advance(qid, qid + "_S05")
		QuestService.turn_in(qid))


# ---------- враги и трофеи ----------

func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_ensure_spawns()
	_bubble_tick -= delta
	if _bubble_tick <= 0.0:
		_bubble_tick = 6.0
		_bubble()


## Держит в мире то, что нужно текущему этапу: врага, если вещи нет ни в кармане, ни на земле;
## группу, если трофеев не хватает и на земле их нет. Прогресс, принесённый из сохранения, засчитывает.
func _ensure_spawns() -> void:
	var qid := active()
	if qid == "":
		return
	var e := errand(qid)
	match stage_type(qid):
		"collect_unique":
			if GameState.item_count(e.elite.item.id) > 0:
				QuestService.advance(qid, qid + "_S02")
			elif not _alive(_elite) and not _on_ground(e.elite.item.id):
				_spawn_elite(qid)
		"collect_stack":
			if GameState.item_count(e.stack.item.id) >= int(e.stack.count):
				QuestService.advance(qid, qid + "_S03")
			elif _group.filter(_alive).is_empty() and not _on_ground(e.stack.item.id):
				_spawn_group(qid)


func _alive(m) -> bool:
	return m != null and is_instance_valid(m) and m.is_alive()


func _on_ground(item: String) -> bool:
	for d in get_tree().get_nodes_in_group("loot"):
		if d.get("item_id") == item:
			return true
	return false


## Сила врагов растёт с рекомендуемым уровнем задания: +4 % здоровья и +2 % урона за уровень.
static func level_k(qid: String) -> Vector2:
	var l := float(GameData.quest(qid).get("min_level", 1)) - 1.0
	return Vector2(1.0 + 0.04 * l, 1.0 + 0.02 * l)


func _spawn_elite(qid: String) -> void:
	var e := errand(qid)
	var k := level_k(qid)
	var m := EnemyDrone.new()
	m.mob_type = e.elite.base
	m.position = _spots[qid][0]
	add_child(m)
	m.display_name = e.elite.name
	m.max_hp *= ELITE_HP * k.x
	m.hp = m.max_hp
	m.attack_damage *= k.y
	m.bark = e.elite.bark
	m.loot_babki *= 3
	m.xp *= 3
	m.scale = Vector3.ONE * ELITE_SCALE
	m._update_bar()
	# имя над головой и золотой круг: видно, что это не рядовой моб
	var l := Kit.label(m, "★ " + String(e.elite.name), Vector3(0, 2.9, 0), 40, UiSkin.GOLD)
	l.no_depth_test = true
	Kit.cylinder(m, 1.0, 0.02, Vector3(0, 0.05, 0), Color(1, 0.8, 0.2, 0.6), 1.5) \
			.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.defeated.connect(func(d: EnemyDrone) -> void:
		var key := "errand:%s:u:%d" % [qid, Time.get_ticks_usec()]
		LootDrop.drop(self, d.global_position + Vector3(0, 1, 0), key, e.elite.item.id)
		LootDrop.drop(self, d.global_position + Vector3(0, 1, 0), key + ":b", "", d.loot_babki)
		GameState.add_combat_xp(d.xp))
	_elite = m


func _spawn_group(qid: String) -> void:
	var e := errand(qid)
	var k := level_k(qid)
	_group.clear()
	var n := int(e.stack.count) + 1
	for i in n:
		var m := EnemyDrone.new()
		m.mob_type = e.stack.base
		m.position = _spots[qid][1] + Vector3(cos(i * TAU / n), 0, sin(i * TAU / n)) * 2.5
		add_child(m)
		m.display_name = e.stack.mob
		m.max_hp *= k.x
		m.hp = m.max_hp
		m.attack_damage *= k.y
		m._update_bar()
		m.defeated.connect(func(d: EnemyDrone) -> void:
			GameState.add_combat_xp(d.xp)
			var need := int(e.stack.count) - GameState.item_count(e.stack.item.id)
			if need <= 0:
				return
			if randf() < float(e.stack.chance) or _misses >= PITY:
				_misses = 0
				LootDrop.drop(self, d.global_position + Vector3(0, 1, 0), "errand:%s:s:%d" % [qid, Time.get_ticks_usec()],
						e.stack.item.id)
			else:
				_misses += 1
				AbilityFx.pop(self, d.global_position + Vector3(0, 2, 0), "пусто", Color(0.8, 0.8, 0.8), 28))
		_group.append(m)


func _on_item(id: String, _n: int) -> void:
	var qid := active()
	if qid == "":
		return
	var e := errand(qid)
	if id == e.elite.item.id or id == e.stack.item.id:
		_ensure_spawns()
		if stage_type(qid) == "craft":
			world.hud.show_toast("Всё собрано — неси %s" % e.name)


# ---------- цели, метки, карта ----------

## Цель для стрелки: [позиция, подпись, подсказка].
func objective(qid: String) -> Array:
	var e := errand(qid)
	if e.is_empty() or not _npcs.has(qid):
		return [Vector3.INF, "", ""]
	var npc: Node3D = _npcs[qid]
	match stage_type(qid):
		"collect_unique":
			var drop := _ground_pos(e.elite.item.id)
			if drop != Vector3.INF:
				return [drop, String(e.elite.item.name), "Подбери «%s»" % e.elite.item.name]
			var at: Vector3 = _elite.global_position if _alive(_elite) else _spots[qid][0]
			return [at, "★ " + String(e.elite.name), "Победи «%s»" % e.elite.name]
		"collect_stack":
			var have := GameState.item_count(e.stack.item.id)
			var detail := "%s: %d из %d" % [e.stack.item.name, have, int(e.stack.count)]
			var drop := _ground_pos(e.stack.item.id)
			if drop != Vector3.INF:
				return [drop, String(e.stack.item.name), detail]
			var best: Vector3 = _spots[qid][1]
			var pp: Vector3 = world.player.global_position
			for m in _group:
				if _alive(m) and (best == _spots[qid][1] or m.global_position.distance_to(pp) < best.distance_to(pp)):
					best = m.global_position
			return [best, String(e.stack.mob), detail]
		"craft", "deliver":
			return [npc.global_position, String(e.name), "Вернись к жителю: соберёт и заберёт"]
	return [Vector3.INF, "", ""]


func _ground_pos(item: String) -> Vector3:
	for d in get_tree().get_nodes_in_group("loot"):
		if d.get("item_id") == item:
			return (d as Node3D).global_position
	return Vector3.INF


## Враги поручения на мини-карте.
func map_points() -> Array:
	var out: Array = []
	for m in _group + [_elite]:
		if _alive(m):
			out.append({"pos": m.global_position, "kind": "enemy", "label": ""})
	return out


func _refresh_marks() -> void:
	var busy := active()
	for qid in _npcs:
		var npc: Node3D = _npcs[qid]
		# Павел (N07) стоит во дворе, пока идёт MAIN_001: вторая копия на точке не нужна
		npc.visible = District.override_for(String(errand(qid).point)).is_empty()
		var mark: Label3D = _marks[qid]
		var st := QuestService.state_of(qid)
		var ready: bool = qid == busy and stage_type(qid) in ["craft", "deliver"]
		mark.visible = npc.visible and (ready or (st == QuestService.AVAILABLE and busy == ""))
		mark.text = "?" if ready else "!"
		mark.modulate = UiSkin.GREEN if ready else UiSkin.GOLD


## Реплика над головой ближайшего жителя, пока его не позвали: район разговаривает сам.
func _bubble() -> void:
	if world == null or world.player == null:
		return
	var pp: Vector3 = world.player.global_position
	for qid in _bubbles:
		var b: Label3D = _bubbles[qid]
		var npc: Node3D = _npcs[qid]
		var near := npc.visible and npc.global_position.distance_to(pp) < 16.0
		b.visible = near and not world.hud.dialog.is_open()
		if b.visible:
			var e := errand(qid)
			var pool: Array = e.lines.hello.duplicate()
			if QuestService.state_of(qid) == QuestService.COMPLETED:
				pool = [e.lines.done[0]]
			var t: String = pool[randi() % pool.size()]
			b.text = t.get_slice(". ", 0).trim_suffix(".") + ("…" if t.contains(". ") else "")
