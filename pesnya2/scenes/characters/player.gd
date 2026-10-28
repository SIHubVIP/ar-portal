class_name Player
extends CharacterBody3D
## Герой. Ввод приходит от сенсорного управления (move_input, use_*) или клавиатуры.
## Исход боя решают правила AbilityBook и GameState, анимация только показывает.

signal died

const SPEED := 6.0
const DODGE_DISTANCE := 4.5
const DODGE_TIME := 0.22
const ATTACK_RANGE := 2.6
const ATTACK_COOLDOWN := 0.45
const ATTACK_DAMAGE := 12.0
const CLASS_COLORS := {"CLASS_1": Color(0.75, 0.16, 0.14), "CLASS_2": Color(0.2, 0.55, 0.3),
		"CLASS_3": Color(0.45, 0.25, 0.7)}

## Азимут изометрической камеры: ввод стика поворачивается на него.
var camera_yaw := deg_to_rad(45.0)
var move_input := Vector2.ZERO
var controls_enabled := true
var book: AbilityBook
var t := 0.0
var facing := Vector3(0, 0, 1)

var _attack_ready_at := 0.0
var _dodge_left := 0.0
var _dodge_dir := Vector3.ZERO
var _guard_until := 0.0
var _buff_until := 0.0
var _walk_phase := 0.0
var _rig: Node3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _weapon: Node3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)
	book = AbilityBook.new(GameState.class_id if GameState.class_id != "" else "CLASS_1")
	_build_rig()


func _build_rig() -> void:
	_rig = Node3D.new()
	add_child(_rig)
	var jacket: Color = CLASS_COLORS.get(GameState.class_id, Color(0.5, 0.5, 0.5))
	var skin := Color(0.93, 0.76, 0.62)
	Kit.capsule(_rig, 0.33, 0.95, Vector3(0, 1.2, 0), jacket)
	Kit.sphere(_rig, 0.24, Vector3(0, 1.88, 0), skin)
	Kit.box(_rig, Vector3(0.4, 0.12, 0.3), Vector3(0, 2.07, -0.02), Color(0.2, 0.15, 0.1))  # причёска
	Kit.box(_rig, Vector3(0.3, 0.06, 0.05), Vector3(0, 1.9, 0.23), Color(0.1, 0.1, 0.1))  # брови
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(0.14 * side, 0.82, 0)
		_rig.add_child(leg)
		Kit.box(leg, Vector3(0.18, 0.78, 0.2), Vector3(0, -0.39, 0), Color(0.18, 0.2, 0.3))
		# один ботинок герой потерял: левая нога в носке, пока не найден ботинок
		var shoe := Kit.box(leg, Vector3(0.2, 0.1, 0.32), Vector3(0, -0.78, 0.05), Color(0.1, 0.08, 0.06))
		if side < 0:
			shoe.name = "LeftShoe"
			shoe.visible = GameState.item_count("ITEM_P1_SHOE") > 0 or GameState.has_flag("MAIN_001_A") \
					or GameState.has_flag("MAIN_001_B")
		_legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(0.42 * side, 1.55, 0)
		_rig.add_child(arm)
		Kit.box(arm, Vector3(0.15, 0.7, 0.16), Vector3(0, -0.33, 0), jacket.darkened(0.15))
		Kit.sphere(arm, 0.09, Vector3(0, -0.72, 0), skin)
		_arms.append(arm)
	_weapon = Node3D.new()
	_arms[1].add_child(_weapon)
	match GameState.class_id:
		"CLASS_2":
			Kit.box(_weapon, Vector3(0.1, 0.12, 0.45), Vector3(0, -0.75, 0.2), Color(0.15, 0.15, 0.15))
		"CLASS_3":
			Kit.cylinder(_weapon, 0.04, 1.3, Vector3(0, -0.6, 0.15), Color(0.5, 0.4, 0.25))
			Kit.sphere(_weapon, 0.1, Vector3(0, 0.05, 0.15), Color(0.3, 0.9, 1.0), 2.5)
		_:
			Kit.box(_weapon, Vector3(0.12, 0.85, 0.12), Vector3(0, -0.95, 0.15), Color(0.55, 0.38, 0.2))


func show_shoe() -> void:
	var shoe := _rig.find_child("LeftShoe", true, false)
	if shoe:
		shoe.visible = true


func _physics_process(delta: float) -> void:
	t += delta
	var input := move_input
	if controls_enabled:
		var kb := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		kb += Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
				float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		if kb.length() > 0.1:
			input = kb.limit_length(1.0)
	else:
		input = Vector2.ZERO
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw)
	if _dodge_left > 0.0:
		_dodge_left -= delta
		velocity = _dodge_dir * (DODGE_DISTANCE / DODGE_TIME)
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	if dir.length() > 0.05:
		facing = dir.normalized()
	_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(facing.x, facing.z), 12.0 * delta)
	_animate(delta, dir.length())


func _animate(delta: float, moving: float) -> void:
	_walk_phase += delta * 10.0 * moving
	var swing := sin(_walk_phase) * 0.6 * moving
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing
	_arms[0].rotation.x = -swing * 0.8
	if t > _attack_ready_at - ATTACK_COOLDOWN + 0.2:
		_arms[1].rotation.x = lerpf(_arms[1].rotation.x, swing * 0.8, 10.0 * delta)


func is_guarding() -> bool:
	return t < _guard_until


func is_dodging() -> bool:
	return _dodge_left > 0.0


