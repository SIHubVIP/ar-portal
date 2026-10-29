class_name DistrictMobs
extends Node3D
## Этап 4 ТЗ «Погуляй», первая часть: 30 точек спавна манифеста оживают. Группа появляется,
## когда герой подходит к зоне (радиус + SPAWN_REACH_M), но не ближе spawn_min_distance_to_player_m
## к самому мобу и не в безопасной зоне. Уходит без награды, если герой убежал дальше DESPAWN_M.
## Перебитая группа возвращается через respawn_delay_s. Состав — group_composition манифеста.

const SPAWN_REACH_M := 50.0
const DESPAWN_M := 160.0
const MAX_GROUPS := 4
const TICK_S := 0.5

signal mob_defeated(mob: EnemyDrone)

var player: Node3D
var _groups: Dictionary = {}      # id точки → {"alive": Array, "respawn_at": float}
var _clock := 0.0
var _tick := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "DistrictMobs"
	set_meta("map_skip", true)
	_rng.randomize()
	for p in District.points("mob"):
		_groups[p.id] = {"alive": [], "respawn_at": 0.0}


func _physics_process(delta: float) -> void:
	_clock += delta
	_tick -= delta
	if _tick > 0.0 or player == null:
		return
	_tick = TICK_S
	update_now()


## Один проход: спавн и уборка групп. Публично для тестов и автопрохождения.
func update_now() -> void:
	var pp := District.to_plan(player.global_position)
	var active := 0
	for id in _groups:
		if not _groups[id].alive.is_empty():
			active += 1
	for p in District.points("mob"):
		var g: Dictionary = _groups[p.id]
		var c := District.pos(p)
		var d := pp.distance_to(c)
		var radius := float(p.radius_m)
		if not g.alive.is_empty():
			if d > DESPAWN_M + radius:
				for m in g.alive:
					if is_instance_valid(m):
						m.queue_free()
				g.alive.clear()
				active -= 1
			continue
		if active >= MAX_GROUPS or _clock < g.respawn_at or d > radius + SPAWN_REACH_M:
			continue
		if not District.safe_zone_at(c).is_empty():
			continue
		if spawn_group(p):
			active += 1


func spawn_group(p: Dictionary) -> bool:
	var comp: Dictionary = p.get("group_composition", {})
	var types: Array[String] = []
	for m in comp.get("members", []):
		for i in _rng.randi_range(int(m.count_min), int(m.count_max)):
			types.append(String(m.mob_type_id))
	var spots := _spots(District.pos(p), float(p.radius_m) * 0.4, float(p.get("spawn_min_distance_to_player_m", 25)), types.size())
	if spots.size() < types.size():
		return false
	var g: Dictionary = _groups[p.id]
	for i in types.size():
		var m := EnemyDrone.new()
		m.mob_type = types[i]
		m.position = District.to_world(spots[i])
		m.set_meta("spawn_point", p.id)
		add_child(m)
		m.defeated.connect(_on_defeated.bind(p))
		g.alive.append(m)
	return true


## Места для группы: кучкой около центра зоны, не в доме и не ближе min_d к герою.
func _spots(center: Vector2, spread: float, min_d: float, count: int) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var pp := District.to_plan(player.global_position)
	for attempt in count * 12:
		if out.size() >= count:
			break
		var q := center + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, spread)
		if q.distance_to(pp) < min_d or not District.walkable(q):
			continue
		var crowded := false
		for o in out:
			crowded = crowded or o.distance_to(q) < 1.6
		if not crowded:
			out.append(q)
	return out


func _on_defeated(m: EnemyDrone, p: Dictionary) -> void:
	var g: Dictionary = _groups[p.id]
	g.alive.erase(m)
	if g.alive.is_empty():
		g.respawn_at = _clock + float(p.get("respawn_delay_s", 180))
	GameState.add_combat_xp(m.xp)
	var at := m.global_position + Vector3(0, 1, 0)
	var key := "loot:%s:%d:%d" % [m.mob_type, Time.get_ticks_usec(), _rng.randi()]
	LootDrop.drop(get_parent(), at, key + ":babki", "", m.loot_babki)
	if _rng.randf() < 0.35:
		LootDrop.drop(get_parent(), at, key + ":item", GameState.roll_loot("drone", _rng.randf()))
	mob_defeated.emit(m)


func alive_count(point_id := "") -> int:
	var n := 0
	for id in _groups:
		if point_id == "" or id == point_id:
			n += _groups[id].alive.size()
	return n
