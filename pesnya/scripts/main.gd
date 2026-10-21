extends Node3D
## «Песня» — офлайн-версия (студия Aolovo).
## Двор «Берёзки» + ГК «Песня»: бой под бит, мобы, добыча, квесты, база в гараже, робот Вася, магазин, ежедневные задания, сохранения.

const BPM := 96.0
var beat_len := 60.0 / BPM
var beat_win := 0.13

enum { MENU, SELECT, LOADING, PLAY, DIALOG, BAG, PAUSE, DEAD, LIST }
var state := MENU
var time := 0.0

var hud: Hud
var cam: Camera3D
var we: WorldEnvironment
var env_world: Environment
var env_studio: Environment
var sun: DirectionalLight3D
var rim: DirectionalLight3D
var studio_lights: Array = []
var stage: Node3D
var stage_hero: Dictionary
var world: Dictionary = {}
var fx_root: Node3D

var race := "rapper"
var cls := "cop"
var hero_name := ""
var portrait: Texture2D

# ---------------------------------------------------------------- player
var hero: Dictionary
var pos := Vector3(0, 0, 12)
var facing := PI
var hp := 300.0
var hp_max := 300.0
var vibe := 0.0
var level := 1
var xp := 0
var coins := 0
var power := 0
var combo := 0
var combo_t := 0.0
var idle_t := 0.0
var walk_phase := 0.0
var attack_anim := 0.0
var dash_t := 0.0
var dash_dir := Vector3.ZERO
var dash_aoe := false
var buff_t := 0.0
var heal_left := 0.0
var invuln := 0.0
var pull_v := Vector3.ZERO
var cd := {"attack": 0.0, "s1": 0.0, "s2": 0.0, "s3": 0.0, "food": 0.0}
var cd_max := {"attack": 0.42, "s1": 7.0, "s2": 9.0, "s3": 5.0, "food": 8.0}
var dead_t := 0.0

# ---------------------------------------------------------------- camera & input
var yaw := 0.0
var pitch := 0.42
var dist := 7.6
var cam_touch_t := 0.0
var joy_idx := -1
var joy_origin := Vector2.ZERO
var joy_vec := Vector2.ZERO
var cam_idx := -1
var cam_last := Vector2.ZERO
var cam_start := Vector2.ZERO
var cam_start_t := 0.0
var btn_touch := {}

# ---------------------------------------------------------------- world entities
var map_id := "yard"
var mobs: Array = []
var loots: Array = []
var shots: Array = []
var fx: Array = []
var npcs: Array = []
var target = null
var current_interact = null
var portal_cd := 0.0
var robot_vis: Dictionary = {}
var robot_walk := 0.0
var slot_nodes := {}

const SLOT_SHORT := {"grill": "Мангал", "garden": "Огород", "gym": "Качалка", "stage": "Сцена", "studio": "Студия", "solar": "Панели"}
const NPC_INFO := {
	"zina": ["Баба Зина", "квесты двора", "Говорить"],
	"misha": ["Дядя Миша", "дворник · ежедневные задания", "Задания"],
	"lyuba": ["Люба", "ларёк «Шаурма»", "Ларёк"],
	"petrovich": ["Петрович", "председатель ГК", "Говорить"],
}

# ---------------------------------------------------------------- progress (saved)
var quest := 0          # 0 none, 1 kill 6, 2 feather, 3 Pakhan, 4 return, 5 done
var quest_kills := 0
var feather_kills := 0
var quest2 := 0         # 0 none, 1 find Petrovich, 2 send robot, 3 collect, 4 build grill, 5 return, 6 done
var inventory: Array = []
var equipped := {}
var res := {"brick": 0, "cement": 0, "planks": 0, "wires": 0}
var food := 0
var buildings := {"grill": 0, "garden": 0, "gym": 0, "stage": 0, "studio": 0, "solar": 0}
var b_since := {"grill": 0.0, "garden": 0.0}
var robot_task := {"task": "", "start": 0.0, "end": 0.0, "told": false}
var daily := {"date": "", "pigeon": 0, "scooter": 0, "vacuum": 0, "claimed": []}
var time_shift := 0.0     # debug fast-forward (autotest only)
var save_t := 0.0
var list_kind := ""
var list_arg := ""

# ---------------------------------------------------------------- audio & settings
var music: AudioStreamPlayer
var run_stream: AudioStream
var menu_stream: AudioStream
var sfx := {}
var sfx_players: Array = []
var music_on := true
var beat_offset := 0.0
var quality := 1
var autotest := false
var save_path := GameData.SAVE_PATH


func _ready() -> void:
	Kit.init()
	randomize()
	Engine.max_fps = 60
	autotest = OS.get_cmdline_user_args().has("--autotest")
	if autotest:
		save_path = "user://pesnya_autotest.json"
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	_setup_audio()
	_setup_env()
	_load_settings_only()
	fx_root = Node3D.new()
	add_child(fx_root)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(self)
	get_viewport().size_changed.connect(func(): hud.size = get_viewport().get_visible_rect().size)
	hud.size = get_viewport().get_visible_rect().size
	_build_stage()
	_play_music(menu_stream)
	to_menu()
	if autotest:
		_run_autotest()


func now() -> float:
	return Time.get_unix_time_from_system() + time_shift


# ================================================================== environment
func _setup_env() -> void:
	env_world = Environment.new()
	env_world.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color("4a7ac8")
	psm.sky_horizon_color = Color("ffc08a")
	psm.sky_curve = 0.12
	psm.ground_horizon_color = Color("ffc08a")
	psm.ground_bottom_color = Color("3a3040")
	psm.sun_angle_max = 20.0
	psm.sun_curve = 0.1
	sky.sky_material = psm
	env_world.sky = sky
	env_world.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_world.ambient_light_color = Color("8a9ac8")
	env_world.ambient_light_energy = 0.68
	env_world.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_world.tonemap_white = 6.0
	env_world.glow_enabled = true
	env_world.glow_intensity = 0.8
	env_world.glow_bloom = 0.05
	env_world.glow_hdr_threshold = 0.9
	env_world.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env_world.fog_enabled = true
	env_world.fog_light_color = Color("e8b8a0")
	env_world.fog_density = 0.006
	env_world.fog_sky_affect = 0.3
	env_world.adjustment_enabled = true
	env_world.adjustment_saturation = 1.12
	env_world.adjustment_contrast = 1.05

	env_studio = Environment.new()
	env_studio.background_mode = Environment.BG_COLOR
	env_studio.background_color = Color("120e22")
	env_studio.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_studio.ambient_light_color = Color("6a5a9a")
	env_studio.ambient_light_energy = 0.6
	env_studio.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_studio.glow_enabled = true
	env_studio.glow_intensity = 1.0
	env_studio.glow_hdr_threshold = 0.9
	env_studio.fog_enabled = true
	env_studio.fog_light_color = Color("1a1430")
	env_studio.fog_density = 0.03

	we = WorldEnvironment.new()
	we.environment = env_studio
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.light_color = Color("ffcc90")
	sun.light_energy = 1.8
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 34.0
	sun.shadow_blur = 1.2
	sun.rotation_degrees = Vector3(-24, 205, 0)
	sun.visible = false
	add_child(sun)
	rim = DirectionalLight3D.new()
	rim.light_color = Color("9ad0ff")
	rim.light_energy = 0.35
	rim.rotation_degrees = Vector3(-30, -20, 0)
	rim.visible = false
	add_child(rim)
	cam = Camera3D.new()
	cam.far = 260
	cam.fov = 60
	add_child(cam)


func set_quality(q: int) -> void:
	quality = q
	sun.shadow_enabled = q == 1
	env_world.glow_enabled = q == 1
	get_viewport().msaa_3d = Viewport.MSAA_2X if q == 1 else Viewport.MSAA_DISABLED


# ================================================================== audio
func _setup_audio() -> void:
	run_stream = load("res://audio/music_run.ogg")
	menu_stream = load("res://audio/music_menu.ogg")
	if run_stream is AudioStreamOggVorbis:
		run_stream.loop = true
	if menu_stream is AudioStreamOggVorbis:
		menu_stream.loop = true
	music = AudioStreamPlayer.new()
	music.volume_db = -4.0
	add_child(music)
	for n in ["jump", "pickup", "drop", "bank", "beat", "laser", "bolt", "stumble", "dash", "smash", "land", "near", "over", "ui"]:
		sfx[n] = load("res://audio/sfx_%s.ogg" % n)
	for i in range(10):
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
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
	if on:
		_play_music(run_stream if in_world() else menu_stream)
	else:
		music.stop()


func play_sfx(n: String, pitch_scale := 1.0, vol := 0.0) -> void:
	if not sfx.has(n):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sfx[n]
			p.pitch_scale = pitch_scale
			p.volume_db = -6.0 + vol
			p.play()
			return


func beat_time() -> float:
	if music.playing and music.stream == run_stream:
		return music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() - beat_offset
	return time - beat_offset


func beat_phase() -> float:
	return fposmod(beat_time() / beat_len, 1.0)


func beat_index() -> int:
	return int(floor(beat_time() / beat_len))


func on_beat() -> bool:
	var ph := beat_phase()
	return minf(ph, 1.0 - ph) * beat_len < beat_win



# ================================================================== menu / select stage
func _build_stage() -> void:
	stage = Node3D.new()
	stage.position = Vector3(0, 0, 400)
	add_child(stage)
	Kit.part(stage, Kit.BOX, Kit.mat(Color("1a1626"), 0.25, 0.4), Vector3(60, 0.2, 60), Vector3(0, -0.1, 0))
	for i in range(9):
		var a := -1.2 + i * 0.3
		var n := Node3D.new()
		n.position = Vector3(sin(a) * 14, 0, -cos(a) * 14 - 2)
		stage.add_child(n)
		n.look_at_from_position(n.position, Vector3(0, 0, 0), Vector3.UP)
		Kit.part(n, Kit.BOX, Kit.mat(Color("221a3a"), 0.6), Vector3(3.8, 12, 0.3), Vector3(0, 6, 0))
		Kit.part(n, Kit.BOX, Kit.neon([Kit.TEAL, Color("c38bff"), Kit.GOLD][i % 3], 2.5), Vector3(0.12, 10, 0.05), Vector3(1.7, 6, -0.2))
	Kit.part(stage, Kit.CYL, Kit.mat(Color("2a2440"), 0.2, 0.6), Vector3(3.6, 0.3, 3.6), Vector3(0, 0.15, 0))
	Chars.ring(stage, Vector3(0, 0.31, 0), 1.8, Kit.GOLD, 0.05, 4.0)
	Chars.ring(stage, Vector3(0, 0.31, 0), 1.6, Kit.TEAL, 0.03, 3.0)
	var cast := [Chars.gopnik(), Chars.goth(), Chars.hipster(), Chars.granny_tank(), Chars.it_mage()]
	var xs := [-4.6, -3.0, 3.0, 4.6, 6.1]
	for i in range(cast.size()):
		var c: Dictionary = cast[i]
		stage.add_child(c.root)
		c.root.position = Vector3(xs[i] if i < 4 else -6.1, 0, -3.0 - absf(xs[i]) * 0.15)
		Chars.pose(c, {"ra": Vector3(0.1, 0, 0.15), "la": Vector3(0.1, 0, -0.15)})
		if c.has("shield"):
			c.shield.visible = false
		Kit.bake_tree(c.root)
	Kit.bake_tree(stage)
	for l in [[Vector3(0, 8, 3), Color("fff0e0"), 7.0], [Vector3(-4, 6, 2), Kit.TEAL, 4.0], [Vector3(4, 6, 2), Color("ff8ad8"), 4.0]]:
		var sp := SpotLight3D.new()
		stage.add_child(sp)
		sp.position = l[0]
		sp.look_at(stage.global_position + Vector3(0, 1, 0), Vector3.UP)
		sp.light_color = l[1]
		sp.light_energy = l[2]
		sp.spot_range = 16
		sp.spot_angle = 26
		studio_lights.append(sp)
	var key := DirectionalLight3D.new()
	key.light_color = Color("ffe0c0")
	key.light_energy = 1.0
	key.rotation_degrees = Vector3(-35, 20, 0)
	stage.add_child(key)
	studio_lights.append(key)
	_rebuild_stage_hero()


