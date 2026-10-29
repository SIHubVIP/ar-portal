extends Node3D
## Вертикальный срез: Погуляй, парковка «Похмельная» и улица до киоска.
## Здесь играется MAIN_001 «Проснись, тебя уже посчитали» по карточке и сцене SCENE_01.
## Геометрия — заглушки из Kit, ID объектов и этапов канонические.

const QID := "MAIN_001"
const SPAWN := Vector3(0, 0, 4)
const CHECKPOINT_POS := Vector3(0, 0, -28)
const EXIT_POS := Vector3(0, 0, -43)
const KIOSK_POS := Vector3(-13, 0, -55)
const GARAGE_POS := Vector3(6.5, 0, 13)
const UFO_POS := Vector3(-25, 55, -70)
## Арка в торцевом доме — выход со двора на север (ворота в PogulyayDressing._bounds).
const EXIT_ARCH := Vector3(0, 0, -67)

var player: Player
var camera: IsoCamera
var hud: Hud
var respawn_point := SPAWN

var _interactables: Array = []
var _zones: Array = []
var _pickups: Dictionary = {}
var _drones: Array = []
var _drone_respawn := -1.0
var _kiosk_wreck: Node3D
var _battery: Node3D
var _kiosk_owner: Node3D
var _lit_windows: Array = []
var _dark_windows: Array = []
var _save_pending := false
var _marker: Node3D
var _npc_marks: Array = []
var _objective_tick := 0.0
var _autotest := false
var chunks: DistrictChunks
var _pavel: Node3D


func _ready() -> void:
	_autotest = OS.get_cmdline_user_args().has("--autotest")
	_build_environment()
	_build_city()
	_build_parking()
	_build_queue()
	_build_checkpoint()
	_build_kiosk()
	_build_exit_to_delovoy()
	_build_locals()
	_build_windows()
	PogulyayDressing.build(self)
	ParkingReference.build(self)
	_build_pavel()

	if OS.get_cmdline_user_args().has("--gender=f"):
		GameState.gender = "f"
	player = Player.new()
	add_child(player)
	# герой всегда чуть подсвечен тёплым светом, как в Torchlight
	var hero_light := OmniLight3D.new()
	hero_light.position = Vector3(0, 2.6, 0)
	hero_light.light_color = Color(1, 0.85, 0.65)
	hero_light.light_energy = 1.1
	hero_light.omni_range = 6.5
	player.add_child(hero_light)
	player.died.connect(_on_player_died)
	camera = IsoCamera.new()
	camera.target = player
	add_child(camera)
	camera.make_current()
	hud = Hud.new()
	add_child(hud)
	hud.set_player(player)
	hud.pointer.camera = camera
	_build_marker()
	hud.controls.attack.connect(player.basic_attack)
	hud.controls.dodge.connect(player.dodge)
	hud.controls.ability.connect(player.use_ability)
	hud.controls.interact.connect(_on_interact)
	hud.pause_action.connect(_on_pause_action)
	hud.controls.camera_rotate.connect(camera.rotate_by)
	hud.controls.camera_zoom.connect(camera.zoom_by)
	hud.controls.camera_tilt.connect(camera.tilt_by)

	EventBus.quest_stage_changed.connect(func(_q, _s): _queue_save())
	EventBus.quest_state_changed.connect(func(_q, _s): _queue_save())

	chunks = DistrictChunks.new()
	chunks.name = "District"
	chunks.player = player
	add_child(chunks)
	_restore_progress()
	var args := OS.get_cmdline_user_args()
	if _autotest:
		_run_autotest.call_deferred()
	elif args.has("--no-intro"):
		QuestService.accept(QID)
	elif QuestService.state_of(QID) == QuestService.AVAILABLE:
		_intro.call_deferred()
	for arg in args:
		if arg.begins_with("--cam="):
			var dy := arg.trim_prefix("--cam=").split(",")
			camera.size = float(dy[0])
			camera.rotate_by(deg_to_rad(float(dy[1])))
			if dy.size() > 2:
				camera.tilt_by(deg_to_rad(float(dy[2])) - camera._pitch_target)
		if arg.begins_with("--open="):
			_dev_open.call_deferred(arg.trim_prefix("--open="))
		if arg.begins_with("--spawn="):
			var xz := arg.trim_prefix("--spawn=").split(",")
			player.position = Vector3(float(xz[0]), 0, float(xz[1]))
		if arg.begins_with("--plan="):      # точка по плану района в метрах: --plan=1490,1490
			var xy := arg.trim_prefix("--plan=").split(",")
			player.position = District.to_world(Vector2(float(xy[0]), float(xy[1])))
		if arg == "--free":                 # проверка этапа 1: выход со двора открыт сразу
			PogulyayDressing.open_exit(self, true)
	chunks.load_now()
	hud.setup_map.call_deferred(self, camera, player)


## Отладка и скриншоты: --open=bags|hero|abilities|quests|map|map:quarter|map:N07|dlg:GLORP, --gender=f
func _dev_open(what: String) -> void:
	if GameState.class_id == "":
		GameState.class_id = "CLASS_1"
	GameState.give_starter_kit()
	hud.dialog.skip()
	await get_tree().process_frame
	if what.begins_with("dlg:"):
		hud.run_dialogue(what.trim_prefix("dlg:"))
	elif what.begins_with("map"):           # map, map:quarter или map:ID точки реестра
		hud.open_map()
		if what == "map:quarter":
			hud.world_map._tab = "quarter"
			hud.world_map._render()
		elif what.begins_with("map:"):
			hud.world_map.show_point(District.point(what.trim_prefix("map:")))
	elif what == "quests":
		hud.open_quests()
	elif what.begins_with("item:"):
		hud.open_inventory("gear")
		hud.inventory.select(what.trim_prefix("item:"))
	else:
		hud.open_inventory(what)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_now()


# ---------- окружение ----------

