class_name Player
extends CharacterBody3D
## Герой. Ввод приходит от сенсорного управления (move_input, use_*) или клавиатуры.
## Исход боя решают правила AbilityBook и GameState, анимация только показывает.
## Вышибала — 3D-модель со скелетом (assets/characters/vyshibala), остальные классы пока из фигур.

signal died
## Серия ударов (0.20): n — какой по счёту удар подряд попал, 0 — серия сорвалась.
signal combo(n: int)
## Ловкий уклон: удар врага прошёл сквозь уклон — следующий удар двойной.
signal perfect_dodge

const SPEED := 6.0
const DODGE_DISTANCE := 4.5
const DODGE_TIME := 0.22
const ATTACK_RANGE := 2.6
const ATTACK_COOLDOWN := 0.45
const ATTACK_DAMAGE := 12.0
## Серия: если следующий удар попал не позже COMBO_WINDOW с, серия растёт. Каждый третий —
## размашистый: бьёт всех рядом сильнее и отбрасывает.
const COMBO_WINDOW := 1.1
const COMBO_MULT := [1.0, 1.15, 1.8]
const SWEEP_RANGE := 3.4
const PERFECT_WINDOW := 2.5
const PERFECT_MULT := 2.0
const CLASS_COLORS := {"CLASS_1": Color(0.75, 0.16, 0.14), "CLASS_2": Color(0.2, 0.55, 0.3),
		"CLASS_3": Color(0.45, 0.25, 0.7)}
const MODELS := {"CLASS_1": "res://assets/characters/vyshibala/vyshibala.glb",
		"CLASS_1_f": "res://assets/characters/vyshibala/vyshibala_f.glb"}
const LOOPED := ["Idle", "Walk", "Run"]

## Азимут камеры: ввод стика поворачивается на него (камера обновляет каждый кадр).
var camera_yaw := deg_to_rad(45.0)
var move_input := Vector2.ZERO
var controls_enabled := true
var book: AbilityBook
var t := 0.0
var facing := Vector3(0, 0, 1)
var guard_until := 0.0
var buff_until := 0.0
## id безопасной зоны района (S0–S4), где стоит герой; пусто снаружи. Там по нему не бьют.
var safe_zone := ""

var _attack_ready_at := 0.0
var combo_count := 0
var _combo_until := 0.0
var _perfect_until := 0.0
var _dodge_left := 0.0
var _dodge_dir := Vector3.ZERO
var _knock := Vector3.ZERO
var _walk_phase := 0.0
var _rig: Node3D
var _anim: AnimationPlayer
var _anim_lock := 0.0
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []


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
	_rig = Node3D.new()
	add_child(_rig)
	var cid := GameState.class_id if GameState.class_id != "" else "CLASS_1"
	var model_path: String = MODELS.get(cid + ("_f" if GameState.gender == "f" else ""), MODELS.get(cid, ""))
	if model_path != "" and ResourceLoader.exists(model_path):
		_build_model(model_path)
	else:
		_build_blocks()


func _build_model(path: String) -> void:
	var model: Node3D = load(path).instantiate()
	_rig.add_child(model)
	_anim = model.find_child("AnimationPlayer", true, false)
	if _anim:
		for name in LOOPED:
			if _anim.has_animation(name):
				_anim.get_animation(name).loop_mode = Animation.LOOP_LINEAR
		_anim.play("Idle")


