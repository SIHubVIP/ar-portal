extends Node3D
## Вертикальный срез: Погуляй, двор «Похмельная» по макету «Рубин» (StartYard) и район.
## Здесь играется MAIN_001 «Проснись, тебя уже посчитали» по карточке и сцене SCENE_01:
## пробуждение у кабриолета → телефон, ботинок, долг → пункт приёма благодарности →
## киоск «НЛО напрокат» → разговор и выбор → выход через арку или восточный проход.

const QID := "MAIN_001"
const CONVERTIBLE_POS := Vector3(-53, 0, -2)
const SPAWN := Vector3(-49, 0, 3)
const CHECKPOINT_POS := Vector3(38, 0, 2)
const EXIT_POS := Vector3(38, 0, -8)
const KIOSK_POS := StartYard.KIOSK
const GARAGE_POS := StartYard.GARAGE_13
const UFO_POS := Vector3(70, 62, -230)
## Арка в северном корпусе — выход со двора (ворота в StartYard._bounds).
const EXIT_ARCH := StartYard.EXIT_ARCH
## Такси «Межрайон» (0.14, три района с 0.15): у будки во дворе, у площади «Последний талон»
## в Деловом и у ворот «Базара под куполом» в «До свидания».
const TAXI_YARD := StartYard.BOOTH + Vector3(10, 0, 7)
const TAXI_DL_PLAN := Vector2(4600, 1598)
const TAXI_DS_PLAN := Vector2(4560, -1399)

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
var _save_pending := false
var _marker: Node3D
var _npc_marks: Array = []
var _objective_tick := 0.0
var _autotest := false
var chunks: DistrictChunks
var mobs: DistrictMobs
var street_life: StreetLife
var _pavel: Node3D
var _safe_tick := 0.0
var physics_props: PhysicsProps
var _cine_hidden: Array = []
var _cine_turned: Array = []

const SAFE_HEAL_PER_S := 6.0