func _build_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	# поздний вечер после вторжения (ориентир парковки): тёплые окна и фонари, холодное небо
	sm.sky_top_color = Color(0.04, 0.05, 0.1)
	sm.sky_horizon_color = Color(0.42, 0.2, 0.16)
	sm.ground_horizon_color = Color(0.25, 0.13, 0.1)
	sm.ground_bottom_color = Color(0.04, 0.03, 0.03)
	sm.sky_energy_multiplier = 0.8
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.46, 0.38, 0.36)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.13, 0.12)
	env.fog_density = 0.006
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-52, 35, 0)
	moon.light_color = Color(0.6, 0.66, 0.95)
	moon.light_energy = 0.35
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	# мокрая брусчатка отражает фонари и неон: одна статичная проба на весь двор
	var probe := ReflectionProbe.new()
	probe.position = Vector3(0, 6, -25)
	probe.size = Vector3(34, 14, 100)
	probe.box_projection = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.9
	add_child(probe)


func _build_city() -> void:
	# земля и улица
	Kit.solid_box(self, Vector3(160, 1, 170), Vector3(0, -0.5, -25), Color(0.28, 0.28, 0.3))
	Kit.box(self, Vector3(12, 0.02, 70), Vector3(0, 0.01, -30), Color(0.2, 0.2, 0.22))
	for z in range(-62, 4, 6):
		Kit.box(self, Vector3(0.25, 0.03, 3), Vector3(0, 0.02, z), Color(0.9, 0.9, 0.85))
	for side in [-1, 1]:
		Kit.box(self, Vector3(3, 0.25, 70), Vector3(7.5 * side, 0.12, -30), Color(0.45, 0.44, 0.42))
	# панельки: [центр, размер, цвет]
	var blocks := [
		[Vector3(-19, 0, 6), Vector3(12, 15, 18), Color(0.62, 0.6, 0.56)],
		[Vector3(-19, 0, -16), Vector3(12, 27, 20), Color(0.7, 0.66, 0.6)],
		[Vector3(-19, 0, -38), Vector3(12, 15, 16), Color(0.58, 0.6, 0.62)],
		# низкий кирпичный дом отступает за рынок у канала: камера с юго-востока видит канал
		# и лотки, а не крышу (композиция ориентира)
		[Vector3(21, 0, 2), Vector3(8, 6, 20), Color(0.66, 0.62, 0.58), true],
		[Vector3(19, 0, -22), Vector3(12, 15, 22), Color(0.6, 0.58, 0.6)],
		[Vector3(19, 0, -46), Vector3(12, 24, 18), Color(0.68, 0.64, 0.6)],
		[Vector3(-14.5, 0, -72), Vector3(19, 30, 10), Color(0.5, 0.5, 0.56)],
		[Vector3(14.5, 0, -72), Vector3(19, 30, 10), Color(0.5, 0.5, 0.56)],
	]
	for b in blocks:
		var size: Vector3 = b[1]
		var floors := roundi(size.y / 3.0)
		var model := "panel_%d" % floors
		if Props.exists(model) and b[0].z > -70.0:
			# панелька из Blender: подъезды смотрят на улицу, окна и балконы уже в модели
			var body := Props.collider(self, size, b[0] + Vector3(0, size.y / 2, 0), true)
			Props.place(body, model, Vector3(0, -size.y / 2, 0), 0.0 if b[0].x < 0 else 180.0,
					Vector3(size.x / 12.0, 1, size.z / 20.0))
		else:
			var body := Kit.solid_box(self, size, b[0] + Vector3(0, size.y / 2, 0), b[2], 0.0, true)
			_queue_windows(b[0], size)
			if b.size() > 3:
				Surfaces.brick_all(body)
	# арка в торцевом доме: выход со двора в остальной Погуляй (над проходом — этажи дома)
	Kit.solid_box(self, Vector3(10, 24, 10), Vector3(0, 18, -72), Color(0.5, 0.5, 0.56), 0.0, true)
	_queue_windows(Vector3(0, 6, -72), Vector3(10, 24, 10))
	# вывески и парадоксальная реклама (редакторские надписи вертикального среза)
	_sign("ПОГУЛЯЙ", Vector3(0, 24, -66.9), 260, Color(1, 0.3, 0.6), 0.0)
	_sign("ЛОМБАРД «ВЕЧНОСТЬ»", Vector3(-12.9, 5, 6), 90, Color(0.3, 1, 0.8), 90.0)
	_sign("ШАУРМА 24 · ДАЖЕ ПОСЛЕ КОНЦА СВЕТА", Vector3(12.9, 4, -22), 80, Color(1, 0.8, 0.2), -90.0)
	_sign("КЛУБ «ТРИДЦАТЬ ЛАЙКОВ»", Vector3(12.9, 6, -46), 90, Color(0.9, 0.3, 1), -90.0)
	_sign("КЛАНЯЙТЕСЬ ТАРЕЛКЕ — ЭТО БЕСПЛАТНО*", Vector3(-12.9, 12, -16), 80, Color(0.4, 0.9, 1), 90.0)
	_sign("*при наличии согласия", Vector3(-12.9, 10.8, -16), 40, Color(0.7, 0.85, 1), 90.0)
	# тарелка: огромная, видна в начальной сцене
	var ufo := Node3D.new()
	ufo.name = "UFO"
	ufo.position = UFO_POS
	add_child(ufo)
	Kit.cylinder(ufo, 34, 3, Vector3.ZERO, Color(0.35, 0.37, 0.42), 0.0, 22)
	Kit.cylinder(ufo, 22, 2.5, Vector3(0, -2.6, 0), Color(0.25, 0.27, 0.3), 0.0, 30)
	Kit.sphere(ufo, 10, Vector3(0, 3, 0), Color(0.5, 0.9, 1, 0.8), 0.6)
	for i in 16:
		var a := TAU * i / 16.0
		Kit.sphere(ufo, 1.0, Vector3(cos(a) * 30, -1, sin(a) * 30), Color(0.4, 1, 0.6), 4.0)
	ufo.create_tween().set_loops().tween_property(ufo, "rotation:y", TAU, 60.0).from(0.0)


func _sign(text: String, pos: Vector3, size: int, color: Color, yaw_deg: float) -> void:
	var l := Kit.label(self, text, pos, size, color.lightened(0.3), false)
	l.rotation_degrees.y = yaw_deg
	l.outline_size = 0


