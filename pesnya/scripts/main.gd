extends Node3D
## «Песня» — тестовая сборка геймплея (студия Aolovo).
## Двор «Берёзки»: герой от третьего лица, бой под бит, голуби-вымогатели, добыча, квест бабы Зины, Голубиный Пахан.

const BPM := 96.0
var beat_len := 60.0 / BPM
var beat_win := 0.13

enum { MENU, SELECT, LOADING, PLAY, DIALOG, BAG, PAUSE, DEAD }
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
var regen_t := 0.0
var cd := {"attack": 0.0, "s1": 0.0, "s2": 0.0, "s3": 0.0}
var cd_max := {"attack": 0.42, "s1": 7.0, "s2": 9.0, "s3": 5.0}
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
var mobs: Array = []
var loots: Array = []
var shots: Array = []
var fx: Array = []
var target = null
var npc: Dictionary
var npc_pos := Vector3(-5.9, 0, -5.0)

# ---------------------------------------------------------------- quest & items
var quest := 0          # 0 not taken, 1 kill 6, 2 find feather, 3 beat Pakhan, 4 return, 5 done
var quest_kills := 0
var feather_kills := 0
var inventory: Array = []
var equipped := {}

const ITEMS := {
	"seeds": {"name": "Семки", "rarity": 0, "slot": "", "power": 0, "desc": "Голубиная валюта. Баба Зина говорит, полезные."},
	"feather": {"name": "Пёрышко", "rarity": 0, "slot": "", "power": 0, "desc": "Мягкое. Можно щекотать врагов (нельзя)."},
	"crumbs": {"name": "Крошки батона", "rarity": 0, "slot": "", "power": 0, "desc": "Остатки голубиной роскоши."},
	"cap": {"name": "Кепка вымогателя", "rarity": 1, "slot": "head", "power": 4, "desc": "Восьмиклинка. +4 к силе и к понтам."},
	"chain": {"name": "Цепочка голубя", "rarity": 1, "slot": "neck", "power": 4, "desc": "Тонкая, но своя."},
	"sneaker": {"name": "Кроссовок-беглец", "rarity": 1, "slot": "feet", "power": 5, "desc": "Второй где-то во дворе."},
	"mic": {"name": "Микрофон «Голубиный»", "rarity": 2, "slot": "weapon", "power": 12, "desc": "Воркует в бит. +12 к силе."},
	"luck": {"name": "Перо удачи", "rarity": 2, "slot": "neck", "power": 10, "desc": "То самое перо, о котором шепчет весь двор."},
	"pakhan_cap": {"name": "Кепка Пахана", "rarity": 3, "slot": "head", "power": 25, "desc": "Легендарная. Голуби кланяются при виде."},
}

# ---------------------------------------------------------------- audio
var music: AudioStreamPlayer
var run_stream: AudioStream
var menu_stream: AudioStream
var sfx := {}
var sfx_players: Array = []
var music_on := true
var beat_offset := 0.0
var quality := 1
var autotest := false


func _ready() -> void:
	Kit.init()
	randomize()
	Engine.max_fps = 60
	autotest = OS.get_cmdline_user_args().has("--autotest")
	_setup_audio()
	_setup_env()
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
	for p in [hud.menu_panel, hud.select_panel, hud.dialog_panel, hud.bag_panel, hud.pause_panel, hud.dead_panel, hud.loading_panel]:
		p.visible = p == panel


func to_menu() -> void:
	get_tree().paused = false
	if world.has("root"):
		_clear_world()
	state = MENU
	we.environment = env_studio
	sun.visible = false
	rim.visible = false
	stage.visible = true
	for l in studio_lights:
		l.visible = true
	_stage_cam()
	_show_only(hud.menu_panel)
	_play_music(menu_stream)


func open_select() -> void:
	state = SELECT
	_show_only(hud.select_panel)
	hud.refresh_select()


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


func start_game() -> void:
	hero_name = Chars.HERO_NAMES[race + "_" + cls]
	# portrait from the podium render
	var img := get_viewport().get_texture().get_image()
	if img != null:
		_grab_portrait(img)
	state = LOADING
	_show_only(hud.loading_panel)
	await get_tree().process_frame
	await get_tree().process_frame
	_build_world()
	state = PLAY
	_show_only(null)
	hud.big("Двор «Берёзки»", "Найди бабу Зину — у неё есть дело", 3.0)


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