func _ready() -> void:
	_autotest = OS.get_cmdline_user_args().has("--autotest")
	_build_environment()
	StartYard.build(self)
	_build_ufo()
	_build_parking()
	_build_queue()
	_build_checkpoint()
	_build_kiosk()
	_build_exit_to_delovoy()
	_build_taxi()
	_build_locals()
	_trim_shadows(self)
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

	hud.dialog.closed.connect(func() -> void:
		# реплики могут идти цепочкой: камера возвращается, только если разговор правда кончился
		await get_tree().process_frame
		if not hud.dialog.is_open():
			camera.end_cinematic()
			for h in _cine_hidden:
				if is_instance_valid(h):
					h.visible = true
			_cine_hidden.clear()
			if not _cine_turned.is_empty() and is_instance_valid(_cine_turned[0]):
				_cine_turned[0].rotation.y = _cine_turned[1]
			_cine_turned = []
			for m: NpcModel in get_tree().get_nodes_in_group("npc_talking"):
				m.set_talking(false))
	chunks = DistrictChunks.new()
	chunks.name = "District"
	chunks.player = player
	add_child(chunks)
	var lamp_lights := LampLights.new()
	lamp_lights.player = player
	add_child(lamp_lights)
	physics_props = PhysicsProps.new()
	physics_props.player = player
	# двор: конусы у шлагбаума и места посадки, урны у парковки, коробки у киоска, шины у гаражей
	physics_props.extra = [[Vector3(16.5, 0, 12.8), "cone"], [Vector3(17.3, 0, 13.4), "cone"], [Vector3(18.1, 0, 12.8), "cone"],
			[Vector3(-46, 0, 8), "bin"], [Vector3(-60, 0, -8), "bin"], [Vector3(10, 0, -55), "bin"],
			[Vector3(-14, 0, -64), "cone"], [Vector3(-6, 0, -64), "cone"], [Vector3(38.5, 0, -15.5), "box"],
			[Vector3(39.4, 0, -15.0), "box"], [Vector3(88, 0, -40), "tire"], [Vector3(88, 0, -70), "tire"]]
	add_child(physics_props)
	var pigeons := Pigeons.new()
	pigeons.player = player
	add_child(pigeons)
	var leaves := Leaves.new()
	leaves.target = player
	add_child(leaves)
	# дворовые коты: рыжий у будки и серый у гаражей
	for c: Array in [[Rect2(8, 16, 30, 22), Color(0.9, 0.5, 0.18)], [Rect2(62, -125, 22, 60), Color(0.45, 0.45, 0.48)]]:
		var cat := YardCat.new()
		cat.area = c[0]
		cat.fur = c[1]
		cat.player = player
		cat.position = Vector3(c[0].get_center().x, 0, c[0].get_center().y)
		add_child(cat)
	mobs = DistrictMobs.new()
	mobs.player = player
	add_child(mobs)
	street_life = StreetLife.new()
	street_life.player = player
	add_child(street_life)
	_restore_progress()
	var warm: Array = [EnemyDrone._FLASH, Kit.mat(Color(1, 0.15, 0.1, 0.45), 1.5), Kit.mat(Color(1, 0.15, 0.2, 0.5), 1.2),
			Kit.mat(Color(1, 0.3, 0.1, 0.55), 2.0), IsoCamera.cut_material(Kit.mat(Color(0.5, 0.5, 0.55)))]
	for k in 4:
		warm.append(chunks._mat("house_%d" % k))
		warm.append(IsoCamera.cut_material(chunks._mat("house_%d" % k)))
	ShaderWarmup.run(self, player.global_position, warm)
	DistrictDressing.warm()
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
		if arg.begins_with("--talk="):     # скриншот кинокамеры: --talk=Зина подходит и заговаривает
			var who := arg.trim_prefix("--talk=")
			get_tree().create_timer(1.0).timeout.connect(func() -> void:
				for it in _interactables:
					if it.has("face") and (it.face.name == who or it.label == who):
						player.global_position = it.pos
						if (it.face.global_position * Vector3(1, 0, 1)).distance_to(it.pos) < 1.0:
							player.global_position = it.pos + Vector3(1.2, 0, 1.4)   # шаг в сторону, как подходит игрок
						_on_interact()
						if OS.get_cmdline_user_args().has("--nodlg"):
							hud.dialog.modulate.a = 0.0
						break)
		if arg == "--fight":                # скриншот боя: через секунду герой встаёт рядом с появившейся группой
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				var m := mobs.get_children().filter(func(n: Node) -> bool: return n is EnemyDrone)
				if not m.is_empty():
					player.global_position = (m[0] as Node3D).global_position + Vector3(4, 0, 4))
		if arg == "--free":                 # проверка этапа 1: выход со двора открыт сразу
			StartYard.open_exit(self, true)
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


## Тень от луны дают только дома и персонажи (0.10): каждый предмет с тенью рисуется ещё
## раз в карту теней, и двор с вывесками и мелочью вдвое увеличивал число вызовов отрисовки.
static func _trim_shadows(root: Node) -> void:
	for gi in root.find_children("*", "GeometryInstance3D", true, false):
		var g := gi as GeometryInstance3D
		if g is Label3D:
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif not _is_building(g):
			g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Дом двора: тело-«окклюдер» или его модель. Тень от дома держит объём двора.
static func _is_building(n: Node) -> bool:
	var p := n.get_parent()
	while p != null:
		if p.is_in_group("occluders"):
			return true
		p = p.get_parent()
	return false


# ---------- окружение ----------