## Окна на гранях, обращённых к улице и к камере. Все окна города — два MultiMesh (горит / не горит).
func _queue_windows(center: Vector3, size: Vector3) -> void:
	var floors := int(size.y / 3.0)
	var faces := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)]
	for n: Vector3 in faces:
		var width := size.z if n.x != 0 else size.x
		var depth := (size.x if n.x != 0 else size.z) / 2.0 + 0.03
		var tangent := Vector3(0, 0, 1) if n.x != 0 else Vector3(1, 0, 0)
		var cols := int(width / 3.0)
		for fl in floors:
			for c in cols:
				var p := center + n * depth + tangent * ((c + 0.5) * width / cols - width / 2.0) \
						+ Vector3(0, 1.6 + fl * 3.0, 0)
				(_lit_windows if randf() < 0.22 else _dark_windows).append([p, n])


func _build_windows() -> void:
	for pair in [[_lit_windows, Color(1, 0.85, 0.5), 2.2], [_dark_windows, Color(0.2, 0.24, 0.32), 0.0]]:
		var wins: Array = pair[0]
		var quad := QuadMesh.new()
		quad.size = Vector2(1.3, 1.6)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = quad
		mm.instance_count = wins.size()
		for i in wins.size():
			var n: Vector3 = wins[i][1]
			# QuadMesh смотрит в +Z; поворачиваем лицом наружу по нормали грани
			var basis := Basis.looking_at(-n, Vector3.UP)
			mm.set_instance_transform(i, Transform3D(basis, wins[i][0]))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Kit.mat(pair[1], pair[2])
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)


func _person(pos: Vector3, color: Color, name_tag := "") -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	Kit.capsule(n, 0.3, 1.0, Vector3(0, 1.1, 0), color)
	Kit.sphere(n, 0.22, Vector3(0, 1.8, 0), Color(0.9, 0.74, 0.6))
	Kit.box(n, Vector3(0.36, 0.8, 0.22), Vector3(0, 0.4, 0), color.darkened(0.5))
	if name_tag != "":
		Kit.label(n, name_tag, Vector3(0, 2.4, 0), 36, Color(1, 0.95, 0.7))
		n.set_meta("map_label", name_tag)
	return n


# ---------- парковка и находки этапа 1 ----------

func _build_parking() -> void:
	Kit.label(self, "Парковка «Похмельная»", Vector3(-4, 0.05, 8), 70, Color(1, 1, 1, 0.5), false) \
			.rotation_degrees = Vector3(-90, 0, 0)
	for x in range(-10, 12, 4):
		Kit.box(self, Vector3(0.15, 0.03, 4), Vector3(x, 0.02, 0), Color(0.9, 0.9, 0.85))
	# чужой кабриолет
	var car := Node3D.new()
	car.name = "Convertible"
	car.position = Vector3(2, 0, 1)
	add_child(car)
	var body := StaticBody3D.new()
	car.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2, 1.2, 4.4)
	cs.shape = bs
	cs.position.y = 0.6
	body.add_child(cs)
	if Props.place(car, "convertible", Vector3.ZERO, 180.0) == null:
		Kit.box(car, Vector3(2, 0.7, 4.4), Vector3(0, 0.65, 0), Color(0.8, 0.1, 0.12))
	Kit.label(car, "ИМУЩЕСТВО ФЛОТА №0001", Vector3(0, 1.0, 2.21), 28, Color(0.4, 1, 0.6), false)
	# скамейка, урны, автомат
	Props.collider(self, Vector3(2.4, 0.5, 0.7), Vector3(6, 0.25, -3))
	Props.place(self, "bench", Vector3(6, 0, -3), 180.0)
	Kit.solid_box(self, Vector3(0.7, 1.0, 0.7), Vector3(-5, 0.5, 5), Color(0.25, 0.35, 0.3))
	Kit.solid_box(self, Vector3(1.2, 2.0, 0.8), Vector3(-3, 1.0, -7), Color(0.3, 0.3, 0.6), 0.2)
	_add_pickup("ITEM_P1_PHONE", Vector3(6.2, 0.6, -2.2))
	_add_pickup("ITEM_P1_SHOE", Vector3(-4.2, 0.3, 4.2))
	_add_pickup("ITEM_P1_DEBT_NOTICE", Vector3(-3, 0.4, -6.2))
	# гараж №13 — вход на личную базу
	for i in 6:
		var gx := -10.0 + i * 4.2
		var g := Props.collider(self, Vector3(4, 3, 4), Vector3(gx, 1.5, 16), true)
		if Props.place(g, "garage_13" if i == 4 else "garage", Vector3(0, -1.5, 0), 180.0) == null:
			Kit.box(g, Vector3(4, 3, 4), Vector3.ZERO, Color(0.42, 0.4, 0.38))
	Kit.label(self, "ГАРАЖ №13", GARAGE_POS + Vector3(0, 3.4, 0), 44, Color(1, 0.8, 0.3))
	_interactables.append({"pos": GARAGE_POS, "radius": 3.0, "label": "База", "cb": _enter_base,
			"enabled": func(): return true})


func _add_pickup(item_id: String, pos: Vector3) -> void:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	Kit.sphere(n, 0.25, Vector3.ZERO, Color(1, 0.85, 0.3), 3.0)
	Kit.label(n, GameData.item_name(item_id), Vector3(0, 0.8, 0), 32, Color(1, 0.9, 0.5))
	n.create_tween().set_loops().tween_property(n, "position:y", pos.y + 0.3, 0.6).from(pos.y) \
			.set_trans(Tween.TRANS_SINE)
	var beam := Kit.cylinder(n, 0.12, 3.0, Vector3(0, 1.5 - pos.y, 0), Color(1, 0.85, 0.3, 0.35), 2.0, 0.02)
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_pickups[item_id] = n
	_zones.append({"pos": pos, "radius": 1.6, "cb": func(): _collect(item_id),
			"when": func(): return QuestService.is_on_stage(QID, "MAIN_001_S01") and GameState.item_count(item_id) == 0})