# ================================================================== world
func _build_world() -> void:
	stage.visible = false
	for l in studio_lights:
		l.visible = false
	we.environment = env_world
	sun.visible = true
	rim.visible = true
	set_quality(quality)
	world = World.build(self)
	# hero
	hero = Chars.hero(race, cls)
	world.root.add_child(hero.root)
	Kit.bake_tree(hero.root)
	pos = Vector3(0, 0, 12)
	facing = PI
	yaw = 0.0
	hp_max = 300.0 * (1.2 if race == "punk" else 1.0)
	hp = hp_max
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
	target = null
	if cls == "cop":
		cd_max = {"attack": 0.42, "s1": 7.0, "s2": 9.0, "s3": 5.0}
	else:
		cd_max = {"attack": 0.42, "s1": 9.0, "s2": 15.0, "s3": 6.0}
	for k in cd:
		cd[k] = 0.0
	# NPC
	npc = Chars.granny_npc()
	world.root.add_child(npc.root)
	npc.root.position = npc_pos
	npc.root.rotation.y = PI / 2
	Kit.bake_tree(npc.root)
	# pigeons
	mobs.clear()
	var spawns := [Vector3(3, 0, -6), Vector3(-2, 0, -11), Vector3(6, 0, -14), Vector3(-9, 0, -19), Vector3(2, 0, -19),
		Vector3(11, 0, -21), Vector3(-13, 0, 3), Vector3(12, 0, 9), Vector3(-13, 0, -9), Vector3(14, 0, -2)]
	for i in range(spawns.size()):
		_spawn_pigeon(spawns[i], 2 + i % 3)
	_play_music(run_stream)


func _spawn_pigeon(at: Vector3, lvl: int, boss := false) -> Dictionary:
	var p := Chars.pigeon(true, boss)
	world.root.add_child(p.root)
	Kit.bake_tree(p.root)
	var sc := 1.25 if boss else 0.72
	p.root.scale = Vector3.ONE * sc
	var m := {
		"kind": "pakhan" if boss else "pigeon", "node": p.root, "body": p.body, "head": p.head, "wings": p.wings,
		"pos": at, "home": at, "yaw": randf() * TAU, "lvl": lvl, "scale": sc,
		"name": "Голубиный Пахан" if boss else "Голубь-вымогатель",
		"hp_max": 1500.0 if boss else 70.0 + lvl * 32.0, "dmg": 26.0 if boss else 5.0 + lvl * 3.0,
		"xp": 420 if boss else 24 + lvl * 9, "height": 3.0 * sc, "radius": 1.1 * sc,
		"st": "idle", "t": randf() * 3.0, "atk_cd": 1.0, "stun": 0.0, "alive": true, "respawn": 0.0,
		"wander": at, "flap": 0.0, "hit": 0.0, "aggro": 12.0 if boss else 7.0, "leash": 22.0 if boss else 15.0,
		"special": 4.0, "tele": null, "tele_t": 0.0, "summoned": false, "dead_t": 0.0,
	}
	m.hp = m.hp_max
	p.root.position = at
	mobs.append(m)
	return m


func _clear_world() -> void:
	for m in mobs:
		if is_instance_valid(m.node):
			m.node.queue_free()
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
	if world.has("root"):
		world.root.queue_free()
	world = {}
	target = null


func in_world() -> bool:
	return state in [PLAY, DIALOG, BAG, PAUSE, DEAD]


# ================================================================== quest
func quest_lines() -> Array:
	match quest:
		0: return ["Двор «Берёзки»", "Найди бабу Зину у лавочки (жёлтая «!»)"]
		1: return ["Голубиная мафия", "Разогнать голубей: %d / 6" % quest_kills, "Совет: бей в бит — урон ×2"]
		2: return ["Голубиная мафия", "Найти Перо удачи у голубей", "Оно светится фиолетовым"]
		3: return ["Голубиная мафия", "Победить Голубиного Пахана", "У гаражей. Не стой в красном круге!"]
		4: return ["Голубиная мафия", "Вернуться к бабе Зине"]
	return ["Свободная игра", "Голуби возрождаются. Качайся!"]


func npc_marker() -> String:
	if quest == 0:
		return "!"
	if quest == 4:
		return "?"
	return ""


func can_talk() -> bool:
	return state == PLAY and pos.distance_to(npc_pos) < 3.4


func talk() -> void:
	if not can_talk():
		return
	state = DIALOG
	_face(npc_pos)
	var close := func(): hud.hide_dialog(); state = PLAY
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
			hud.show_dialog("Баба Зина", "Пахан у гаражей! Он крыльями машет — красный круг видишь, сразу отбегай!", [["Есть!", close]])
		4:
			hud.show_dialog("Баба Зина", "Батюшки! Сам Пахан! Держи пирожок и монеты. Весь двор теперь за тебя!", [["Спасибо, баб Зин! (+300 монет)", func(): _finish_quest(); close.call()]])
		_:
			hud.show_dialog("Баба Зина", "Заходи ещё, милок! Скоро в гаражах базы откроются — говорят, роботов дадут.", [["До встречи!", close]])
	play_sfx("ui")


func _accept_quest() -> void:
	quest = 1
	hud.toast("Новое задание: «Голубиная мафия»", Hud.GOLD)
	play_sfx("bank")