func take_hit(damage: float) -> void:
	if is_dodging() or GameState.hp <= 0.0:
		return
	if is_guarding():
		damage *= 0.3
	GameState.damage(damage)
	_flash()
	if GameState.hp <= 0.0:
		died.emit()


func basic_attack() -> void:
	if t < _attack_ready_at or not controls_enabled:
		return
	_attack_ready_at = t + ATTACK_COOLDOWN
	var target := _nearest_enemy(ATTACK_RANGE + (6.0 if GameState.class_id == "CLASS_2" else 0.0))
	if target:
		facing = (target.global_position - global_position).normalized()
		facing.y = 0.0
	_arms[1].rotation.x = -2.2
	var tw := create_tween()
	tw.tween_property(_arms[1], "rotation:x", 0.6, 0.15)
	if target == null:
		return
	if GameState.class_id == "CLASS_2" or GameState.class_id == "CLASS_3":
		Kit.beam(get_parent(), global_position + Vector3(0, 1.3, 0), target.global_position + Vector3(0, 1, 0),
				Color(1, 0.85, 0.3) if GameState.class_id == "CLASS_2" else Color(0.3, 0.9, 1))
	target.take_hit(AbilityBook.scaled(ATTACK_DAMAGE, GameState.level, t < _buff_until), global_position)


func dodge() -> void:
	if _dodge_left > 0.0 or not controls_enabled:
		return
	_dodge_dir = facing
	_dodge_left = DODGE_TIME


func ability_remaining(index: int) -> float:
	if index >= book.abilities.size():
		return 0.0
	return book.remaining(book.abilities[index].id, t)


func use_ability(index: int) -> void:
	if index >= book.abilities.size() or not controls_enabled:
		return
	var a: Dictionary = book.abilities[index]
	if not book.cast(a.id, t):
		return
	var s := book.spec(a)
	var dmg := AbilityBook.scaled(float(s.get("damage", 0.0)), GameState.level, t < _buff_until)
	var origin := global_position
	EventBus.ability_cast.emit(a.id, float(a.cooldown_s))
	match s.effect:
		"strike":
			var e := _nearest_enemy(s.range)
			if e:
				e.take_hit(dmg, origin)
				Kit.ring(get_parent(), e.global_position, 1.0, Color(1, 0.6, 0.2))
			if s.has("guard"):
				_guard_until = t + float(s.guard)
		"shot":
			var e := _nearest_enemy(s.range)
			if e:
				Kit.beam(get_parent(), origin + Vector3(0, 1.3, 0), e.global_position + Vector3(0, 1, 0), Color(0.4, 1, 1))
				e.take_hit(dmg, origin)
		"dash":
			var e := _nearest_enemy(s.range)
			_dodge_dir = (e.global_position - origin).normalized() * Vector3(1, 0, 1) if e and dmg > 0.0 else facing
			_dodge_left = DODGE_TIME * clampf(s.range / DODGE_DISTANCE, 1.0, 2.0)
			if e and dmg > 0.0:
				e.take_hit(dmg, origin)
		"guard":
			_guard_until = t + float(s.duration)
			Kit.ring(get_parent(), origin, 1.2, Color(0.4, 0.7, 1), float(s.duration))
		"stun":
			Kit.ring(get_parent(), origin, s.range, Color(0.8, 0.5, 1))
			for e in _enemies_in(s.range):
				e.stun(float(s.duration))
				if dmg > 0.0:
					e.take_hit(dmg, origin)
		"area":
			Kit.ring(get_parent(), origin, s.range, Color(1, 0.4, 0.1), 0.5)
			for e in _enemies_in(s.range):
				e.take_hit(dmg, origin)
		"turret":
			_spawn_turret(s)
		"buff":
			_buff_until = t + float(s.duration)
			GameState.heal(GameState.max_hp * 0.25)
			Kit.ring(get_parent(), origin, 1.0, Color(0.3, 1, 0.5), float(s.duration))


func _spawn_turret(s: Dictionary) -> void:
	var turret := Node3D.new()
	get_parent().add_child(turret)
	turret.global_position = global_position + facing * 1.5
	Kit.cylinder(turret, 0.3, 0.6, Vector3(0, 0.3, 0), Color(0.3, 0.3, 0.35))
	Kit.sphere(turret, 0.2, Vector3(0, 0.8, 0), Color(0.3, 0.9, 1), 2.0)
	var shots := int(float(s.duration) / 0.8)
	var tw := turret.create_tween()
	for i in shots:
		tw.tween_interval(0.8)
		tw.tween_callback(func():
			var e := _nearest_enemy_from(turret.global_position, s.range)
			if e:
				Kit.beam(get_parent(), turret.global_position + Vector3(0, 0.8, 0), e.global_position + Vector3(0, 1, 0),
						Color(0.3, 0.9, 1), 0.1)
				e.take_hit(AbilityBook.scaled(float(s.damage), GameState.level, false), turret.global_position))
	tw.tween_callback(turret.queue_free)


func _enemies_in(radius: float) -> Array:
	return get_tree().get_nodes_in_group("enemies").filter(
		func(e): return e.is_alive() and e.global_position.distance_to(global_position) <= radius)


func _nearest_enemy(radius: float) -> Node3D:
	return _nearest_enemy_from(global_position, radius)


func _nearest_enemy_from(from: Vector3, radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_alive():
			continue
		var d: float = e.global_position.distance_to(from)
		if d <= best_d:
			best_d = d
			best = e
	return best


func _flash() -> void:
	var tw := create_tween()
	_rig.scale = Vector3(1.08, 0.94, 1.08)
	tw.tween_property(_rig, "scale", Vector3.ONE, 0.15)
