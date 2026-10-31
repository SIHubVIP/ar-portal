class_name EnemyDrone
extends CharacterBody3D
## «Сборщик обязательной благодарности» — патрульный дрон оккупации.
## Каждая атака сначала телеграфирует круг на земле, из него можно уйти.

signal defeated(drone: EnemyDrone)

@export var display_name := "Сборщик благодарности"
@export var max_hp := 40.0
@export var speed := 3.2
@export var aggro_radius := 9.0
@export var attack_radius := 1.8
@export var attack_damage := 10.0
@export var telegraph_time := 0.9
@export var loot_babki := 12
## Тип уличного моба манифеста (mob_01 … mob_10, MobTypes). Пусто — дрон патруля MAIN_001.
@export var mob_type := ""
var attack_kind := "melee"
var attack_range := 0.0
var xp := 20
var bark := ""
var _fly := true
var _base_y := 1.2
var _group := "drones"

var hp := 40.0
var home := Vector3.ZERO
var _stun_left := 0.0
var _attack_cd := 0.0
var _telegraph: MeshInstance3D
var _telegraph_left := 0.0
var _body: Node3D
var _model: NpcModel   # у мобов-людей (0.9): руки ходят в такт шагу
var _bar: HealthBar3D
var _t := 0.0
var _knock := Vector3.ZERO
var _bark_cd := 0.0
var _lunge_to := Vector3.INF
var _has_token := false
## Сколько уличных мобов сейчас замахиваются. Больше MAX_ATTACKERS одновременно не бьют.
static var _attackers := 0
const MAX_ATTACKERS := 2
static var _FLASH: StandardMaterial3D = _make_flash()


static func _make_flash() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1, 0.75)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _ready() -> void:
	add_to_group("enemies")
	var prof := MobTypes.profile(mob_type)
	if not prof.is_empty():
		display_name = prof.name
		max_hp = prof.hp
		speed = prof.speed
		attack_damage = prof.damage
		attack_kind = prof.kind
		attack_range = float(prof.get("range", 0.0))
		attack_radius = prof.radius
		telegraph_time = prof.telegraph
		aggro_radius = 16.0
		loot_babki = int(prof.babki)
		xp = int(prof.xp)
		bark = prof.bark
		_fly = prof.get("fly", false)
		_base_y = 1.2 if _fly else 0.85
		_group = "street_mobs"
	add_to_group(_group)
	hp = max_hp
	home = global_position
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.6
	shape.shape = s
	shape.position.y = 1.2
	add_child(shape)
	_body = Node3D.new()
	_body.position.y = _base_y
	add_child(_body)
	if prof.is_empty():
		Kit.sphere(_body, 0.5, Vector3.ZERO, Color(0.75, 0.78, 0.82))
		Kit.cylinder(_body, 0.85, 0.08, Vector3(0, 0, 0), Color(0.3, 0.3, 0.35))
		Kit.sphere(_body, 0.16, Vector3(0, 0.05, 0.42), Color(1, 0.15, 0.3), 3.0)
		Kit.box(_body, Vector3(0.6, 0.12, 0.02), Vector3(0, 0.3, 0.45), Color(0.1, 0.9, 0.5), 1.5)
	else:
		MobTypes.build_body(_body, mob_type)
		_model = _body.get_node_or_null("Model") as NpcModel
		# красный круг под ногами: враг читается ночью и в толпе прохожих
		var mark := Kit.cylinder(self, 0.75, 0.02, Vector3(0, 0.04, 0), Color(1, 0.15, 0.2, 0.5), 1.2)
		mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar = HealthBar3D.new()
	_bar.position = Vector3(0, 2.3, 0)
	add_child(_bar)


func is_alive() -> bool:
	return hp > 0.0


func stun(seconds: float) -> void:
	_stun_left = maxf(_stun_left, seconds)
	_cancel_telegraph()


