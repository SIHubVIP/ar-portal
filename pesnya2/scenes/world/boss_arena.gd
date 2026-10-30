class_name BossArena
extends Node3D
## Арена ARENA_01 «Рекламная площадь» у точки B1 (0.16): плиточная площадь 110 × 90 м, сцена
## стримерши, экраны по углам и десять рекламных тумб-укрытий. Бой начинается, когда герой
## заходит на площадь; сбрасывается, если он ушёл далеко или отключился. Победа — разовая
## награда (ключ boss:BOSS_01) и трофей на базе.

signal won(boss_id: String)

const POINT_ID := "B1"
const BOSS_ID := "BOSS_01"
const BUILD_M := 240.0
const LEAVE_M := 14.0
const REWARD := {"xp": 400, "babki": 250, "reputation": 5, "items": {"ITEM_P3_MUTE_CORE": 1}}
## Тумбы: два кольца вокруг сцены, со сдвигом — укрытие есть с любой стороны
const COLUMNS := [[-14, -10], [0, -16], [14, -10], [-20, 4], [20, 4], [-9, 13], [9, 13],
		[-30, -20], [30, -20], [0, 26]]

var player: Player
var hud: Hud
var center := Vector3.ZERO
var size := Vector2(110, 90)
var boss: Boss
var columns: Array[AdColumn] = []
var built := false


func _ready() -> void:
	name = "BossArena"
	set_meta("map_skip", true)
	var p := District.point(POINT_ID)
	center = District.to_world(District.pos(p))
	var a: Array = p.get("arena_size_m", [110, 90])
	size = Vector2(float(a[0]), float(a[1]))


static func key() -> String:
	return "boss:%s" % BOSS_ID


func is_won() -> bool:
	return GameState.granted.has(key())


func rect() -> Rect2:
	return Rect2(Vector2(center.x, center.z) - size * 0.5, size)


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var pp := Vector2(player.global_position.x, player.global_position.z)
	if not built:
		if pp.distance_to(Vector2(center.x, center.z)) < BUILD_M:
			build()
		return
	if boss == null or is_won():
		return
	if not boss.active:
		if rect().has_point(pp) and GameState.hp > 0.0 and player.safe_zone == "":
			start_fight()
	else:
		if not rect().grow(LEAVE_M).has_point(pp) or GameState.hp <= 0.0:
			reset_fight()
		elif hud != null:
			hud.set_boss(boss.hp / boss.max_hp, "Фаза %d · %s%s" % [boss.phase, boss.phase_info().get("attack", ""),
					" · ОКНО АТАКИ" if boss.in_window() else ""])


func build() -> void:
	if built:
		return
	built = true
	var root := Node3D.new()
	root.name = "ArenaSet"
	root.position = center
	add_child(root)
	_floor(root)
	_stage(root)
	_screens(root)
	_fence(root)
	for i in COLUMNS.size():
		var c := AdColumn.new()
		c.seed_ = i
		c.position = center + Vector3(COLUMNS[i][0], 0, COLUMNS[i][1])
		add_child(c)
		columns.append(c)
	boss = Boss.new()
	boss.boss_id = BOSS_ID
	boss.position = center + Vector3(0, 0.6, -2)
	boss.player = player
	boss.arena = rect()
	add_child(boss)
	boss.defeated.connect(_on_defeated)
	if is_won():
		boss.hp = 0.0
		boss.remove_from_group("enemies")
		boss.visible = false
		_leftovers(root)


func start_fight() -> void:
	for c in columns:
		c.restore()
	boss.active = true
	boss.taunt()
	if hud != null:
		hud.show_boss(boss.display_name())
		hud.show_banner(boss.display_name(), "«%s»" % boss.data.get("taunt", ""))
		if GameState.level < int(District.point(POINT_ID).get("legacy_level", 8)):
			hud.show_toast("Босс %d уровня. Прячься за тумбами от полос и веера, из кругов — уходи" %
					int(District.point(POINT_ID).get("legacy_level", 8)))


func reset_fight() -> void:
	boss.reset()
	for c in columns:
		c.restore()
	if hud != null:
		hud.hide_boss()
		hud.show_toast("Люся ждёт реванша. Стрим продолжается")


func _on_defeated(_b: Boss) -> void:
	GameState.grant(key(), "Босс «%s»" % boss.display_name(), REWARD)
	if hud != null:
		hud.set_boss(0.0, "Повержена")
		hud.show_banner("Босс повержен", "«%s». Трофей ждёт на базе" % boss.display_name())
		get_tree().create_timer(2.5).timeout.connect(hud.hide_boss)
	won.emit(BOSS_ID)


# ---------- декорации ----------

