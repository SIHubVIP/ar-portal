extends Node3D
## «Башня на спине» by Aolovo — main game: world, hero, tower physics, input, flow.

const ROOF_HALF := 4.0
const GRAV := 24.0
const CP_EVERY := 400.0
const TILT_MAX := 0.62
const BPM := 96.0
const BEAT := 60.0 / BPM
const SAVE_PATH := "user://save.json"

const ITEMS := [
	{"id": "mic", "name": "Микрофон", "value": 30, "h": 0.62, "tag": "фристайл: комбо ×2"},
	{"id": "boombox", "name": "Бумбокс", "value": 40, "h": 0.5, "tag": "бит ×2"},
	{"id": "player", "name": "Плеер", "value": 20, "h": 0.46, "tag": "шафл: шанс хита"},
	{"id": "notebook", "name": "Блокнот рифм", "value": 15, "h": 0.13, "tag": "рифма за пару"},
	{"id": "tablet", "name": "Планшет", "value": 25, "h": 0.08, "tag": "стрим: звёзды капают"},
	{"id": "headphones", "name": "Шумоизоляция", "value": 30, "h": 0.5, "tag": "глушит выстрел дрона"},
	{"id": "chain", "name": "Золотая цепь", "value": 70, "h": 0.12, "tag": "дорогая и тяжёлая"},
	{"id": "sneakers", "name": "Коробка кроссов", "value": 35, "h": 0.36, "tag": "прыжок выше"},
	{"id": "spray", "name": "Баллончик", "value": 15, "h": 0.55, "tag": "тег: сдача +10%"},
	{"id": "crate", "name": "Ящик пластинок", "value": 10, "h": 0.62, "tag": ""},
	{"id": "vinyl", "name": "Пластинка", "value": 80, "h": 0.05, "tag": "редкость"},
	{"id": "balloon", "name": "Шарик", "value": 15, "h": 0.75, "tag": "башня легче"},
	{"id": "magnet", "name": "Магнит", "value": 25, "h": 0.45, "tag": "притягивает вещи"},
]
const ADS := [["AOLOVO", Color("f5b55c")], ["РЭП-БАТТЛ", Color("ff5d7a")], ["СТУДИЯ ЗВУКА", Color("55cdbe")],
	["AOLOVO", Color("55cdbe")], ["ЛАПША 24/7", Color("ff5d7a")], ["КАРАОКЕ", Color("ff8ad8")], ["ПЕЛЬМЕНИ", Color("f5b55c")]]

enum { MENU, PLAY, PAUSE, OVER }
var state := MENU

var ui: GameUI
var world: Node3D
var cam: Camera3D
var sun: DirectionalLight3D
var speed_lines: CPUParticles3D
var hero: Dictionary
var TYPE := {}

# run state
var x := 0.0
var y := 0.0
var z := 0.0
var vx := 0.0
var vy := 0.0
var ax := 0.0
var speed := 11.0
var on_ground := true
var coyote := 0.0
var jump_buf := 0.0
var jumps_left := 0
var tower: Array = []
var theta := 0.0
var omega := 0.0
var pitch := 0.0
var pitch_v := 0.0
var bank := 0
var pool := 0.0
var phase := 0.0
var gen_z := 8.0
var next_cp_gen := CP_EVERY
var stumble_t := 0.0
var drone_timer := 6.0
var time := 0.0
var cam_x := 0.0
var cam_y := 4.0
var last_seg_y := 0.0
var seg_n := 0
var wind := 0.0
var wind_t := 0.0
var dash := 0.0
var dash_cd := 0.0
var combo := 0
var combo_t := 0.0
var shake := 0.0
var fov_kick := 0.0
var rocket_t := 0.0
var dance_t := 0.0
var beat_pulse := 0.0
var stream_acc := 0.0
var last_pick := ""
var tut := {}

var segs: Array = []
var things: Array = []

# input
var steer := 0.0
var steer_idx := -1
var steer_origin := Vector2.ZERO

# audio
var music: AudioStreamPlayer
var run_stream: AudioStream
var menu_stream: AudioStream
var sfx_players: Array = []
var sfx := {}
var music_on := true

# save
var save := {"stars": 0, "best": 0, "best_dist": 0, "runs": 0, "music": true, "tutorial": false}

# materials
var facades: Array = []
var roofs: Array = []
var parapet_mat: StandardMaterial3D


func _ready() -> void:
	Kit.init()
	randomize()
	for t in ITEMS:
		TYPE[t.id] = t
	_load_save()
	music_on = save.music
	_setup_env()
	_setup_audio()
	world = Node3D.new()
	add_child(world)
	facades = [Kit.facade_material(Color("4a2c3c"), 0.35, 1), Kit.facade_material(Color("2c2f4a"), 0.45, 2),
		Kit.facade_material(Color("5a3328"), 0.3, 3), Kit.facade_material(Color("243548"), 0.5, 4),
		Kit.facade_material(Color("3d3346"), 0.4, 5)]
	roofs = [Kit.tile_material(Color("b9785e"), Color("6a3434")), Kit.tile_material(Color("6f8a82"), Color("2f4a44")),
		Kit.tile_material(Color("847aa4"), Color("3a3262"))]
	parapet_mat = Kit.mat(Color("8a4a44"), 0.9)
	_build_backdrop()
	ui = GameUI.new()
	add_child(ui)
	ui.start_pressed.connect(start_run)
	ui.again_pressed.connect(start_run)
	ui.menu_pressed.connect(to_menu)
	ui.resume_pressed.connect(toggle_pause)
	ui.pause_pressed.connect(toggle_pause)
	ui.quit_pressed.connect(func(): state = PLAY; game_over("Забег окончен", "Сданное в банк засчитано."))
	ui.mute_pressed.connect(func(): set_music(not music_on))
	ui.set_music_icon(music_on)
	_make_hero()
	_attract()
	ui.show_screen("menu")
	ui.set_menu_stats(save.stars, save.best, save.best_dist)
	_play_music(menu_stream)
	if OS.get_cmdline_user_args().has("--autotest"):
		_autotest()