func _build_blocks() -> void:
	var jacket: Color = CLASS_COLORS.get(GameState.class_id, Color(0.5, 0.5, 0.5))
	var skin := Color(0.93, 0.76, 0.62)
	Kit.capsule(_rig, 0.33, 0.95, Vector3(0, 1.2, 0), jacket)
	Kit.sphere(_rig, 0.24, Vector3(0, 1.88, 0), skin)
	Kit.box(_rig, Vector3(0.4, 0.12, 0.3), Vector3(0, 2.07, -0.02), Color(0.2, 0.15, 0.1))
	if GameState.gender == "f":
		Kit.sphere(_rig, 0.13, Vector3(0, 1.98, -0.25), Color(0.95, 0.82, 0.55))
		Kit.sphere(_rig, 0.1, Vector3(0, 1.8, -0.3), Color(0.95, 0.82, 0.55))
	Kit.box(_rig, Vector3(0.3, 0.06, 0.05), Vector3(0, 1.9, 0.23), Color(0.1, 0.1, 0.1))
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(0.14 * side, 0.82, 0)
		_rig.add_child(leg)
		Kit.box(leg, Vector3(0.18, 0.78, 0.2), Vector3(0, -0.39, 0), Color(0.18, 0.2, 0.3))
		Kit.box(leg, Vector3(0.2, 0.1, 0.32), Vector3(0, -0.78, 0.05), Color(0.1, 0.08, 0.06))
		_legs.append(leg)
		var arm := Node3D.new()
		arm.position = Vector3(0.42 * side, 1.55, 0)
		_rig.add_child(arm)
		Kit.box(arm, Vector3(0.15, 0.7, 0.16), Vector3(0, -0.33, 0), jacket.darkened(0.15))
		Kit.sphere(arm, 0.09, Vector3(0, -0.72, 0), skin)
		_arms.append(arm)
	var weapon := Node3D.new()
	_arms[1].add_child(weapon)
	match GameState.class_id:
		"CLASS_2":
			Kit.box(weapon, Vector3(0.1, 0.12, 0.45), Vector3(0, -0.75, 0.2), Color(0.15, 0.15, 0.15))
		"CLASS_3":
			Kit.cylinder(weapon, 0.04, 1.3, Vector3(0, -0.6, 0.15), Color(0.5, 0.4, 0.25))
			Kit.sphere(weapon, 0.1, Vector3(0, 0.05, 0.15), Color(0.3, 0.9, 1.0), 2.5)
		_:
			Kit.box(weapon, Vector3(0.12, 0.85, 0.12), Vector3(0, -0.95, 0.15), Color(0.55, 0.38, 0.2))


func show_shoe() -> void:
	pass  # ботинок виден в инвентаре; модель уже обута


## Анимация действия: на модели — клип из glb, у фигур — простое движение руки.
func play_action(name: String, seconds := 0.5) -> void:
	_anim_lock = seconds
	if _anim and _anim.has_animation(name):
		_anim.play(name, 0.08)
		_anim.seek(0.0, true)
	elif not _arms.is_empty():
		_arms[1].rotation.x = -2.2
		create_tween().tween_property(_arms[1], "rotation:x", 0.6, 0.2)


func _physics_process(delta: float) -> void:
	t += delta
	var input := move_input
	if controls_enabled:
		var kb := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
				float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		kb += Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		if kb.length() > 0.1:
			input = kb.limit_length(1.0)
	else:
		input = Vector2.ZERO
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, camera_yaw)
	if _dodge_left > 0.0:
		_dodge_left -= delta
		velocity = _dodge_dir * (DODGE_DISTANCE / DODGE_TIME)
	elif _knock.length() > 0.3:
		# отбрасывание ударной волной босса (0.16): управление возвращается, когда толчок погас
		velocity.x = _knock.x
		velocity.z = _knock.z
		_knock = _knock.lerp(Vector3.ZERO, clampf(6.0 * delta, 0.0, 1.0))
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	_push_props()
	if dir.length() > 0.05:
		facing = dir.normalized()
	_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(facing.x, facing.z), 12.0 * delta)
	_animate(delta, dir.length())


func _animate(delta: float, moving: float) -> void:
	_anim_lock -= delta
	if _anim:
		if _anim_lock > 0.0:
			return
		var want := "Idle"
		if moving > 0.75:
			want = "Run"
		elif moving > 0.1:
			want = "Walk"
		if _anim.current_animation != want:
			_anim.play(want, 0.15)
		return
	_walk_phase += delta * 10.0 * moving
	var swing := sin(_walk_phase) * 0.6 * moving
	_legs[0].rotation.x = swing
	_legs[1].rotation.x = -swing
	_arms[0].rotation.x = -swing * 0.8
	if _anim_lock <= 0.0:
		_arms[1].rotation.x = lerpf(_arms[1].rotation.x, swing * 0.8, 10.0 * delta)


func is_guarding() -> bool:
	return t < guard_until


func is_dodging() -> bool:
	return _dodge_left > 0.0


func take_hit(damage: float) -> void:
	if is_dodging() and GameState.hp > 0.0 and t >= _perfect_until:
		# увернулся в последний момент — награда за риск
		_perfect_until = t + PERFECT_WINDOW
		perfect_dodge.emit()
	if is_dodging() or GameState.hp <= 0.0 or safe_zone != "":
		return
	if is_guarding():
		damage *= 0.3
	damage = maxf(1.0, damage - GameState.stat("armor"))
	GameState.damage(damage)
	Juice.shake(get_tree(), clampf(damage / 80.0, 0.06, 0.2))
	play_action("Hit", 0.3)
	if GameState.hp <= 0.0:
		died.emit()