func _collect(item_id: String) -> void:
	GameState.grant("pickup:%s" % item_id, "Находка MAIN_001", {"items": {item_id: 1}})
	if _pickups.has(item_id):
		_pickups[item_id].queue_free()
		_pickups.erase(item_id)
	if item_id == "ITEM_P1_SHOE":
		player.show_shoe()
	if item_id == "ITEM_P1_DEBT_NOTICE":
		hud.play_dialog([_scene_line(3)])
	var all := ["ITEM_P1_PHONE", "ITEM_P1_SHOE", "ITEM_P1_DEBT_NOTICE"].all(func(i): return GameState.item_count(i) > 0)
	if all:
		QuestService.advance(QID, "MAIN_001_S01")
		hud.show_toast("Всё нашлось. Теперь — мимо патруля благодарности.")


# ---------- очередь за бесплатной квартирой ----------

func _build_queue() -> void:
	Kit.solid_box(self, Vector3(0.3, 3, 3.5), Vector3(-11.5, 1.5, 10), Color(0.2, 0.3, 0.6), 0.3)
	_sign("ОЧЕРЕДЬ ЗА БЕСПЛАТНОЙ КВАРТИРОЙ", Vector3(-11.3, 2.6, 10), 34, Color(0.9, 0.95, 1), 90.0)
	var colors := [Color(0.4, 0.3, 0.5), Color(0.3, 0.45, 0.4), Color(0.55, 0.4, 0.25), Color(0.35, 0.35, 0.5),
			Color(0.5, 0.25, 0.3), Color(0.3, 0.3, 0.3), Color(0.45, 0.45, 0.2)]
	for i in colors.size():
		var p := _person(Vector3(-10 + i * 1.1, 0, 10), colors[i])
		p.rotation_degrees.y = -90
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "rotation_degrees:z", 3.0, 1.2 + i * 0.1)
		tw.tween_property(p, "rotation_degrees:z", -3.0, 1.2 + i * 0.1)
	var passer := _person(Vector3(-2, 0, 10), Color(0.6, 0.5, 0.35), "Прохожий")
	_npc_mark(passer, "PASSER")
	_interactables.append({"pos": passer.position, "radius": 2.5, "label": "Говорить", "cb": func():
		hud.run_dialogue("PASSER"), "enabled": func(): return true})


# ---------- патруль сборщиков обязательной благодарности (этап 2) ----------

func _build_checkpoint() -> void:
	var term := Node3D.new()
	term.name = "PatrolTerminal"
	term.position = CHECKPOINT_POS + Vector3(-4.5, 0, 0)
	add_child(term)
	Kit.cylinder(term, 0.2, 2.6, Vector3(0, 1.3, 0), Color(0.3, 0.3, 0.35))
	Kit.box(term, Vector3(1.4, 1.0, 0.1), Vector3(0, 2.6, 0.15), Color(0.1, 0.9, 0.5), 1.5)
	Kit.label(term, "ВЫРАЖЕНИЕ ЛИЦА:\nНЕДОСТАТОЧНО", Vector3(0, 2.6, 0.25), 22, Color(0.05, 0.2, 0.1), false)
	# пункт приёма благодарности: арка поперёк улицы, сканер ходит вверх-вниз
	for side in [-1, 1]:
		Props.collider(self, Vector3(0.6, 5, 0.6), CHECKPOINT_POS + Vector3(side * 6.5, 2.5, 0))
		Kit.box(self, Vector3(0.6, 5, 0.6), CHECKPOINT_POS + Vector3(side * 6.5, 2.5, 0), Color(0.3, 0.32, 0.38))
		Kit.box(self, Vector3(0.1, 4.2, 0.1), CHECKPOINT_POS + Vector3(side * 6.15, 2.4, 0), Color(0.3, 1, 0.6), 2.5)
	Kit.box(self, Vector3(13.6, 0.8, 0.6), CHECKPOINT_POS + Vector3(0, 5.2, 0), Color(0.25, 0.27, 0.32))
	var gate_sign := Kit.label(self, "ПУНКТ ПРИЁМА БЛАГОДАРНОСТИ", CHECKPOINT_POS + Vector3(0, 5.2, 0.32), 64,
			Color(0.4, 1, 0.7), false)
	gate_sign.outline_size = 0
	var scan := Kit.box(self, Vector3(12.4, 0.05, 0.05), CHECKPOINT_POS + Vector3(0, 0.3, 0), Color(0.4, 1, 0.6), 4.0)
	var scan_tw := scan.create_tween().set_loops()
	scan_tw.tween_property(scan, "position:y", 4.4, 1.4).set_trans(Tween.TRANS_SINE)
	scan_tw.tween_property(scan, "position:y", 0.3, 1.4).set_trans(Tween.TRANS_SINE)
	var gate_light := OmniLight3D.new()
	gate_light.position = CHECKPOINT_POS + Vector3(0, 4, 0)
	gate_light.light_color = Color(0.4, 1, 0.65)
	gate_light.omni_range = 9.0
	gate_light.light_energy = 2.0
	add_child(gate_light)
	_zones.append({"pos": CHECKPOINT_POS, "radius": 9.0, "once": true, "cb": _talk_terminal,
			"when": func(): return QuestService.is_on_stage(QID, "MAIN_001_S02")})
	_interactables.append({"pos": term.position, "radius": 3.5, "label": "Терминал", "cb": _talk_terminal,
			"enabled": func(): return QuestService.is_on_stage(QID, "MAIN_001_S02")})
	_zones.append({"pos": EXIT_POS, "radius": 4.5, "cb": _escaped_patrol,
			"when": func(): return QuestService.is_on_stage(QID, "MAIN_001_S02")})
	Kit.label(self, "ПЕРЕУЛОК →", EXIT_POS + Vector3(0, 0.1, 0), 90, Color(1, 1, 1, 0.6), false) \
			.rotation_degrees = Vector3(-90, 0, 0)


func _talk_terminal() -> void:
	hud.run_dialogue("TERMINAL", _on_terminal_event)


func _on_terminal_event(e: String) -> void:
	match e:
		"fight":
			hud.show_toast("Патруль: «Коррекция лица!»")
		"moon":
			for d in _drones:
				d.stun(4.0)
			hud.show_toast("Дроны в шоке. Бей, пока перезагружаются!")
		"bribe", "pass":
			for d in _drones:
				d.stun(30.0)
			_escaped_patrol()