func take_hit(damage: float, from: Vector3) -> void:
	if not is_alive():
		return
	hp -= damage
	AbilityFx.damage_number(get_parent(), global_position + Vector3(0, 2.0, 0), damage, damage >= 30.0)
	AbilityFx.sparks(get_parent(), global_position + Vector3(0, 1.2, 0), Color(0.6, 1, 0.9), 4)
	var push := (global_position - from) * Vector3(1, 0, 1)
	if push.length() > 0.01:
		_knock = push.normalized() * (7.0 if damage >= 30.0 else 4.5)
	_flash()
	_body.scale = Vector3(1.25, 0.8, 1.25)
	create_tween().tween_property(_body, "scale", Vector3.ONE, 0.15)
	_update_bar()
	if hp <= 0.0:
		Juice.shake(get_tree(), 0.08)
		_die()
	elif damage >= 30.0:
		Juice.shake(get_tree(), 0.08)


func _die() -> void:
	_cancel_telegraph()
	remove_from_group("enemies")
	remove_from_group(_group)
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_property(_body, "position:y", 0.2, 0.3)
	tw.parallel().tween_property(_body, "scale", Vector3(1.4, 0.2, 1.4), 0.3)
	tw.tween_callback(queue_free)


## Белая вспышка на долю секунды: попадание видно даже в толпе.
func _flash() -> void:
	for mi in _body.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = _FLASH
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if is_instance_valid(_body):
			for mi in _body.find_children("*", "MeshInstance3D", true, false):
				(mi as MeshInstance3D).material_overlay = null)


func _physics_process(delta: float) -> void:
	_t += delta
	if not is_alive():
		return
	if _fly:
		_body.position.y = _base_y + sin(_t * 3.0) * 0.08
		_body.rotation.y += delta * 0.5
	else:
		# походка вразвалку: чем быстрее идёт, тем сильнее качает
		var sway := clampf(velocity.length() / 3.0, 0.0, 1.5)
		_body.position.y = _base_y + absf(sin(_t * 9.0)) * 0.08 * sway
		_body.rotation.z = sin(_t * 9.0) * 0.08 * sway
		if _model != null:
			_model.walk = clampf(sway, 0.0, 1.0)
	_bark_cd -= delta
	if _knock.length() > 0.05:
		velocity = _knock
		_knock = _knock.lerp(Vector3.ZERO, clampf(10.0 * delta, 0.0, 1.0))
		move_and_slide()
		return
	if _stun_left > 0.0:
		_stun_left -= delta
		_body.rotation.z = sin(_t * 20.0) * 0.3
		return
	if _fly:
		_body.rotation.z = 0.0
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or GameState.hp <= 0.0:
		return
	if _telegraph_left > 0.0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			_resolve_attack(player)
		return
	_attack_cd -= delta
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var target := home
	if to_player.length() < aggro_radius and player.controls_enabled and player.safe_zone == "":
		target = player.global_position
		if bark != "" and _bark_cd <= 0.0:
			_bark_cd = randf_range(8.0, 14.0)
			_say(bark)
		var can_melee := to_player.length() <= attack_radius
		var can_range := attack_kind != "melee" and to_player.length() <= attack_range
		if (can_melee or can_range) and _attack_cd <= 0.0:
			if _take_token():
				_start_telegraph(Vector3.INF if can_melee else player.global_position)
				return
			# очередь занята: кружит вокруг героя и ждёт, а не бьёт всей толпой разом
			var around := Vector3(-to_player.z, 0, to_player.x).normalized() * (1.0 if get_instance_id() % 2 == 0 else -1.0)
			target = player.global_position - to_player.normalized() * (attack_radius + 1.8) + around * 2.0
		if attack_kind == "ranged" and to_player.length() < attack_range * 0.6:
			target = global_position - to_player       # дальник отходит, держит дистанцию
	var dir := target - global_position
	dir.y = 0.0
	var stop := (maxf(1.2, attack_radius * 0.7) if _group == "street_mobs" else attack_radius * 0.6) if target != home else 0.8
	# мобы расталкивают друг друга, чтобы не слипаться в одну кучу
	var sep := Vector3.ZERO
	for other in get_tree().get_nodes_in_group(_group):
		if other != self:
			var away: Vector3 = (global_position - other.global_position) * Vector3(1, 0, 1)
			if away.length() < 1.8 and away.length() > 0.01:
				sep += away.normalized() * (1.8 - away.length())
	if dir.length() > stop:
		velocity = dir.normalized() * speed + sep * 3.0
		look_at(global_position + dir, Vector3.UP)
		_body.rotation.y = 0.0
	else:
		velocity = sep * 3.0
	move_and_slide()