func _rebuild_stage_hero() -> void:
	if stage_hero.has("root"):
		stage_hero.root.queue_free()
	stage_hero = Chars.hero(race, cls)
	stage.add_child(stage_hero.root)
	stage_hero.root.position = Vector3(0, 0.3, 0)
	stage_hero.root.rotation.y = -0.35
	Chars.pose(stage_hero, {"ra": Vector3(-0.3, 0, 0.2), "la": Vector3(-2.6, 0, -0.3), "head": Vector3(0, 0.2, 0)})


func _stage_cam() -> void:
	cam.global_position = stage.global_position + Vector3(0, 1.6, 6.4)
	cam.fov = 48
	cam.look_at(stage.global_position + Vector3(0, 1.3, -1.0), Vector3.UP)



func _show_only(panel: Control) -> void:
	for p in [hud.menu_panel, hud.select_panel, hud.dialog_panel, hud.bag_panel, hud.pause_panel, hud.dead_panel, hud.loading_panel, hud.list_panel]:
		p.visible = p == panel


func to_menu() -> void:
	get_tree().paused = false
	if world.has("root"):
		save_game()
		_clear_world()
	state = MENU
	we.environment = env_studio
	sun.visible = false
	rim.visible = false
	stage.visible = true
	for l in studio_lights:
		l.visible = true
	var summary := _save_summary()
	hud.menu_continue.visible = summary != ""
	hud.menu_continue.text = "ПРОДОЛЖИТЬ · " + summary
	hud.menu_new.text = "НОВЫЙ ГЕРОЙ" if summary != "" else "ИГРАТЬ"
	if summary != "":
		_secondary_style(hud.menu_new)
	if stage_hero.has("root"):
		_rebuild_stage_hero()
	_stage_cam()
	_show_only(hud.menu_panel)
	_play_music(menu_stream)


func _secondary_style(b: Button) -> void:
	hud._secondary(b)


func open_select() -> void:
	state = SELECT
	_show_only(hud.select_panel)
	hud.refresh_select()
	if _save_summary() != "":
		hud.toast("Новый герой заменит сохранение", Hud.CREAM)


func set_combo(r: String, c: String) -> void:
	race = r
	cls = c
	_rebuild_stage_hero()
	hud.refresh_select()


func combo_label() -> String:
	return ("Рэпер" if race == "rapper" else "Панк") + " · " + ("Коп" if cls == "cop" else "Медик")


func skill_info() -> Array:
	if cls == "cop":
		return [["cuffs", "Протокол"], ["siren", "Сирена"], ["dash", "Рывок"]]
	return [["heal", "Аккорд жизни"], ["needle", "Панк-укол"], ["dash", "Стейдждайв"]]


func continue_game() -> void:
	if not load_game():
		hud.toast("Сохранение не читается — начнём заново", Hud.CREAM)
		open_select()
		return
	_rebuild_stage_hero()
	await get_tree().process_frame
	start_game(false)


func start_game(new_game := true) -> void:
	if new_game:
		_reset_progress()
	hero_name = Chars.HERO_NAMES[race + "_" + cls]
	_stage_cam()
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if img != null:
		_grab_portrait(img)
	await _travel(map_id, "start")
	if new_game:
		hud.big("Двор «Берёзки»", "Найди бабу Зину — у неё есть дело", 3.0)
	else:
		hud.big(world.name, "С возвращением, %s!" % hero_name, 2.5)
	save_game()


func _grab_portrait(img: Image) -> void:
	var hp3: Vector3 = stage_hero.head.global_position
	var sp := cam.unproject_position(hp3)
	var vs := get_viewport().get_visible_rect().size
	var scale := float(img.get_width()) / vs.x
	var r := int(70 * scale)
	var cx := int(sp.x * scale)
	var cy := int(sp.y * scale)
	if cx - r >= 0 and cy - r >= 0 and cx + r < img.get_width() and cy + r < img.get_height():
		var crop := img.get_region(Rect2i(cx - r, cy - r, r * 2, r * 2))
		crop.resize(96, 96)
		portrait = ImageTexture.create_from_image(crop)


func _reset_progress() -> void:
	level = 1
	xp = 0
	coins = 0
	power = 0
	vibe = 0.0
	combo = 0
	inventory.clear()
	equipped.clear()
	quest = 0
	quest_kills = 0
	feather_kills = 0
	quest2 = 0
	res = {"brick": 0, "cement": 0, "planks": 0, "wires": 0}
	food = 1
	buildings = {"grill": 0, "garden": 0, "gym": 0, "stage": 0, "studio": 0, "solar": 0}
	b_since = {"grill": 0.0, "garden": 0.0}
	robot_task = {"task": "", "start": 0.0, "end": 0.0, "told": false}
	daily = {"date": "", "pigeon": 0, "scooter": 0, "vacuum": 0, "claimed": []}
	map_id = "yard"
	_recalc_stats()
	hp = hp_max


# ================================================================== save / load
func _save_dict() -> Dictionary:
	var inv := []
	for it in inventory:
		inv.append(it.id)
	var eq := {}
	for s in equipped:
		eq[s] = inventory.find(equipped[s])
	return {"ver": GameData.SAVE_VERSION, "race": race, "cls": cls, "level": level, "xp": xp, "coins": coins, "inv": inv, "eq": eq,
		"quest": quest, "quest_kills": quest_kills, "feather_kills": feather_kills, "quest2": quest2, "res": res, "food": food,
		"buildings": buildings, "b_since": b_since, "robot": robot_task, "daily": daily, "map": map_id,
		"settings": {"music": music_on, "quality": quality, "beat_offset": beat_offset}, "saved_at": now()}


func save_game() -> void:
	if not world.has("root") and state != MENU:
		return
	if hero_name == "":
		return
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(_save_dict()))
	f.close()
	save_t = 0.0


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


func _save_summary() -> String:
	var d := _read_save()
	if d.is_empty() or not d.has("race"):
		return ""
	var n: String = Chars.HERO_NAMES.get(str(d.race) + "_" + str(d.cls), "Герой")
	return "%s · ур. %d" % [n, int(d.get("level", 1))]


func _load_settings_only() -> void:
	var d := _read_save()
	if d.has("settings"):
		music_on = bool(d.settings.get("music", true))
		quality = int(d.settings.get("quality", 1))
		beat_offset = float(d.settings.get("beat_offset", 0.0))


func load_game() -> bool:
	var d := _read_save()
	if d.is_empty() or not d.has("race"):
		return false
	race = str(d.race)
	cls = str(d.cls)
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	coins = int(d.get("coins", 0))
	quest = int(d.get("quest", 0))
	quest_kills = int(d.get("quest_kills", 0))
	feather_kills = int(d.get("feather_kills", 0))
	quest2 = int(d.get("quest2", 0))
	food = int(d.get("food", 0))
	map_id = str(d.get("map", "yard"))
	if map_id not in ["yard", "garages"]:
		map_id = "yard"
	for k in res:
		res[k] = int(d.get("res", {}).get(k, 0))
	for k in buildings:
		buildings[k] = clampi(int(d.get("buildings", {}).get(k, 0)), 0, 3)
	for k in b_since:
		b_since[k] = float(d.get("b_since", {}).get(k, 0.0))
	var rt: Dictionary = d.get("robot", {})
	robot_task = {"task": str(rt.get("task", "")), "start": float(rt.get("start", 0.0)), "end": float(rt.get("end", 0.0)), "told": bool(rt.get("told", false))}
	var dl: Dictionary = d.get("daily", {})
	daily = {"date": str(dl.get("date", "")), "pigeon": int(dl.get("pigeon", 0)), "scooter": int(dl.get("scooter", 0)), "vacuum": int(dl.get("vacuum", 0)), "claimed": dl.get("claimed", [])}
	inventory.clear()
	equipped.clear()
	for id in d.get("inv", []):
		if GameData.ITEMS.has(id):
			var it: Dictionary = GameData.ITEMS[id].duplicate()
			it["id"] = id
			inventory.append(it)
	var eq: Dictionary = d.get("eq", {})
	for s in eq:
		var i := int(eq[s])
		if i >= 0 and i < inventory.size():
			equipped[s] = inventory[i]
	_recalc_power()
	_recalc_stats()
	hp = hp_max
	return true


# ================================================================== maps
func _travel(to: String, spawn: String) -> void:
	state = LOADING
	hud.loading_title.text = "Загружаем %s…" % ("двор «Берёзки»" if to == "yard" else "ГК «Песня»")
	_show_only(hud.loading_panel)
	await get_tree().process_frame
	await get_tree().process_frame
	_enter_map(to, spawn)
	state = PLAY
	_show_only(null)
	portal_cd = 1.2


func _enter_map(id: String, spawn: String) -> void:
	_clear_world()
	map_id = id
	stage.visible = false
	for l in studio_lights:
		l.visible = false
	we.environment = env_world
	sun.visible = true
	rim.visible = true
	set_quality(quality)
	world = World.build_yard(self) if id == "yard" else Base.build_garages(self)
	hero = Chars.hero(race, cls)
	world.root.add_child(hero.root)
	Kit.bake_tree(hero.root)
	var sp: Array = world.spawns.get(spawn, world.spawns.start)
	pos = sp[0]
	facing = sp[1]
	yaw = facing + PI
	target = null
	_recalc_stats()
	if cls == "cop":
		cd_max = {"attack": 0.42, "s1": 7.0, "s2": 9.0, "s3": 5.0, "food": 8.0}
	else:
		cd_max = {"attack": 0.42, "s1": 9.0, "s2": 15.0, "s3": 6.0, "food": 8.0}
	for k in cd:
		cd[k] = 0.0
	for n in world.npcs:
		_spawn_npc(n.id, n.pos, n.rot)
	for e in world.mobs:
		_spawn_mob(e[0], e[1], e[2])
	if id == "yard" and quest == 3:
		_spawn_mob("pakhan", Vector3(0, 0, -24), 7)
	if id == "garages":
		for sid in world.anchors:
			_refresh_slot(sid)
		_refresh_robot()
	_play_music(run_stream)
	_check_daily_reset()


func _spawn_npc(id: String, at: Vector3, rot: float) -> void:
	var h: Dictionary
	match id:
		"zina": h = Chars.granny_npc()
		"misha": h = Chars.misha_npc()
		"lyuba": h = Chars.lyuba_npc()
		_: h = Chars.petrovich_npc()
	world.root.add_child(h.root)
	h.root.position = at
	h.root.rotation.y = rot
	Kit.bake_tree(h.root)
	var info: Array = NPC_INFO[id]
	npcs.append({"id": id, "name": info[0], "role": info[1], "act": info[2], "pos": at, "node": h.root, "body": h.body, "head": h.head})