# ================================================================== environment
func _setup_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color("2b1650")
	psm.sky_horizon_color = Color("ff8f6a")
	psm.sky_curve = 0.12
	psm.ground_horizon_color = Color("ff8f6a")
	psm.ground_bottom_color = Color("2a1838")
	psm.sun_angle_max = 25.0
	psm.sun_curve = 0.08
	sky.sky_material = psm
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("6a5a9a")
	env.ambient_light_energy = 0.75
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_strength = 1.0
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.fog_enabled = true
	env.fog_light_color = Color("94507a")
	env.fog_light_energy = 0.8
	env.fog_density = 0.0065
	env.fog_sky_affect = 0.2
	env.fog_aerial_perspective = 0.25
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffb27a")
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_blur = 1.5
	sun.rotation_degrees = Vector3(-16, 165, 0)
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color("7fd8ff")
	rim.light_energy = 0.45
	rim.rotation_degrees = Vector3(-30, -10, 0)
	add_child(rim)

	cam = Camera3D.new()
	cam.fov = 62
	cam.far = 260
	add_child(cam)
	speed_lines = CPUParticles3D.new()
	var sl_mesh := BoxMesh.new()
	sl_mesh.size = Vector3(0.02, 0.02, 3.0)
	var sl_mat := StandardMaterial3D.new()
	sl_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sl_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sl_mat.albedo_color = Color(1, 0.9, 0.8, 0.22)
	sl_mesh.material = sl_mat
	speed_lines.mesh = sl_mesh
	speed_lines.amount = 50
	speed_lines.lifetime = 0.45
	speed_lines.local_coords = true
	speed_lines.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	speed_lines.emission_box_extents = Vector3(7, 4, 2)
	speed_lines.position = Vector3(0, 0, -22)
	speed_lines.direction = Vector3(0, 0, 1)
	speed_lines.spread = 0
	speed_lines.gravity = Vector3.ZERO
	speed_lines.initial_velocity_min = 55
	speed_lines.initial_velocity_max = 70
	speed_lines.emitting = false
	cam.add_child(speed_lines)


func _build_backdrop() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Kit.BOX
	mm.instance_count = 220
	for i in range(220):
		var side := 1.0 if i % 2 else -1.0
		var far := i % 4 >= 2
		var h := randf_range(14, 48) if far else randf_range(8, 30)
		var bx := side * (randf_range(60, 110) if far else randf_range(30, 58))
		var t := Transform3D(Basis().scaled(Vector3(randf_range(6, 16), h, randf_range(6, 16))), Vector3(bx, -22 + h / 2, -float(i / 2) * 9.0 + 40))
		mm.set_instance_transform(i, t)
	var bd := Node3D.new()
	bd.name = "Backdrop"
	add_child(bd)
	for k in range(2):
		var mk := MultiMesh.new()
		mk.transform_format = MultiMesh.TRANSFORM_3D
		mk.mesh = Kit.BOX
		mk.instance_count = 110
		for j in range(110):
			mk.set_instance_transform(j, mm.get_instance_transform(j * 2 + k))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mk
		mmi.material_override = facades[k * 2 + 1]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bd.add_child(mmi)
	# street level far below: dark ground with glowing street lamps
	Kit.part(bd, Kit.BOX, Kit.mat(Color("1a1222"), 1.0), Vector3(400, 1, 600), Vector3(0, -24, -150))
	var lamps := MultiMesh.new()
	lamps.transform_format = MultiMesh.TRANSFORM_3D
	lamps.mesh = Kit.SPH
	lamps.instance_count = 160
	for j in range(160):
		var lx: float = [-16.0, 16.0, -26.0, 26.0][j % 4]
		lamps.set_instance_transform(j, Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(lx, -22.5, 40 - (j / 4) * 12.0)))
	var lmi := MultiMeshInstance3D.new()
	lmi.multimesh = lamps
	lmi.material_override = Kit.neon(Color("ffb35c"), 4.0)
	lmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bd.add_child(lmi)


# ================================================================== audio
func _setup_audio() -> void:
	run_stream = load("res://audio/music_run.ogg")
	menu_stream = load("res://audio/music_menu.ogg")
	if run_stream is AudioStreamOggVorbis:
		run_stream.loop = true
	if menu_stream is AudioStreamOggVorbis:
		menu_stream.loop = true
	music = AudioStreamPlayer.new()
	music.volume_db = -3.0
	add_child(music)
	for n in ["jump", "pickup", "drop", "bank", "beat", "laser", "bolt", "stumble", "dash", "smash", "land", "near", "over", "ui"]:
		sfx[n] = load("res://audio/sfx_%s.ogg" % n)
	for i in range(8):
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		sfx_players.append(p)


func _play_music(s: AudioStream) -> void:
	if not music_on:
		music.stop()
		return
	if music.stream == s and music.playing:
		return
	music.stream = s
	music.play()


func set_music(on: bool) -> void:
	music_on = on
	save.music = on
	_save()
	ui.set_music_icon(on)
	if on:
		_play_music(run_stream if state == PLAY else menu_stream)
	else:
		music.stop()


func play_sfx(n: String, pitch_scale := 1.0) -> void:
	if not sfx.has(n):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx[n]
			p.pitch_scale = pitch_scale
			p.play()
			return


func beat_phase() -> float:
	if music.playing and music.stream == run_stream:
		var t := music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		return fposmod(t / BEAT, 1.0)
	return fposmod(time / BEAT, 1.0)


func on_beat() -> bool:
	var ph := beat_phase()
	return minf(ph, 1.0 - ph) * BEAT < 0.12


func buzz(ms: int) -> void:
	Input.vibrate_handheld(ms)


# ================================================================== save
func _load_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			for k in d:
				save[k] = d[k]


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))


# ================================================================== hero
func _make_hero() -> void:
	hero = Models.make_rapper(Models.SKINS.classic)
	hero.tower_base.scale = Vector3.ONE * 1.3
	add_child(hero.root)


func count_type(id: String) -> int:
	var c := 0
	for t in tower:
		if t.type.id == id:
			c += 1
	return c


func tower_height() -> float:
	var h := 0.0
	for t in tower:
		h += t.type.h
	return h


func multiplier() -> float:
	return 1.0 + maxf(0, tower.size() - 1) * 0.25


func add_to_tower(type: Dictionary) -> void:
	var parent: Node3D = tower[-1].link if tower.size() else hero.tower_base
	var link := Node3D.new()
	link.position.y = tower[-1].type.h if tower.size() else 0.0
	var it := Models.make_item(type.id)
	it.rotation.y = randf_range(-0.3, 0.3)
	it.position.x = randf_range(-0.04, 0.04)
	link.add_child(it)
	parent.add_child(link)
	it.scale = Vector3.ONE * 1.35
	tower.append({"type": type, "link": link, "item": it, "pop": 0.2, "spent": false})
	omega += randf_range(-0.2, 0.2)