func _start_telegraph(at := Vector3.INF) -> void:
	_telegraph_left = telegraph_time
	var center := global_position if at == Vector3.INF else at
	center.y = global_position.y
	_lunge_to = center if attack_kind == "lunge" and at != Vector3.INF else Vector3.INF
	if attack_kind == "ranged" and at != Vector3.INF:
		_projectile(center)
	_telegraph = Kit.cylinder(get_parent(), attack_radius, 0.04, center + Vector3(0, 0.07, 0),
			Color(1, 0.15, 0.1, 0.45))
	_telegraph.material_override = Kit.mat(Color(1, 0.15, 0.1, 0.45), 1.5)
	_telegraph.scale = Vector3(0.2, 1, 0.2)
	_telegraph.create_tween().tween_property(_telegraph, "scale", Vector3.ONE, telegraph_time)


func _resolve_attack(player: Player) -> void:
	var center := _telegraph.global_position if _telegraph else global_position
	_cancel_telegraph()
	_attack_cd = float(MobTypes.profile(mob_type).get("cd", 1.6))
	if _lunge_to != Vector3.INF:
		var tw := create_tween()
		tw.tween_property(self, "global_position", _lunge_to, 0.12).set_ease(Tween.EASE_OUT)
		_lunge_to = Vector3.INF
	Kit.ring(get_parent(), center, attack_radius, Color(1, 0.3, 0.1), 0.2)
	if (player.global_position * Vector3(1, 0, 1)).distance_to(center * Vector3(1, 0, 1)) <= attack_radius:
		player.take_hit(attack_damage)


func _cancel_telegraph() -> void:
	_telegraph_left = 0.0
	if _has_token:
		_has_token = false
		_attackers -= 1
	if is_instance_valid(_telegraph):
		_telegraph.queue_free()
	_telegraph = null


func _update_bar() -> void:
	_bar.set_ratio(hp / max_hp)


## Снаряд дальника: летит дугой к центру круга ровно за время телеграфа.
func _projectile(to: Vector3) -> void:
	var col: Color = MobTypes.profile(mob_type).get("color", Color(1, 0.4, 0.6))
	var from := global_position + Vector3(0, _base_y + 0.3, 0)
	var p := Kit.sphere(get_parent(), 0.18, from, col, 3.0)
	var tw := p.create_tween()
	var t := telegraph_time
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(p):
			p.global_position = from.lerp(to + Vector3(0, 0.3, 0), k) + Vector3(0, sin(k * PI) * 2.5, 0), 0.0, 1.0, t)
	tw.tween_callback(p.queue_free)


## Реплика над головой на пару секунд.
func _say(text: String) -> void:
	var l := Kit.label(self, text, Vector3(0, 2.6, 0), 34, Color(1, 0.95, 0.8))
	l.no_depth_test = true
	var tw := l.create_tween()
	tw.tween_interval(2.2)
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)


func _take_token() -> bool:
	if _group != "street_mobs":
		return true
	if _attackers >= MAX_ATTACKERS:
		_attack_cd = randf_range(0.3, 0.7)
		return false
	_attackers += 1
	_has_token = true
	return true


func _exit_tree() -> void:
	if _has_token:
		_has_token = false
		_attackers -= 1