func _spawn_mob(kind: String, at: Vector3, lvl: int) -> Dictionary:
	var d: Dictionary = GameData.MOBS[kind]
	var model: Dictionary
	match kind:
		"pigeon": model = Chars.pigeon(true, false)
		"pakhan": model = Chars.pigeon(true, true)
		"scooter": model = Chars.scooter()
		_: model = Chars.vacuum()
	world.root.add_child(model.root)
	Kit.bake_tree(model.root)
	var sc: float = d.scale
	model.root.scale = Vector3.ONE * sc
	var m := {
		"kind": kind, "node": model.root, "body": model.body, "head": model.head, "wings": model.get("wings", []), "wheels": model.get("wheels", []),
		"pos": at, "home": at, "yaw": randf() * TAU, "lvl": lvl, "scale": sc, "name": d.name,
		"hp_max": d.hp[0] + d.hp[1] * lvl, "dmg": d.dmg[0] + d.dmg[1] * lvl, "xp": d.xp[0] + d.xp[1] * lvl,
		"height": d.height * sc, "radius": d.radius * sc, "speed": d.speed, "aggro": d.aggro, "leash": d.leash, "atk": d.atk,
		"st": "idle", "t": randf() * 3.0, "atk_cd": 1.0, "stun": 0.0, "alive": true, "respawn": 0.0,
		"wander": at, "flap": 0.0, "hit": 0.0, "special": 4.0, "tele": null, "tele_t": 0.0, "summoned": false, "dead_t": 0.0,
		"charge_t": 0.0, "charge_dir": Vector3.ZERO, "pull_cd": 3.0, "temp": false,
	}
	m.hp = m.hp_max
	model.root.position = at
	mobs.append(m)
	return m


func _clear_world() -> void:
	for m in mobs:
		if m.tele and is_instance_valid(m.tele):
			m.tele.queue_free()
	mobs.clear()
	for l in loots:
		l.node.queue_free()
	loots.clear()
	for s in shots:
		s.node.queue_free()
	shots.clear()
	for f in fx:
		if is_instance_valid(f.node):
			f.node.queue_free()
	fx.clear()
	npcs.clear()
	robot_vis = {}
	slot_nodes = {}
	if world.has("root"):
		world.root.queue_free()
	world = {}
	target = null
	current_interact = null


func in_world() -> bool:
	return state in [PLAY, DIALOG, BAG, PAUSE, DEAD, LIST]


# ================================================================== stats
func _bval(id: String) -> float:
	var l: int = buildings[id]
	if l <= 0:
		return 0.0
	return GameData.BUILDINGS[id].value[l - 1]


func _recalc_stats() -> void:
	var ratio := hp / hp_max if hp_max > 0 else 1.0
	hp_max = (300.0 + (level - 1) * 45.0) * (1.2 if race == "punk" else 1.0) * (1.0 + _bval("gym"))
	hp = clampf(hp_max * ratio, 1.0, hp_max)


func _recalc_power() -> void:
	power = 0
	for s in equipped:
		power += equipped[s].power


func res_line() -> String:
	var p := []
	for k in GameData.RES_ORDER:
		p.append("%s %d" % [GameData.RES_NAMES[k], res[k]])
	return " · ".join(p)


# ================================================================== quests
func quest_lines() -> Array:
	var out: Array = []
	if quest < 5:
		match quest:
			0: out = ["Двор «Берёзки»", "Найди бабу Зину у лавочки (жёлтая «!»)"]
			1: out = ["Голубиная мафия", "Разогнать голубей: %d / 6" % quest_kills, "Совет: бей в бит — урон ×2"]
			2: out = ["Голубиная мафия", "Найти Перо удачи у голубей", "Оно светится фиолетовым"]
			3: out = ["Голубиная мафия", "Победить Голубиного Пахана", "У гаражей. Не стой в красном круге!"]
			4: out = ["Голубиная мафия", "Вернуться к бабе Зине"]
	elif quest2 < 6:
		match quest2:
			0: out = ["Голубиная мафия · готово", "Поговори с бабой Зиной"]
			1: out = ["Свой гараж", "Найди Петровича в ГК «Песня»", "Арка «ГК Песня» справа у гаражей"]
			2: out = ["Свой гараж", "Отправь Васю за покупками", "Робот стоит у бокса №40"]
			3:
				var left: float = robot_task.end - now()
				out = ["Свой гараж", "Дождись Васю: %s" % _mmss(left) if left > 0 else "Забери покупки у Васи", "Таймер идёт, даже если игра закрыта"]
			4: out = ["Свой гараж", "Построй мангал у бокса №40", "Нужно: 6 досок, 4 кирпича, 60 монет"]
			5: out = ["Свой гараж", "Вернись к Петровичу"]
	else:
		out = ["Свободная игра", "Улучшай базу, отправляй Васю", "Скоро: подземелье «Стройка»"]
	var done := _daily_ready_count()
	var finished: int = daily.claimed.size()
	if quest >= 1:
		out.append("Ежедневные дяди Миши: %d/3%s" % [finished, (" · можно забрать: %d" % done) if done > 0 else ""])
	return out


func npc_marker(id: String) -> String:
	match id:
		"zina":
			if quest == 0 or (quest == 5 and quest2 == 0):
				return "!"
			if quest == 4:
				return "?"
		"petrovich":
			if quest2 == 1 or (quest2 == 0 and quest >= 5):
				return "!"
			if quest2 == 5:
				return "?"
		"misha":
			if _daily_ready_count() > 0:
				return "?"
			if quest >= 1 and daily.claimed.size() == 0 and daily.pigeon + daily.scooter + daily.vacuum == 0:
				return "!"
	return ""


func world_labels() -> Array:
	var out := []
	if not world.has("root"):
		return out
	for pt in world.portals:
		out.append([pt.pos + Vector3(0, 2.2, 0), "→ " + pt.label, 18, Hud.TEAL])
	if map_id == "garages" and quest2 >= 2:
		var t: String
		var col := Hud.CREAM
		if robot_task.task == "":
			t = "Вася ждёт поручение"
		elif now() < robot_task.end:
			t = "Вася в пути: %s" % _mmss(robot_task.end - now())
		else:
			t = "Вася вернулся!"
			col = Hud.GOLD
		var rp: Vector3 = Base.ROBOT_HOME + Vector3(0, 2.9, 0)
		out.append([rp, t, 16, col])
		if buildings.grill > 0:
			var n := _prod_count("grill")
			if n > 0:
				out.append([Base.SLOTS.grill + Vector3(0, 2.0, 0), "Шаурма готова: %d" % n, 15, Hud.GOLD])
		if buildings.garden > 0:
			var g := _prod_count("garden")
			if g > 0:
				out.append([Base.SLOTS.garden + Vector3(0, 1.6, 0), "Урожай: +%d монет" % (g * GameData.BUILDINGS.garden.coins[buildings.garden - 1]), 15, Hud.GOLD])
	return out


func _mmss(sec: float) -> String:
	var s := maxi(0, int(ceil(sec)))
	return "%02d:%02d" % [s / 60, s % 60]


func _accept_quest() -> void:
	quest = 1
	hud.toast("Новое задание: «Голубиная мафия»", Hud.GOLD)
	play_sfx("bank")
	save_game()


func _finish_quest() -> void:
	quest = 5
	coins += 300
	gain_xp(300)
	hud.big("ГОЛУБИНАЯ МАФИЯ РАЗГРОМЛЕНА!", "Баба Зина довольна. Поговори с ней ещё раз", 4.0)
	play_sfx("bank")
	save_game()


func _on_kill(m: Dictionary) -> void:
	if not m.temp and daily.has(m.kind):
		daily[m.kind] = int(daily[m.kind]) + 1
		for dd in GameData.DAILIES:
			if dd[0] == m.kind and int(daily[m.kind]) == dd[2] and quest >= 1:
				hud.toast("Ежедневное задание выполнено: %s — забери у дяди Миши" % dd[1], Hud.GREEN)
	if quest == 1 and m.kind == "pigeon" and not m.temp:
		quest_kills += 1
		if quest_kills >= 6:
			quest = 2
			hud.toast("Задание обновлено: найди Перо удачи", Hud.GOLD)
			play_sfx("bank")
			save_game()
	elif quest == 2 and m.kind == "pigeon":
		feather_kills += 1
	elif m.kind == "pakhan":
		quest = 4
		hud.big("ПАХАН ПОВЕРЖЕН!", "Вернись к бабе Зине", 4.0)
		save_game()


# ================================================================== dialogs & interaction
func _close_dialog() -> void:
	hud.hide_dialog()
	state = PLAY


func _interactables() -> Array:
	var out := []
	for n in npcs:
		out.append({"label": n.act, "kind": "npc", "id": n.id, "pos": n.pos, "r": 3.2})
	if map_id == "garages" and world.has("anchors"):
		for id in Base.SLOTS:
			var lv: int = buildings[id]
			out.append({"label": ("Стройка" if lv == 0 else SLOT_SHORT[id]), "kind": "slot", "id": id, "pos": Base.SLOTS[id], "r": 2.4})
		if quest2 >= 2:
			out.append({"label": "Вася", "kind": "robot", "id": "robot", "pos": Base.ROBOT_HOME, "r": 2.6})
	return out


func _find_interact():
	var best = null
	var bd := INF
	for e in _interactables():
		var d := Vector2(pos.x - e.pos.x, pos.z - e.pos.z).length()
		if d < e.r and d < bd:
			bd = d
			best = e
	return best


func interact_label() -> String:
	if state != PLAY or current_interact == null:
		return ""
	return current_interact.label


func can_talk() -> bool:
	return interact_label() != ""


func interact() -> void:
	if state != PLAY or current_interact == null:
		return
	var e: Dictionary = current_interact
	_face(e.pos)
	play_sfx("ui")
	match e.kind:
		"npc":
			match e.id:
				"zina": _talk_zina()
				"misha": open_list("daily")
				"lyuba": open_list("shop")
				"petrovich": _talk_petrovich()
		"slot": open_list("slot", e.id)
		"robot": open_list("robot")


func talk() -> void:
	interact()


func _talk_zina() -> void:
	state = DIALOG
	var close := func(): _close_dialog()
	match quest:
		0:
			hud.show_dialog("Баба Зина", "Ой, милок! Голуби совсем обнаглели — семки у всего двора отжимают. В кепках ходят, как бандиты! Разгонишь шестерых?", [
				["Сделаю, баб Зин!", func(): _accept_quest(); close.call()],
				["А что мне за это?", func(): hud.show_dialog("Баба Зина", "Пирожок с капустой, уважение двора и монетки! Ну, иди уже.", [["Ладно, иду!", func(): _accept_quest(); close.call()]])],
			])
		1:
			hud.show_dialog("Баба Зина", "Шестерых, милок! Пока ты разогнал %d. Бей их в такт музыке — так больнее!" % quest_kills, [["Понял!", close]])
		2:
			hud.show_dialog("Баба Зина", "Говорят, у одного голубя есть Перо удачи. Пока оно у них — ихний Пахан из гаражей не вылезет. Найди перо!", [["Найду!", close]])
		3:
			hud.show_dialog("Баба Зина", "Пахан у гаражей! Он крыльями машет — красный круг видишь, сразу отбегай! Шаурма в кармане есть? Жми её, если прижмёт.", [["Есть!", close]])
		4:
			hud.show_dialog("Баба Зина", "Батюшки! Сам Пахан! Держи пирожок и монеты. Весь двор теперь за тебя!", [["Спасибо, баб Зин! (+300 монет)", func(): _finish_quest(); close.call()]])
		_:
			if quest2 == 0:
				hud.show_dialog("Баба Зина", "Милок, тебя председатель гаражей искал, Петрович! Говорит, бокс пустует, а ты парень видный. Иди через арку «ГК Песня» — вон, справа у гаражей.", [
					["Бегу к Петровичу!", func():
						quest2 = 1
						hud.toast("Новое задание: «Свой гараж»", Hud.GOLD)
						play_sfx("bank")
						save_game()
						close.call()]])
			else:
				var lines := ["Заходи ещё, милок! Голуби тебя теперь за версту обходят.", "Ты, говорят, гараж обустраиваешь? Мангал заведи — с шаурмой веселее.", "Люба опять шаурму в ларёк завезла. Хрустящая!"]
				hud.show_dialog("Баба Зина", lines[randi() % lines.size()], [["До встречи!", close]])