func _build_environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	# 0.11: тёплый осенний вечер концептов «Рубин» — низкое солнце, золотой свет, окна горят
	sm.sky_top_color = Color(0.3, 0.38, 0.62)
	sm.sky_horizon_color = Color(0.98, 0.68, 0.42)
	sm.ground_horizon_color = Color(0.62, 0.42, 0.3)
	sm.ground_bottom_color = Color(0.2, 0.15, 0.12)
	sm.sun_angle_max = 20.0
	sm.sky_energy_multiplier = 1.0
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.56, 0.7)      # голубоватые тени против золотого солнца
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.9
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	# дымка только вдали (по глубине от 120 м): двор у героя чистый, дальние кварталы — в золоте
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 120.0
	env.fog_depth_end = 700.0
	env.fog_density = 0.6
	env.fog_light_color = Color(0.85, 0.66, 0.5)
	env.fog_sun_scatter = 0.1
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.14
	env.adjustment_contrast = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# закатное солнце с запада-юго-запада: длинные тёплые тени, фасады в золоте
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-36, -118, 0)
	sun.light_color = Color(1.0, 0.86, 0.7)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	# камера на плече 60 м видит пятно ~40 м: одного каскада до 110 м хватает (на телефоне каскады — 4 прохода)
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 110.0
	sun.shadow_opacity = 0.8
	add_child(sun)


## Тарелка флота над районом: огромная, видна из двора в начальной сцене.
func _build_ufo() -> void:
	var ufo := Node3D.new()
	ufo.name = "UFO"
	ufo.position = UFO_POS
	add_child(ufo)
	Kit.cylinder(ufo, 34, 3, Vector3.ZERO, Color(0.55, 0.57, 0.62), 0.0, 22)
	Kit.cylinder(ufo, 22, 2.5, Vector3(0, -2.6, 0), Color(0.38, 0.4, 0.45), 0.0, 30)
	Kit.sphere(ufo, 10, Vector3(0, 3, 0), Color(0.5, 0.9, 1, 0.8), 0.6)
	for i in 16:
		var a := TAU * i / 16.0
		Kit.sphere(ufo, 1.0, Vector3(cos(a) * 30, -1, sin(a) * 30), Color(0.4, 1, 0.6), 4.0)
	ufo.create_tween().set_loops().tween_property(ufo, "rotation:y", TAU, 60.0).from(0.0)
	# тарелка висит над двором, но тени не бросает: иначе полдвора в полосе тени
	for g: GeometryInstance3D in ufo.find_children("*", "GeometryInstance3D", true, false):
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Вывеска на стене (0.10): стиль — Signboard (короб, неон, щит, плакат…). size — прежний
## размер шрифта надписи, из него берётся высота строки.
func _sign(text: String, pos: Vector3, size: int, color: Color, yaw_deg: float, kind := "neon",
		opts := {}) -> Signboard:
	return Signboard.make(self, text, kind, color, pos, yaw_deg, size * 0.0105, opts)


func _person(pos: Vector3, color: Color, name_tag := "", look := {}) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	add_child(n)
	# облик детерминирован местом: одна и та же очередь при каждом запуске
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3i(pos * 10.0))
	var l := NpcModel.random_look(rng, color)
	l.merge(look, true)
	var m := NpcModel.make(l)
	m.name = "Model"
	n.add_child(m)
	n.set_meta("head_y", 1.73 * float(l.height))
	if name_tag != "":
		Kit.label(n, name_tag, Vector3(0, 2.4, 0), 36, Color(1, 0.95, 0.7))
		n.set_meta("map_label", name_tag)
	return n


# ---------- парковка и находки этапа 1 ----------