func drop_top(dir := 0.0) -> void:
	if tower.is_empty():
		return
	var top: Dictionary = tower.pop_back()
	var link: Node3D = top.link
	var gt := link.global_transform
	link.get_parent().remove_child(link)
	world.add_child(link)
	link.global_transform = gt
	var side := dir if dir != 0.0 else (signf(theta) if theta != 0.0 else (1.0 if randf() < 0.5 else -1.0))
	things.append({"kind": "falling", "node": link, "v": Vector3(side * 4 + vx * 0.3, 4, -speed * 0.6), "spin": randf_range(-4, 4), "t": 0.0})
	pop("−1 " + top.type.name, "bad", gt.origin)
	combo = 0
	combo_t = 0.0
	play_sfx("drop")
	buzz(40)
	ui.flash(Color("ff3c5a"), 0.18)


func bank_tower(at: Vector3) -> void:
	if tower.is_empty() and pool < 1:
		pop("Башня пуста", "bad", at)
		return
	var sum := 0
	for t in tower:
		sum += t.type.value
	var gain := int(round((round(sum * multiplier()) + pool) * (1.0 + 0.1 * count_type("spray"))))
	bank += gain
	pool = 0
	while tower.size():
		var t: Dictionary = tower.pop_back()
		burst(t.link.global_position, 4, [Kit.GOLD, Kit.TEAL, Color.WHITE], 6, 0.16, 6, 1.0)
		t.link.queue_free()
	theta *= 0.2
	omega = 0
	dance_t = 1.2
	pop("+%d в банк!" % gain, "bank", at)
	burst(at, 60, [Kit.GOLD, Kit.TEAL, Color("ff5d7a"), Color("c38bff"), Color.WHITE], 14, 0.2, 10, 1.6, 12)
	ui.flash(Color.WHITE, 0.45)
	shake = 0.5
	play_sfx("bank")
	buzz(60)
	if not save.tutorial and state == PLAY:
		save.tutorial = true
		_save()
		get_tree().create_timer(0.9).timeout.connect(func(): ui.tip("Отлично! Звёзды из банка остаются с тобой навсегда", 4.0))


# ================================================================== level
func segment_at(zz: float):
	for s in segs:
		if zz <= s.z0 and zz >= s.z1:
			return s
	return null


func add_segment(length: float, sy: float, z0: float) -> Dictionary:
	var z1 := z0 - length
	var zc := (z0 + z1) / 2.0
	var g := Node3D.new()
	world.add_child(g)
	var f: StandardMaterial3D = facades[seg_n % facades.size()]
	Kit.part(g, Kit.BOX, f, Vector3(ROOF_HALF * 2 + 1.4, 40, length), Vector3(0, sy - 20.15, zc))
	Kit.part(g, Kit.BOX, roofs[seg_n % roofs.size()], Vector3(ROOF_HALF * 2 + 1.4, 0.3, length), Vector3(0, sy - 0.15, zc))
	for s in [-1, 1]:
		Kit.part(g, Kit.BOX, parapet_mat, Vector3(0.3, 0.4, length), Vector3(s * (ROOF_HALF + 0.55), sy + 0.2, zc))
	# neighbours with neon signs
	for s in [-1, 1]:
		if randf() < 0.25:
			continue
		var h := randf_range(30, 36)
		var w := randf_range(6, 9)
		var by := sy - 3 - randf() * 6
		var nf: StandardMaterial3D = facades[(seg_n + 1 + (1 if s > 0 else 0)) % facades.size()]
		Kit.part(g, Kit.BOX, nf, Vector3(w, h, minf(length, randf_range(18, 28))), Vector3(s * (ROOF_HALF + 3.2 + w / 2), by - h / 2, zc))
		if randf() < 0.75:
			var ad = ADS[randi() % ADS.size()]
			var l := Label3D.new()
			l.text = ad[0]
			l.font = ui.display_font if ui else null
			l.font_size = 110
			l.pixel_size = 0.011
			l.modulate = ad[1] * 2.4
			l.outline_modulate = Color(0.05, 0.02, 0.08, 0.9)
			l.outline_size = 18
			l.double_sided = true
			l.position = Vector3(s * (ROOF_HALF + 3.6), by + 2.4, zc + randf_range(-3, 3))
			l.rotation.y = -s * 0.9
			g.add_child(l)
	# string lights
	if seg_n % 2 == 1 and length > 26:
		var zz := zc + randf_range(-1, 1) * (length - 16) / 2
		for i in range(11):
			var u := i / 10.0
			var bx := -ROOF_HALF - 0.5 + u * (ROOF_HALF * 2 + 1)
			var byy := sy + 4.6 - sin(u * PI) * 0.9
			var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL, Color("2ed38f")]
			Kit.part(g, Kit.SPH, Kit.neon(cols[i % 4], 3.0), Vector3(0.16, 0.2, 0.16), Vector3(bx, byy, zz))
		for s in [-1, 1]:
			Kit.part(g, Kit.BOX, Kit.mat(Color("3a3d4a")), Vector3(0.12, 4.6, 0.12), Vector3(s * (ROOF_HALF + 0.55), sy + 2.3, zz))
	# water tank
	if randf() < 0.45:
		var tank := Node3D.new()
		Kit.part(tank, Kit.CYL, Kit.mat(Color("8c5f34"), 0.9), Vector3(1.6, 1.8, 1.6), Vector3(0, 2.6, 0))
		Kit.part(tank, Kit.CONE, Kit.mat(Color("2a2632")), Vector3(1.8, 0.8, 1.8), Vector3(0, 3.9, 0))
		for p in [Vector2(-0.6, -0.6), Vector2(0.6, -0.6), Vector2(-0.6, 0.6), Vector2(0.6, 0.6)]:
			Kit.part(tank, Kit.BOX, Kit.mat(Color("3a3d4a")), Vector3(0.12, 1.8, 0.12), Vector3(p.x, 0.9, p.y))
		tank.position = Vector3((-1 if randf() < 0.5 else 1) * (ROOF_HALF + 2.3), sy, zc + randf_range(-0.3, 0.3) * length)
		g.add_child(tank)
	var seg := {"z0": z0, "z1": z1, "y": sy, "node": g}
	segs.append(seg)
	gen_z = z1
	last_seg_y = sy
	seg_n += 1
	return seg