func _talk_petrovich() -> void:
	state = DIALOG
	var close := func(): _close_dialog()
	if quest < 5 and quest2 == 0:
		hud.show_dialog("Петрович", "Ты кто такой? Новенький? Сначала двор от голубиной мафии очисти — баба Зина потом за тебя поручится. Тогда и поговорим.", [["Понял, Петрович", close]])
		return
	match quest2:
		0, 1:
			hud.show_dialog("Петрович", "Зина говорит, ты самого Пахана прогнал! Уважаю. Держи ключи от бокса №40 — пустует, зараза. И робота в придачу: Вася-3000. Он сам по магазинам ходит. Золото, а не робот!", [
				["Беру! (бокс №40 + робот Вася)", func():
					quest2 = 2
					hud.big("БОКС №40 ТВОЙ!", "Подойди к Васе у гаража и отправь его за покупками", 4.0)
					play_sfx("bank")
					_refresh_robot()
					save_game()
					close.call()]])
		2:
			hud.show_dialog("Петрович", "Вася у твоего гаража стоит, скучает. Отправь его в «Ёжик» — пусть досок принесёт.", [["Иду", close]])
		3:
			hud.show_dialog("Петрович", "Ждёшь Васю? Он пока все акции не изучит — не вернётся. Можешь пока во дворе голубей погонять.", [["Ладно", close]])
		4:
			hud.show_dialog("Петрович", "Материалы есть — ставь мангал! Подходи к синей разметке «СТРОЙКА» у своего бокса.", [["Ставлю!", close]])
		5:
			hud.show_dialog("Петрович", "Дымок пошёл — значит, гараж живой! Держи премию от правления. И слушай… На стройке за гаражами Шумодав завёлся. Скоро туда бригаду соберём.", [
				["Спасибо! (+200 монет, кирпич, провода)", func():
					quest2 = 6
					coins += 200
					res.brick += 10
					res.wires += 8
					gain_xp(250)
					hud.big("ГАРАЖ ОБЖИТ!", "Скоро: подземелье «Стройка» и босс Шумодав", 4.5)
					play_sfx("bank")
					save_game()
					close.call()]])
		_:
			var lines := ["Взносы за гараж — шучу, тебе бесплатно. Пока.", "Сцену поставь — по субботам концерты устроим.", "Солнечные панели — вещь! Вася с ними как на крыльях."]
			hud.show_dialog("Петрович", lines[randi() % lines.size()], [["Ага", close]])


# ================================================================== list panels: shop, dailies, base slots, robot
func open_list(kind: String, arg := "") -> void:
	list_kind = kind
	list_arg = arg
	state = LIST
	match kind:
		"shop": _list_shop()
		"daily": _list_daily()
		"slot": _list_slot(arg)
		"robot": _list_robot()


func close_list() -> void:
	hud.list_panel.visible = false
	list_kind = ""
	state = PLAY
	save_game()


func _refresh_list() -> void:
	if list_kind != "":
		open_list(list_kind, list_arg)


func _list_shop() -> void:
	var rows := []
	for e in GameData.SHOP:
		var id: String = e[0]
		var price: int = e[2]
		rows.append({"text": "%s — %d монет" % [e[1], price], "sub": e[4], "btn": "Купить", "enabled": coins >= price,
			"cb": func(): _buy(id, price, e[3])})
	var junk := 0
	var junk_n := 0
	for it in inventory:
		if _is_junk(it):
			junk += GameData.SELL_PRICE[it.rarity]
			junk_n += 1
	rows.append({"text": "Продать ненужное (%d шт.)" % junk_n, "sub": "Обычный хлам и лишняя экипировка (надетое не трогаем) — +%d монет" % junk, "btn": "Продать",
		"enabled": junk_n > 0, "cb": func(): _sell_junk(), "color": Hud.GOLD})
	hud.show_list("Ларёк «Шаурма» · Люба", "«Бери, пока горячая!» · Монеты: %d · Шаурма: %d\n%s" % [coins, food, res_line()], rows)


func _is_junk(it: Dictionary) -> bool:
	if it.rarity >= 3:
		return false
	for s in equipped:
		if is_same(equipped[s], it):
			return false
	if it.id == "luck":
		return false
	return true


func _buy(id: String, price: int, amount: int) -> void:
	if coins < price:
		return
	coins -= price
	if id == "food":
		food += amount
	else:
		res[id] += amount
	play_sfx("pickup")
	_refresh_list()


func _sell_junk() -> void:
	var gain := 0
	for it in inventory.duplicate():
		if _is_junk(it):
			gain += GameData.SELL_PRICE[it.rarity]
			inventory.erase(it)
	coins += gain
	hud.toast("Продано на %d монет" % gain, Hud.GOLD)
	play_sfx("bank")
	_refresh_list()


func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if daily.date != today:
		daily = {"date": today, "pigeon": 0, "scooter": 0, "vacuum": 0, "claimed": []}


func _daily_ready_count() -> int:
	var n := 0
	for dd in GameData.DAILIES:
		if int(daily.get(dd[0], 0)) >= dd[2] and not (dd[0] in daily.claimed):
			n += 1
	return n


func _list_daily() -> void:
	_check_daily_reset()
	var rows := []
	for dd in GameData.DAILIES:
		var k: String = dd[0]
		var got := mini(int(daily[k]), dd[2])
		var claimed: bool = k in daily.claimed
		var rw: Dictionary = dd[4]
		var rtxt := "%d монет" % dd[3]
		for r in rw:
			rtxt += " · %s %d" % [GameData.RES_NAMES[r], rw[r]]
		rows.append({"text": "%s: %d / %d" % [dd[1], got, dd[2]], "sub": "Награда: " + rtxt,
			"btn": "Готово ✓" if claimed else "Забрать", "enabled": (not claimed) and got >= dd[2], "cb": func(): _claim_daily(k),
			"color": Hud.GREEN if claimed else Hud.CREAM})
	hud.show_list("Дядя Миша · ежедневные дела", "«Двор сам себя не подметёт! Голубей гоняй, самокаты лови, пылесосы выключай.» Обновляются в полночь.", rows)


func _claim_daily(k: String) -> void:
	for dd in GameData.DAILIES:
		if dd[0] == k and not (k in daily.claimed) and int(daily[k]) >= dd[2]:
			daily.claimed.append(k)
			coins += dd[3]
			for r in dd[4]:
				res[r] += dd[4][r]
			gain_xp(60)
			play_sfx("bank")
			if daily.claimed.size() == 3:
				hud.big("ВСЕ ДЕЛА СДЕЛАНЫ!", "Дядя Миша жмёт руку. Завтра будут новые", 3.0)
	_refresh_list()


func _cost_text(cost: Array) -> String:
	var t := "%d монет" % cost[0]
	for r in GameData.RES_ORDER:
		if cost[1].has(r):
			t += " · %s %d/%d" % [GameData.RES_NAMES[r], res[r], cost[1][r]]
	return t


func _affordable(cost: Array) -> bool:
	if coins < cost[0]:
		return false
	for r in cost[1]:
		if res[r] < cost[1][r]:
			return false
	return true


func _effect_text(id: String, lv: int) -> String:
	var b: Dictionary = GameData.BUILDINGS[id]
	if lv <= 0:
		return "не построено"
	match id:
		"grill": return b.fx % int(b.period[lv - 1] / 60)
		"garden": return b.fx % b.coins[lv - 1]
		_: return b.fx % int(round(b.value[lv - 1] * 100))


func _list_slot(id: String) -> void:
	var b: Dictionary = GameData.BUILDINGS[id]
	var lv: int = buildings[id]
	if quest2 < 2:
		state = PLAY
		hud.toast("Сначала получи бокс №40 у Петровича", Hud.CREAM)
		return
	var rows := []
	rows.append({"text": "%s · уровень %d / 3" % [b.name, lv], "sub": "%s\nСейчас: %s" % [b.desc, _effect_text(id, lv)], "color": Hud.GOLD})
	if lv < 3:
		var cost: Array = b.cost[lv]
		rows.append({"text": ("Построить" if lv == 0 else "Улучшить до ур. %d" % (lv + 1)) + " → " + _effect_text(id, lv + 1),
			"sub": "Нужно: " + _cost_text(cost), "btn": "Построить" if lv == 0 else "Улучшить", "enabled": _affordable(cost), "cb": func(): _build(id)})
	else:
		rows.append({"text": "Максимальный уровень", "sub": "Скоро здесь появятся новые улучшения", "color": Hud.GREEN})
	if id == "grill" and lv > 0:
		var n := _prod_count("grill")
		rows.append({"text": "Готовая шаурма: %d (макс. 5)" % n, "sub": "Жарится сама, даже когда игра закрыта", "btn": "Забрать", "enabled": n > 0, "cb": func(): _collect("grill")})
	if id == "garden" and lv > 0:
		var g := _prod_count("garden")
		rows.append({"text": "Урожай: +%d монет" % (g * b.coins[lv - 1]), "sub": "Люба сразу выкупает всё оптом", "btn": "Собрать", "enabled": g > 0, "cb": func(): _collect("garden")})
	hud.show_list("Стройка · бокс №40", "Монеты: %d · %s" % [coins, res_line()], rows)


func _build(id: String) -> void:
	var lv: int = buildings[id]
	if lv >= 3:
		return
	var cost: Array = GameData.BUILDINGS[id].cost[lv]
	if not _affordable(cost):
		return
	coins -= cost[0]
	for r in cost[1]:
		res[r] -= cost[1][r]
	buildings[id] = lv + 1
	if b_since.has(id) and lv == 0:
		b_since[id] = now()
	_recalc_stats()
	_refresh_slot(id)
	var at: Vector3 = Base.SLOTS[id]
	_burst(at + Vector3(0, 1, 0), [Color("e8d8b0"), Color("c8b898"), Color.WHITE], 30)
	_ring_fx(at + Vector3(0, 0.1, 0), Kit.GOLD, 2.6, 0.6)
	hud.big("%s · ур. %d" % [GameData.BUILDINGS[id].name, lv + 1], _effect_text(id, lv + 1), 2.5)
	play_sfx("smash", 1.2, -4.0)
	play_sfx("bank")
	if id == "grill" and quest2 == 4:
		quest2 = 5
		hud.toast("Задание обновлено: вернись к Петровичу", Hud.GOLD)
	save_game()
	_refresh_list()


func _prod_count(id: String) -> int:
	var lv: int = buildings[id]
	if lv <= 0:
		return 0
	var b: Dictionary = GameData.BUILDINGS[id]
	return mini(b.cap, int(maxf(0.0, now() - b_since[id]) / b.period[lv - 1]))


func _collect(id: String) -> void:
	var n := _prod_count(id)
	if n <= 0:
		return
	var b: Dictionary = GameData.BUILDINGS[id]
	var lv: int = buildings[id]
	if id == "grill":
		food += n
		hud.toast("+%d шаурмы" % n, Hud.GOLD)
	else:
		var c: int = n * b.coins[lv - 1]
		coins += c
		hud.toast("+%d монет за урожай" % c, Hud.GOLD)
	if n >= b.cap:
		b_since[id] = now()
	else:
		b_since[id] += n * b.period[lv - 1]
	play_sfx("pickup")
	save_game()
	_refresh_list()