## Урны, конусы и коробки отлетают от героя на ходу (0.10), а не стоят стеной.
func _push_props() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as RigidBody3D
		if body != null:
			var push := -c.get_normal() * Vector3(1, 0, 1)
			body.apply_central_impulse(push.normalized() * velocity.length() * 0.35 * body.mass + Vector3(0, 0.4, 0))


func basic_attack() -> void:
	if t < _attack_ready_at or not controls_enabled:
		return
	_attack_ready_at = t + ATTACK_COOLDOWN
	# удар разбрасывает мелочь перед героем, даже если врага рядом нет
	PhysProp.blast(get_tree(), global_position + facing * 1.2, 2.4, 5.5)
	var ranged := GameState.class_id == "CLASS_2" or GameState.class_id == "CLASS_3"
	var target := nearest_enemy(ATTACK_RANGE + (6.0 if ranged else 0.0))
	if target:
		face(target.global_position)
	play_action("Attack", 0.45)
	if target == null:
		if combo_count > 0:
			combo_count = 0
			combo.emit(0)
		return
	combo_count = combo_count + 1 if t < _combo_until else 1
	_combo_until = t + COMBO_WINDOW
	var step := (combo_count - 1) % 3
	var mult: float = COMBO_MULT[step]
	if t < _perfect_until:
		mult *= PERFECT_MULT
		_perfect_until = 0.0
	var dmg := attack_damage(ATTACK_DAMAGE) * mult
	if ranged:
		Kit.beam(get_parent(), global_position + Vector3(0, 1.3, 0), target.global_position + Vector3(0, 1, 0),
				Color(1, 0.85, 0.3) if GameState.class_id == "CLASS_2" else Color(0.3, 0.9, 1))
	if step == 2:
		# третий удар серии — размашистый: достаётся всем рядом с целью
		for e in enemies_in(SWEEP_RANGE, target.global_position):
			if e != target:
				e.take_hit(dmg * 0.6, global_position)
		Juice.shake(get_tree(), 0.1)
	target.take_hit(dmg, global_position)
	combo.emit(combo_count)


## Урон с учётом уровня, оружия и баффа «Бесплатная молодость».
func attack_damage(base: float) -> float:
	return AbilityBook.scaled(base + GameState.stat("damage"), GameState.level, t < buff_until)


func dodge() -> void:
	if _dodge_left > 0.0 or not controls_enabled:
		return
	dash(facing, DODGE_TIME)
	play_action("Dodge", 0.4)


## Толчок со стороны: ударная волна, взрыв. Уклон в момент толчка спасает и от него.
func knock(push: Vector3) -> void:
	if is_dodging() or safe_zone != "":
		return
	_knock = push * Vector3(1, 0, 1)


func dash(dir: Vector3, seconds: float) -> void:
	_dodge_dir = (dir * Vector3(1, 0, 1)).normalized()
	_dodge_left = seconds


func face(point: Vector3) -> void:
	var d := (point - global_position) * Vector3(1, 0, 1)
	if d.length() > 0.01:
		facing = d.normalized()


func unlock_level(index: int) -> int:
	return AbilityBook.unlock_level(index)


func ability_unlocked(index: int) -> bool:
	return GameState.level >= unlock_level(index)


func ability_remaining(index: int) -> float:
	if index >= book.abilities.size():
		return 0.0
	return book.remaining(book.abilities[index].id, t)


func use_ability(index: int) -> void:
	if index >= book.abilities.size() or not controls_enabled:
		return
	if not ability_unlocked(index):
		EventBus.toast.emit("«%s» откроется на %d уровне" % [book.abilities[index].name, unlock_level(index)])
		return
	var a: Dictionary = book.abilities[index]
	if not book.cast(a.id, t):
		return
	EventBus.ability_cast.emit(a.id, float(a.cooldown_s))
	AbilityFx.perform(self, a, book.spec(a))
	PhysProp.blast(get_tree(), global_position + facing * 1.5, 4.0, 8.0)


func enemies_in(radius: float, from := Vector3.INF) -> Array:
	var c := global_position if from == Vector3.INF else from
	return get_tree().get_nodes_in_group("enemies").filter(
		func(e): return e.is_alive() and e.global_position.distance_to(c) <= radius)


func nearest_enemy(radius: float, from := Vector3.INF) -> Node3D:
	var c := global_position if from == Vector3.INF else from
	var best: Node3D = null
	var best_d := radius
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_alive():
			continue
		var d: float = e.global_position.distance_to(c)
		if d > radius:
			continue
		# мусор и ящики — только если рядом нет живых врагов
		if "is_prop" in e:
			d += radius
		if d <= best_d or best == null:
			best_d = d
			best = e
	return best


func set_visible_body(v: bool) -> void:
	_rig.visible = v