func _spawn_drones() -> void:
	for offset in [Vector3(-3, 0, 2), Vector3(3, 0, -1), Vector3(0, 0, -5)]:
		var d := EnemyDrone.new()
		d.position = CHECKPOINT_POS + offset
		add_child(d)
		d.defeated.connect(_on_drone_defeated)
		_drones.append(d)


func _on_drone_defeated(d: EnemyDrone) -> void:
	_drones.erase(d)
	var key := "loot:drone:%d:%d" % [Time.get_ticks_usec(), randi()]
	GameState.grant(key, "Сборщик благодарности", {"xp": 20})
	LootDrop.drop(self, d.global_position + Vector3(0, 1, 0), key + ":babki", "", d.loot_babki)
	if randf() < 0.45:
		LootDrop.drop(self, d.global_position + Vector3(0, 1, 0), key + ":item", GameState.roll_loot("drone", randf()))
	if _drones.is_empty():
		_drone_respawn = 25.0
		if QuestService.is_on_stage(QID, "MAIN_001_S02"):
			_escaped_patrol()


func _escaped_patrol() -> void:
	if QuestService.advance(QID, "MAIN_001_S02") or QuestService.is_on_stage(QID, "MAIN_001_S03"):
		respawn_point = EXIT_POS
		hud.show_toast("Патруль отстал. Где-то впереди киоск с живым человеком.")


# ---------- киоск (этапы 3 и 4) ----------

func _build_kiosk() -> void:
	var k := Node3D.new()
	k.name = "Kiosk"
	k.position = KIOSK_POS
	add_child(k)
	Props.collider(k, Vector3(4, 3, 3), Vector3(0, 1.5, 0))
	if Props.place(k, "kiosk", Vector3.ZERO) == null:
		Kit.box(k, Vector3(4, 3, 3), Vector3(0, 1.5, 0), Color(0.85, 0.85, 0.8))
	_sign("КИОСК 24/7 · РАССРОЧКА НА ВСЁ", KIOSK_POS + Vector3(0, 3.3, 1.75), 40, Color(1, 1, 1), 0.0)
	_kiosk_owner = _person(KIOSK_POS + Vector3(0.6, 0, 0.6), Color(0.5, 0.35, 0.3), "Киоскёр")
	# разбитый дрон, привалившийся к двери, и батарея на месте аварии
	_kiosk_wreck = Node3D.new()
	_kiosk_wreck.position = KIOSK_POS + Vector3(2.4, 0, 1.4)
	add_child(_kiosk_wreck)
	Kit.sphere(_kiosk_wreck, 0.9, Vector3(0, 0.8, 0), Color(0.55, 0.57, 0.6))
	Kit.cylinder(_kiosk_wreck, 1.4, 0.12, Vector3(0, 0.6, 0), Color(0.3, 0.3, 0.35)).rotation_degrees.z = 35
	_battery = Node3D.new()
	_battery.position = KIOSK_POS + Vector3(5, 0, 3.5)
	add_child(_battery)
	Kit.box(_battery, Vector3(0.5, 0.8, 0.5), Vector3(0, 0.4, 0), Color(0.3, 1, 0.7), 3.0)
	Kit.label(_battery, "Инопланетная батарея", Vector3(0, 1.3, 0), 30, Color(0.6, 1, 0.8))
	_zones.append({"pos": KIOSK_POS, "radius": 6.0, "cb": _reach_kiosk,
			"when": func(): return QuestService.is_on_stage(QID, "MAIN_001_S03")})
	_interactables.append({"pos": KIOSK_POS + Vector3(0, 0, 2), "radius": 4.0, "label": "Решить",
			"cb": _talk_kiosk, "enabled": func(): return QuestService.is_on_stage(QID, "MAIN_001_S04")})


func _reach_kiosk() -> void:
	if QuestService.advance(QID, "MAIN_001_S03"):
		_talk_kiosk()


## Канонический выбор MAIN_001 A/B живёт внутри разговора с киоскёром (события choose_A / choose_B).
func _talk_kiosk() -> void:
	hud.run_dialogue("KIOSK", func(e: String):
		if e.begins_with("choose_"):
			_on_choice(e.trim_prefix("choose_")))


func _on_choice(key: String) -> void:
	if not QuestService.choose(QID, key):
		return
	var q := GameData.quest(QID)
	if key == "A":
		_kiosk_wreck.create_tween().tween_property(_kiosk_wreck, "position", _kiosk_wreck.position + Vector3(3, 0, 2), 0.6)
		GameState.grant("main001:choice_a:item", "Киоскёр благодарен", {"items": {"ITEM_P1_KIOSK_DISCOUNT": 1}})
	else:
		_battery.queue_free()
		GameState.grant("main001:choice_b:item", "Батарея с места аварии", {"items": {"ITEM_P1_ALIEN_BATTERY": 1}})
	QuestService.turn_in(QID)
	PogulyayDressing.open_exit(self)
	hud.play_dialog([{"speaker": "journal", "text": "%s." % q.choices[key].result},
			{"speaker": "journal", "text": "Поворот: %s" % q.twist}], func():
		var next := GameData.quest("MAIN_002")
		hud.show_toast("Новое задание: «%s» — %s" % [next.title, next.location]))


# ---------- местные и пришелец-стажёр (editorial_P2) ----------