func gen_next() -> void:
	var hard := minf(1.0, -gen_z / 1600.0)
	var gap := 2.6 + randf() * (2.0 + hard * 2.6)
	var length := 22.0 + randf() * 28.0
	var ny := last_seg_y + randf_range(-0.9, 0.9)
	ny = clampf(minf(ny, last_seg_y + 0.7), -2.0, 2.0)
	var seg := add_segment(length, ny, gen_z - gap)
	var gd := next_cp_gen
	if gd < -seg.z0 + 6:
		gd = -seg.z0 + 8
	if gd <= -seg.z1 - 6:
		add_gate(seg, -gd)
		next_cp_gen = gd + CP_EVERY
	populate(seg, hard)


func populate(seg: Dictionary, hard: float) -> void:
	var zz: float = seg.z0 - 6
	var line_mode := false
	while zz > seg.z1 + 5:
		var near_gate := false
		for t in things:
			if t.kind == "gate" and absf(t.z - zz) < 7:
				near_gate = true
		if near_gate:
			zz -= 4
			continue
		var r := randf()
		var px := randf_range(-1, 1) * (ROOF_HALF - 0.8)
		if r < 0.14 and not line_mode:
			var x0 := randf_range(-2.5, 2.5)
			var dir := -1.0 if randf() < 0.5 else 1.0
			for i in range(4):
				if zz <= seg.z1 + 4:
					break
				add_pickup(clampf(x0 + dir * i * 0.9, -3.4, 3.4), seg.y + 1.1, zz)
				zz -= 2.6
			line_mode = true
			continue
		line_mode = false
		if r < 0.5:
			add_pickup(px, seg.y + 1.1, zz)
		elif r < 0.78 + hard * 0.12:
			add_obstacle(px, seg.y, zz)
			if hard > 0.35 and randf() < 0.35:
				add_obstacle(px - 2.4 if px > 0 else px + 2.4, seg.y, zz)
		zz -= 4.5 + randf() * (6.5 - hard * 2.5)


func pick_type() -> Dictionary:
	var r := randf()
	if r < 0.04:
		return TYPE.vinyl
	if r < 0.1:
		return TYPE.balloon
	if r < 0.15:
		return TYPE.magnet
	return ITEMS[randi() % 10]


func add_pickup(px: float, py: float, pz: float) -> void:
	var type := pick_type()
	var g := Node3D.new()
	var it := Models.make_item(type.id)
	it.position.y = -type.h / 2.0
	g.add_child(it)
	var glow := MeshInstance3D.new()
	glow.mesh = QuadMesh.new()
	glow.material_override = Kit.glow_material(Kit.TEAL if type.id == "vinyl" else Kit.GOLD, 0.55)
	glow.scale = Vector3.ONE * 2.2
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(glow)
	g.position = Vector3(px, py, pz)
	g.scale = Vector3.ONE * 1.35
	world.add_child(g)
	things.append({"kind": "pickup", "type": type, "node": g, "x": px, "y": py, "z": pz, "ph": randf() * 6})


func add_obstacle(px: float, py: float, pz: float) -> void:
	var g := Models.make_obstacle(0 if randf() < 0.6 else 1)
	g.position = Vector3(px, py, pz)
	world.add_child(g)
	things.append({"kind": "obstacle", "node": g, "x": px, "y": py, "z": pz, "hw": 0.75, "h": 1.05, "hit": false})


func add_gate(seg: Dictionary, gz: float) -> void:
	var g := Node3D.new()
	var sy: float = seg.y
	var green := Kit.neon(Color("2ed38f"), 2.6)
	var purple := Kit.neon(Color("b07aff"), 2.6)
	var whitec := Kit.neon(Color("ffe9b0"), 2.0)
	Kit.part(g, Kit.BOX, green, Vector3(0.3, 3.8, 0.3), Vector3(-ROOF_HALF - 0.3, sy + 1.9, 0))
	Kit.part(g, Kit.BOX, whitec, Vector3(0.3, 3.8, 0.3), Vector3(0, sy + 1.9, 0))
	Kit.part(g, Kit.BOX, purple, Vector3(0.3, 3.8, 0.3), Vector3(ROOF_HALF + 0.3, sy + 1.9, 0))
	Kit.part(g, Kit.BOX, green, Vector3(ROOF_HALF + 0.5, 0.3, 0.3), Vector3(-ROOF_HALF / 2 - 0.2, sy + 3.8, 0))
	Kit.part(g, Kit.BOX, purple, Vector3(ROOF_HALF + 0.5, 0.3, 0.3), Vector3(ROOF_HALF / 2 + 0.2, sy + 3.8, 0))
	for sign in [[-2.1, "◀ СДАТЬ ДОБЫЧУ", Color("2ed38f")], [2.1, "РИСК ДАЛЬШЕ ▶", Color("c38bff")]]:
		var l := Label3D.new()
		l.text = sign[1]
		l.font = ui.display_font
		l.font_size = 80
		l.pixel_size = 0.01
		l.modulate = sign[2] * 2.2
		l.outline_modulate = Color(0.04, 0.02, 0.06, 0.95)
		l.outline_size = 16
		l.position = Vector3(sign[0], sy + 3.1, 0.25)
		g.add_child(l)
		var floor_m := StandardMaterial3D.new()
		floor_m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		floor_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		floor_m.albedo_color = Color(sign[2], 0.45)
		Kit.part(g, Kit.BOX, floor_m, Vector3(3.8, 0.02, 2.4), Vector3(sign[0], sy + 0.03, 0))
	g.position.z = gz
	world.add_child(g)
	things.append({"kind": "gate", "node": g, "z": gz, "used": false})


func add_drone() -> void:
	var seg = segment_at(z - 46)
	var sy: float = seg.y if seg else last_seg_y
	var d := Models.make_drone()
	var px := randf_range(-3, 3)
	var g: Node3D = d.node
	g.position = Vector3(px, sy + 5.2, z - 46)
	world.add_child(g)
	var laser := MeshInstance3D.new()
	laser.mesh = Kit.CYL
	laser.material_override = Kit.neon(Color("ff3b5c"), 2.5)
	laser.visible = false
	laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(laser)
	things.append({"kind": "drone", "node": g, "laser": laser, "eye": d.eye, "rotors": d.rotors, "x": px, "y": sy + 5.2, "z": z - 46, "st": "idle", "t": 0.0})