func _errand_time(id: String) -> float:
	return GameData.ERRANDS[id].time * (1.0 - _bval("solar"))


func _list_robot() -> void:
	var rows := []
	var sub := "Вася-3000 ходит по магазинам сам. Таймер идёт и когда игра закрыта."
	if robot_task.task == "":
		for id in GameData.ERRAND_ORDER:
			var e: Dictionary = GameData.ERRANDS[id]
			var rw := ""
			for r in GameData.RES_ORDER:
				if e.res.has(r):
					rw += "%s %d · " % [GameData.RES_NAMES[r], e.res[r]]
			if e.food > 0:
				rw += "шаурма %d · " % e.food
			rows.append({"text": "%s — %s" % [e.name, _mmss(_errand_time(id))], "sub": "%s%s" % [rw, ("%d монет на покупки" % e.cost) if e.cost > 0 else "бесплатно"],
				"btn": "Отправить", "enabled": coins >= e.cost, "cb": func(): _send_robot(id)})
	elif now() < robot_task.end:
		var e2: Dictionary = GameData.ERRANDS[robot_task.task]
		rows.append({"text": "Вася в пути: %s" % e2.name, "sub": "Вернётся через %s. Можно закрыть игру — он всё равно придёт." % _mmss(robot_task.end - now()), "color": Hud.TEAL})
	else:
		var e3: Dictionary = GameData.ERRANDS[robot_task.task]
		rows.append({"text": "Вася вернулся из: %s!" % e3.name, "sub": "Тележка полна. " + e3.note, "btn": "Забрать", "cb": func(): _collect_robot(), "color": Hud.GOLD})
	if buildings.solar > 0:
		sub += " Солнечные панели: быстрее на %d%%." % int(round(_bval("solar") * 100))
	hud.show_list("Робот «Вася-3000»", sub, rows)


func _send_robot(id: String) -> void:
	var e: Dictionary = GameData.ERRANDS[id]
	if coins < e.cost or robot_task.task != "":
		return
	coins -= e.cost
	robot_task = {"task": id, "start": now(), "end": now() + _errand_time(id), "told": false}
	robot_walk = 6.0
	hud.toast("Вася ушёл: %s" % e.name, Hud.TEAL)
	play_sfx("dash", 0.8)
	if quest2 == 2:
		quest2 = 3
	save_game()
	close_list()


func _collect_robot() -> void:
	if robot_task.task == "" or now() < robot_task.end:
		return
	var e: Dictionary = GameData.ERRANDS[robot_task.task]
	var parts := []
	for r in e.res:
		var amt: int = e.res[r]
		res[r] += amt
		parts.append("%s +%d" % [GameData.RES_NAMES[r], amt])
	if e.food > 0:
		food += e.food
		parts.append("шаурма +%d" % e.food)
	if robot_task.task == "dump":
		var r2 := randf()
		if r2 < 0.05:
			add_item("hose")
		elif r2 < 0.3:
			add_item(["cap", "chain", "sneaker", "bell", "filter"][randi() % 5])
	hud.toast("Вася принёс: " + ", ".join(parts), Hud.GOLD)
	robot_task = {"task": "", "start": 0.0, "end": 0.0, "told": false}
	play_sfx("bank")
	if quest2 == 3:
		quest2 = 4
		hud.toast("Задание обновлено: построй мангал", Hud.GOLD)
	_refresh_robot()
	save_game()
	_refresh_list()


func _refresh_slot(id: String) -> void:
	if not world.has("anchors"):
		return
	var a: Node3D = world.anchors[id]
	for c in a.get_children():
		c.queue_free()
	a.add_child(Base.building(id, buildings[id]))


func _refresh_robot() -> void:
	if map_id != "garages" or not world.has("root"):
		return
	if quest2 < 2:
		return
	if robot_vis.is_empty():
		var r := Chars.robot()
		var ct := Chars.cart()
		r.root.add_child(ct)
		ct.position = Vector3(0, 0, 1.55)
		world.root.add_child(r.root)
		Kit.bake_tree(r.root)
		robot_vis = r
		robot_vis["cart"] = ct
		r.root.position = Base.ROBOT_HOME
		r.root.rotation.y = PI / 2


func _update_robot(dt: float) -> void:
	# the robot comes back in real time, even in another map
	if robot_task.task != "" and now() >= robot_task.end and not robot_task.told:
		robot_task.told = true
		hud.toast("Вася вернулся: %s! Забери покупки у бокса №40" % GameData.ERRANDS[robot_task.task].name, Hud.GOLD)
		play_sfx("bank", 1.2)
	if robot_vis.is_empty():
		return
	var node: Node3D = robot_vis.root
	var away: bool = robot_task.task != "" and now() < robot_task.end
	if away:
		if robot_walk > 0.0:
			robot_walk -= dt
			var to := Base.GATE_WEST - node.position
			to.y = 0
			if to.length() > 0.5:
				node.position += to.normalized() * 5.0 * dt
				node.rotation.y = atan2(to.x, to.z)
			var sw := sin(time * 9.0) * 0.6
			robot_vis.legs[0].rotation.x = sw
			robot_vis.legs[1].rotation.x = -sw
			node.visible = true
		else:
			node.visible = false
	else:
		node.visible = true
		node.position = Base.ROBOT_HOME
		node.rotation.y = PI / 2
		robot_vis.legs[0].rotation.x = 0
		robot_vis.legs[1].rotation.x = 0
		robot_vis.head.rotation.y = sin(time * 1.3) * 0.4
		robot_vis.body.position.y = maxf(0.0, 0.04 - minf(beat_phase(), 1.0 - beat_phase()) * 0.15)


# ================================================================== items, xp
func xp_next() -> int:
	return 80 + level * 60


func gain_xp(v: int) -> void:
	xp += v
	while xp >= xp_next() and level < 10:
		xp -= xp_next()
		level += 1
		_recalc_stats()
		hp = hp_max
		hud.big("НОВЫЙ УРОВЕНЬ %d!" % level, "Здоровье и урон выросли", 2.5)
		play_sfx("bank", 1.1)
		_ring_fx(pos + Vector3(0, 0.1, 0), Kit.GOLD, 2.5, 0.8)
	if level >= 10:
		xp = mini(xp, xp_next() - 1)


func add_item(id: String) -> void:
	var src: Dictionary = GameData.ITEMS[id]
	var it := src.duplicate()
	it["id"] = id
	inventory.append(it)
	var col: Color = Hud.RARITY[it.rarity]
	hud.toast("+ %s (%s)" % [it.name, Hud.RARITY_NAME[it.rarity]], col)
	if it.slot != "":
		var cur = equipped.get(it.slot, null)
		if cur == null or cur.power < it.power:
			equipped[it.slot] = it
			_recalc_power()
			hud.toast("Надето: %s · сила %d" % [it.name, power], Hud.GREEN)
	if id == "luck" and quest == 2:
		quest = 3
		if map_id == "yard":
			_spawn_mob("pakhan", Vector3(0, 0, -24), 7)
		hud.big("ГОЛУБИНЫЙ ПАХАН", "вылез у гаражей!", 3.5)
		play_sfx("laser", 0.7)
		save_game()


func _drop_loot(m: Dictionary) -> void:
	var d: Dictionary = GameData.MOBS[m.kind]
	var drops: Array = []
	if m.kind == "pakhan":
		drops = ["pakhan_cap", "mic"]
		coins += 150
	else:
		coins += randi_range(4, 12) + m.lvl * 2
		var r := randf()
		for e in d.loot:
			if r < e[0]:
				var opts: PackedStringArray = str(e[1]).split("|")
				drops.append(opts[randi() % opts.size()])
				break
		if quest == 2 and m.kind == "pigeon" and (randf() < 0.35 or feather_kills >= 3):
			drops.append("luck")
		for e in d.res:
			if randf() < e[0]:
				var amt := randi_range(e[2], e[3])
				res[e[1]] += amt
				hud.float_text(m.pos + Vector3(0, m.height + 0.5, 0), "+%d %s" % [amt, GameData.RES_NAMES[e[1]].to_lower()], Hud.TEAL, 20, 40)
	for i in range(drops.size()):
		var id: String = drops[i]
		var it: Dictionary = GameData.ITEMS[id]
		var n := Node3D.new()
		fx_root.add_child(n)
		var lp: Vector3 = m.pos + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
		lp = World.resolve(lp, 0.3, world.rects, world.circles, world.bounds)
		n.position = lp
		Chars.loot_beam(n, Vector3.ZERO, Hud.RARITY[it.rarity], 2.5 + it.rarity * 1.5)
		var bag := Kit.part(n, Kit.BOX, Kit.mat(Hud.RARITY[it.rarity].darkened(0.3), 0.5, 0.3, Hud.RARITY[it.rarity], 0.6), Vector3(0.35, 0.35, 0.35), Vector3(0, 0.4, 0), Vector3(0.3, 0.6, 0))
		loots.append({"node": n, "pos": lp, "item": it, "id": id, "t": 0.0, "spin": bag})


# ================================================================== combat
func _pick_target(max_d := 14.0):
	var best = null
	var best_s := INF
	var fwd := Vector3(sin(facing), 0, cos(facing))
	for m in mobs:
		if not m.alive:
			continue
		var d: Vector3 = m.pos - pos
		var l := d.length()
		if l > max_d:
			continue
		var s := l - 3.0 * fwd.dot(d / maxf(l, 0.01))
		if s < best_s:
			best_s = s
			best = m
	return best


func _valid_target(max_d := 16.0) -> bool:
	return target != null and target.alive and target.pos.distance_to(pos) < max_d


func _base_dmg() -> float:
	var d := (20.0 + level * 6.0 + power) * (1.0 if cls == "cop" else 0.85)
	d *= 1.0 + minf(combo, 10) * 0.05
	d *= 1.0 + _bval("studio")
	if buff_t > 0.0:
		d *= 1.6
	return d * randf_range(0.9, 1.1)


func _beat_action(_name: String) -> bool:
	var ok := on_beat()
	var vg := 1.0 + _bval("stage")
	if ok:
		combo += 1
		vibe = minf(100.0, vibe + 14.0 * vg)
		play_sfx("beat", 1.0 + minf(combo, 8) * 0.03, -3.0)
	else:
		combo = 0
		vibe = minf(100.0, vibe + 4.0 * vg)
	combo_t = 3.0
	idle_t = 0.0
	return ok


func press(name: String) -> void:
	if state != PLAY:
		return
	match name:
		"attack": _attack()
		"s1", "s2", "s3": _skill(name)
		"ult": _ultimate()
		"talk": interact()
		"food": _eat()
		"pause": toggle_pause()
		"bag": open_bag()


func _eat() -> void:
	if cd.food > 0.0:
		return
	if food <= 0:
		hud.toast("Нет шаурмы — купи у Любы или пожарь на мангале", Hud.CREAM)
		return
	if hp >= hp_max - 1.0:
		hud.toast("Ты и так полон сил", Hud.CREAM)
		return
	food -= 1
	cd.food = cd_max.food
	heal_left += hp_max * 0.4
	hud.float_text(pos + Vector3(0, 2.6, 0), "Шаурма! +40%", Color("ffd27a"), 24, 40)
	play_sfx("pickup", 0.9)