func _finish_quest() -> void:
	quest = 5
	coins += 300
	gain_xp(300)
	hud.big("ДЕМО ПРОЙДЕНО!", "Спасибо за тест ♪ Можно играть дальше", 5.0)
	play_sfx("bank")


func _on_kill(m: Dictionary) -> void:
	if quest == 1 and m.kind == "pigeon":
		quest_kills += 1
		if quest_kills >= 6:
			quest = 2
			hud.toast("Задание обновлено: найди Перо удачи", Hud.GOLD)
			play_sfx("bank")
	elif quest == 2 and m.kind == "pigeon":
		feather_kills += 1
	elif m.kind == "pakhan":
		quest = 4
		hud.big("ПАХАН ПОВЕРЖЕН!", "Вернись к бабе Зине", 4.0)


# ================================================================== items, xp
func xp_next() -> int:
	return 80 + level * 60


func gain_xp(v: int) -> void:
	xp += v
	while xp >= xp_next() and level < 10:
		xp -= xp_next()
		level += 1
		hp_max = (300.0 + (level - 1) * 45.0) * (1.2 if race == "punk" else 1.0)
		hp = hp_max
		hud.big("НОВЫЙ УРОВЕНЬ %d!" % level, "Здоровье и урон выросли", 2.5)
		play_sfx("bank", 1.1)
		_ring_fx(pos + Vector3(0, 0.1, 0), Kit.GOLD, 2.5, 0.8)
	if level >= 10:
		xp = mini(xp, xp_next() - 1)


func _recalc_power() -> void:
	power = 0
	for s in equipped:
		power += equipped[s].power


func add_item(id: String) -> void:
	var src: Dictionary = ITEMS[id]
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
		var pk := _spawn_pigeon(Vector3(0, 0, -24), 7, true)
		pk.st = "idle"
		hud.big("ГОЛУБИНЫЙ ПАХАН", "вылез у гаражей!", 3.5)
		play_sfx("laser", 0.7)


func _drop_loot(m: Dictionary) -> void:
	var drops: Array = []
	if m.kind == "pakhan":
		drops = ["pakhan_cap", "mic"]
		coins += 150
	else:
		coins += randi_range(4, 12) + m.lvl * 2
		var r := randf()
		if r < 0.05:
			drops.append("mic")
		elif r < 0.25:
			drops.append(["cap", "chain", "sneaker"][randi() % 3])
		elif r < 0.75:
			drops.append(["seeds", "feather", "crumbs"][randi() % 3])
		if quest == 2 and (randf() < 0.35 or feather_kills >= 3):
			drops.append("luck")
	for i in range(drops.size()):
		var id: String = drops[i]
		var it: Dictionary = ITEMS[id]
		var n := Node3D.new()
		fx_root.add_child(n)
		var lp: Vector3 = m.pos + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
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
	if buff_t > 0.0:
		d *= 1.6
	return d * randf_range(0.9, 1.1)


func _beat_action(name: String) -> bool:
	var ok := on_beat()
	if ok:
		combo += 1
		vibe = minf(100.0, vibe + 14.0)
		play_sfx("beat", 1.0 + minf(combo, 8) * 0.03, -3.0)
	else:
		combo = 0
		vibe = minf(100.0, vibe + 4.0)
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
		"talk": talk()
		"pause": toggle_pause()
		"bag": open_bag()


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
	_burst(m.pos + Vector3(0, 1.2, 0), [Color("c8ccd8"), Color("8a93a8"), Color.WHITE], 24)
	play_sfx("drop", 0.8)
	if is_same(target, m):
		target = null
	_on_kill(m)


func hurt_player(dmg: float, from: Vector3) -> void:
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
	pos = npc_pos + Vector3(2.0, 0, 1.0)
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
	var np: Vector3 = npc_pos + Vector3(0, 1.2, 0)
	if not cam.is_position_behind(np) and cam.unproject_position(np).distance_to(p) < 120 and can_talk():
		talk()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		match state:
			PLAY: toggle_pause()
			PAUSE: toggle_pause()
			BAG: close_bag()
			DIALOG:
				hud.hide_dialog()
				state = PLAY
			SELECT: to_menu()
			MENU: get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if state == PLAY and not autotest:
			toggle_pause()


func toggle_pause() -> void:
	if state == PLAY:
		state = PAUSE
		hud.refresh_pause()
		_show_only(hud.pause_panel)
		music.stream_paused = true
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
			stage.rotation.y = 0.0
		PLAY:
			_update_player(dt)
			_update_mobs(dt)
			_update_shots(dt)
			_update_loot(dt)
			_update_fx(dt)
			_update_camera(dt)
		DIALOG, BAG, PAUSE:
			_animate_hero(dt, 0.0)
			_update_fx(dt)
			_update_camera(dt)
		DEAD:
			dead_t -= dt
			_update_mobs(dt)
			_update_fx(dt)
			_update_camera(dt)
			if dead_t <= 0.0:
				_respawn()