func _build_parking() -> void:
	# чужой кабриолет флота: брошен поперёк парковки (место — из макета, PG_C1_convertible)
	var car := Node3D.new()
	car.name = "Convertible"
	car.position = CONVERTIBLE_POS
	car.rotation_degrees.y = 100.0
	add_child(car)
	var body := StaticBody3D.new()
	car.add_child(body)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2, 1.2, 4.4)
	cs.shape = bs
	cs.position.y = 0.6
	body.add_child(cs)
	var model := Props.place(car, "convertible", Vector3.ZERO, 180.0)
	if model == null:
		Kit.box(car, Vector3(2, 0.7, 4.4), Vector3(0, 0.65, 0), Color(0.15, 0.55, 0.55))
	else:
		_repaint(model, Color(0.12, 0.52, 0.55))     # по концепту кабриолет бирюзовый
	Kit.label(car, "ИМУЩЕСТВО ФЛОТА №0001", Vector3(0, 1.0, 2.21), 28, Color(0.4, 1, 0.6), false)
	# скамейка у машины, автомат с газировкой
	Props.collider(self, Vector3(2.4, 0.5, 0.7), CONVERTIBLE_POS + Vector3(8, 0.25, 6))
	Props.place(self, "bench", CONVERTIBLE_POS + Vector3(8, 0, 6), 180.0)
	Kit.solid_box(self, Vector3(1.2, 2.0, 0.8), CONVERTIBLE_POS + Vector3(-12, 1.0, -8), Color(0.3, 0.3, 0.6), 0.2)
	_add_pickup("ITEM_P1_PHONE", Vector3(-54, 0.6, -4.6))
	_add_pickup("ITEM_P1_SHOE", Vector3(-42, 0.3, 6.5))
	_add_pickup("ITEM_P1_DEBT_NOTICE", Vector3(-31, 0.4, -12))
	# гараж №13 — вход на личную базу
	_interactables.append({"pos": GARAGE_POS, "radius": 3.0, "label": "База", "cb": _enter_base,
			"enabled": func(): return true})


## Перекрасить красные детали модели (кузов) в другой цвет.
static func _repaint(model: Node, color: Color) -> void:
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null:
			continue
		for k in mi.mesh.get_surface_count():
			var m := mi.get_active_material(k) as BaseMaterial3D
			if m != null and m.albedo_color.r > 0.45 and m.albedo_color.r > m.albedo_color.g * 2.0 and not m.emission_enabled:
				var nm := m.duplicate() as BaseMaterial3D
				nm.albedo_color = color
				mi.set_surface_override_material(k, nm)


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
	var q := StartYard.QUEUE
	Kit.solid_box(self, Vector3(0.3, 3, 3.5), q + Vector3(-3.6, 1.5, -2), Color(0.2, 0.3, 0.6), 0.3)
	_sign("ОЧЕРЕДЬ ЗА БЕСПЛАТНОЙ\nКВАРТИРОЙ", q + Vector3(-3.43, 2.4, -2), 30, Color(0.15, 0.2, 0.55), 90.0, "board",
			{"bg": Color(0.93, 0.94, 0.97), "lamp": true})
	_sign("ВЫ 4 718-Й", q + Vector3(-3.43, 1.3, -2.8), 22, Color(0.75, 0.1, 0.1), 90.0, "poster", {"tilt": -5.0})
	var colors := [Color(0.4, 0.3, 0.5), Color(0.3, 0.45, 0.4), Color(0.55, 0.4, 0.25), Color(0.35, 0.35, 0.5),
			Color(0.5, 0.25, 0.3), Color(0.3, 0.3, 0.3), Color(0.45, 0.45, 0.2)]
	for i in colors.size():
		var p := _person(q + Vector3(-2.0, 0, i * 1.1), colors[i])
		p.rotation_degrees.y = 180
		var tw := p.create_tween().set_loops()
		tw.tween_property(p, "rotation_degrees:z", 3.0, 1.2 + i * 0.1)
		tw.tween_property(p, "rotation_degrees:z", -3.0, 1.2 + i * 0.1)
	var passer := _person(StartYard.QUEUE + Vector3(1.5, 0, 9), Color(0.6, 0.5, 0.35), "Прохожий")
	_npc_mark(passer, "PASSER")
	_interactables.append({"pos": passer.position, "radius": 2.5, "label": "Говорить", "face": passer, "cb": func():
		hud.run_dialogue("PASSER"), "enabled": func(): return true})


# ---------- патруль сборщиков обязательной благодарности (этап 2) ----------