func _attack() -> void:
	if cd.attack > 0.0:
		return
	cd.attack = cd_max.attack
	if not _valid_target(16.0):
		target = _pick_target()
	var crit := _beat_action("attack")
	attack_anim = 0.3
	if target == null:
		play_sfx("laser", 1.4, -8.0)
		return
	_face(target.pos)
	var mult := (2.3 if race == "rapper" else 2.0) if crit else 1.0
	_shoot(target, _base_dmg() * mult, crit, 0.0)
	play_sfx("laser", 1.3 if crit else 1.6, -6.0)


func _skill(name: String) -> void:
	if cd[name] > 0.0:
		return
	var crit := false
	if cls == "cop":
		match name:
			"s1":
				if not _valid_target(12.0):
					target = _pick_target(12.0)
				if target == null:
					hud.toast("Нет цели рядом", Hud.CREAM)
					return
				crit = _beat_action(name)
				_face(target.pos)
				_shoot(target, _base_dmg() * (1.5 if not crit else 2.6), crit, 3.5 if crit else 2.5, Color("7ab8ff"))
				hud.float_text(pos + Vector3(0, 2.6, 0), "«Вы имеете право хранить бит!»", Color("9ad0ff"), 20, 30)
			"s2":
				crit = _beat_action(name)
				_aoe(pos, 5.5, _base_dmg() * (1.2 if not crit else 2.2), crit, 0.0)
				_ring_fx(pos + Vector3(0, 0.15, 0), Color("ff3a4a"), 5.5, 0.5)
				_ring_fx(pos + Vector3(0, 0.25, 0), Color("3a7aff"), 4.0, 0.45)
				play_sfx("smash", 1.4, -4.0)
			"s3":
				crit = _beat_action(name)
				_dash(false)
	else:
		match name:
			"s1":
				crit = _beat_action(name)
				heal_left += hp_max * (0.45 if crit else 0.3)
				_notes_fx(pos + Vector3(0, 1.5, 0), Color("2ee88a"))
				hud.float_text(pos + Vector3(0, 2.6, 0), "Аккорд жизни!", Color("6bffa8"), 24, 40)
				play_sfx("pickup", 0.8)
			"s2":
				crit = _beat_action(name)
				buff_t = 10.0 if crit else 8.0
				hud.float_text(pos + Vector3(0, 2.6, 0), "Панк-укол! Урон ×1.6", Color("ff7ad0"), 24, 40)
				_ring_fx(pos + Vector3(0, 0.15, 0), Color("ff4fa8"), 2.0, 0.5)
				play_sfx("near", 0.8)
			"s3":
				crit = _beat_action(name)
				_dash(true)
	cd[name] = cd_max[name]
	if crit:
		hud.float_text(pos + Vector3(0, 3.0, 0), "В БИТ!", Hud.GOLD, 26, 50)


func _ultimate() -> void:
	if vibe < 100.0:
		return
	vibe = 0.0
	_aoe(pos, 7.5, _base_dmg() * 3.5, true, 1.5)
	for i in range(3):
		_ring_fx(pos + Vector3(0, 0.2 + i * 0.4, 0), Kit.GOLD, 3.0 + i * 2.5, 0.6 + i * 0.15)
	_notes_fx(pos + Vector3(0, 2, 0), Kit.GOLD)
	hud.big("ХИТ!", "Весь двор качает", 1.5)
	play_sfx("smash", 0.9)
	attack_anim = 0.4


func _dash(aoe: bool) -> void:
	var dir := Vector3(sin(facing), 0, cos(facing))
	if joy_vec.length() > 0.2:
		dir = _move_dir(joy_vec).normalized()
		facing = atan2(dir.x, dir.z)
	dash_dir = dir
	dash_t = 0.22
	dash_aoe = aoe
	invuln = 0.4
	play_sfx("dash")


func _face(p: Vector3) -> void:
	var d := p - pos
	if d.length() > 0.1:
		facing = atan2(d.x, d.z)


func _shoot(t: Dictionary, dmg: float, crit: bool, stun: float, col := Color("f5b55c")) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	var tip: Node3D = hero.tip
	n.global_position = tip.global_position
	var r := Chars.ring(n, Vector3.ZERO, 0.32 if crit else 0.24, col, 0.05, 5.0 if crit else 3.0)
	r.rotation.x = PI / 2
	if crit:
		Chars.ring(n, Vector3(0, 0, 0), 0.5, col, 0.03, 3.0).rotation.x = PI / 2
	shots.append({"node": n, "t": t, "dmg": dmg, "crit": crit, "stun": stun, "col": col, "life": 1.5})


func _aoe(center: Vector3, r: float, dmg: float, crit: bool, stun: float) -> void:
	for m in mobs:
		if m.alive and m.pos.distance_to(center) < r + m.radius:
			damage_mob(m, dmg * randf_range(0.9, 1.1), crit, stun)


func damage_mob(m: Dictionary, dmg: float, crit: bool, stun := 0.0) -> void:
	if not m.alive:
		return
	m.hp -= dmg
	m.hit = 0.18
	if stun > 0.0:
		m.stun = maxf(m.stun, stun * (0.5 if m.kind == "pakhan" else 1.0))
		m.charge_t = 0.0
	if m.st == "idle":
		m.st = "chase"
	if target == null or not target.alive:
		target = m
	var top: Vector3 = m.pos + Vector3(0, m.height * 0.8, 0)
	if crit:
		hud.float_text(top, "В БИТ! –%d" % int(dmg), Hud.GOLD, 38, 70)
	else:
		hud.float_text(top, "–%d" % int(dmg), Hud.CREAM, 28, 60)
	_burst(top - Vector3(0, 0.6, 0), [Color("fff0b0"), Color("c8ccd8")] if crit else [Color("c8ccd8")], 10 if crit else 5)
	play_sfx("bolt", randf_range(0.9, 1.1), -8.0)
	if m.hp <= 0.0:
		_kill(m)


func _kill(m: Dictionary) -> void:
	m.alive = false
	m.st = "dead"
	m.dead_t = 0.0
	m.respawn = 20.0
	if m.tele and is_instance_valid(m.tele):
		m.tele.queue_free()
		m.tele = null
	gain_xp(m.xp)
	hud.float_text(m.pos + Vector3(0, m.height, 0), "+%d опыта" % m.xp, Color("b9a6ff"), 20, 40)
	_drop_loot(m)
	_burst(m.pos + Vector3(0, 1.0, 0), [Color("c8ccd8"), Color("8a93a8"), Color.WHITE], 24)
	play_sfx("drop", 0.8)
	if is_same(target, m):
		target = null
	_on_kill(m)


func hurt_player(dmg: float, _from: Vector3) -> void:
	if invuln > 0.0 or state != PLAY:
		return
	hp -= dmg
	hud.hurt = 1.0
	hud.float_text(pos + Vector3(0, 2.3, 0), "–%d" % int(dmg), Color("ff6060"), 26, 50)
	play_sfx("stumble", 1.0, -6.0)
	if not autotest:
		Input.vibrate_handheld(40)
	if hp <= 0.0:
		hp = 0.0
		_die()


func _die() -> void:
	state = DEAD
	dead_t = 3.0
	_show_only(hud.dead_panel)
	play_sfx("over")
	for m in mobs:
		if m.alive and m.st == "chase":
			m.st = "return"


func _respawn() -> void:
	var sp: Array = world.spawns.respawn
	pos = sp[0]
	facing = sp[1]
	hp = hp_max * 0.7
	state = PLAY
	_show_only(null)
	target = null
	invuln = 2.0


# ================================================================== fx helpers
func _ring_fx(at: Vector3, col: Color, r: float, life: float) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	n.position = at
	Chars.ring(n, Vector3.ZERO, 1.0, col, 0.06, 4.0)
	n.scale = Vector3.ONE * 0.2
	fx.append({"node": n, "t": 0.0, "life": life, "kind": "ring", "r": r})


func _notes_fx(at: Vector3, col: Color) -> void:
	for i in range(4):
		var n := Node3D.new()
		fx_root.add_child(n)
		n.position = at + Vector3(randf_range(-0.8, 0.8), randf_range(0, 0.6), randf_range(-0.8, 0.8))
		Chars.note3d(n, Vector3.ZERO, col, 0.8)
		fx.append({"node": n, "t": 0.0, "life": 1.2, "kind": "rise"})


func _burst(at: Vector3, cols: Array, n := 12) -> void:
	var p := CPUParticles3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.06
	bm.height = 0.12
	bm.radial_segments = 6
	bm.rings = 3
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.material = m
	p.mesh = bm
	p.amount = n
	p.lifetime = 0.7
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -6, 0)
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array()
	gr.colors = PackedColorArray()
	for i in range(cols.size()):
		gr.add_point(float(i) / maxf(1, cols.size() - 1), cols[i] * 2.0)
	p.color_initial_ramp = gr
	fx_root.add_child(p)
	p.global_position = at
	p.emitting = true
	fx.append({"node": p, "t": 0.0, "life": 1.2, "kind": "none"})


func _telegraph(m: Dictionary) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	n.position = Vector3(m.pos.x, 0.08, m.pos.z)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.1, 0.15, 0.3)
	Kit.part(n, Kit.DISC, mat, Vector3(8.4, 1, 8.4))
	Chars.ring(n, Vector3(0, 0.02, 0), 4.2, Color("ff2a3a"), 0.12, 4.0)
	m.tele = n
	m.tele_t = 1.6



# ================================================================== input
func _move_dir(v: Vector2) -> Vector3:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	return fwd * -v.y + right * v.x


func _input(event: InputEvent) -> void:
	if not in_world():
		return
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if state != PLAY:
				return
			var b := hud.button_at(p)
			if b != "":
				btn_touch[event.index] = b
				press(b)
				return
			if p.x < hud.size.x * 0.42 and joy_idx == -1:
				joy_idx = event.index
				joy_origin = p
				joy_vec = Vector2.ZERO
			elif cam_idx == -1:
				cam_idx = event.index
				cam_last = p
				cam_start = p
				cam_start_t = time
		else:
			btn_touch.erase(event.index)
			if event.index == joy_idx:
				joy_idx = -1
				joy_vec = Vector2.ZERO
			elif event.index == cam_idx:
				cam_idx = -1
				if p.distance_to(cam_start) < 18 and time - cam_start_t < 0.35:
					_tap_select(p)
	elif event is InputEventScreenDrag:
		if event.index == joy_idx:
			var d: Vector2 = event.position - joy_origin
			if d.length() > 96:
				joy_origin += d - d.normalized() * 96
				d = d.normalized() * 96
			joy_vec = d / 96.0
		elif event.index == cam_idx:
			var dd: Vector2 = event.position - cam_last
			cam_last = event.position
			yaw -= dd.x * 0.006
			pitch = clampf(pitch + dd.y * 0.004, 0.12, 1.1)
			cam_touch_t = 1.5
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J, KEY_SPACE: press("attack")
			KEY_1: press("s1")
			KEY_2: press("s2")
			KEY_3: press("s3")
			KEY_4: press("ult")
			KEY_E: press("talk")
			KEY_F: press("food")
			KEY_I: press("bag")
			KEY_ESCAPE: toggle_pause()