# ================================================================== particles & popups
func burst(at: Vector3, n: int, colors: Array, spd := 5.0, size := 0.14, up := 4.0, life := 0.8, grav := 14.0) -> void:
	var p := CPUParticles3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * size
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = m
	p.mesh = bm
	p.amount = n
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 70
	p.initial_velocity_min = spd * 0.4
	p.initial_velocity_max = spd + up
	p.gravity = Vector3(0, -grav, 0)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	var g := Gradient.new()
	g.offsets = PackedFloat32Array()
	g.colors = PackedColorArray()
	for i in range(colors.size()):
		g.add_point(float(i) / max(1, colors.size() - 1), colors[i] * 1.6)
	p.color_initial_ramp = g
	p.position = at
	world.add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.6).timeout.connect(p.queue_free)


func pop(text: String, kind: String, at = null) -> void:
	if state != PLAY:
		return
	var vs := get_viewport().get_visible_rect().size
	var sp := Vector2(vs.x / 2, vs.y * 0.36)
	if at is Vector3 and not cam.is_position_behind(at):
		sp = cam.unproject_position(at)
	ui.pop(text, kind, sp)


# ================================================================== flow
func clear_world() -> void:
	for s in segs:
		s.node.queue_free()
	segs.clear()
	for t in things:
		if t.has("node") and is_instance_valid(t.node):
			t.node.queue_free()
		if t.has("laser") and is_instance_valid(t.laser):
			t.laser.queue_free()
	things.clear()
	for t in tower:
		t.link.queue_free()
	tower.clear()


func reset_run() -> void:
	clear_world()
	x = 0; y = 0; z = 0; vx = 0; vy = 0; ax = 0; speed = 11; on_ground = true; coyote = 0; jump_buf = 0; jumps_left = 0
	theta = 0; omega = 0; pitch = 0; pitch_v = 0; bank = 0; pool = 0; phase = 0; gen_z = 8; next_cp_gen = CP_EVERY
	stumble_t = 0; drone_timer = 6; time = 0; cam_x = 0; cam_y = 4; last_seg_y = 0; seg_n = 0; wind = 0; wind_t = 0
	dash = 0; dash_cd = 0; combo = 0; combo_t = 0; shake = 0; fov_kick = 0; rocket_t = 0; dance_t = 0; stream_acc = 0; last_pick = ""
	tut = {"stage": 0, "steer_t": 0.0, "gap": false, "gate": false, "beat": false, "t": 0.0}
	add_segment(60, 0, 8)
	while gen_z > -180:
		gen_next()


func _attract() -> void:
	reset_run()
	for id in ["crate", "boombox", "mic", "headphones"]:
		add_to_tower(TYPE[id])


func start_run() -> void:
	reset_run()
	steer = 0
	steer_idx = -1
	state = PLAY
	ui.show_screen("play")
	ui.hide_tip()
	ui.set_stick(false, Vector2.ZERO, 0)
	_play_music(run_stream)
	play_sfx("ui")


func to_menu() -> void:
	if state != MENU:
		state = MENU
		_attract()
	ui.show_screen("menu")
	ui.hide_tip()
	ui.set_menu_stats(save.stars, save.best, save.best_dist)
	_play_music(menu_stream)


func game_over(title: String, text: String) -> void:
	if state == MENU:
		_attract()
		return
	state = OVER
	var dist := int(round(-z))
	save.runs += 1
	save.stars += bank
	var is_new: bool = bank > save.best
	if is_new:
		save.best = bank
	if dist > save.best_dist:
		save.best_dist = dist
	_save()
	ui.set_over(title, text, bank, dist, save.stars, save.best, is_new and bank > 0)
	ui.show_screen("over")
	ui.hide_tip()
	music.stop()
	play_sfx("over")
	buzz(120)
	get_tree().create_timer(1.6).timeout.connect(func(): if state == OVER: _play_music(menu_stream))


func toggle_pause() -> void:
	if state == PLAY:
		state = PAUSE
		ui.show_screen("pause")
		music.stream_paused = true
	elif state == PAUSE:
		state = PLAY
		ui.show_screen("play")
		music.stream_paused = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		match state:
			PLAY: toggle_pause()
			PAUSE, OVER: to_menu()
			MENU: get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == PLAY:
			toggle_pause()


# ================================================================== input
func request_jump() -> void:
	if state == PLAY:
		jump_buf = 0.15


func request_dash() -> void:
	if state != PLAY or dash_cd > 0:
		return
	dash = 0.5
	dash_cd = 2.6
	fov_kick = 10
	pitch_v -= 2.5
	omega += randf_range(-0.6, 0.6)
	play_sfx("dash")
	buzz(20)


func _input(event: InputEvent) -> void:
	if state != PLAY or ui.splash_visible():
		return
	var vs := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			if pos.y < 90 and pos.x > vs.x - 230:
				return  # pause / music buttons
			if pos.distance_to(ui.jump_center()) < 72:
				request_jump()
				ui.set_pressed("jump", true)
			elif pos.distance_to(ui.dash_center()) < 58:
				request_dash()
				ui.set_pressed("dash", true)
			elif pos.x < vs.x * 0.5:
				if steer_idx == -1:
					steer_idx = event.index
					steer_origin = pos
					ui.set_stick(true, pos, 0)
			else:
				request_jump()
		else:
			if event.index == steer_idx:
				steer_idx = -1
				steer = 0
				ui.set_stick(false, Vector2.ZERO, 0)
			ui.set_pressed("jump", false)
			ui.set_pressed("dash", false)
	elif event is InputEventScreenDrag and event.index == steer_idx:
		var dx := clampf(event.position.x - steer_origin.x, -60, 60)
		steer = dx / 60.0
		ui.set_stick(true, steer_origin, dx)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_UP, KEY_W: request_jump()
			KEY_SHIFT, KEY_DOWN, KEY_S: request_dash()
			KEY_ESCAPE, KEY_P: toggle_pause()


func key_steer() -> float:
	var s := 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		s -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		s += 1
	return s


# ================================================================== main loop
func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	match state:
		PLAY:
			step(dt)
			_update_hud()
		MENU:
			if segment_at(z - 3.4) == null and on_ground:
				jump_buf = 0.1
			steer = sin(time * 0.7) * 0.15 - theta * 1.5
			var keep := tower.size()
			step(dt * 0.6)
			if tower.size() < keep:
				add_to_tower(pick_type())
		_:
			pass