func _build_checkpoint() -> void:
	var term := Node3D.new()
	term.name = "PatrolTerminal"
	term.position = CHECKPOINT_POS + Vector3(-4.5, 0, 0)
	add_child(term)
	Kit.cylinder(term, 0.2, 2.6, Vector3(0, 1.3, 0), Color(0.3, 0.3, 0.35))
	Kit.box(term, Vector3(1.4, 1.0, 0.1), Vector3(0, 2.6, 0.15), Color(0.1, 0.9, 0.5), 1.5)
	Signboard.make(term, "ВЫРАЖЕНИЕ ЛИЦА:\nНЕДОСТАТОЧНО", "graffiti", Color(0.05, 0.2, 0.1), Vector3(0, 2.6, 0.2), 0.0, 0.2,
			{"font": "block", "tilt": 0.0}).text_node.outline_size = 0
	# пункт приёма благодарности: арка поперёк улицы, сканер ходит вверх-вниз
	for side in [-1, 1]:
		Props.collider(self, Vector3(0.6, 5, 0.6), CHECKPOINT_POS + Vector3(side * 6.5, 2.5, 0))
		Kit.box(self, Vector3(0.6, 5, 0.6), CHECKPOINT_POS + Vector3(side * 6.5, 2.5, 0), Color(0.3, 0.32, 0.38))
		Kit.box(self, Vector3(0.1, 4.2, 0.1), CHECKPOINT_POS + Vector3(side * 6.15, 2.4, 0), Color(0.3, 1, 0.6), 2.5)
	Kit.box(self, Vector3(13.6, 0.8, 0.6), CHECKPOINT_POS + Vector3(0, 5.2, 0), Color(0.25, 0.27, 0.32))
	Signboard.make(self, "ПУНКТ ПРИЁМА БЛАГОДАРНОСТИ", "neon", Color(0.4, 1, 0.7), CHECKPOINT_POS + Vector3(0, 5.2, 0.3),
			0.0, 0.55)
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
	# сам киоск «НЛО напрокат» и вывески строит StartYard; здесь — люди и сюжет
	_kiosk_owner = _person(KIOSK_POS + Vector3(-2.2, 0, 3.6), Color(0.5, 0.35, 0.3), "Киоскёр")
	# разбитый дрон, привалившийся к двери, и батарея на месте аварии
	_kiosk_wreck = Node3D.new()
	_kiosk_wreck.position = KIOSK_POS + Vector3(5.2, 0, 1.8)
	add_child(_kiosk_wreck)
	Kit.sphere(_kiosk_wreck, 0.9, Vector3(0, 0.8, 0), Color(0.55, 0.57, 0.6))
	Kit.cylinder(_kiosk_wreck, 1.4, 0.12, Vector3(0, 0.6, 0), Color(0.3, 0.3, 0.35)).rotation_degrees.z = 35
	_battery = Node3D.new()
	_battery.position = KIOSK_POS + Vector3(7.5, 0, 5.0)
	add_child(_battery)
	Kit.box(_battery, Vector3(0.5, 0.8, 0.5), Vector3(0, 0.4, 0), Color(0.3, 1, 0.7), 3.0)
	Kit.label(_battery, "Инопланетная батарея", Vector3(0, 1.3, 0), 30, Color(0.6, 1, 0.8))
	_zones.append({"pos": KIOSK_POS, "radius": 6.0, "cb": _reach_kiosk,
			"when": func(): return QuestService.is_on_stage(QID, "MAIN_001_S03")})
	_interactables.append({"pos": KIOSK_POS + Vector3(0, 0, 4), "radius": 4.0, "label": "Решить",
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
	StartYard.open_exit(self)
	hud.play_dialog([{"speaker": "journal", "text": "%s." % q.choices[key].result},
			{"speaker": "journal", "text": "Поворот: %s" % q.twist}], func():
		var next := GameData.quest("MAIN_002")
		hud.show_toast("Новое задание: «%s» — %s" % [next.title, next.location]))


# ---------- местные и пришелец-стажёр (editorial_P2) ----------

func _build_locals() -> void:
	# Гл'орп: стажёр флота, прилетел «в столицу», а попал в Рубин
	var glorp := Node3D.new()
	glorp.name = "Glorp"
	glorp.position = CONVERTIBLE_POS + Vector3(7.5, 0, 9)
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
	_interactables.append({"pos": glorp.position, "radius": 2.5, "label": "Говорить", "face": glorp, "cb": func():
		hud.run_dialogue("GLORP"), "enabled": func(): return true})
	# тётя Зина: балкон второго этажа западного дома, над очередью
	var balcony := StartYard.ZINA_BALCONY
	Kit.solid_box(self, Vector3(1.4, 0.15, 3), balcony, Color(0.55, 0.52, 0.5))
	Kit.box(self, Vector3(0.08, 0.75, 3), balcony + Vector3(0.7, 0.45, 0), Color(0.4, 0.3, 0.3))
	# у самых перил: снизу видно не только макушку
	var zina := _person(balcony + Vector3(0.45, 0.08, 0), Color(0.7, 0.2, 0.3), "Тётя Зина",
			{"style": "curlers", "skirt": true, "hair": Color(0.6, 0.2, 0.15), "height": 0.95, "skin": NpcModel.SKINS[0]})
	zina.name = "Zina"
	zina.rotation_degrees.y = 90
	_npc_mark(zina, "ZINA")
	_interactables.append({"pos": balcony * Vector3(1, 0, 1) + Vector3(3.6, 0, 0), "radius": 3.5, "label": "Зина", "face": zina, "cb": func():
		hud.run_dialogue("ZINA"), "enabled": func(): return true})


# ---------- Павел Тарелкин у временного киоска «НЛО напрокат» ----------

## ТЗ п. 5: Павел в начальной сцене стоит у прокатного киоска, пока идёт MAIN_001; потом
## уходит в парк (N07). Одна копия: видимость решает переопределение из данных района.
func _build_pavel() -> void:
	_pavel = _person(StartYard.PAVEL, Color(0.42, 0.3, 0.22), "Павел Тарелкин",
			{"style": "short", "skirt": false, "height": 1.04, "hair": Color(0.2, 0.14, 0.1)})
	_pavel.name = "Pavel"
	_pavel.rotation_degrees.y = 110.0
	Kit.box(_pavel, Vector3(0.3, 0.32, 0.03), Vector3(0, 1.3, 0.16), Color(0.92, 0.9, 0.85))   # футболка с пришельцем
	Kit.sphere(_pavel, 0.07, Vector3(0, 1.33, 0.18), Color(0.45, 0.85, 0.35))
	_npc_mark(_pavel, "PAVEL")
	_interactables.append({"pos": StartYard.PAVEL, "radius": 2.6, "label": "Говорить", "face": _pavel,
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
	Signboard.make(self, "ВЫХОД В ПОГУЛЯЙ", "letters", Color(1, 0.75, 0.35), EXIT_ARCH + Vector3(0, 6.6, 0.1), 0.0, 0.6)
	_interactables.append({"pos": EXIT_ARCH + Vector3(0, 0, 3), "radius": 3.0, "label": "Ворота", "cb": func():
		hud.show_toast("Ворота откроются, когда разберёшься с киоском."),
		"enabled": func(): return QuestService.state_of(QID) != QuestService.COMPLETED})


# ---------- такси «Межрайон» между районами (0.14) ----------

func _build_taxi() -> void:
	var stops := {
		"PG": {"at": TAXI_YARD, "title": "ПОГУЛЯЙ", "sub": "Двор у киоска. Таксист взял чаевые талонами.", "to": "Такси в Погуляй"},
		"DL": {"at": District.to_world(TAXI_DL_PLAN), "title": "ДЕЛОВОЙ",
				"sub": "Площадь «Последний талон». Счётчик тикал быстрее сердца.", "to": "Такси в Деловой"},
		"DS": {"at": District.to_world(TAXI_DS_PLAN), "title": "ДО СВИДАНИЯ",
				"sub": "Ворота «Базара под куполом». Таксист дальше не поедет — тут даже GPS прощается.",
				"to": "Такси в «До свидания»"},
	}
	for id in stops:
		var st: Dictionary = stops[id]
		var at: Vector3 = st.at
		if id != "PG":
			Props.collider(self, Vector3(1.8, 1.4, 4.3), at + Vector3(-3, 0.7, 0))
			Props.place(self, "taxi", at + Vector3(-3, 0, 0), 0.0)
			Props.place(self, "taxi_sign", at + Vector3(0, 0, -1.5), 0.0)
		Signboard.make(self, "МЕЖРАЙОН\nПОГУЛЯЙ · ДЕЛОВОЙ · ДО СВИДАНИЯ", "board", Color(0.1, 0.08, 0.05), at + Vector3(0, 3.3, -2.3), 0.0,
				0.2, {"bg": Color(0.98, 0.8, 0.15)})
		var k := 0
		for to in stops:
			if to == id:
				continue
			var dest: Dictionary = stops[to]
			# во дворе такси ждёт, пока не разберёшься с киоском (MAIN_001)
			_interactables.append({"pos": at + Vector3(-1.8 + k * 3.6, 0, 2.5), "radius": 1.7, "label": dest.to, "stop": id,
					"cb": _ride.bind(dest.at + Vector3(0, 0, 1.0), dest.title, dest.sub),
					"enabled": func(): return id != "PG" or QuestService.state_of(QID) == QuestService.COMPLETED})
			k += 1


## Поездка: затемнение, перенос героя, подгрузка участков, баннер с названием района.
func _ride(to: Vector3, title: String, sub: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 50
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(black)
	add_child(layer)
	var tw := black.create_tween()
	tw.tween_property(black, "color:a", 1.0, 0.35)
	tw.tween_callback(func() -> void:
		player.global_position = to
		player.velocity = Vector3.ZERO
		chunks.load_now()
		_queue_save())
	tw.tween_interval(0.4)
	tw.tween_property(black, "color:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		layer.queue_free()
		hud.show_banner(title, sub))


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
		StartYard.open_exit(self, true)
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
	torus.rings = 32
	torus.ring_segments = 6
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
	_safe_tick -= delta
	if _safe_tick <= 0.0:
		_safe_tick = 0.5
		_update_safe_zone()
	if player.safe_zone != "" and GameState.hp < GameState.max_hp:
		GameState.heal(SAFE_HEAL_PER_S * delta)
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


## Безопасные зоны S0–S4 (этап 3 ТЗ): мобы не нападают и отстают, здоровье восстанавливается.
func _update_safe_zone() -> void:
	var z := District.safe_zone_at(District.to_plan(player.global_position))
	var id: String = z.get("id", "")
	if id == player.safe_zone:
		return
	if id != "":
		hud.show_toast("Безопасная зона «%s»: здесь не нападают, здоровье восстанавливается" % z.get("name", id))
	elif player.safe_zone != "":
		hud.show_toast("Ты вышел из безопасной зоны")
	player.safe_zone = id


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
		# с собеседником — кинокамера: переезд к герою, взгляд на лицо говорящего
		if best.has("face") and hud.dialog.is_open():
			var who: Node3D = best.face
			camera.cinematic(who.global_position + who.global_transform.basis.y * float(who.get_meta("head_y", 1.8)))
			var model := who.get_node_or_null("Model") as NpcModel
			if model != null:
				model.set_talking(true)
			# крупным планом подписи и «!» над головой только мешают
			for l in who.find_children("*", "Label3D", true, false):
				if l.visible:
					_cine_hidden.append(l)
					l.visible = false
			# собеседник поворачивается к герою (перед у фигур — +Z)
			var to_hero := (player.global_position - who.global_position) * Vector3(1, 0, 1)
			if to_hero.length() > 0.3 and who.global_position.y < 1.0:
				_cine_turned = [who, who.rotation.y]
				who.rotation.y = atan2(to_hero.x, to_hero.z)
			# почти от первого лица: свою голову герой не видит
			_cine_hidden.append(player)
			player.visible = false


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
	# после боя герой должен ходить (0.8: застывал на месте)
	var before_move := player.global_position
	player.move_input = Vector2(1, 0)
	await _frames(30)
	player.move_input = Vector2.ZERO
	var moved := player.global_position.distance_to(before_move)
	log.call("после боя: прошёл %.1f м, пауза %s, управление %s, диалог %s, кино %s, time_scale %.2f" % [moved,
			get_tree().paused, player.controls_enabled, hud.dialog.is_open(), camera.in_cinematic(), Engine.time_scale])
	if moved < 1.0:
		print("AUTOTEST_FAIL")
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
	# этап 3: безопасная зона S1 — вход, лечение, удар не проходит, выход
	var back := player.global_position
	player.global_position = District.to_world(District.pos(District.point("S1")), 0.5)
	GameState.damage(30)
	var hp_in := GameState.hp
	await _frames(40)
	var healed := GameState.hp > hp_in
	var hp_hit := GameState.hp
	player.take_hit(25.0)
	var no_hit := is_equal_approx(GameState.hp, hp_hit)
	log.call("безопасная зона %s: лечит %s, удар не прошёл %s" % [player.safe_zone, healed, no_hit])
	player.global_position = back
	await _frames(40)
	if player.safe_zone != "" or not healed or not no_hit:
		print("AUTOTEST_FAIL")
	# 0.7: живая улица и группа мобов у M10-1
	var mp := District.pos(District.point("M10-1"))
	player.global_position = District.to_world(mp + Vector2(0, 40), 0.5)
	chunks.load_now()
	await _frames(40)
	mobs.update_now()
	var group := mobs.alive_count("M10-1")
	var xp_before := GameState.xp
	for m in mobs.get_children():
		if m is EnemyDrone:
			m.take_hit(999.0, player.global_position)
	await _frames(30)
	var walkers := street_life.get_children().filter(func(n: Node3D) -> bool: return n.visible).size()
	log.call("улица: видно %d прохожих и машин; группа M10-1: %d, опыт +%d" % [walkers, group, GameState.xp - xp_before])
	if group < 4 or GameState.xp <= xp_before or walkers < 5:
		print("AUTOTEST_FAIL")
	player.global_position = back
	await _frames(20)
	# 0.14–0.15: такси «Межрайон» — двор → Деловой → «До свидания» → двор
	var trip := [["PG", "Такси в Деловой", "DL"], ["DL", "Такси в «До свидания»", "DS"], ["DS", "Такси в Погуляй", "PG"]]
	var rode := []
	for leg in trip:
		var ride := {}
		for it in _interactables:
			if it.get("stop", "") == leg[0] and it.label == leg[1]:
				ride = it
		if ride.is_empty() or not ride.enabled.call():
			rode.append(false)
			break
		ride.cb.call()
		await get_tree().create_timer(1.6).timeout
		rode.append(District.district_at(District.to_plan(player.global_position)).id == leg[2])
	var home := player.global_position.distance_to(TAXI_YARD) < 4.0
	log.call("такси «Межрайон»: %s, обратно во двор %s" % [str(rode), home])
	if rode != [true, true, true] or not home:
		print("AUTOTEST_FAIL")
	player.global_position = back
	await _frames(20)
	# 0.8: кинокамера разговора и возврат в изометрию
	for it in _interactables:
		if it.has("face") and it.label == "Зина":
			player.global_position = it.pos
	await _frames(5)
	_on_interact()
	await _frames(70)
	var cine_ok := camera.projection == Camera3D.PROJECTION_PERSPECTIVE and not player.visible
	for i in 30:
		if not hud.dialog.is_open():
			break
		if not hud.dialog.pick_tone():
			hud.dialog.skip()
		await _frames(3)
	await _frames(80)
	var back_ok := camera.projection == Camera3D.PROJECTION_ORTHOGONAL and player.visible \
			and is_equal_approx(camera.size, IsoCamera.DEFAULT_SIZE)
	log.call("кинокамера у Зины: %s, вернулась в изометрию: %s" % [cine_ok, back_ok])
	if not cine_ok or not back_ok:
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