func _tap_select(p: Vector2) -> void:
	if state != PLAY:
		return
	var best = null
	var bd := 110.0
	for m in mobs:
		if not m.alive:
			continue
		var w: Vector3 = m.pos + Vector3(0, m.height * 0.6, 0)
		if cam.is_position_behind(w):
			continue
		var d := cam.unproject_position(w).distance_to(p)
		if d < bd:
			bd = d
			best = m
	if best != null:
		target = best
		play_sfx("ui", 1.2, -6.0)
		return
	if current_interact != null:
		var ip: Vector3 = current_interact.pos + Vector3(0, 1.2, 0)
		if not cam.is_position_behind(ip) and cam.unproject_position(ip).distance_to(p) < 140:
			interact()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		match state:
			PLAY: toggle_pause()
			PAUSE: toggle_pause()
			BAG: close_bag()
			LIST: close_list()
			DIALOG: _close_dialog()
			SELECT: to_menu()
			MENU: get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if in_world():
			save_game()
		if state == PLAY and not autotest and what != NOTIFICATION_WM_CLOSE_REQUEST:
			toggle_pause()


func toggle_pause() -> void:
	if state == PLAY:
		state = PAUSE
		hud.refresh_pause()
		_show_only(hud.pause_panel)
		music.stream_paused = true
		save_game()
	elif state == PAUSE:
		state = PLAY
		_show_only(null)
		music.stream_paused = false


func open_bag() -> void:
	if state != PLAY:
		return
	state = BAG
	hud.show_bag()


func close_bag() -> void:
	hud.bag_panel.visible = false
	state = PLAY


# ================================================================== main loop
func _process(delta: float) -> void:
	var dt := minf(delta, 0.05)
	time += dt
	match state:
		MENU, SELECT:
			if stage_hero.has("body"):
				stage_hero.body.position.y = absf(sin(time * PI / beat_len)) * 0.04
				stage_hero.head.rotation.x = sin(time * TAU / beat_len) * 0.06
		PLAY:
			_update_player(dt)
			_update_mobs(dt)
			_update_shots(dt)
			_update_loot(dt)
			_update_fx(dt)
			_update_npcs(dt)
			_update_robot(dt)
			_update_camera(dt)
			save_t += dt
			if save_t > 30.0:
				save_game()
		DIALOG, BAG, PAUSE, LIST:
			_animate_hero(dt, 0.0)
			_update_fx(dt)
			_update_npcs(dt)
			_update_robot(dt)
			_update_camera(dt)
		DEAD:
			dead_t -= dt
			_update_mobs(dt)
			_update_fx(dt)
			_update_camera(dt)
			if dead_t <= 0.0:
				_respawn()


func _update_npcs(_dt: float) -> void:
	var bob := maxf(0.0, 0.05 - minf(beat_phase(), 1.0 - beat_phase()) * 0.2)
	for n in npcs:
		n.body.position.y = bob
		var d: Vector3 = pos - n.pos
		if d.length() < 6.0:
			n.head.rotation.y = clampf(lerp_angle(n.head.rotation.y, atan2(d.x, d.z) - n.node.rotation.y, 0.1), -0.9, 0.9)


func _update_player(dt: float) -> void:
	for k in cd:
		cd[k] = maxf(0.0, cd[k] - dt)
	invuln = maxf(0.0, invuln - dt)
	buff_t = maxf(0.0, buff_t - dt)
	attack_anim = maxf(0.0, attack_anim - dt)
	portal_cd = maxf(0.0, portal_cd - dt)
	combo_t -= dt
	if combo_t <= 0.0:
		combo = 0
	idle_t += dt
	if idle_t > 5.0:
		vibe = maxf(0.0, vibe - 3.0 * dt)
	if heal_left > 0.0:
		var h := minf(heal_left, hp_max * 0.25 * dt)
		heal_left -= h
		hp = minf(hp_max, hp + h)
	var in_combat := false
	for m in mobs:
		if m.alive and m.st == "chase":
			in_combat = true
			break
	if not in_combat:
		hp = minf(hp_max, hp + hp_max * 0.04 * dt)

	var kb := Vector2.ZERO
	if Input.is_key_pressed(KEY_A): kb.x -= 1
	if Input.is_key_pressed(KEY_D): kb.x += 1
	if Input.is_key_pressed(KEY_W): kb.y -= 1
	if Input.is_key_pressed(KEY_S): kb.y += 1
	var jv := joy_vec if joy_vec.length() > 0.12 else kb.limit_length(1.0)
	var spd := 0.0
	if dash_t > 0.0:
		dash_t -= dt
		pos += dash_dir * 32.0 * dt
		if dash_t <= 0.0 and dash_aoe:
			_aoe(pos, 3.2, _base_dmg() * 1.2, false, 0.6)
			_ring_fx(pos + Vector3(0, 0.15, 0), Color("ff4fa8"), 3.2, 0.4)
			play_sfx("smash", 1.3, -6.0)
		spd = 1.0
	elif jv.length() > 0.0:
		var md := _move_dir(jv)
		var sp := 6.2 * minf(1.0, jv.length() * 1.3)
		pos += md.normalized() * sp * dt
		spd = sp / 6.2
		var want := atan2(md.x, md.z)
		if attack_anim <= 0.0:
			facing = lerp_angle(facing, want, minf(1.0, dt * 12.0))
	if pull_v.length() > 0.05:
		pos += pull_v * dt
		pull_v = pull_v.move_toward(Vector3.ZERO, 14.0 * dt)
	pos = World.resolve(pos, 0.45, world.rects, world.circles, world.bounds)
	for m in mobs:
		if m.alive:
			var d := Vector2(pos.x - m.pos.x, pos.z - m.pos.z)
			var rr: float = m.radius + 0.45
			if d.length() < rr and d.length() > 0.01:
				var push := d.normalized() * (rr - d.length())
				pos.x += push.x
				pos.z += push.y
	_animate_hero(dt, spd)
	if target != null and (not target.alive or target.pos.distance_to(pos) > 30.0):
		target = null
	current_interact = _find_interact()
	if portal_cd <= 0.0 and state == PLAY:
		for pt in world.portals:
			if Vector2(pos.x - pt.pos.x, pos.z - pt.pos.z).length() < pt.r:
				save_game()
				_travel(pt.to, pt.spawn)
				return


func _animate_hero(dt: float, spd: float) -> void:
	if not hero.has("root") or not is_instance_valid(hero.root):
		return
	walk_phase += dt * (9.0 * spd)
	var sw := sin(walk_phase) * 0.8 * minf(1.0, spd)
	hero.legs[0].rotation.x = sw
	hero.legs[1].rotation.x = -sw
	var arm_r := -sw * 0.7
	if attack_anim > 0.0:
		arm_r = -1.6 + (0.3 - attack_anim) * 2.0
	if cls == "medic" and attack_anim > 0.0:
		hero.guitar.rotation.z = -0.9 + sin(attack_anim * 20.0) * 0.3
	hero.arms[1].rotation.x = arm_r
	hero.arms[0].rotation.x = sw * 0.7
	var beat_bob := maxf(0.0, 0.06 - minf(beat_phase(), 1.0 - beat_phase()) * 0.25)
	hero.body.position.y = absf(cos(walk_phase)) * 0.08 * minf(1.0, spd) + beat_bob * (1.0 - minf(1.0, spd))
	hero.head.rotation.x = -beat_bob * 1.5
	hero.body.rotation.x = 0.12 * minf(1.0, spd) + (0.3 if dash_t > 0.0 else 0.0)
	hero.root.position = pos
	hero.root.rotation.y = facing
	if invuln > 0.0 and state == PLAY:
		hero.root.visible = int(time * 20) % 2 == 0 or dash_t > 0.0
	else:
		hero.root.visible = true


func _update_camera(dt: float) -> void:
	cam_touch_t = maxf(0.0, cam_touch_t - dt)
	if cam_touch_t <= 0.0 and joy_vec.length() > 0.5 and state == PLAY:
		var want := facing + PI
		yaw = lerp_angle(yaw, want, minf(1.0, dt * 0.9 * absf(joy_vec.y)))
	var pivot := pos + Vector3(0, 1.7, 0)
	var back := Vector3(sin(yaw), 0, cos(yaw))
	var cp := pivot + back * dist * cos(pitch) + Vector3.UP * dist * sin(pitch)
	cp.y = maxf(cp.y, 0.6)
	cam.global_position = cam.global_position.lerp(cp, minf(1.0, dt * 14.0)) if cam.global_position.distance_to(cp) < 20 else cp
	cam.fov = 60
	cam.look_at(pivot + Vector3(0, 0.2, 0) - back * 1.5, Vector3.UP)


func _update_mobs(dt: float) -> void:
	for m in mobs:
		var node: Node3D = m.node
		if not m.alive:
			m.dead_t += dt
			node.rotation.z = minf(1.5, m.dead_t * 5.0)
			node.position.y = -minf(1.0, maxf(0.0, m.dead_t - 1.0)) * 2.0
			if m.dead_t > 2.0:
				node.visible = false
			if m.kind != "pakhan" and not m.temp:
				m.respawn -= dt
				if m.respawn <= 0.0:
					m.alive = true
					m.hp = m.hp_max
					m.pos = m.home
					m.st = "idle"
					m.stun = 0.0
					node.visible = true
					node.rotation.z = 0
					node.position = m.pos
			continue
		m.hit = maxf(0.0, m.hit - dt)
		m.atk_cd -= dt
		var to_p: Vector3 = pos - m.pos
		to_p.y = 0
		var dp := to_p.length()
		var from_home: float = m.pos.distance_to(m.home)
		var spd := 0.0
		if m.stun > 0.0:
			m.stun -= dt
		elif m.st == "idle":
			m.t -= dt
			if m.t <= 0.0:
				m.wander = m.home + Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
				m.t = randf_range(2.5, 5.0)
			var wd: Vector3 = m.wander - m.pos
			if wd.length() > 0.3:
				spd = 1.2 if m.kind != "scooter" else 2.2
				m.yaw = lerp_angle(m.yaw, atan2(wd.x, wd.z), minf(1.0, dt * 4))
				m.pos += wd.normalized() * spd * dt
			if dp < m.aggro and state == PLAY:
				m.st = "chase"
				play_sfx("near", 1.4, -10.0)
		elif m.st == "chase":
			if state != PLAY or from_home > m.leash:
				m.st = "return"
				m.charge_t = 0.0
			else:
				spd = _mob_chase(m, dt, to_p, dp)
		elif m.st == "return":
			var hd: Vector3 = m.home - m.pos
			if hd.length() < 0.6:
				m.st = "idle"
				m.hp = m.hp_max
			else:
				spd = 6.5
				m.yaw = lerp_angle(m.yaw, atan2(hd.x, hd.z), minf(1.0, dt * 8))
				m.pos += hd.normalized() * spd * dt
				m.hp = minf(m.hp_max, m.hp + m.hp_max * 0.3 * dt)
		for o in mobs:
			if not is_same(o, m) and o.alive:
				var d := Vector2(m.pos.x - o.pos.x, m.pos.z - o.pos.z)
				var rr: float = m.radius + o.radius
				if d.length() < rr and d.length() > 0.01:
					var push := d.normalized() * (rr - d.length()) * 0.5
					m.pos.x += push.x
					m.pos.z += push.y
		m.pos = World.resolve(m.pos, m.radius * 0.8, world.rects, world.circles, world.bounds)
		_animate_mob(m, dt, spd)