func _floor(root: Node3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = size
	var floor := MeshInstance3D.new()
	floor.mesh = pm
	floor.position.y = 0.05
	floor.material_override = Surfaces.slabs(Color(0.78, 0.74, 0.8))
	floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(floor)
	# бордюр по краю и разметка «зон контента» на плитке
	for side in [-1, 1]:
		Kit.box(root, Vector3(size.x, 0.18, 0.4), Vector3(0, 0.09, side * size.y * 0.5), Color(0.55, 0.54, 0.52))
		Kit.box(root, Vector3(0.4, 0.18, size.y), Vector3(side * size.x * 0.5, 0.09, 0), Color(0.55, 0.54, 0.52))
	for r in [18.0, 32.0]:
		var ring := MeshInstance3D.new()
		var tor := TorusMesh.new()
		tor.inner_radius = r - 0.2
		tor.outer_radius = r
		tor.rings = 64
		tor.ring_segments = 4
		ring.mesh = tor
		ring.scale.y = 0.05
		ring.position.y = 0.07
		ring.material_override = Kit.mat(Color(0.95, 0.35, 0.6, 0.6), 0.6)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(ring)


## Сцена Люси: помост, ступени, штативы со светом и стопка «запрещённых» микрофонов.
func _stage(root: Node3D) -> void:
	var st := Kit.solid_box(root, Vector3(9, 0.6, 6), Vector3(0, 0.3, -2), Color(0.16, 0.13, 0.18))
	Kit.box(st, Vector3(9.1, 0.06, 6.1), Vector3(0, 0.31, 0), Color(0.95, 0.3, 0.6), 1.2)
	for k in 3:
		Kit.box(root, Vector3(3, 0.2, 0.6), Vector3(0, 0.1 + k * 0.2, 1.3 - k * 0.35), Color(0.3, 0.28, 0.3))
	for side in [-1, 1]:
		var tri := Node3D.new()
		tri.position = Vector3(side * 5.5, 0, -4.5)
		root.add_child(tri)
		for k in 3:
			var leg := Kit.cylinder(tri, 0.04, 3.2, Vector3.ZERO, Color(0.1, 0.1, 0.12))
			leg.rotation = Vector3(0.25, TAU * k / 3.0, 0)
			leg.position = Vector3(sin(TAU * k / 3.0) * 0.4, 1.5, cos(TAU * k / 3.0) * 0.4)
		Kit.box(tri, Vector3(0.8, 0.6, 0.3), Vector3(0, 3.2, 0), Color(0.12, 0.12, 0.14))
		Kit.box(tri, Vector3(0.7, 0.5, 0.05), Vector3(0, 3.2, 0.16), Color(1, 0.95, 0.85), 3.0)
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, 3.3, 0.3)
		spot.light_color = Color(1, 0.6, 0.85)
		spot.light_energy = 3.0
		spot.spot_range = 18.0
		spot.spot_angle = 35.0
		tri.add_child(spot)
		spot.look_at(center + Vector3(0, 0.5, 0), Vector3.UP)
	Signboard.make(root, "СТРИМ ЛЮСИ · 24/7", "neon", Color(1, 0.4, 0.75), Vector3(0, 4.0, -5.2), 0.0, 0.8)
	Kit.box(root, Vector3(9, 4.2, 0.3), Vector3(0, 2.7, -5.4), Color(0.08, 0.07, 0.1))


## Экраны по углам: реклама, счётчик лайков и бегущая строка указов.
func _screens(root: Node3D) -> void:
	var texts := ["ЛАЙК = НАЛОГ", "ДИЗЛАЙКИ ОТКЛЮЧЕНЫ", "ПОДПИШИСЬ ИЛИ ПЛАТИ", "ЛАЙКОВ: 0"]
	var cols := [Color(0.3, 0.75, 1), Color(1, 0.35, 0.45), Color(0.98, 0.8, 0.25), Color(0.55, 1, 0.5)]
	var i := 0
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var at := Vector3(sx * (size.x * 0.5 - 6), 0, sz * (size.y * 0.5 - 6))
			var yaw := rad_to_deg(atan2(-at.x, -at.z))
			for k in 2:
				var off := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw))) * (k * 2 - 1) * 2.6
				Kit.solid_box(root, Vector3(0.4, 6.5, 0.4), at + off + Vector3(0, 3.25, 0), Color(0.2, 0.2, 0.22))
			var screen := Node3D.new()
			screen.position = at + Vector3(0, 7.5, 0)
			screen.rotation_degrees.y = yaw
			root.add_child(screen)
			Kit.box(screen, Vector3(7.4, 3.6, 0.4), Vector3.ZERO, Color(0.06, 0.06, 0.08))
			Kit.box(screen, Vector3(7.0, 3.2, 0.05), Vector3(0, 0, 0.21), cols[i] * 0.35, 1.0)
			var l := Kit.label(screen, texts[i], Vector3(0, 0, 0.26), 110, cols[i], false)
			l.outline_size = 4
			i += 1


## Ограждение-барьеры по краю с проходами посередине сторон.
func _fence(root: Node3D) -> void:
	var b := DistrictDressing.Batch.new()
	for side in [-1, 1]:
		for x in range(-int(size.x * 0.5) + 2, int(size.x * 0.5) - 1, 3):
			if absi(x) > 6:
				b.box("picket", Vector3(x, 0.55, side * (size.y * 0.5 + 0.8)), Vector3(2.6, 1.1, 0.08), 0.0,
						Color(0.85, 0.85, 0.82))
		for z in range(-int(size.y * 0.5) + 2, int(size.y * 0.5) - 1, 3):
			if absi(z) > 6:
				b.box("picket", Vector3(side * (size.x * 0.5 + 0.8), 0.55, z), Vector3(0.08, 1.1, 2.6), 0.0,
						Color(0.85, 0.85, 0.82))
	# без flush: тот регистрирует фонари участка, а у арены своего участка нет
	for kind: String in b.items:
		DistrictDressing._multimesh(root, DistrictDressing._mesh(kind), DistrictDressing._material(kind), b.items[kind], Transform3D())


## После победы: погасшая лампа и брошенный микрофон на помосте.
func _leftovers(root: Node3D) -> void:
	var tor := TorusMesh.new()
	tor.inner_radius = 0.55
	tor.outer_radius = 0.68
	var ring := MeshInstance3D.new()
	ring.mesh = tor
	ring.material_override = Kit.mat(Color(0.3, 0.3, 0.32))
	ring.position = Vector3(1.5, 0.75, -2)
	root.add_child(ring)
	Kit.cylinder(root, 0.07, 0.9, Vector3(-1, 0.7, -1.5), Color(0.12, 0.12, 0.14)).rotation.z = PI / 2