func _build_locals() -> void:
	# Гл'орп: стажёр флота, прилетел «в столицу», а попал в Рубин
	var glorp := Node3D.new()
	glorp.position = Vector3(5.5, 0, 7)
	add_child(glorp)
	Kit.capsule(glorp, 0.28, 0.8, Vector3(0, 0.75, 0), Color(0.25, 0.25, 0.3))
	Kit.sphere(glorp, 0.32, Vector3(0, 1.45, 0), Color(0.56, 0.82, 0.48))
	for side in [-1, 1]:
		Kit.sphere(glorp, 0.1, Vector3(side * 0.12, 1.5, 0.27), Color(0.05, 0.05, 0.1))
		Kit.cylinder(glorp, 0.02, 0.4, Vector3(side * 0.12, 1.9, 0), Color(0.4, 0.7, 0.3))
		Kit.sphere(glorp, 0.06, Vector3(side * 0.12, 2.12, 0), Color(0.9, 1, 0.4), 3.0)
	Kit.box(glorp, Vector3(0.08, 0.35, 0.02), Vector3(0, 1.0, 0.28), Color(0.8, 0.1, 0.15))
	Kit.label(glorp, "Гл'орп", Vector3(0, 2.5, 0), 36, Color(0.7, 1, 0.6))
	_npc_mark(glorp, "GLORP")
	var shake := glorp.create_tween().set_loops()
	shake.tween_property(glorp, "rotation_degrees:z", 4.0, 0.15)
	shake.tween_property(glorp, "rotation_degrees:z", -4.0, 0.15)
	_interactables.append({"pos": glorp.position, "radius": 2.5, "label": "Говорить", "cb": func():
		hud.run_dialogue("GLORP"), "enabled": func(): return true})
	# тётя Зина: балкон второго этажа над ломбардом
	var balcony := Vector3(-12.6, 3.2, 1.5)
	Kit.solid_box(self, Vector3(1.4, 0.15, 3), balcony, Color(0.55, 0.52, 0.5))
	Kit.box(self, Vector3(0.08, 1.0, 3), balcony + Vector3(0.7, 0.55, 0), Color(0.4, 0.3, 0.3))
	var zina := _person(balcony + Vector3(0, 0.08, 0), Color(0.7, 0.2, 0.3), "Тётя Зина")
	zina.rotation_degrees.y = 90
	_npc_mark(zina, "ZINA")
	for i in 5:
		Kit.sphere(zina, 0.06, Vector3(-0.2 + i * 0.1, 2.0, 0), Color(0.95, 0.4, 0.6))
	_interactables.append({"pos": Vector3(-9.5, 0, 1.5), "radius": 3.0, "label": "Зина", "cb": func():
		hud.run_dialogue("ZINA"), "enabled": func(): return true})


# ---------- Павел Тарелкин у временного киоска «НЛО напрокат» ----------

## ТЗ п. 5: Павел в начальной сцене стоит у прокатного киоска, пока идёт MAIN_001; потом
## уходит в парк (N07). Одна копия: видимость решает переопределение из данных района.
func _build_pavel() -> void:
	_pavel = _person(ParkingReference.PAVEL_POS, Color(0.42, 0.3, 0.22), "Павел Тарелкин")
	_pavel.name = "Pavel"
	_pavel.rotation_degrees.y = 110.0
	Kit.box(_pavel, Vector3(0.38, 0.5, 0.05), Vector3(0, 1.25, 0.24), Color(0.92, 0.9, 0.85))   # футболка с пришельцем
	Kit.sphere(_pavel, 0.09, Vector3(0, 1.3, 0.27), Color(0.45, 0.85, 0.35))
	_npc_mark(_pavel, "PAVEL")
	_interactables.append({"pos": ParkingReference.PAVEL_POS, "radius": 2.6, "label": "Говорить",
			"cb": func(): hud.run_dialogue("PAVEL"), "enabled": func(): return _pavel.visible})
	EventBus.quest_state_changed.connect(func(_q, _s): _update_pavel())
	_update_pavel()


func _update_pavel() -> void:
	_pavel.visible = not District.override_for("N07").is_empty()
	if not _pavel.visible:
		_pavel.remove_from_group("map_npc")


# ---------- арка: выход со двора в остальной Погуляй ----------

func _build_exit_to_delovoy() -> void:
	# выход со двора — арка в торцевом доме на севере; ворота открываются после MAIN_001
	Kit.label(self, "АРКА · ВЫХОД В ПОГУЛЯЙ", EXIT_ARCH + Vector3(0, 6.6, 1.2), 54, Color(1, 0.85, 0.5), false).outline_size = 0
	_interactables.append({"pos": EXIT_ARCH + Vector3(0, 0, 3), "radius": 3.0, "label": "Ворота", "cb": func():
		hud.show_toast("Ворота откроются, когда разберёшься с киоском."),
		"enabled": func(): return QuestService.state_of(QID) != QuestService.COMPLETED})


# ---------- MAIN_001: вступление и восстановление ----------

func _scene_line(i: int) -> Dictionary:
	var lines: Array = GameData.scene_by_id["SCENE_01"].lines
	var l: Dictionary = lines[i]
	return {"speaker": String(l.speaker).capitalize() if l.speaker != "ГЕРОЙ" else "Герой", "text": l.text}


func _intro() -> void:
	QuestService.accept(QID)
	hud.run_dialogue("MAIN_001_INTRO", Callable(), func():
		hud.show_banner("Проснись, тебя уже посчитали", "Найди телефон, второй ботинок и уведомление о долге.\nИди за золотой стрелкой."))


func _restore_progress() -> void:
	var state := QuestService.state_of(QID)
	var stage: int = QuestService.records[QID].stage
	player.position = GameState.world_position if GameState.world_position != Vector3.ZERO else SPAWN
	if state == QuestService.ACTIVE and stage >= 1:
		respawn_point = CHECKPOINT_POS + Vector3(0, 0, 12)
	if state == QuestService.ACTIVE and stage >= 2:
		respawn_point = EXIT_POS
	for id in _pickups.keys():
		if GameState.item_count(id) > 0 or state == QuestService.COMPLETED or stage >= 1:
			_pickups[id].queue_free()
			_pickups.erase(id)
	if state == QuestService.COMPLETED:
		PogulyayDressing.open_exit(self, true)
		if QuestService.records[QID].choice == "A":
			_kiosk_wreck.position += Vector3(3, 0, 2)
		else:
			_battery.queue_free()
	_spawn_drones()


# ---------- куда идти ----------