func _mob_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	var reach: float = m.radius + 0.9
	match m.kind:
		"scooter":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				spd = 11.0
				m.pos += m.charge_dir * spd * dt
				if dp < reach + 0.3:
					hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
					pull_v = m.charge_dir * 9.0
					m.charge_t = 0.0
					m.atk_cd = m.atk
					hud.float_text(pos + Vector3(0, 2.8, 0), "Дзынь-БАМ!", Color("9af0ff"), 22, 40)
				return spd
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
			if m.atk_cd <= 0.0 and dp < 9.0:
				m.charge_dir = to_p.normalized()
				m.charge_t = 0.85
				m.flap = 0.3
				play_sfx("dash", 1.5, -6.0)
			elif dp > 4.5:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
		"vacuum":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 4))
			m.pull_cd -= dt
			if m.pull_cd <= 0.0 and dp < 7.5 and dp > reach:
				m.pull_cd = 6.0
				m.flap = 1.0
				pull_v = -to_p.normalized() * 8.0
				hud.float_text(m.pos + Vector3(0, 2.2, 0), "ВЖЖЖУХ!", Color("ffd84a"), 26, 40)
				play_sfx("near", 0.6, -2.0)
			if dp > reach:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
		_:
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
			if dp > reach:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
			elif m.atk_cd <= 0.0 and m.tele == null:
				m.atk_cd = m.atk
				m.flap = 0.35
				hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
			if m.kind == "pakhan":
				_boss_special(m, dt)
	return spd


func _animate_mob(m: Dictionary, dt: float, spd: float) -> void:
	var node: Node3D = m.node
	m.flap = maxf(0.0, m.flap - dt)
	match m.kind:
		"scooter":
			for w in m.wheels:
				w.rotation.x += dt * spd * 6.0
			m.head.rotation.x = -0.25 if m.charge_t > 0.0 else sin(time * 3.0 + m.home.x) * 0.05
			m.body.rotation.z = sin(time * 8.0) * 0.06 * minf(1.0, spd)
		"vacuum":
			m.head.rotation.y = sin(time * 2.2 + m.home.z) * 0.5
			m.head.rotation.x = -0.4 if m.flap > 0.0 else sin(time * 3.0) * 0.08
			m.body.scale = Vector3.ONE * (1.0 + (sin(time * 30.0) * 0.03 if m.flap > 0.0 else 0.0))
		_:
			var flap := 0.0
			if m.st == "chase" or m.flap > 0.0:
				flap = (sin(time * 22.0) * 0.6 + 0.4) if m.stun <= 0.0 else 0.0
			m.wings[0].rotation.z = -flap
			m.wings[1].rotation.z = flap
			m.head.rotation.x = 0.6 if m.flap > 0.2 else sin(time * 6.0 + m.home.x) * 0.15 * minf(1.0, spd)
			m.body.position.y = absf(sin(time * 10.0 + m.home.z)) * 0.08 * minf(1.0, spd)
	var squash: float = 1.0 + m.hit * 0.8
	node.scale = Vector3(m.scale * squash, m.scale / squash, m.scale * squash)
	node.position = m.pos
	node.rotation.y = m.yaw
	node.rotation.z = sin(time * 12.0) * 0.15 if m.stun > 0.0 else 0.0


func _boss_special(m: Dictionary, dt: float) -> void:
	if m.tele != null:
		m.tele_t -= dt
		m.flap = 0.4
		if m.tele_t <= 0.0:
			var c: Node3D = m.tele
			if Vector2(pos.x - c.position.x, pos.z - c.position.z).length() < 4.2:
				hurt_player(60.0, m.pos)
				hud.toast("Крылья-ураган! Отбегай из красного круга", Color("ff8080"))
			_ring_fx(c.position + Vector3(0, 0.2, 0), Color("ff2a3a"), 4.4, 0.4)
			play_sfx("smash", 0.8, -2.0)
			c.queue_free()
			m.tele = null
		return
	m.special -= dt
	if m.special <= 0.0:
		m.special = 6.5
		_telegraph(m)
		hud.toast("Пахан машет крыльями — уйди из круга!", Color("ff9a9a"))
	if not m.summoned and m.hp < m.hp_max * 0.5:
		m.summoned = true
		for o in [Vector3(-3, 0, 2), Vector3(3, 0, 2)]:
			var s := _spawn_mob("pigeon", m.pos + o, 4)
			s.st = "chase"
			s.temp = true
		hud.toast("Пахан позвал подмогу!", Color("ff9a9a"))


func _update_shots(dt: float) -> void:
	for s in shots.duplicate():
		var n: Node3D = s.node
		s.life -= dt
		var t: Dictionary = s.t
		var aim: Vector3 = t.pos + Vector3(0, t.height * 0.55, 0)
		var d := aim - n.global_position
		var step := 24.0 * dt
		if d.length() <= step or not t.alive or s.life <= 0.0:
			if t.alive and s.life > 0.0:
				damage_mob(t, s.dmg, s.crit, s.stun)
			n.queue_free()
			shots.erase(s)
			continue
		n.global_position += d.normalized() * step
		n.look_at(aim, Vector3.UP)
		var sc: float = 1.0 + (1.5 - s.life) * 1.2
		n.scale = Vector3.ONE * sc


func _update_loot(dt: float) -> void:
	for l in loots.duplicate():
		l.t += dt
		l.spin.rotation.y += dt * 2.0
		l.spin.position.y = 0.4 + sin(l.t * 3.0) * 0.1
		if l.t > 0.6 and Vector2(pos.x - l.pos.x, pos.z - l.pos.z).length() < 1.8:
			add_item(l.id)
			play_sfx("pickup", 1.0 + l.item.rarity * 0.08)
			l.node.queue_free()
			loots.erase(l)
		elif l.t > 120.0:
			l.node.queue_free()
			loots.erase(l)


func _update_fx(dt: float) -> void:
	for f in fx.duplicate():
		f.t += dt
		var n = f.node
		if not is_instance_valid(n):
			fx.erase(f)
			continue
		var k: float = f.t / f.life
		match f.kind:
			"ring":
				n.scale = Vector3.ONE * lerpf(0.2, f.r, minf(1.0, k * 1.4))
			"rise":
				n.position.y += dt * 1.4
				n.rotation.y += dt * 3.0
		if f.t >= f.life:
			n.queue_free()
			fx.erase(f)


# ================================================================== automated test (CI / local)
func _bot_fight(frames_max: int, until: Callable) -> int:
	var frames := 0
	while frames < frames_max and not until.call():
		await get_tree().process_frame
		frames += 1
		if state == DEAD:
			continue
		if state != PLAY:
			continue
		var t = _pick_target(60.0)
		if t != null:
			var d: Vector3 = t.pos - pos
			if d.length() > 7.0:
				joy_vec = Vector2(0, -1)
				yaw = atan2(-d.x, -d.z)
			else:
				joy_vec = Vector2.ZERO
				target = t
				if frames % 3 == 0:
					press("attack")
				if frames % 50 == 0:
					press(["s1", "s2", "s3"][(frames / 50) % 3])
				if vibe >= 100.0:
					press("ult")
		for l in loots:
			if l.pos.distance_to(pos) < 9.0:
				pos = l.pos
				break
		hp = maxf(hp, hp_max * 0.5)
	joy_vec = Vector2.ZERO
	return frames


func _go_interact(p: Vector3) -> void:
	pos = p + Vector3(1.2, 0, 0.6)
	await get_tree().process_frame
	await get_tree().process_frame
	interact()


func _run_autotest() -> void:
	var shots_dir := ""
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0 and i + 1 < args.size():
		shots_dir = args[i + 1]
	var quick := args.has("--quick")
	var lg := []
	await get_tree().create_timer(0.5).timeout
	if shots_dir != "":
		await _snap(shots_dir, "0_menu")
	open_select()
	set_combo("rapper", "cop")
	await get_tree().create_timer(0.3).timeout
	await start_game(true)
	while state != PLAY:
		await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	# chain 1
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_accept_quest()
	_close_dialog()
	var f1 := await _bot_fight(150 if quick else (240 if args.has("--skip1") else 3000), func(): return quest >= 4)
	lg.append("chain1 quest=%d frames=%d" % [quest, f1])
	if shots_dir != "":
		await _snap(shots_dir, "1_yard_fight")
	if quick:
		_finish_report(lg, t0)
		return
	quest = 4
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_finish_quest()
	_close_dialog()
	await _go_interact(Vector3(-5.9, 0, -5.0))
	await get_tree().create_timer(0.2).timeout
	quest2 = 1
	_close_dialog()
	# shop + dailies
	coins += 500
	await _go_interact(Vector3(-9.7, 0, -13.1))
	lg.append("shop open=%s" % str(state == LIST and list_kind == "shop"))
	_buy("food", 30, 1)
	_buy("planks", 60, 5)
	_sell_junk()
	if shots_dir != "":
		await _snap(shots_dir, "2_shop")
	close_list()
	daily.pigeon = 99
	daily.scooter = 99
	daily.vacuum = 99
	await _go_interact(Vector3(4.6, 0, 13.6))
	_claim_daily("pigeon")
	_claim_daily("scooter")
	_claim_daily("vacuum")
	lg.append("dailies claimed=%d" % daily.claimed.size())
	close_list()
	# travel to the garages through the arch
	pos = Vector3(15.6, 0, -27.6)
	portal_cd = 0.0
	while map_id != "garages" or state != PLAY:
		await get_tree().process_frame
	lg.append("map=%s npcs=%d" % [map_id, npcs.size()])
	await _go_interact(Vector3(10.2, 0, 4.6))
	_close_dialog()
	quest2 = 2
	_refresh_robot()
	await _go_interact(Base.ROBOT_HOME)
	_send_robot("ezhik")
	lg.append("robot task=%s quest2=%d" % [robot_task.task, quest2])
	for k in range(60):
		await get_tree().process_frame
	if shots_dir != "":
		await _snap(shots_dir, "3_garages_robot_leaving")
	time_shift += 200.0
	await get_tree().process_frame
	await _go_interact(Base.ROBOT_HOME)
	_collect_robot()
	close_list()
	lg.append("after robot quest2=%d planks=%d food=%d" % [quest2, res.planks, food])
	res.brick += 60
	res.planks += 60
	res.cement += 40
	res.wires += 60
	coins += 3000
	for id in GameData.BUILD_ORDER:
		_build(id)
	_build("grill")
	_build("stage")
	_build("stage")
	close_list()
	lg.append("buildings=%s quest2=%d hp_max=%d" % [str(buildings), quest2, int(hp_max)])
	time_shift += 1300.0
	await get_tree().process_frame
	await _go_interact(Base.SLOTS.grill)
	_collect("grill")
	close_list()
	await _go_interact(Base.SLOTS.garden)
	_collect("garden")
	close_list()
	await _go_interact(Vector3(10.2, 0, 4.6))
	_close_dialog()
	if quest2 == 5:
		quest2 = 6
	pos = Vector3(4, 0, 0)
	facing = PI * 0.9
	yaw = facing + PI
	for k in range(20):
		await get_tree().process_frame
	if shots_dir != "":
		await _snap(shots_dir, "4_garages_base")
	# save / load round trip
	save_game()
	var before := JSON.stringify(_save_dict()).length()
	var c0 := coins
	coins = 0
	load_game()
	lg.append("save roundtrip coins=%d==%d len=%d" % [coins, c0, before])
	# back to the yard
	pos = Vector3(29.6, 0, 0)
	portal_cd = 0.0
	while map_id != "yard" or state != PLAY:
		await get_tree().process_frame
	await _bot_fight(120 if shots_dir != "" else 400, func(): return false)
	if shots_dir != "":
		open_bag()
		await _snap(shots_dir, "5_bag")
		close_bag()
	lg.append("final level=%d coins=%d food=%d items=%d" % [level, coins, food, inventory.size()])
	_finish_report(lg, t0)


func _finish_report(lg: Array, t0: int) -> void:
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	for l in lg:
		print("AUTOTEST ", l)
	print("AUTOTEST_DONE quest=%d quest2=%d level=%d coins=%d ms=%d draws=%d prims=%d" % [quest, quest2, level, coins, Time.get_ticks_msec() - t0, dc, prims])
	get_tree().quit()


func _snap(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