func step(dt: float) -> void:
	time += dt
	var hard := minf(1.0, -z / 1600.0)
	var n := tower.size()
	var target := (11.0 + minf(10.0, -z / 120.0)) * (1.0 - minf(0.18, n * 0.01))
	speed += (target - speed) * minf(1.0, dt * 2.0)
	var fwd := speed
	if dash > 0:
		dash -= dt
		fwd *= 1.75
	dash_cd -= dt
	if stumble_t > 0:
		stumble_t -= dt
		fwd *= 0.35
	z -= fwd * dt
	combo_t -= dt
	if combo_t <= 0 and combo > 0:
		combo = 0
	var tabs := count_type("tablet")
	if tabs > 0:
		stream_acc += 2.0 * tabs * dt
		if stream_acc >= 1.0:
			var w := floorf(stream_acc)
			pool += w
			stream_acc -= w

	# steering
	var st := clampf(steer + (key_steer() if state == PLAY else 0.0), -1.0, 1.0)
	var prev_vx := vx
	vx += (st * 8.0 - vx) * minf(1.0, dt * 10.0)
	x += vx * dt
	if x > ROOF_HALF:
		x = ROOF_HALF; vx = 0
	if x < -ROOF_HALF:
		x = -ROOF_HALF; vx = 0
	ax = (vx - prev_vx) / maxf(dt, 0.0001)

	# vertical
	var seg = segment_at(z)
	var ground_y: float = seg.y if seg else -999.0
	jump_buf -= dt
	if on_ground:
		coyote = 0.12
	else:
		coyote -= dt
	if jump_buf > 0:
		var power := 9.2 * (1.0 - minf(0.18, n * 0.012)) * (1.0 + 0.04 * count_type("sneakers") + 0.03 * count_type("balloon"))
		if on_ground or coyote > 0:
			vy = power; on_ground = false; coyote = 0; jump_buf = 0
			pitch_v -= 1.2
			play_sfx("jump")
			burst(Vector3(x, y + 0.1, z), 8, [Color("d9c7b5")], 3, 0.12, 1.5, 0.4, 6)
			if on_beat():
				var bonus := 10 * (1 + count_type("boombox"))
				pool += bonus
				omega *= 0.35
				beat_pulse = 0.35
				pop("В бит! +%d" % bonus, "neon", Vector3(x, y + 2.6, z))
				play_sfx("beat")
				if state == PLAY and not tut.beat:
					tut.beat = true
	if not on_ground:
		vy -= GRAV * dt
		var ny := y + vy * dt
		if seg and vy <= 0 and y >= ground_y - 0.05 and ny <= ground_y:
			y = ground_y
			on_ground = true
			omega += randf_range(-0.45, 0.45) * minf(1.5, -vy / 8.0)
			pitch_v += 1.6
			if vy < -9:
				shake = maxf(shake, 0.2)
				play_sfx("land")
				burst(Vector3(x, y + 0.1, z), 10, [Color("d9c7b5")], 4, 0.14, 1.5, 0.5, 6)
			vy = 0
		else:
			y = ny
	elif not seg:
		on_ground = false
	elif ground_y > y + 0.05:
		y = ground_y
		stumble("Споткнулся!")
	elif ground_y < y - 0.05:
		on_ground = false
	else:
		y = ground_y
	if y < -9:
		game_over("Сорвался!", ("Башня из %d вещей улетела в пропасть вместе с тобой." % tower.size()) if tower.size() else "Пропасть оказалась шире прыжка.")
		return

	# tower: inverted pendulum on the hero's back
	if n > 0:
		var L := 0.9 + tower_height() * 0.85
		var g := 9.8 * 0.55
		wind_t -= dt
		if wind_t <= 0:
			wind = randf_range(-0.5, 0.5) * (0.6 + hard * 1.6)
			wind_t = randf_range(1, 3)
		var stab := maxf(0.55, 1.0 - 0.12 * count_type("balloon")) * (1.0 + 0.1 * count_type("chain"))
		var inst := (g / L) * (0.35 + n * 0.12) * stab
		var alpha := inst * sin(theta) - (ax / L) * 0.3 * (1.0 + n * 0.06) * cos(theta) - 2.7 * omega + wind * (0.4 + n * 0.06) / L
		omega += alpha * dt
		theta += omega * dt
		if absf(theta) > TILT_MAX:
			drop_top(signf(theta))
			theta = signf(theta) * TILT_MAX * 0.55
			omega *= -0.3
	else:
		theta *= 0.9
		omega = 0
	pitch_v += (-pitch * 30.0 - pitch_v * 6.0) * dt
	pitch += pitch_v * dt
	var nt := tower.size()
	var share := 1.0 / nt if nt else 0.0
	for i in range(nt):
		var t: Dictionary = tower[i]
		var l: Node3D = t.link
		l.rotation.z = theta * share * (1.4 if i == 0 else 0.96)
		l.rotation.x = pitch * share * 0.6
		if t.pop > 0:
			t.pop -= dt
			t.item.scale = Vector3.ONE * (1.0 + maxf(0, t.pop) * 1.75)

	var tower_top := Vector3(x, y + 1.6, z)
	if tower.size():
		tower_top = tower[-1].link.global_position + Vector3(0, tower[-1].type.h * 0.5, 0)

	drone_timer -= dt
	if -z > 220 and drone_timer <= 0:
		add_drone()
		drone_timer = 8.0 - hard * 4.0 + randf() * 3.0

	_update_things(dt, fwd, tower_top)

	while gen_z > z - 190:
		gen_next()
	while segs.size() and segs[0].z1 - z > 30:
		segs[0].node.queue_free()
		segs.pop_front()

	_animate_hero(dt, fwd)
	if state == PLAY and not save.tutorial:
		_tutorial(dt, st)
	_update_camera(dt, fwd)