func _build_marker() -> void:
	_marker = Node3D.new()
	add_child(_marker)
	var gem := Kit.box(_marker, Vector3(0.45, 0.45, 0.45), Vector3(0, 3.2, 0), Color(1, 0.8, 0.25), 3.0)
	gem.rotation_degrees = Vector3(45, 0, 45)
	gem.create_tween().set_loops().tween_property(gem, "rotation:y", TAU, 2.0).from(0.0)
	var bob := _marker.create_tween().set_loops()
	bob.tween_property(gem, "position:y", 3.5, 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(gem, "position:y", 3.2, 0.6).set_trans(Tween.TRANS_SINE)
	# кольцо на земле — тонкий обод, а не блин: цель видно, асфальт под ней тоже
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.15
	torus.outer_radius = 1.3
	ring.mesh = torus
	ring.position.y = 0.05
	ring.scale.y = 0.15
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(1, 0.8, 0.25)
	rm.emission_enabled = true
	rm.emission = Color(1, 0.75, 0.2)
	rm.emission_energy_multiplier = 1.5
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = rm
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_marker.add_child(ring)
	var pulse := ring.create_tween().set_loops()
	pulse.tween_property(ring, "scale", Vector3(1.25, 0.15, 1.25), 0.7)
	pulse.tween_property(ring, "scale", Vector3(0.85, 0.15, 0.85), 0.7)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 2.5, 0)
	l.light_color = Color(1, 0.8, 0.3)
	l.omni_range = 5.0
	l.light_energy = 1.5
	_marker.add_child(l)