func _update_player(dt: float) -> void:
	for k in cd:
		cd[k] = maxf(0.0, cd[k] - dt)
	invuln = maxf(0.0, invuln - dt)
	buff_t = maxf(0.0, buff_t - dt)
	attack_anim = maxf(0.0, attack_anim - dt)
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
	# out-of-combat regeneration
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
	pos = World.resolve(pos, 0.45, world.rects, world.circles)
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


func _animate_hero(dt: float, spd: float) -> void:
	if not hero.has("root"):
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
	# gently swing behind the hero while running (mobile MMO style)
	if cam_touch_t <= 0.0 and joy_vec.length() > 0.5 and state == PLAY:
		var want := facing + PI   # yaw at which the camera forward equals the hero's facing
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
			if m.kind == "pigeon":
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
				spd = 1.2
				m.yaw = lerp_angle(m.yaw, atan2(wd.x, wd.z), minf(1.0, dt * 4))
				m.pos += wd.normalized() * spd * dt
			if dp < m.aggro and state == PLAY:
				m.st = "chase"
				play_sfx("near", 1.4, -10.0)
		elif m.st == "chase":
			if state != PLAY or from_home > m.leash:
				m.st = "return"
			else:
				m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
				var reach: float = m.radius + 0.9
				if dp > reach:
					spd = 4.4 if m.kind == "pigeon" else 3.6
					m.pos += to_p.normalized() * spd * dt
				elif m.atk_cd <= 0.0 and m.tele == null:
					m.atk_cd = 1.5 if m.kind == "pigeon" else 1.8
					m.flap = 0.35
					hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
				if m.kind == "pakhan":
					_boss_special(m, dt)
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
		# separation & world collision
		for o in mobs:
			if not is_same(o, m) and o.alive:
				var d := Vector2(m.pos.x - o.pos.x, m.pos.z - o.pos.z)
				var rr: float = m.radius + o.radius
				if d.length() < rr and d.length() > 0.01:
					var push := d.normalized() * (rr - d.length()) * 0.5
					m.pos.x += push.x
					m.pos.z += push.y
		m.pos = World.resolve(m.pos, m.radius * 0.8, world.rects, world.circles)
		# animation
		m.flap = maxf(0.0, m.flap - dt)
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
			var s := _spawn_pigeon(m.pos + o, 4)
			s.st = "chase"
			s.home = s.pos
			s.respawn = 9999.0
			s.kind = "pigeon_temp"
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
func _run_autotest() -> void:
	var shots_dir := ""
	var args := OS.get_cmdline_user_args()
	var i := args.find("--shots")
	if i >= 0 and i + 1 < args.size():
		shots_dir = args[i + 1]
	await get_tree().create_timer(0.5).timeout
	if shots_dir != "":
		await _snap(shots_dir, "0_menu")
	open_select()
	set_combo("rapper", "cop")
	await get_tree().create_timer(0.3).timeout
	if shots_dir != "":
		await _snap(shots_dir, "1_select")
	start_game()
	while state != PLAY:
		await get_tree().process_frame
	# walk to Zina and take the quest
	pos = npc_pos + Vector3(2.2, 0, 0.5)
	await get_tree().create_timer(0.3).timeout
	talk()
	await get_tree().create_timer(0.2).timeout
	_accept_quest()
	hud.hide_dialog()
	state = PLAY
	var frames := 0
	var t0 := Time.get_ticks_msec()
	var limit := 150 if args.has("--quick") else 2400
	while frames < limit and quest < 5:
		await get_tree().process_frame
		frames += 1
		if state == DEAD:
			continue
		if quest == 4:
			pos = npc_pos + Vector3(2.0, 0, 0.5)
			talk()
			_finish_quest()
			hud.hide_dialog()
			state = PLAY
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
		hp = maxf(hp, hp_max * 0.5)  # keep the bot alive
		if shots_dir != "" and frames == 500:
			await _snap(shots_dir, "2_fight")
		if shots_dir != "" and quest == 3 and frames % 400 == 0:
			await _snap(shots_dir, "3_boss_%d" % frames)
	var ms := Time.get_ticks_msec() - t0
	if shots_dir != "":
		open_bag()
		await _snap(shots_dir, "4_bag")
		close_bag()
	var dc := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var objs := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	print("AUTOTEST_DONE quest=%d level=%d coins=%d items=%d mobs=%d frames=%d ms=%d fps=%d draws=%d prims=%d objs=%d" % [quest, level, coins, inventory.size(), mobs.size(), frames, ms, Engine.get_frames_per_second(), dc, prims, objs])
	get_tree().quit()


func _snap(dir: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