func _update_things(dt: float, fwd: float, tower_top: Vector3) -> void:
	var i := things.size() - 1
	while i >= 0:
		var t: Dictionary = things[i]
		var remove := false
		match t.kind:
			"pickup":
				var node: Node3D = t.node
				node.rotation.y += dt * 2.0
				node.position.y = t.y + sin(time * 3 + t.ph) * 0.12
				var reach := 1.05 + (0.9 if count_type("magnet") else 0.0)
				if reach > 1.1 and t.z < z + 1 and z - t.z < 7 and absf(t.x - x) < reach * 1.7:
					t.x += (x - t.x) * minf(1.0, dt * 5.0)
					node.position.x = t.x
				if absf(t.z - z) < 0.95 + (reach - 1.05) * 0.4 and absf(t.x - x) < reach and absf(t.y - (y + 1)) < 1.7:
					node.queue_free()
					things.remove_at(i)
					_collect(t)
					i -= 1
					continue
			"obstacle":
				if not t.hit and absf(t.z - z) < 0.75 and absf(t.x - x) < t.hw + 0.3 and y < t.y + t.h - 0.1:
					t.hit = true
					if dash > 0:
						t.kind = "falling"
						t["v"] = Vector3((t.x - x if t.x != x else 0.5) * 6, 6, -fwd * 0.9)
						t["spin"] = 8.0
						t["t"] = 0.0
						burst(Vector3(t.x, t.y + 0.6, t.z), 20, [Color("d9c7b5"), Color.WHITE, Color("ff5d7a")], 9, 0.18, 6, 0.8)
						pool += 15
						shake = 0.35
						omega += randf_range(-1.1, 1.1)
						pop("Таран! +15", "neon", Vector3(t.x, t.y + 2, t.z))
						play_sfx("smash")
						buzz(30)
					else:
						stumble("Бум!")
						omega += (1.0 if x > t.x else -1.0) * 1.6
			"gate":
				if not t.used and z < t.z:
					t.used = true
					if x < 0:
						bank_tower(Vector3(x, y + 2, z - 2))
					elif tower.size():
						pop("Рискуем! ×%s" % str(snappedf(multiplier(), 0.01)), "neon", Vector3(x, y + 2, z - 2))
						pool += 20 * tower.size()
			"drone":
				t.t += dt
				var node: Node3D = t.node
				for r in t.rotors:
					r.rotation.y += dt * 30
				node.position.y = t.y + sin(time * 2 + t.x) * 0.2
				node.look_at(Vector3(tower_top.x, node.position.y, tower_top.z), Vector3.UP, true)
				var d: float = t.z - z
				if t.st == "idle" and -d < 26:
					t.st = "aim"
					t.t = 0.0
					play_sfx("laser")
				if t.st == "aim":
					var a: Vector3 = node.global_position
					var length := a.distance_to(tower_top)
					var laser: MeshInstance3D = t.laser
					laser.visible = int(t.t * 14) % 2 == 0
					laser.global_position = a.lerp(tower_top, 0.5)
					laser.look_at(tower_top, Vector3.UP)
					laser.rotate_object_local(Vector3.RIGHT, PI / 2)
					laser.scale = Vector3(0.06, length, 0.06)
					t.eye.scale = Vector3.ONE * (0.28 + t.t * 0.4)
					if t.t > 0.8:
						t.st = "fired"
						laser.visible = false
						var bolt := MeshInstance3D.new()
						bolt.mesh = Kit.SPH
						bolt.material_override = Kit.neon(Color("ffd0dc"), 3.0)
						bolt.scale = Vector3.ONE * 0.35
						bolt.global_position = a
						world.add_child(bolt)
						bolt.global_position = a
						var aim := tower_top + Vector3(0, 0, -speed * 0.22)
						things.append({"kind": "bolt", "node": bolt, "v": (aim - a).normalized() * 30.0, "t": 0.0, "near": false, "paid": false})
						play_sfx("bolt")
				if d > 12:
					t.laser.queue_free()
					remove = true
			"bolt":
				t.t += dt
				var node: Node3D = t.node
				node.position += t.v * dt
				var dd := node.position.distance_to(tower_top)
				if dd < 0.9:
					burst(node.position, 16, [Color("ff5d7a"), Color.WHITE], 8, 0.14, 4, 0.5)
					var hp = null
					for tt in tower:
						if tt.type.id == "headphones" and not tt.spent:
							hp = tt
							break
					if hp:
						hp.spent = true
						pop("Шумоизоляция!", "neon", tower_top)
						play_sfx("near")
					elif tower.size():
						drop_top(signf(t.v.x) if t.v.x != 0 else 1.0)
						omega += signf(t.v.x) * 0.8
					else:
						stumble("Попали!")
					remove = true
				else:
					if dd < 2.2:
						t.near = true
					if t.near and dd > 2.2 and not t.paid:
						t.paid = true
						pool += 10
						pop("Мимо! +10", "neon", tower_top)
						play_sfx("near")
					if t.t > 2.5:
						remove = true
			"falling":
				t.t += dt
				var node: Node3D = t.node
				t.v.y -= GRAV * 0.8 * dt
				node.position += t.v * dt
				node.rotation.x += t.spin * dt
				node.rotation.z += t.spin * 0.7 * dt
				if t.t > 2.2:
					remove = true
		if not remove and t.has("z") and t.kind != "falling" and t.z - z > 14:
			remove = true
			if t.has("laser") and is_instance_valid(t.laser):
				t.laser.queue_free()
		if remove:
			if is_instance_valid(t.node):
				t.node.queue_free()
			things.remove_at(i)
		i -= 1


func _collect(t: Dictionary) -> void:
	var type: Dictionary = t.type
	add_to_tower(type)
	combo = combo + 1 if combo_t > 0 else 1
	combo_t = 2.6
	if count_type("player") and randf() < 0.25 * count_type("player"):
		pool += 15
		get_tree().create_timer(0.25).timeout.connect(func(): pop("Хит! +15", "neon"))
	if count_type("notebook") and last_pick == type.id:
		var rb := 20 * count_type("notebook")
		pool += rb
		get_tree().create_timer(0.45).timeout.connect(func(): pop("Рифма! +%d" % rb, "neon"))
	last_pick = type.id
	if combo >= 2:
		pool += combo * 5 * (2 if count_type("mic") else 1)
	var label: String = "+" + type.name + ((" · " + type.tag) if type.tag != "" else "")
	pop(label, "neon" if type.tag != "" else "good", Vector3(x, y + 2.2, z))
	burst(Vector3(t.x, t.y, t.z), 14, [Kit.GOLD, Color.WHITE, Kit.TEAL], 6, 0.12, 5, 0.6, 10)
	play_sfx("pickup", 1.0 + minf(combo, 8) * 0.04)


func stumble(text: String) -> void:
	if stumble_t > 0:
		return
	stumble_t = 0.55
	omega += 1.4 if randf() < 0.5 else -1.4
	pitch_v += 3.0
	shake = 0.45
	if tower.size():
		drop_top()
	pop(text, "bad", Vector3(x, y + 2.4, z))
	play_sfx("stumble")
	buzz(60)