func _npc_mark(npc: Node3D, dialogue_id: String) -> void:
	var m := Kit.label(npc, "!", Vector3(0, 3.0, 0), 110, Color(1, 0.82, 0.2))
	m.outline_size = 14
	var tw := m.create_tween().set_loops()
	tw.tween_property(m, "position:y", 3.25, 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(m, "position:y", 3.0, 0.5).set_trans(Tween.TRANS_SINE)
	_npc_marks.append([m, dialogue_id])
	npc.add_to_group("map_npc")


const _MAP_KIND := {"npc": "npc", "boss": "enemy", "mob": "enemy", "underground": "transport", "safe": "base"}


## Живые точки для мини-карты и карты квартала: [{pos, kind, label}]. Плюс точки реестра района
## в 120 м от героя — разметка этапа 1 (их персонажей и бои подключит этап 4).
func map_points() -> Array:
	var out: Array = []
	for n in get_tree().get_nodes_in_group("map_npc"):
		if n is Node3D and n.is_visible_in_tree():
			out.append({"pos": n.global_position, "kind": "npc", "label": String(n.get_meta("map_label", ""))})
	for d in _drones:
		if is_instance_valid(d):
			out.append({"pos": d.global_position, "kind": "enemy", "label": ""})
	out.append({"pos": EXIT_ARCH, "kind": "transport", "label": "Арка"})
	out.append({"pos": GARAGE_POS, "kind": "base", "label": "Гараж"})
	out.append({"pos": KIOSK_POS, "kind": "shop", "label": "Киоск"})
	var here := District.to_plan(player.global_position)
	for p in District.points():
		var at := District.pos(p)
		if _MAP_KIND.has(p.type) and at.distance_to(here) < 120.0 and not District.start_area().has_point(at) \
				and District.override_for(p.id).is_empty():
			out.append({"pos": District.to_world(at), "kind": _MAP_KIND[p.type], "label": String(p.name)})
	return out


## Текущая цель отслеживаемого задания: [позиция, подпись, прогресс]. INF — цели нет.
func objective() -> Array:
	var state := QuestService.state_of(QID)
	if state == QuestService.COMPLETED:
		return [EXIT_ARCH + Vector3(0, 0, -14), "Погуляй", "Двор пройден. Через арку — в остальной Погуляй"]
	if state != QuestService.ACTIVE and state != QuestService.TURN_IN_READY:
		return [Vector3.INF, "", ""]
	if QuestService.is_on_stage(QID, "MAIN_001_S01"):
		var found := ["ITEM_P1_PHONE", "ITEM_P1_SHOE", "ITEM_P1_DEBT_NOTICE"].filter(func(i): return GameState.item_count(i) > 0).size()
		var best := Vector3.INF
		var best_id := ""
		for id in _pickups:
			var p: Vector3 = _pickups[id].position * Vector3(1, 0, 1)
			if best == Vector3.INF or p.distance_to(player.global_position) < best.distance_to(player.global_position):
				best = p
				best_id = id
		return [best, GameData.item_name(best_id), "Найдено %d из 3" % found]
	if QuestService.is_on_stage(QID, "MAIN_001_S02"):
		if not GameState.has_flag("talked:TERMINAL"):
			return [CHECKPOINT_POS + Vector3(-4.5, 0, 0), "Пункт приёма", "Пройди пункт приёма благодарности"]
		return [EXIT_POS, "Переулок", "Беги в переулок или разбери дронов"]
	if QuestService.is_on_stage(QID, "MAIN_001_S03"):
		return [KIOSK_POS + Vector3(0, 0, 2), "Киоск", ""]
	return [KIOSK_POS + Vector3(0, 0, 2), "Киоскёр", "Поговори с киоскёром и реши"]


func _update_objective() -> void:
	var o := objective()
	hud.set_objective(o[0], o[1], o[2])
	_marker.visible = o[0] != Vector3.INF
	if _marker.visible:
		_marker.global_position = o[0]
	for pair in _npc_marks:
		pair[0].visible = not GameState.has_flag("talked:%s" % pair[1])


# ---------- кадр ----------

func _physics_process(delta: float) -> void:
	if hud == null or get_tree().paused:
		return
	GameState.playtime += delta
	_objective_tick -= delta
	if _objective_tick <= 0.0:
		_objective_tick = 0.2
		_update_objective()
	var pp := player.global_position
	for z in _zones:
		if z.get("done", false) or not z.when.call():
			continue
		if pp.distance_to(z.pos) <= z.radius:
			if z.get("once", false):
				z.done = true
			z.cb.call()
			break
	var label := ""
	var best := INF
	for it in _interactables:
		var d := pp.distance_to(it.pos)
		if d <= it.radius and d < best and it.enabled.call():
			best = d
			label = it.label
	hud.controls.interact_label = label
	if _drone_respawn > 0.0:
		_drone_respawn -= delta
		if _drone_respawn <= 0.0:
			_spawn_drones()


func _on_interact() -> void:
	var pp := player.global_position
	var best: Dictionary = {}
	var best_d := INF
	for it in _interactables:
		var d := pp.distance_to(it.pos)
		if d <= it.radius and d < best_d and it.enabled.call():
			best_d = d
			best = it
	if not best.is_empty():
		best.cb.call()


func _on_player_died() -> void:
	hud.show_death()


func _on_pause_action(action: String) -> void:
	match action:
		"save":
			hud.show_toast("Сохранено" if _save_now() else "Не удалось сохранить: %s" % SaveService.last_error)
		"base":
			hud.toggle_pause()
			_enter_base()
		"zoom_in":
			camera.zoom_by(-3.0)
		"zoom_out":
			camera.zoom_by(3.0)
		"title":
			_save_now()
			get_tree().paused = false
			WorldRouter.go_to_title()
		"respawn":
			GameState.heal(GameState.max_hp)
			player.global_position = respawn_point
			for d in _drones:
				d.global_position = d.home


func _enter_base() -> void:
	get_tree().paused = false
	WorldRouter.go_to_base(scene_file_path, player.global_position)


func _queue_save() -> void:
	if _save_pending:
		return
	_save_pending = true
	(func():
		_save_pending = false
		_save_now()).call_deferred()


func _save_now() -> bool:
	if player:
		GameState.world_scene = scene_file_path
		GameState.world_position = player.global_position
	return SaveService.save_game()


# ---------- автопрохождение для CI (--autotest) ----------

func _run_autotest() -> void:
	var log := func(msg: String): print("AUTOTEST ", msg)
	if QuestService.state_of(QID) == QuestService.COMPLETED:
		log.call("вернулись с базы; хранилище: %s" % str(GameState.storage))
		var ok := SaveService.load_game() and QuestService.state_of(QID) == QuestService.COMPLETED
		log.call("загрузка сохранения: %s" % ("ok" if ok else "FAIL"))
		print("AUTOTEST_DONE" if ok else "AUTOTEST_FAIL")
		get_tree().quit(0 if ok else 1)
		return
	if GameState.class_id == "":
		GameState.class_id = "CLASS_1"
	GameState.give_starter_kit()
	_intro()
	await _frames(5)
	log.call("вступление: портрет %s, ответов %d" % [hud.dialog._name.text, hud.dialog._options.get_child_count()])
	hud.dialog.skip()
	hud.dialog.pick_tone("cyan")
	await _frames(2)
	hud.dialog.skip()
	await _frames(2)
	log.call("стартовый набор: %s, урон +%d, броня +%d" % [str(GameState.equipment), GameState.stat("damage"), GameState.stat("armor")])
	for id in ["ITEM_P1_PHONE", "ITEM_P1_SHOE", "ITEM_P1_DEBT_NOTICE"]:
		player.global_position = _pickups[id].position * Vector3(1, 0, 1)
		await _frames(3)
		hud.dialog.skip()
	log.call("этап 1: %s" % QuestService.current_stage(QID).get("id", "-"))
	# Павел Тарелкин у «НЛО напрокат» — только пока идёт MAIN_001; карта района
	var pavel_seen := _pavel.visible
	hud.run_dialogue("PAVEL")
	hud.dialog.skip()
	await _frames(2)
	hud.open_map()
	await _frames(2)
	log.call("Павел у киоска: %s, поручение услышано: %s; мини-карта %s, карта открыта %s, участков %d" % [pavel_seen,
			GameState.has_flag("offered:NPC_07_1"), hud.minimap.visible, hud.world_map.visible, chunks.loaded.size()])
	hud.world_map.close_panel()
	# Гл'орп по-рубински
	hud.run_dialogue("GLORP")
	hud.dialog.pick_tone("purple")
	await _frames(2)
	hud.dialog.skip()
	await _frames(2)
	log.call("характер: %s, кукуха %d" % [GameState.character_title(), GameState.kukukha])
	# бой: подходим к патрулю, терминалу показываем задницу, бьём дронов
	player.global_position = CHECKPOINT_POS + Vector3(0, 0, 5)
	await _frames(3)
	log.call("терминал: %s" % hud.dialog._name.text)
	hud.dialog.pick_tone("purple")
	await _frames(2)
	hud.dialog.skip()
	await _frames(2)
	for i in 7:
		player.use_ability(i)
		player.basic_attack()
		await _frames(20)
	log.call("дронов осталось: %d, HP героя %.0f" % [_drones.size(), GameState.hp])
	player.global_position = EXIT_POS
	await _frames(3)
	log.call("этап 2 -> %s" % QuestService.current_stage(QID).get("id", "-"))
	player.global_position = KIOSK_POS + Vector3(0, 0, 4)
	await _frames(3)
	hud.dialog.skip()
	log.call("киоск: ответов %d" % hud.dialog._options.get_child_count())
	hud.dialog.pick_tone("orange")
	await _frames(2)
	hud.dialog.pick_tone("green")
	await _frames(2)
	hud.dialog.skip()
	await _frames(3)
	hud.dialog.skip()
	await _frames(2)
	# инвентарь: пиво и экран сумок
	var hp_before := GameState.hp
	GameState.damage(40)
	GameState.use_item("ITEM_P2_BEER")
	hud.open_inventory("bags")
	await _frames(2)
	log.call("инвентарь открыт: %s, HP %.0f -> %.0f" % [hud.inventory.visible, hp_before - 40, GameState.hp])
	hud.inventory.close_panel()
	log.call("MAIN_001: %s, выбор %s, флаги %s" % [QuestService.state_of(QID), QuestService.records[QID].choice,
			str(GameState.flags.keys())])
	log.call("ресурсы: бабки %d, репутация %d, уровень %d" % [GameState.babki, GameState.reputation, GameState.level])
	log.call("MAIN_002: %s" % QuestService.state_of("MAIN_002"))
	log.call("Павел после MAIN_001 ушёл в парк: %s" % (not _pavel.visible))
	if not pavel_seen or _pavel.visible or not GameState.has_flag("offered:NPC_07_1"):
		print("AUTOTEST_FAIL")
	if QuestService.state_of(QID) != QuestService.COMPLETED:
		print("AUTOTEST_FAIL")
		get_tree().quit(1)
		return
	GameState.add_item("ITEM_P1_SCRAP", 2)
	_enter_base()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