func _animate_hero(dt: float, fwd: float) -> void:
	var moving := on_ground
	phase += dt * fwd * (1.2 if moving else 0.0)
	var sw := sin(phase) * 0.95 if moving else 0.0
	var legs: Array = hero.legs
	var arms: Array = hero.arms
	legs[0].rotation.x = sw if moving else -0.6
	legs[1].rotation.x = -sw if moving else 0.4
	arms[0].rotation.x = -sw * 0.9 if moving else -2.6
	arms[1].rotation.x = sw * 0.9 if moving else -2.6
	var body: Node3D = hero.body
	body.position.y = absf(cos(phase)) * 0.09 if moving else 0.0
	body.rotation.z = -vx * 0.035 - theta * 0.15
	body.rotation.x = 0.14 + (0.3 if dash > 0 else 0.0) + (0.35 if stumble_t > 0 else 0.0)
	if dance_t > 0:
		dance_t -= dt
		var w := sin(time * 18.0)
		arms[0].rotation.x = -2.7 + w * 0.3
		arms[1].rotation.x = -2.7 - w * 0.3
		arms[0].rotation.z = 0.3 * w
		arms[1].rotation.z = 0.3 * w
	else:
		arms[0].rotation.z = 0
		arms[1].rotation.z = 0
	if hero.speaker:
		var ph := beat_phase()
		var k := 1.0 + maxf(0, 0.18 - minf(ph, 1 - ph)) * 1.4 + maxf(0, beat_pulse)
		hero.speaker.scale = Vector3.ONE * k
		if moving:
			body.position.y += maxf(0, 0.05 - minf(ph, 1 - ph) * 0.2)
	beat_pulse = maxf(0, beat_pulse - dt)
	hero.root.position = Vector3(x, y, z)
	rocket_t = maxf(0, rocket_t - dt)
	hero.flame.visible = dash > 0
	hero.flame.scale.y = 0.45 + randf() * 0.3


func _update_camera(dt: float, fwd: float) -> void:
	var th := minf(6.0, tower_height())
	var cx := x * 0.55
	var cy := y + 3.5 + th * 0.45
	var cz := z + 6.4 + th * 0.55 + (1.2 if dash > 0 else 0.0)
	var k := minf(1.0, dt * 5.0)
	cam_x += (cx - cam_x) * k
	cam_y += (cy - cam_y) * k * 0.8
	shake = maxf(0, shake - dt)
	var sh := shake * shake * 1.6
	cam.position = Vector3(cam_x + randf_range(-0.5, 0.5) * sh, cam_y + randf_range(-0.5, 0.5) * sh, cz)
	cam.look_at(Vector3(x * 0.4, y + 1.5 + th * 0.4, z - 6), Vector3.UP)
	cam.rotate_object_local(Vector3.FORWARD, vx * 0.006)
	fov_kick = maxf(0, fov_kick - dt * 18)
	var vs := get_viewport().get_visible_rect().size
	var base := 78.0 if vs.x < vs.y else 62.0
	var fov := base + minf(10.0, maxf(0, fwd - 11) * 0.9) + fov_kick
	cam.fov += (fov - cam.fov) * minf(1.0, dt * 6.0)
	speed_lines.emitting = state == PLAY and (fwd > 16.0 or dash > 0)
	var bdn := get_node_or_null("Backdrop")
	if bdn:
		bdn.position.z = floorf(z / 9.0) * 9.0


func _update_hud() -> void:
	var gate := INF
	for t in things:
		if t.kind == "gate" and not t.used and t.z < z:
			gate = minf(gate, z - t.z)
	var sum := 0
	for t in tower:
		sum += t.type.value
	var ab := []
	if count_type("mic"): ab.append("Фристайл ×2")
	if count_type("boombox"): ab.append("Бит ×%d" % (1 + count_type("boombox")))
	if count_type("tablet"): ab.append("Стрим +%d★/с" % (2 * count_type("tablet")))
	var live := 0
	for t in tower:
		if t.type.id == "headphones" and not t.spent:
			live += 1
	if live: ab.append("Шумоизоляция ×%d" % live)
	if count_type("notebook"): ab.append("Рифмы")
	if count_type("player"): ab.append("Шафл")
	if count_type("spray"): ab.append("Тег +%d%%" % (10 * count_type("spray")))
	ui.set_hud({
		"dist": int(round(-z)), "spd": int(round(speed * 3.6)), "bank": bank, "tcount": tower.size(),
		"tmult": multiplier(), "tval": int(round(sum * multiplier() + pool)),
		"gate": "скоро" if gate == INF else "%d м" % int(round(gate)),
		"tilt": theta / TILT_MAX, "combo": combo, "abil": " · ".join(ab),
		"dash_ready": 1.0 - maxf(0, dash_cd) / 2.6,
	})
	var ph := beat_phase()
	ui.set_beat(ph < 0.16 or ph > 0.94)


func _tutorial(dt: float, st: float) -> void:
	tut.t += dt
	if tut.stage == 0:
		if tut.t > 0.6 and tut.t < 0.7:
			ui.tip("Веди пальцем по левой половине экрана — бег влево-вправо")
		if absf(st) > 0.4:
			tut.steer_t += dt
		if tut.steer_t > 0.7:
			tut.stage = 1
			ui.hide_tip()
	elif tut.stage == 1 and tower.size() > 0:
		tut.stage = 2
		ui.tip("Вещи растут башней за спиной. Следи за шкалой крена и подбегай под башню", 5.0)
	if tut.stage >= 2 and not tut.beat and tut.t > 14:
		tut.beat = true
		ui.tip("Прыгай в бит: кнопка «Прыжок» и колонка на спине мигают в ритм", 5.0)
	if not tut.gap and on_ground and segment_at(z - 13) == null and segment_at(z) != null:
		tut.gap = true
		ui.tip("Пропасть впереди — жми «Прыжок»!", 2.5)
	if not tut.gate:
		for t in things:
			if t.kind == "gate" and not t.used and t.z < z and z - t.z < 45:
				tut.gate = true
				ui.tip("Ворота! Беги в левый проход, чтобы сдать добычу в банк", 4.0)
				break


# ================================================================== automated test (used by CI)
func _autotest() -> void:
	await get_tree().create_timer(3.5).timeout
	start_run()
	var k := 0
	var errors := 0
	while k < 600:
		await get_tree().process_frame
		k += 1
		steer = sin(k * 0.05)
		if segment_at(z - 4.0) == null and on_ground:
			request_jump()
		if k % 90 == 0:
			request_dash()
		if state == OVER:
			start_run()
	print("AUTOTEST_DONE dist=%d tower=%d segs=%d things=%d state=%d" % [int(-z), tower.size(), segs.size(), things.size(), state])
	get_tree().quit()
