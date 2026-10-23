extends Node3D
## «Песня» — офлайн-версия (студия Aolovo).
## Двор «Берёзки» + ГК «Песня» + Стройка Глушилки: бой под бит, мобы, добыча, квесты, база в гараже, робот Вася, магазин,
## ежедневные задания, сохранения; 0.3 — Тишинки, босс Шумодав, напарница баба Зина и маунт Избушка-Бас;
## 0.4 — серверная Кощея: дверь с рэп-кодом, робо-зайцы, заяц-сейф, рэп-баттл с Кощеем, напарник Вася-3000;
## 0.5 — концерт в ГК (ритм-игра), набережная и Калинов мост, колонки-автоплеи, чайки, Змей Горыныч.
## 0.6 — 12 новых соседей и их задания, журнал, тихие зоны, уровни до 70, вещи с характеристиками.
## 0.7 — парк «Заря» за Калиновым мостом, Колесо Обновлений, вторые задания соседей, ремиксы боссов,
##       золотые синглы и Сингл Принц, карта Рубина и аэротакси Шустрого Пилота.

const BPM := 96.0
var beat_len := 60.0 / BPM
var beat_win := 0.13

enum { MENU, SELECT, LOADING, PLAY, DIALOG, BAG, PAUSE, DEAD, LIST, CONCERT }
var state := MENU
var time := 0.0

var hud: Hud
var cam: Camera3D
var we: WorldEnvironment
var env_world: Environment
var env_studio: Environment
var sky_mat: ProceduralSkyMaterial
var map_env := {}
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
var mob_shots: Array = []     # silence bubbles of the Tishinka drones
var companion: Dictionary = {}  # Baba Zina following the player on the construction site
var mount_vis: Dictionary = {}  # Izbushka-Bass model while riding
var mounted := false
var silence_t := 0.0          # «Тишина»: skills are muted, an on-beat hit breaks it
var silence_msg_t := 0.0
var group_t := 0.0            # «Песня группы» buff from Zina

const SLOT_SHORT := {"grill": "Мангал", "garden": "Огород", "gym": "Качалка", "stage": "Сцена", "studio": "Студия", "solar": "Панели"}
const NPC_INFO := {
	"zina": ["Баба Зина", "квесты двора", "Говорить"],
	"misha": ["Дядя Миша", "дворник · ежедневные задания", "Задания"],
	"lyuba": ["Люба", "ларёк «Шаурма»", "Ларёк"],
	"petrovich": ["Петрович", "председатель ГК", "Говорить"],
	"shumodav": ["Шумодав", "бывшая сцена ДК · лифт", "Лифт"],
	"gorynych": ["Змей Горыныч", "бывший хранитель бэкапа", "Говорить"],
	"guard": ["Охранник Подписочкин", "ООО «Тишина Плюс» · проверяет подписку", "Говорить"],
	"prince": ["Сингл Принц", "выпускает релизы · исчезнет через 3 минуты", "Лавка"],
}

# ---------------------------------------------------------------- progress (saved)
var quest := 0          # 0 none, 1 kill 6, 2 feather, 3 Pakhan, 4 return, 5 done
var quest_kills := 0
var feather_kills := 0
var quest2 := 0         # 0 none, 1 find Petrovich, 2 send robot, 3 collect, 4 build grill, 5 return, 6 done
var quest3 := 0         # «Флешка Кощея»: 0 none, 1 get the voucher from Petrovich, 2 go to the site, 3 drones, 4 Shumodav, 5 return to Zina, 6 done
var q3_kills := 0
var mount_owned := false
var quest4 := 0         # «Перепрошивка»: 0 none, 1 lift, 2 rap door, 3 hares, 4 chest, 5 safe hare, 6 Koschei, 7 return to Zina, 8 done
var q4_kills := 0
var lock_active := false
var lock_hits := 0
var vasya_mate: Dictionary = {}
var quest5 := 0         # «Бэкап Горыныча»: 0 none, 1 concert, 2 run to Zina, 3 go to the embankment, 4 speakers, 5 Gorynych, 6 return, 7 done
var q5_kills := 0
var concert: Dictionary = {}
var side: SideRun             # 0.6: side quests of the new neighbours
var stats := {}               # 0.6: secondary stats from equipment (rhythm, luck, hp, speed, vibe)
const SAFE_R := 6.5           # 0.6: «quiet zone» around NPCs — mobs do not start fights there
const RESPAWN_T := 45.0       # 0.6: was 20 s
var quest6 := 0               # 0.7 «Рассвет по подписке»: 0 none, 1 cross the bridge, 2 talk to the guard, 3 dawn stones, 4 stones on the stage, 5 the wheel, 6 return to Zari, 7 done
var q6_stones := 0            # bitmask of the found dawn stones
var singles := 0              # 0.7: golden singles — the rare currency of Сингл Принц
var taxi := false             # 0.7: Pilot's aerotaxi (fast travel from the city map)
var remix := {"best": {}, "day": "", "looted": [], "passes": 0, "wins": 0}
var prince := {"met": false, "next": 2100.0, "left": 0.0, "stock": [], "hit": "", "map": ""}
var prince_npc: Dictionary = {}
var metro_until := 0.0        # «Метроном Сингл Принца»: wider beat window until this unix time
var wheel_deco: Dictionary = {}   # the ferris wheel when it is not a boss
var wheel_t := 0.0
var remix_hidden := {}        # npc id -> npc entry hidden while its remix boss fights
var stone_marks: Array = []
var quest7 := 0               # 0.8 «Мыльная опера»: see U08.main_lines
var kits := 0                 # 0.8: «Отличные аптечки» of the medics (auto-use at HP < 25%)
var kit_cd := 0.0
var grace := 0                # 0.8: Благодать of Бог Здорово
var gifts := {"hp": 0, "luck": 0, "beat": 0, "qxp": 0}
var blessing := {"day": "", "kind": ""}
var medics := false           # 0.8: respawn at the ambulance «Отлично-03»
var fusion := false           # 0.8: recipe «Чебурек-фьюжн» — shawarma speeds up
var fusion_t := 0.0
var slow_t := 0.0             # 0.8: plunger slow
var wind_day := ""            # 0.8: «Второе дыхание» (once a day)
var u08: U08
var quest8 := 0               # 0.9 «Своё дело»: see U09.main_lines
var u09: U09
var concert_nodes: Array = []
var waves: Array = []         # expanding noise rings (speakers, Gorynych)
var traps: Array = []         # delayed red circles on the ground
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
# 0.8: the music changes by itself — a playlist of loops at the same tempo; the beat clock never jumps back between them
var tracks: Array = []          # [{"id", "name", "stream", "len"}]
var track_i := 0
var track_recent: Array = []
var _mclock_base := 0.0
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
	side = SideRun.new(self)
	u08 = U08.new(self)
	u09 = U09.new(self)
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
	sky_mat = psm
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
	menu_stream = load("res://audio/music_menu.ogg")
	if menu_stream is AudioStreamOggVorbis:
		menu_stream.loop = true
	for t in GameData.TRACKS:
		var st: AudioStream = load("res://audio/%s.ogg" % t[0])
		if st is AudioStreamOggVorbis:
			st.loop = false
		tracks.append({"id": t[0], "name": t[1], "stream": st, "len": st.get_length() if st != null else 60.0})
	run_stream = tracks[0].stream
	music = AudioStreamPlayer.new()
	music.volume_db = -4.0
	add_child(music)
	music.finished.connect(_on_track_finished)
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
		if in_world():
			_play_world_music()
		else:
			_play_music(menu_stream)
	else:
		music.stop()


func _is_track(s) -> bool:
	for t in tracks:
		if t.stream == s:
			return true
	return false


## In the world: keep the current track if one is already playing (travel does not restart the song).
func _play_world_music() -> void:
	if not music_on:
		music.stop()
		return
	if music.playing and _is_track(music.stream):
		return
	_start_track(_pick_track(), false)


func _pick_track() -> int:
	var theme: String = GameData.MAP_TRACK.get(map_id, "")
	for i in range(tracks.size()):
		if tracks[i].id == theme and not (i in track_recent):
			return i
	var pool := []
	for i in range(tracks.size()):
		if not (i in track_recent) and i != track_i:
			pool.append(i)
	if pool.is_empty():
		pool = range(tracks.size())
	return pool[randi() % pool.size()]


func _start_track(i: int, announce: bool) -> void:
	track_i = i
	track_recent.append(i)
	while track_recent.size() > 3:
		track_recent.pop_front()
	run_stream = tracks[i].stream
	music.stream = run_stream
	music.play()
	if announce and state == PLAY and not autotest:
		hud.toast("Сейчас играет: «%s»" % tracks[i].name, Color("d8a8ff"))


## A track ended: the beat clock goes on from the whole number of beats it lasted, the next song starts on the downbeat.
func _on_track_finished() -> void:
	if not _is_track(music.stream) or not music_on or not in_world():
		return
	var n_beats: float = round(float(tracks[track_i].len) / beat_len)
	_mclock_base += n_beats * beat_len
	_start_track(_pick_track(), true)


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


var _mpos_last := -1.0
var _mpos_stall := 0.0


func _watch_music_clock(dt: float) -> void:
	# if the audio device does not advance the music (no sound device, tests), fall back to the game clock
	var p := music.get_playback_position() if music.playing else -1.0
	if music.playing and absf(p - _mpos_last) < 0.00001:
		_mpos_stall += dt
	else:
		_mpos_stall = 0.0
	_mpos_last = p


func beat_time() -> float:
	if music.playing and music.stream == run_stream and not autotest and _mpos_stall < 0.4:
		return _mclock_base + music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency() - beat_offset
	return time - beat_offset


func beat_phase() -> float:
	return fposmod(beat_time() / beat_len, 1.0)


func beat_index() -> int:
	return int(floor(beat_time() / beat_len))


func on_beat() -> bool:
	var ph := beat_phase()
	return minf(ph, 1.0 - ph) * beat_len < beat_win_now()


func beat_win_now() -> float:
	return beat_win + u08.beat_bonus() + (GameData.METRONOME_WIN if now() < metro_until else 0.0)


func is_playing() -> bool:
	return state == PLAY



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
	for p in [hud.menu_panel, hud.select_panel, hud.dialog_panel, hud.bag_panel, hud.pause_panel, hud.dead_panel, hud.loading_panel, hud.list_panel, hud.city_map]:
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
	var old_ver := int(_read_save().get("ver", GameData.SAVE_VERSION))
	if not load_game():
		hud.toast("Сохранение не читается — начнём заново", Hud.CREAM)
		open_select()
		return
	_rebuild_stage_hero()
	await get_tree().process_frame
	await start_game(false)
	if old_ver < 3:
		hud.toast("Обновление 0.3: стройка Глушилки, Шумодав и Избушка-Бас!", Hud.GOLD)
		if quest2 >= 6:
			hud.toast("Баба Зина во дворе ждёт тебя с новым делом", Hud.CREAM)
	elif old_ver < 4:
		hud.toast("Обновление 0.4: серверная Кощея и рэп-баттл!", Hud.GOLD)
		if quest3 >= 6:
			hud.toast("Баба Зина знает, где флешка Кощея — загляни к ней", Hud.CREAM)
	elif old_ver < 5:
		hud.toast("Обновление 0.5: концерт в ГК и Змей Горыныч!", Hud.GOLD)
		if quest4 >= 8:
			hud.toast("Петрович собирает концерт — загляни в правление ГК", Hud.CREAM)
	elif old_ver < 7:
		hud.toast("Обновление 0.7: парк «Заря», ремиксы боссов и Сингл Принц!", Hud.GOLD)
		if quest5 >= 7:
			hud.toast("Мыслитель Зари на набережной нашёл карту парка «Заря»", Hud.CREAM)
		hud.toast("Карта Рубина — новая кнопка вверху справа", Hud.CREAM)
	if old_ver < 9 and old_ver >= 8:
		hud.toast("Обновление 0.9 «Своё дело»: Помойка, изобретатели и постройки до 5 уровня!", Hud.GOLD)
		if quest7 >= 7:
			hud.toast("Мыслитель Зари на набережной знает, что дальше", Hud.CREAM)
		hud.toast("Ремиксы боссов теперь дают спецматериалы для мастерской", Hud.CREAM)
	if old_ver < 8 and old_ver >= 7:
		hud.toast("Обновление 0.8 «Мыльная опера»: Чебуречная, Прачечная, Бог Здорово и 5 новых мелодий!", Hud.GOLD)
		if quest6 >= 7:
			hud.toast("Мыслитель Зари на набережной знает, как выкупить парк", Hud.CREAM)
		hud.toast("Аэротакси теперь от 170 монет — чем дальше, тем дороже", Hud.CREAM)
	elif old_ver < 7:
		hud.toast("0.8: соседи переехали в сюжет — ищи их по всему району", Hud.CREAM)


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
	quest3 = 0
	q3_kills = 0
	quest4 = 0
	q4_kills = 0
	quest5 = 0
	q5_kills = 0
	quest6 = 0
	q6_stones = 0
	singles = 0
	taxi = false
	remix = {"best": {}, "day": "", "looted": [], "passes": 0, "wins": 0}
	prince = {"met": false, "next": 2100.0, "left": 0.0, "stock": [], "hit": "", "map": ""}
	metro_until = 0.0
	mount_owned = false
	mounted = false
	res = {"brick": 0, "cement": 0, "planks": 0, "wires": 0}
	food = 1
	buildings = {"grill": 0, "garden": 0, "gym": 0, "stage": 0, "studio": 0, "solar": 0}
	b_since = {"grill": 0.0, "garden": 0.0}
	robot_task = {"task": "", "start": 0.0, "end": 0.0, "told": false}
	daily = {"date": "", "pigeon": 0, "scooter": 0, "vacuum": 0, "claimed": []}
	side.reset()
	u08.reset()
	u09.reset()
	fusion_t = 0.0
	slow_t = 0.0
	map_id = "yard"
	_recalc_power()
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
		"quest": quest, "quest_kills": quest_kills, "feather_kills": feather_kills, "quest2": quest2, "quest3": quest3, "q3_kills": q3_kills, "quest4": quest4, "q4_kills": q4_kills, "quest5": quest5, "q5_kills": q5_kills,
		"quest6": quest6, "q6_stones": q6_stones, "singles": singles, "taxi": taxi, "remix": remix, "metro_until": metro_until,
		"prince": {"met": prince.met, "next": prince.next},
		"mount": mount_owned, "res": res, "food": food,
		"buildings": buildings, "b_since": b_since, "robot": robot_task, "daily": daily, "map": map_id, "side": side.to_save(), "u08": u08.to_save(), "u09": u09.to_save(),
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
	quest3 = int(d.get("quest3", 0))
	q3_kills = int(d.get("q3_kills", 0))
	quest4 = int(d.get("quest4", 0))
	q4_kills = int(d.get("q4_kills", 0))
	quest5 = int(d.get("quest5", 0))
	q5_kills = int(d.get("q5_kills", 0))
	quest6 = int(d.get("quest6", 0))
	q6_stones = int(d.get("q6_stones", 0))
	singles = int(d.get("singles", 0))
	taxi = bool(d.get("taxi", false))
	metro_until = float(d.get("metro_until", 0.0))
	var rx: Dictionary = d.get("remix", {})
	var best := {}
	var rb = rx.get("best", {})
	if rb is Dictionary:
		for k in rb:
			if GameData.REMIX.has(k):
				best[k] = clampi(int(rb[k]), -1, 3)
	var looted := []
	for k in rx.get("looted", []):
		looted.append(str(k))
	remix = {"best": best, "day": str(rx.get("day", "")), "looted": looted, "passes": int(rx.get("passes", 0)), "wins": int(rx.get("wins", 0))}
	var pr: Dictionary = d.get("prince", {})
	prince = {"met": bool(pr.get("met", false)), "next": clampf(float(pr.get("next", 2100.0)), 60.0, 2400.0), "left": 0.0, "stock": [], "hit": "", "map": ""}
	mount_owned = bool(d.get("mount", false))
	mounted = false
	food = int(d.get("food", 0))
	map_id = str(d.get("map", "yard"))
	if map_id not in GameData.MAPS:
		map_id = "yard"
	for k in res:
		res[k] = int(d.get("res", {}).get(k, 0))
	for k in buildings:
		buildings[k] = clampi(int(d.get("buildings", {}).get(k, 0)), 0, 5)
	for k in b_since:
		b_since[k] = float(d.get("b_since", {}).get(k, 0.0))
	var rt: Dictionary = d.get("robot", {})
	robot_task = {"task": str(rt.get("task", "")), "start": float(rt.get("start", 0.0)), "end": float(rt.get("end", 0.0)), "told": bool(rt.get("told", false))}
	var dl: Dictionary = d.get("daily", {})
	daily = {"date": str(dl.get("date", "")), "pigeon": int(dl.get("pigeon", 0)), "scooter": int(dl.get("scooter", 0)), "vacuum": int(dl.get("vacuum", 0)), "claimed": dl.get("claimed", []),
		"concert": bool(dl.get("concert", false)), "greet": dl.get("greet", [])}
	side.load_from(d.get("side", {}))
	var u8 = d.get("u08", {})
	u08.load_from(u8 if u8 is Dictionary else {})
	var u9 = d.get("u09", {})
	u09.load_from(u9 if u9 is Dictionary else {})
	fusion_t = 0.0
	slow_t = 0.0
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
	hud.loading_title.text = "Загружаем %s…" % GameData.MAP_NAMES.get(to, to)
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
	_apply_map_env(id)
	match id:
		"yard": world = World.build_yard(self)
		"stroyka": world = Stroyka.build(self)
		"server": world = ServerRoom.build(self)
		"embankment": world = Embankment.build(self)
		"park": world = Park.build(self, quest6 >= 6)
		"cheburek": world = Cheb.build(self)
		"laundry": world = Laundry.build(self)
		"dump": world = Dump.build(self)
		_: world = Base.build_garages(self)
	if id == "garages" and quest3 >= 2:
		_add_site_portal()
	if id == "garages" and quest4 >= 8:
		_build_concert_stage()
	if id == "yard" and quest5 >= 3:
		_add_river_portal()
	if id == "embankment" and quest6 >= 1:
		_add_park_portal()
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
	side.boss_live = {}
	for sid in SideQ.NPCS:
		var sn: Dictionary = SideQ.NPCS[sid]
		if sn.map == id and u08.npc_shown(sid):
			var place: Array = u08.npc_place(sid)
			_spawn_npc(sid, place[0], place[1])
	for e in world.mobs:
		_spawn_mob(e[0], e[1], e[2])
	if id == "yard" and quest == 3:
		_spawn_mob("pakhan", Vector3(0, 0, -24), 7)
	if id == "stroyka":
		if quest3 == 2:
			quest3 = 3
			hud.toast("Задание обновлено: заглуши 8 Тишинок", Hud.GOLD)
		if quest3 == 4:
			_spawn_mob("shumodav", Stroyka.BOSS_HOME, 10)
		elif quest3 >= 5:
			_spawn_npc("shumodav", Stroyka.BOSS_HOME + Vector3(1.0, 0, 0), PI / 2)
		if quest3 >= 2:
			_spawn_companion()
	if id == "server":
		lock_active = false
		if quest4 == 1:
			quest4 = 2
			hud.toast("Задание обновлено: взломай дверь рифмой", Hud.GOLD)
		if quest4 >= 3:
			_open_door(false)
		if quest4 >= 5:
			world.chest.visible = false
		if quest4 == 5:
			_spawn_mob("safe_hare", ServerRoom.CHEST + Vector3(0, 0, 1.5), 10)
		elif quest4 == 6:
			_spawn_koschei(false)
		_spawn_companion()
		_spawn_vasya()
	if id == "embankment":
		if quest5 == 3:
			quest5 = 4
			hud.toast("Задание обновлено: выключи %d колонок-автоплеев" % GameData.Q5_SPEAKERS, Hud.GOLD)
		if quest5 == 5:
			_spawn_mob("gorynych", Embankment.BOSS_HOME, 12)
		elif quest5 >= 6:
			_spawn_npc("gorynych", Embankment.BOSS_HOME + Vector3(5.0, 0, 1.5), PI * 0.8)
		_spawn_companion()
	if id == "park":
		_enter_park()
	u08.on_enter_map(id)
	u09.on_enter_map(id)
	_add_remix_consoles()
	if mounted:
		_create_mount_vis()
	if id == "garages":
		for sid in world.anchors:
			_refresh_slot(sid)
		_refresh_robot()
	_play_world_music()
	_check_daily_reset()
	side.refresh_marks()
	if id == "embankment" and prince.met and Time.get_datetime_dict_from_system().weekday == 5:
		_prince_appear("friday")


func _spawn_npc(id: String, at: Vector3, rot: float) -> void:
	if SideQ.NPCS.has(id):
		var sh := Npcs.build(id)
		world.root.add_child(sh.root)
		sh.root.position = at
		sh.root.rotation.y = rot
		Kit.bake_tree(sh.root)
		var sn: Dictionary = SideQ.NPCS[id]
		npcs.append({"id": id, "name": sn.name, "role": sn.role, "act": "Говорить", "pos": at, "node": sh.root, "body": sh.body, "head": sh.head,
			"h": Npcs.PLATE_H.get(id, 2.3), "r": sn.get("r", 3.2)})
		return
	var h: Dictionary
	match id:
		"zina": h = Chars.granny_npc()
		"misha": h = Chars.misha_npc()
		"lyuba": h = Chars.lyuba_npc()
		"gorynych":
			var gg := Chars.gorynych()
			gg.root.scale = Vector3.ONE * 0.8
			for nk in gg.necks:
				nk.rotation.x = -0.15
			h = {"root": gg.root, "body": gg.root, "head": gg.head}
		"shumodav":
			var gm := Chars.golem()
			gm.root.scale = Vector3.ONE * 0.62
			gm.arms[0].rotation = Vector3(-0.2, 0, -0.3)
			gm.arms[1].rotation = Vector3(-0.2, 0, 0.3)
			h = {"root": gm.root, "body": gm.root, "head": gm.head}
		"guard": h = Mobs07.guard()
		"prince": h = Mobs07.prince()
		_: h = Chars.petrovich_npc()
	world.root.add_child(h.root)
	h.root.position = at
	h.root.rotation.y = rot
	Kit.bake_tree(h.root)
	var info: Array = NPC_INFO[id]
	var role: String = info[1]
	if id == "guard" and quest6 >= 6:
		role = "бывший охранник · теперь просто гуляет"
	npcs.append({"id": id, "name": info[0], "role": role, "act": info[2], "pos": at, "node": h.root, "body": h.body, "head": h.head,
		"h": 5.4 if id == "shumodav" else (6.0 if id == "gorynych" else (2.7 if id == "prince" else 2.2)), "r": 4.2 if id == "shumodav" else (5.0 if id == "gorynych" else 3.2)})


func _spawn_mob(kind: String, at: Vector3, lvl: int) -> Dictionary:
	var d: Dictionary = GameData.MOBS[kind]
	var model: Dictionary
	match kind:
		"pigeon": model = Chars.pigeon(true, false)
		"pakhan": model = Chars.pigeon(true, true)
		"scooter": model = Chars.scooter()
		"drone": model = Chars.drone()
		"hare": model = Chars.robohare(false)
		"gull": model = Chars.pigeon(true, false, true)
		"autoplay": model = Chars.autoplay()
		"gorynych": model = Chars.gorynych()
		"safe_hare": model = Chars.robohare(true)
		"koschei":
			var kh := Chars.koschei()
			model = {"root": kh.root, "body": kh.body, "head": kh.head, "wings": kh.arms, "wheels": kh.legs, "carpet": kh.carpet, "dome": kh.dome}
		"shumodav":
			var gm := Chars.golem()
			model = {"root": gm.root, "body": gm.head, "head": gm.head, "wings": gm.arms}
		"mower": model = Mobs07.mower()
		"bag": model = Mobs07.bag()
		"duck": model = Mobs07.roboduck()
		"loader": model = Mobs07.loader()
		"wheel": model = Park.wheel()
		"roach", "fly", "cheb", "plunger_mob", "pelmeshek", "sock", "washer", "iron", "bubble", "dough", "drum":
			model = u08.model(kind, at)
		"rat", "fridge", "mattress", "king":
			model = u09.model(kind)
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
		"boss": d.get("boss", false), "whisper_t": 0.0, "phase": 0, "strafe": 1.0 if randf() < 0.5 else -1.0,
		"extra": model, "alt": 0.0, "loading": 0.0, "heads": 3, "shield": kind == "koschei", "rap": 0, "shield_t": 8.0 if kind == "gorynych" else 0.0, "fly_t": 6.0, "fly_to": null, "chast": false,
		"remix": 0, "remix_id": "", "spin_a": 0.0, "restored": false,
	}
	if kind in U08.MOB_KINDS:
		u08.setup_mob(m)
	if kind in U09.MOB_KINDS:
		u09.setup_mob(m)
	if kind == "wheel":
		m.yaw = 0.0
		m.fly_t = 18.0
		m.pull_cd = 3.0
		m.special = 2.0
		m.whisper_t = 8.0
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
	for b in mob_shots:
		if is_instance_valid(b.node):
			b.node.queue_free()
	mob_shots.clear()
	for w in waves:
		if is_instance_valid(w.node):
			w.node.queue_free()
	waves.clear()
	for t in traps:
		if is_instance_valid(t.node):
			t.node.queue_free()
	traps.clear()
	_concert_cleanup()
	concert = {}
	companion = {}
	vasya_mate = {}
	prince_npc = {}
	wheel_deco = {}
	remix_hidden = {}
	stone_marks = []
	lock_active = false
	mount_vis = {}
	robot_vis = {}
	slot_nodes = {}
	if world.has("root"):
		world.root.queue_free()
	world = {}
	target = null
	current_interact = null


func is_concert() -> bool:
	return state == CONCERT


func in_world() -> bool:
	return state in [PLAY, DIALOG, BAG, PAUSE, DEAD, LIST, CONCERT]


# ================================================================== stats
func _bval(id: String) -> float:
	var l: int = buildings[id]
	if l <= 0:
		return 0.0
	return GameData.BUILDINGS[id].value[l - 1]


func _recalc_stats() -> void:
	var ratio := hp / hp_max if hp_max > 0 else 1.0
	hp_max = (300.0 + (level - 1) * 45.0 + stat("hp") * 12.0) * (1.2 if race == "punk" else 1.0) * (1.0 + _bval("gym")) * u08.hp_mult()
	hp = clampf(hp_max * ratio, 1.0, hp_max)


func _recalc_power() -> void:
	power = 0
	stats = {}
	for s in equipped:
		power += equipped[s].power
		var add: Dictionary = GameData.item_stats(equipped[s])
		for k in add:
			stats[k] = int(stats.get(k, 0)) + int(add[k])
	beat_win = 0.13 + minf(0.05, stat("rhythm") * 0.002)


func res_line() -> String:
	var p := []
	for k in GameData.RES_ORDER:
		p.append("%s %d" % [GameData.RES_NAMES[k], res[k]])
	return " · ".join(p)


# ================================================================== quests
func quest_lines() -> Array:
	var out: Array = main_quest_lines()
	var sl: Array = side.tracker_lines()
	if sl.size() > 0 and out.size() > 2:
		out = out.slice(0, 2)
	out += sl
	var done := _daily_ready_count()
	var finished: int = daily.claimed.size()
	if quest >= 1:
		out.append("Ежедневные дяди Миши: %d/3%s" % [finished, (" · можно забрать: %d" % done) if done > 0 else ""])
	var gl: String = u08.status_line()
	if gl != "":
		out.append(gl)
	return out


func main_quest_lines() -> Array:
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
	elif quest3 < 6:
		match quest3:
			0: out = ["Флешка Кощея", "Поговори с бабой Зиной во дворе", "У неё срочное дело"]
			1: out = ["Флешка Кощея", "Получи путёвку на подвиг у Петровича", "ГК «Песня», правление"]
			2: out = ["Флешка Кощея", "Иди на стройку Глушилки", "Западные ворота ГК «Песня»"]
			3: out = ["Флешка Кощея", "Заглуши Тишинок: %d / %d" % [q3_kills, GameData.Q3_DRONES], "Попадай в бит — ритм сильнее тишины"]
			4: out = ["Флешка Кощея", "Победи Шумодава", "Красный круг — отбегай, «ШШШ» — рывок!"]
			5: out = ["Флешка Кощея", "Вернись к бабе Зине во двор"]
	elif quest4 < 8:
		match quest4:
			0: out = ["Перепрошивка", "Поговори с бабой Зиной", "Она знает, где флешка Кощея"]
			1: out = ["Перепрошивка", "Поднимись на Шумодаве-лифте", "Стройка Глушилки, у площадки"]
			2: out = ["Перепрошивка", "Взломай дверь рифмой", "Подойди к двери и атакуй в бит 4 раза подряд"]
			3: out = ["Перепрошивка", "Заглуши робо-зайцев: %d / %d" % [q4_kills, GameData.Q4_HARES], "Они прыгают — отходи рывком"]
			4: out = ["Перепрошивка", "Открой сундук на железном дубе", "В центре серверной"]
			5: out = ["Перепрошивка", "Догони Зайца-сейфа!", "Внутри — утка, яйцо и флешка"]
			6: out = ["Перепрошивка", "Рэп-баттл с Кощеем", "3 удара в бит подряд ломают «подписку»"]
			7: out = ["Перепрошивка", "Вернись к бабе Зине во двор"]
	elif quest5 < 7:
		match quest5:
			0: out = ["Концерт", "Поговори с Петровичем в ГК", "У правления кооператива"]
			1: out = ["Концерт", "Выступи на сцене в ГК", "У западных ворот · жми в ноту"]
			2: out = ["Бэкап Горыныча", "Музыка заикается! Беги к бабе Зине"]
			3: out = ["Бэкап Горыныча", "Иди на набережную", "Южная калитка двора"]
			4: out = ["Бэкап Горыныча", "Выключи колонки-автоплеи: %d / %d" % [q5_kills, GameData.Q5_SPEAKERS], "Кольца звука перепрыгивай рывком"]
			5: out = ["Бэкап Горыныча", "Победи Змея Горыныча", "Три головы — три беды"]
			6: out = ["Бэкап Горыныча", "Вернись к бабе Зине во двор"]
	elif quest6 < 7:
		match quest6:
			0:
				if side.is_done("treasure"):
					out = ["Рассвет по подписке", "Поговори с Мыслителем Зари", "Набережная, у западной скамейки"]
				else:
					out = ["Часть вторая: «Жар-птица»", "Мыслитель Зари на набережной знает про карту", "Сначала его загадки «Что, где лежит» (с 13 ур.)"]
			1: out = ["Рассвет по подписке", "Перейди Калинов мост — парк «Заря»", "Набережная, у моста · оранжевое кольцо"]
			2: out = ["Рассвет по подписке", "Поговори с охранником у входа в парк"]
			3: out = ["Рассвет по подписке", "Найди камни рассвета: %d / 3" % _stones_found(), "У воды, у фонтана, на траве — золотые лучи"]
			4: out = ["Рассвет по подписке", "Положи камни на летнюю сцену «Заря»", "В конце главной аллеи парка"]
			5: out = ["Рассвет по подписке", "Останови Колесо Обновлений!", "Жёлтые круги — отбегай · «Не выключайте» — бей в бит"]
			6: out = ["Рассвет по подписке", "Вернись к Мыслителю Зари на набережную"]
	elif quest7 < 7:
		out = u08.main_lines()
	else:
		out = u09.main_lines()
	return out


# ================================================================== 0.6 helpers: dialogs, items, quiet zones, journal
func npc_title(id: String) -> String:
	if NPC_INFO.has(id):
		return NPC_INFO[id][0]
	return id


func open_dialog(who: String, text: String, opts: Array) -> void:
	state = DIALOG
	hud.show_dialog(who, text, opts)


func close_dialog() -> void:
	_close_dialog()


func count_item(id: String) -> int:
	var n := 0
	for it in inventory:
		if it.id == id:
			n += 1
	return n


func remove_items(id: String, n: int) -> void:
	for it in inventory.duplicate():
		if n <= 0:
			break
		if it.id == id and not equipped.values().has(it):
			inventory.erase(it)
			n -= 1


func stat(k: String) -> int:
	if k == "luck":
		return int(stats.get(k, 0)) + u08.luck_bonus()
	return int(stats.get(k, 0))


## Mobs ignore the player standing next to an NPC (reading a quest) — unless the player attacks from there.
func player_safe() -> bool:
	if idle_t < 2.5 or state != PLAY:
		return false
	for n in npcs:
		if Vector2(pos.x - n.pos.x, pos.z - n.pos.z).length() < SAFE_R:
			return true
	return false


func equip(it: Dictionary) -> void:
	if str(it.slot) == "":
		return
	var need := GameData.item_level(it)
	if level < need:
		hud.toast("«%s» — с %d уровня" % [it.name, need], Hud.RED)
		return
	equipped[it.slot] = it
	_recalc_power()
	_recalc_stats()
	play_sfx("pickup", 1.1)
	hud.toast("Надето: %s · сила %d" % [it.name, power], Hud.GREEN)


func open_journal() -> void:
	if state != PLAY:
		return
	open_list("journal")


func _list_journal() -> void:
	var rows: Array = side.journal_rows()
	var extra: Array = _journal_rows07()
	var at := 1 if rows.size() > 0 else 0
	for i in range(extra.size()):
		rows.insert(at + i, extra[i])
	hud.show_list("ЖУРНАЛ ЗАДАНИЙ", "Уровень %d · соседи: выполнено %d из %d · здесь можно спокойно перечитать тексты заданий" % [level, side.done_count(), SideQ.ORDER.size()], rows)


func npc_marker(id: String) -> String:
	match id:
		"zina":
			if quest == 0 or (quest == 5 and quest2 == 0) or (quest2 >= 6 and quest3 == 0) or (quest3 >= 6 and quest4 == 0):
				return "!"
			if quest5 == 2:
				return "!"
			if quest == 4 or quest3 == 5 or quest4 == 7 or quest5 == 6:
				return "?"
		"shumodav":
			if quest4 == 1:
				return "!"
		"petrovich":
			if u09.petrovich_marker() != "" and not side.has_talk_for("petrovich"):
				return u09.petrovich_marker()
			if quest2 == 1 or (quest2 == 0 and quest >= 5) or quest3 == 1 or (quest4 >= 8 and quest5 == 0):
				return "!"
			if quest2 == 5:
				return "?"
		"zari":
			var zm: String = u08.zari_marker()
			if zm == "":
				zm = u09.zari_marker()
			if zm != "" and not side.has_talk_for("zari"):
				return zm
			if not side.has_talk_for("zari"):
				if quest6 == 0 and quest5 >= 7 and side.is_done("treasure"):
					return "!"
				if quest6 == 6:
					return "?"
		"guard":
			if quest6 == 2:
				return "!"
			return ""
		"prince":
			return "" if prince.met else "!"
		"misha":
			if _daily_ready_count() > 0:
				return "?"
			if quest >= 1 and daily.claimed.size() == 0 and daily.pigeon + daily.scooter + daily.vacuum == 0:
				return "!"
	return side.marker(id)


func world_labels() -> Array:
	var out := []
	if not world.has("root"):
		return out
	out += side.world_labels()
	out += _labels07()
	out += u08.labels()
	out += u09.labels()
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
	if int(m.remix) > 0:
		_remix_win(m)
		return
	if m.kind == "wheel":
		_wheel_defeated(m)
		return
	u08.on_kill(m)
	u09.on_kill(m)
	side.on_kill(m)
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
	elif m.kind == "drone" and quest3 == 3 and not m.temp:
		q3_kills += 1
		if q3_kills >= GameData.Q3_DRONES:
			quest3 = 4
			hud.big("ШУМОДАВ ПРОСНУЛСЯ!", "Он на площадке у Глушилки. Красный круг — отбегай!", 4.0)
			play_sfx("laser", 0.6)
			_spawn_mob("shumodav", Stroyka.BOSS_HOME, 10)
			save_game()
	elif m.kind == "hare" and quest4 == 3 and not m.temp:
		q4_kills += 1
		if q4_kills >= GameData.Q4_HARES:
			quest4 = 4
			hud.big("СУНДУК НА ДУБЕ!", "Подойди к железному дубу в центре серверной", 3.5)
			play_sfx("bank")
			save_game()
	elif m.kind == "safe_hare" and quest4 == 5:
		quest4 = 6
		hud.big("ПИИ-ИК! УТКА → ЯЙЦО → ФЛЕШКА!", "«БЕССМЕРТИЕ_ФИНАЛ_ФИНАЛ2.exe» · Кощей летит сюда!", 4.0)
		play_sfx("laser", 0.5)
		_duck_fx(m.pos)
		save_game()
		get_tree().create_timer(2.5).timeout.connect(func():
			if map_id == "server" and quest4 == 6 and state in [PLAY, DIALOG, LIST, BAG, PAUSE]:
				_spawn_koschei(true))
	elif m.kind == "autoplay" and quest5 == 4 and not m.temp:
		q5_kills += 1
		if q5_kills >= GameData.Q5_SPEAKERS:
			quest5 = 5
			hud.big("ИЗ-ПОД МОСТА ВЫПОЛЗ ЗМЕЙ ГОРЫНЫЧ!", "Три головы: «Реклама», «Автоплей», «Бэкап»", 4.5)
			play_sfx("laser", 0.45)
			_spawn_mob("gorynych", Embankment.BOSS_HOME, 12)
			save_game()
	elif m.kind == "gorynych":
		if quest5 == 5:
			quest5 = 6
			hud.big("БЭКАП УДАЛЁН!", "Горыныч сдался. Вернись к бабе Зине", 5.0)
		hud.float_text(m.pos + Vector3(0, 7.0, 0), "Ладно-ладно! Я вообще за музыку — просто Кощей платил подпиской…", Color("c8f0d0"), 24, 30)
		save_game()
	elif m.kind == "koschei" and quest4 == 6:
		quest4 = 7
		hud.big("КОЩЕЙ ПЕРЕПРОШИТ!", "Он танцует! Вернись к бабе Зине во двор", 5.0)
		hud.float_text(m.pos + Vector3(0, 4.0, 0), "Это не конец! Я вернусь! С обновлением!", Color("c8f0d0"), 26, 30)
		save_game()
	elif m.kind == "shumodav":
		if quest3 == 4:
			quest3 = 5
			hud.big("ШУМОДАВ ВСПОМНИЛ, ЧТО БЫЛ СЦЕНОЙ!", "Вернись к бабе Зине во двор", 5.0)
		else:
			hud.big("ШУМОДАВ ОТДЫХАЕТ", "Завтра снова на смену. Добыча твоя!", 3.5)
		hud.float_text(m.pos + Vector3(0, m.height + 1.0, 0), "Я… БЫЛ… СЦЕНОЙ…", Color("ffd0a0"), 30, 30)
		save_game()


# ================================================================== dialogs & interaction
func _close_dialog() -> void:
	hud.hide_dialog()
	state = PLAY


func _interactables() -> Array:
	var out := []
	for n in npcs:
		out.append({"label": n.act, "kind": "npc", "id": n.id, "pos": n.pos, "r": n.get("r", 3.2)})
	out += side.interactables()
	out += _interactables07()
	out += u08.interactables()
	out += u09.interactables()
	if map_id == "server" and world.has("door"):
		if quest4 == 2:
			out.append({"label": "Рэп-код", "kind": "door", "id": "door", "pos": Vector3(ServerRoom.DOOR_X + 1.6, 0, 0), "r": 3.2})
		if quest4 == 4:
			out.append({"label": "Сундук", "kind": "chest", "id": "chest", "pos": ServerRoom.CHEST, "r": 3.4})
	if map_id == "garages" and quest4 >= 8:
		out.append({"label": "Концерт", "kind": "concert", "id": "concert", "pos": CONCERT_FRONT, "r": 3.0})
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
			u08.greet(e.id)
			if e.id == "kesha" and u09.kesha_talk():
				return
			var ne = _npc_entry(e.id)
			if ne != null and ne.has("guest") and not side.has_business(e.id):
				u08.guest_line(ne)
				return
			if e.id == "zari" and _zari_main():
				return
			if e.id == "zari" and not side.has_talk_for("zari") and u08.zari_talk():
				return
			if e.id == "zari" and not side.has_talk_for("zari") and u09.zari_talk():
				return
			if e.id == "petrovich" and not side.has_talk_for("petrovich") and u09.petrovich_talk():
				return
			if e.id == "prince":
				_talk_prince()
				return
			if side.talk(e.id):
				return
			match e.id:
				"zina": _talk_zina()
				"misha": open_list("daily")
				"lyuba": open_list("shop")
				"petrovich": _talk_petrovich()
				"shumodav": _talk_shumodav()
				"gorynych": _talk_gorynych()
				"guard": _talk_guard()
		"side_find": side.inspect(e.id)
		"stone": _take_stone(int(e.id))
		"stage": _stage_stones()
		"remix": open_list("remix", e.id)
		"door": _start_rap_lock()
		"concert": start_concert()
		"chest": _open_chest()
		"slot": open_list("slot", e.id)
		"robot": open_list("robot")
		"bench": u08.bench()
		"ideas", "workshop": u09.interact(e)


func _npc_entry(id: String):
	for n in npcs:
		if n.id == id:
			return n
	return null


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
			if quest2 >= 6 and quest3 != 6:
				_talk_zina_q3()
				return
			if quest3 >= 6 and quest4 < 8:
				_talk_zina_q4()
				return
			if quest4 >= 8 and quest5 >= 2 and quest5 < 7:
				_talk_zina_q5()
				return
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
				if quest5 >= 7:
					lines = ["Горыныч-то на концерт просился. Три билета ему, говорю, на каждую голову!", "Кощей опять притих. Затишье перед обновлением, не иначе.",
						"Женщине столько лет, на сколько она пляшет! А на концерте я сто лет сбросила.", "Сходи на концерт в ГК — народ тебя ждёт."]
				elif quest4 >= 8:
					lines = ["Музыка вернулась — и голуби подпевают! Слышишь, милок?", "Кощей, говорят, Горынычу звонил. Про какой-то бэкап… Ох, не к добру.",
						"Женщине столько лет, на сколько она пляшет! А я сегодня ещё не плясала.", "Флешку береги. Там теперь вся наша музыка."]
				elif quest3 >= 6:
					lines = ["Как тебе моя Избушка? Бас любит — тишину нет. Береги её, милок.", "Кощей свою флешку на последнем этаже Глушилки прячет. Но это уже другая сказка — скоро!",
						"Шумодав-то, говорят, по ночам песни под нос мычит. Сцена — она и в бетоне сцена.", "Женщине столько лет, на сколько она пляшет!"]
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
			hud.show_dialog("Петрович", "Дымок пошёл — значит, гараж живой! Держи премию от правления. И слушай… На стройке за гаражами Шумодав завёлся. Зинаида Ивановна про это больше знает — зайди к ней.", [
				["Спасибо! (+200 монет, кирпич, провода)", func():
					quest2 = 6
					coins += 200
					res.brick += 10
					res.wires += 8
					gain_xp(250)
					hud.big("ГАРАЖ ОБЖИТ!", "Баба Зина ждёт тебя во дворе — у неё дело про Кощея", 4.5)
					play_sfx("bank")
					save_game()
					close.call()]])
		_:
			if quest4 >= 8 and quest5 == 0:
				hud.show_dialog("Петрович", "Граждане! Музыка вернулась — по уставу положен концерт! Сцену Шумодав собой предоставил, у западных ворот. Выступишь?", [
					["Выступлю! (задание «Концерт»)", func():
						quest5 = 1
						hud.toast("Новое задание: «Концерт» — сцена у западных ворот ГК", Hud.GOLD)
						play_sfx("bank")
						save_game()
						close.call()]])
				return
			if quest3 == 1:
				hud.show_dialog("Петрович", "Зинаида Ивановна предупреждала. Держи: путёвка на подвиг. Номер один. Форма тринадцать-Б. Без путёвки подвиг не засчитают.", [
					["Кто не засчитает?", func():
						hud.show_dialog("Петрович", "Я. *шлёп* Всё, печать стоит. Западные ворота ГК теперь для тебя открыты. Шумодава там не буди без нужды — он по уставу сторож.", [
							["Беру путёвку!", func():
								_open_site_gate()
								close.call()]])]])
				return
			var lines := ["Взносы за гараж — шучу, тебе бесплатно. Пока.", "Сцену поставь — по субботам концерты устроим.", "Солнечные панели — вещь! Вася с ними как на крыльях."]
			if quest3 >= 2:
				lines += ["Путёвку не потерял? Без неё подвиг не засчитаю.", "Шумодав, между прочим, из бетона старой сцены ДК отлит. Я там в молодости на баяне играл."]
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
		"journal": _list_journal()
		"remix": _list_remix(arg)
		"prince": _list_prince()
		"bench": u08.bench_list()
		"ideas": u09.list_ideas(arg)
		"workshop13": u09.list_workshop13()


func close_list() -> void:
	hud.list_panel.visible = false
	hud.city_map.visible = false
	list_kind = ""
	state = PLAY
	save_game()


func _refresh_list() -> void:
	if list_kind == "map":
		hud.city_map.refresh()
	elif list_kind != "":
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
	for it in _junk_items():
		junk += GameData.SELL_PRICE[it.rarity]
		junk_n += 1
	rows.append({"text": "Продать ненужное (%d шт.)" % junk_n, "sub": "Хлам и лишняя экипировка (надетое, уникальное и нужное соседям не трогаем) — +%d монет" % junk, "btn": "Продать",
		"enabled": junk_n > 0, "cb": func(): _sell_junk(), "color": Hud.GOLD})
	hud.show_list("Ларёк «Шаурма» · Люба", "«Бери, пока горячая!» · Монеты: %d · Шаурма: %d\n%s" % [coins, food, res_line()], rows)


func _is_junk(it: Dictionary) -> bool:
	if it.rarity >= 3 or it.get("unique", false):
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


## Junk minus the items accepted side quests still need.
func _junk_items() -> Array:
	var keep: Dictionary = side.reserved()
	var out := []
	for it in inventory:
		if not _is_junk(it):
			continue
		if int(keep.get(it.id, 0)) > 0:
			keep[it.id] = int(keep[it.id]) - 1
			continue
		out.append(it)
	return out


func _sell_junk() -> void:
	var gain := 0
	for it in _junk_items():
		gain += GameData.SELL_PRICE[it.rarity]
		inventory.erase(it)
	coins += gain
	hud.toast("Продано на %d монет" % gain, Hud.GOLD)
	play_sfx("bank")
	_refresh_list()


func _check_daily_reset() -> void:
	var today := Time.get_date_string_from_system()
	if daily.date != today:
		daily = {"date": today, "pigeon": 0, "scooter": 0, "vacuum": 0, "claimed": [], "concert": false, "greet": []}


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
			"btn": "Готово" if claimed else "Забрать", "enabled": (not claimed) and got >= dd[2], "cb": func(): _claim_daily(k),
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
	rows.append({"text": "%s · уровень %d / %d" % [b.name, lv, u09.max_level()], "sub": "%s\nСейчас: %s" % [b.desc, _effect_text(id, lv)], "color": Hud.GOLD})
	if lv < 3:
		var cost: Array = b.cost[lv]
		rows.append({"text": ("Построить" if lv == 0 else "Улучшить до ур. %d" % (lv + 1)) + " → " + _effect_text(id, lv + 1),
			"sub": "Нужно: " + _cost_text(cost), "btn": "Построить" if lv == 0 else "Улучшить", "enabled": _affordable(cost), "cb": func(): _build(id)})
	else:
		rows += u09.slot_rows(id, lv)
	if id == "grill" and lv > 0:
		var n := _prod_count("grill")
		rows.append({"text": "Готовая шаурма: %d (макс. %d)" % [n, u09.cap("grill")], "sub": "Жарится сама, даже когда игра закрыта", "btn": "Забрать", "enabled": n > 0, "cb": func(): _collect("grill")})
	if id == "garden" and lv > 0:
		var g := _prod_count("garden")
		rows.append({"text": "Урожай: +%d монет" % (g * b.coins[lv - 1]), "sub": "Люба сразу выкупает всё оптом", "btn": "Собрать", "enabled": g > 0, "cb": func(): _collect("garden")})
	hud.show_list("Стройка · бокс №40", "Монеты: %d · %s" % [coins, res_line()], rows)


func _build(id: String) -> void:
	var lv: int = buildings[id]
	if lv >= 5 or not u09.can_upgrade(id, lv):
		return
	var cost: Array = GameData.BUILDINGS[id].cost[lv]
	if not _affordable(cost):
		return
	u09.pay_upgrade(id, lv)
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
	return mini(u09.cap(id), int(maxf(0.0, now() - b_since[id]) / b.period[lv - 1]))


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
		if lv >= 5:
			food += n
			hud.toast("+%d шаурмы из теплицы" % n, Hud.GOLD)
	if n >= u09.cap(id):
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
	return GameData.xp_for_level(level)


func gain_xp(v: int) -> void:
	v = int(round(v * u08.xp_mult()))
	xp += v
	while xp >= xp_next() and level < GameData.MAX_LEVEL:
		xp -= xp_next()
		level += 1
		_recalc_stats()
		hp = hp_max
		hud.big("НОВЫЙ УРОВЕНЬ %d!" % level, "Здоровье и урон выросли", 2.5)
		play_sfx("bank", 1.1)
		_ring_fx(pos + Vector3(0, 0.1, 0), Kit.GOLD, 2.5, 0.8)
	if level >= GameData.MAX_LEVEL:
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
		if (cur == null or cur.power < it.power) and level >= GameData.item_level(it):
			equipped[it.slot] = it
			_recalc_power()
			_recalc_stats()
			hud.toast("Надето: %s · сила %d" % [it.name, power], Hud.GREEN)
		elif level < GameData.item_level(it):
			hud.toast("Наденешь с %d уровня — вещь в сумке" % GameData.item_level(it), Hud.CREAM)
	if id == "luck" and quest == 2:
		quest = 3
		if map_id == "yard":
			_spawn_mob("pakhan", Vector3(0, 0, -24), 7)
		hud.big("ГОЛУБИНЫЙ ПАХАН", "вылез у гаражей!", 3.5)
		play_sfx("laser", 0.7)
		save_game()


func _drop_loot(m: Dictionary) -> void:
	if int(m.remix) > 0:
		return
	var d: Dictionary = GameData.MOBS[m.kind]
	var drops: Array = []
	if m.kind == "wheel":
		drops = ["wheel_mic"]
		if randf() < 0.6:
			drops.append(["cabin_helmet", "dawn_bomber"][randi() % 2])
		coins += 700
	elif m.kind == "pakhan":
		drops = ["pakhan_cap", "mic"]
		coins += 150
	elif m.kind == "gorynych":
		drops = ["phones"]
		if randf() < 0.6:
			drops.append("jacket")
		coins += 600
	elif m.kind in ["dough", "drum"]:
		drops = u08.loot(m)
	elif m.kind == "king":
		drops = u09.loot(m)
	elif m.kind == "safe_hare":
		drops = ["duck"]
		coins += 150
	elif m.kind == "koschei":
		drops = ["gusli"]
		if randf() < 0.7:
			drops.append(["headset", "turtleneck"][randi() % 2])
		coins += 500
	elif m.kind == "shumodav":
		if quest3 == 4 or randf() < 0.25:
			drops.append("megaphone")
		if randf() < 0.6:
			drops.append(["helmet", "vest", "rebar"][randi() % 3])
		coins += 250
		res.cement += 8
		res.brick += 8
		hud.float_text(m.pos + Vector3(0, m.height * 0.6, 0), "+8 цемента · +8 кирпича", Hud.TEAL, 22, 40)
	else:
		coins += int((randi_range(4, 12) + m.lvl * 2) * (1.0 + stat("luck") * 0.01))
		var r := randf() / (1.0 + stat("luck") * 0.015)
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
		_loot_at(drops[i], m.pos + (Vector3(0, 0, -4.0) if m.kind == "wheel" else Vector3.ZERO))


func _loot_at(id: String, at: Vector3) -> void:
	var it: Dictionary = GameData.ITEMS[id]
	var n := Node3D.new()
	fx_root.add_child(n)
	var lp: Vector3 = at + Vector3(randf_range(-1.2, 1.2), 0, randf_range(-1.2, 1.2))
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
	if group_t > 0.0:
		d *= 1.4
	return d * randf_range(0.9, 1.1)


func _beat_action(_name: String) -> bool:
	var ok := on_beat()
	var vg := (1.0 + _bval("stage")) * (1.0 + stat("vibe") * 0.02)
	if ok:
		combo += 1
		side.on_combo(combo)
		vibe = minf(100.0, vibe + 14.0 * vg)
		play_sfx("beat", 1.0 + minf(combo, 8) * 0.03, -3.0)
		if lock_active:
			_rap_lock_hit(true)
		if target != null and target.alive and target.kind == "koschei":
			_rap_battle_hit(target, true)
		var wh = _shielded_wheel()
		if wh != null:
			_wheel_beat(wh, true)
		u08.beat(true)
		u09.beat(true)
		if target != null and target.alive and target.kind == "gorynych" and target.loading > 0.0:
			target.loading = 0.0
			hud.big("ЗАГРУЗКА ПРЕРВАНА РИТМОМ!", "Бэкап не восстановился", 2.0)
			_ring_fx(target.pos + Vector3(0, 0.3, 0), Kit.TEAL, 5.0, 0.5)
		if silence_t > 0.0:
			silence_t = 0.0
			hud.float_text(pos + Vector3(0, 3.2, 0), "Ритм сильнее тишины!", Kit.TEAL, 24, 50)
			_ring_fx(pos + Vector3(0, 0.3, 0), Kit.TEAL, 3.0, 0.4)
		if not companion.is_empty():
			companion.clap = 0.25
			if combo % 5 == 0:
				group_t = 6.0
				hud.float_text(pos + Vector3(0, 3.6, 0), "ПЕСНЯ ГРУППЫ! Урон ×1.4", Kit.TEAL, 28, 50)
				_ring_fx(pos + Vector3(0, 0.2, 0), Kit.TEAL, 4.0, 0.5)
				_ring_fx(companion.pos + Vector3(0, 0.2, 0), Kit.TEAL, 2.5, 0.5)
				_notes_fx(companion.pos + Vector3(0, 1.8, 0), Kit.TEAL)
	else:
		combo = 0
		vibe = minf(100.0, vibe + 4.0 * vg)
		if lock_active:
			_rap_lock_hit(false)
		if target != null and target.alive and target.kind == "koschei":
			_rap_battle_hit(target, false)
		var wh2 = _shielded_wheel()
		if wh2 != null:
			_wheel_beat(wh2, false)
		u08.beat(false)
		u09.beat(false)
	combo_t = 3.0
	idle_t = 0.0
	return ok


func press(name: String) -> void:
	if state != PLAY:
		return
	if mounted and name in ["attack", "s1", "s2", "s3", "ult"]:
		_dismount("")
	match name:
		"mount": toggle_mount()
		"attack": _attack()
		"s1", "s2", "s3": _skill(name)
		"ult": _ultimate()
		"talk": interact()
		"food": _eat()
		"pause": toggle_pause()
		"bag": open_bag()
		"journal": open_journal()
		"map": open_map()


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
	var fh: float = u08.food_heal()
	heal_left += hp_max * fh
	hud.float_text(pos + Vector3(0, 2.6, 0), "Шаурма! +%d%%" % int(round(fh * 100.0)), Color("ffd27a"), 24, 40)
	if fusion:
		fusion_t = 20.0
		hud.float_text(pos + Vector3(0, 3.2, 0), "Чебурек-фьюжн: разгон!", Color("ffb05a"), 20, 40)
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
	var plunger: bool = crit and equipped.has("weapon") and str(equipped.weapon.get("id", "")) == "plunger"
	_shoot(target, _base_dmg() * mult, crit, 0.8 if plunger else 0.0)
	if plunger:
		hud.float_text(target.pos + Vector3(0, minf(target.height, 6.0) + 0.6, 0), "ЧПОК!", Color("d8a8ff"), 24, 40)
	play_sfx("laser", 1.3 if crit else 1.6, -6.0)


func _skill(name: String) -> void:
	if cd[name] > 0.0:
		return
	if silence_t > 0.0:
		if silence_msg_t <= 0.0:
			hud.toast("Тишина! Навыки молчат — ударь в бит, чтобы её сломать", Color("c8d0e8"))
			silence_msg_t = 1.5
		play_sfx("ui", 0.6, -6.0)
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
	if m.kind in ["dough", "drum"]:
		dmg = u08.on_damage(m, dmg, crit)
		if m.kind == "drum" and m.shield:
			stun = 0.0
	if m.kind == "king":
		dmg = u09.on_damage(m, dmg, crit)
		if m.shield:
			stun = 0.0
	if m.kind in ["koschei", "wheel"] and m.shield:
		dmg *= 0.08
		stun = 0.0
		if randf() < 0.3:
			hud.float_text(m.pos + Vector3(0, minf(m.height, 9.0) + 0.8, 0), "ПОДПИСКА! урон −92%" if m.kind == "koschei" else "НЕ ВЫКЛЮЧАЙТЕ! урон -92%", Color("c8d0e8"), 20, 40)
	m.hp -= dmg
	m.hit = 0.18
	if stun > 0.0:
		m.stun = maxf(m.stun, stun * (0.5 if m.kind == "pakhan" else (0.25 if m.kind in ["shumodav", "gorynych", "wheel", "dough", "drum", "king"] else 1.0)))
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
	m.respawn = RESPAWN_T
	if m.tele and is_instance_valid(m.tele):
		m.tele.queue_free()
		m.tele = null
	var gx := mob_xp(m)
	gain_xp(gx)
	hud.float_text(m.pos + Vector3(0, m.height, 0), "+%d опыта" % gx, Color("b9a6ff") if gx >= int(m.xp) else Color(0.7, 0.7, 0.75), 20, 40)
	_drop_loot(m)
	_burst(m.pos + Vector3(0, 1.0, 0), [Color("c8ccd8"), Color("8a93a8"), Color.WHITE], 24)
	play_sfx("drop", 0.8)
	if is_same(target, m):
		target = null
	_on_kill(m)


## Mobs much weaker than the hero give less experience (−15% per level beyond 3, at least 10%).
func mob_xp(m: Dictionary) -> int:
	var diff := level - int(m.lvl)
	var f := 1.0
	if diff > 3:
		f = maxf(0.1, 1.0 - (diff - 3) * 0.15)
	return maxi(1, int(round(int(m.xp) * f)))


func hurt_player(dmg: float, _from: Vector3) -> void:
	if invuln > 0.0 or state != PLAY:
		return
	hp -= dmg
	hud.hurt = 1.0
	if mounted:
		_dismount("Избушка испугалась и присела!")
	hud.float_text(pos + Vector3(0, 2.3, 0), "–%d" % int(dmg), Color("ff6060"), 26, 50)
	play_sfx("stumble", 1.0, -6.0)
	if not autotest:
		Input.vibrate_handheld(40)
	if hp <= 0.0:
		hp = 0.0
		_die()


func _die() -> void:
	if u08.second_wind():
		return
	state = DEAD
	hud.dead_text.text = u08.dead_text()
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
	u08.on_respawn()
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


func _telegraph(m: Dictionary, r := 4.2, t := 1.6, at = null) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	var c: Vector3 = m.pos if at == null else at
	n.position = Vector3(c.x, 0.08, c.z)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.1, 0.15, 0.3)
	Kit.part(n, Kit.DISC, mat, Vector3(r * 2.0, 1, r * 2.0))
	Chars.ring(n, Vector3(0, 0.02, 0), r, Color("ff2a3a"), 0.12, 4.0)
	m.tele = n
	m.tele_t = t



# ================================================================== input
func _move_dir(v: Vector2) -> Vector3:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	return fwd * -v.y + right * v.x


func _input(event: InputEvent) -> void:
	if not in_world():
		return
	if state == CONCERT:
		if (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_J]):
			concert_tap()
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
			KEY_M: press("mount")
			KEY_Q: press("journal")
			KEY_N: press("map")
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
			CONCERT: _finish_concert(true)
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
	_watch_music_clock(dt)
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
			_update_companion(dt)
			_update_vasya(dt)
			_update_mob_shots(dt)
			_update_waves(dt)
			_update_traps(dt)
			_update_beacon()
			_update_wheel_deco(dt)
			_update_prince(dt)
			_update_camera(dt)
			side.update(dt)
			u08.update(dt)
			u09.update(dt)
			save_t += dt
			if save_t > 30.0:
				save_game()
		CONCERT:
			_update_concert(dt)
			_update_fx(dt)
			_update_npcs(dt)
			_update_robot(dt)
		DIALOG, BAG, PAUSE, LIST:
			_animate_hero(dt, 0.0)
			if state != PAUSE:
				_update_prince(dt)
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
	silence_t = maxf(0.0, silence_t - dt)
	silence_msg_t = maxf(0.0, silence_msg_t - dt)
	group_t = maxf(0.0, group_t - dt)
	slow_t = maxf(0.0, slow_t - dt)
	fusion_t = maxf(0.0, fusion_t - dt)
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
		var vmax: float = (GameData.MOUNT_SPEED if mounted else 6.2 * (1.0 + stat("speed") * 0.012)) * u08.speed_mult()
		var sp := vmax * minf(1.0, jv.length() * 1.3)
		pos += md.normalized() * sp * dt
		spd = sp / vmax
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
	if mounted and not mount_vis.is_empty():
		_animate_mount(dt, spd, beat_bob)
	if invuln > 0.0 and state == PLAY:
		hero.root.visible = int(time * 20) % 2 == 0 or dash_t > 0.0
	else:
		hero.root.visible = true


func _update_camera(dt: float) -> void:
	cam_touch_t = maxf(0.0, cam_touch_t - dt)
	if cam_touch_t <= 0.0 and joy_vec.length() > 0.5 and state == PLAY:
		var want := facing + PI
		yaw = lerp_angle(yaw, want, minf(1.0, dt * 0.9 * absf(joy_vec.y)))
	var pivot := pos + Vector3(0, 1.7 + (2.2 if mounted else 0.0), 0)
	var back := Vector3(sin(yaw), 0, cos(yaw))
	var dd := dist + (2.6 if mounted else 0.0) + _boss_cam_extra()
	var cp := pivot + back * dd * cos(pitch) + Vector3.UP * dd * sin(pitch)
	cp.y = maxf(cp.y, 0.6)
	cam.global_position = cam.global_position.lerp(cp, minf(1.0, dt * 14.0)) if cam.global_position.distance_to(cp) < 20 else cp
	cam.fov = 60
	cam.look_at(pivot + Vector3(0, 0.2, 0) - back * 1.5, Vector3.UP)


func _update_mobs(dt: float) -> void:
	var safe := player_safe()
	for m in mobs:
		var node: Node3D = m.node
		if not m.alive:
			m.dead_t += dt
			if m.kind == "koschei":
				# reflashed: he dances and flies away on his carpet
				node.rotation.y += dt * 9.0
				m.alt += dt * (0.6 + m.dead_t * 1.5)
				node.position = m.pos + Vector3(0, m.alt, 0)
				node.rotation.z = 0.0
				if m.dead_t > 5.0:
					node.visible = false
				continue
			if m.kind == "gorynych":
				node.position.y = -minf(0.8, m.dead_t * 0.5)
				for nk in m.extra.necks:
					nk.rotation.x = lerpf(nk.rotation.x, 0.5, minf(1.0, dt * 2.0))
				_remix_after(m)
				continue
			if m.kind == "shumodav":
				# he does not fall apart: he kneels and stays, like an old stage
				node.rotation.x = minf(0.35, m.dead_t * 0.5)
				node.position.y = -minf(0.9, m.dead_t * 0.6)
				m.head.rotation.x = minf(0.5, m.dead_t * 0.4)
				_remix_after(m)
				continue
			if u08.dead_anim(m, dt) or u09.dead_anim(m, dt):
				continue
			if m.kind == "wheel":
				# the wheel slows down and stops; lights go warm
				m.spin_a += dt * maxf(0.0, 0.5 - m.dead_t * 0.15)
				Park.turn_wheel(m.extra, m.spin_a, 0.0)
				m.extra.spinner.visible = false
				_remix_after(m)
				continue
			node.rotation.z = minf(1.5, m.dead_t * 5.0)
			node.position.y = -minf(1.0, maxf(0.0, m.dead_t - 1.0)) * 2.0
			if m.dead_t > 2.0:
				node.visible = false
			if not m.boss and not m.temp:
				m.respawn -= dt
				if m.respawn <= 0.0 and Vector2(pos.x - m.home.x, pos.z - m.home.z).length() < 14.0:
					m.respawn = 3.0   # do not pop up right next to the player — wait until they walk away
				elif m.respawn <= 0.0:
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
			if wd.length() > 0.3 and m.kind not in ["wheel", "drum", "king"]:
				spd = 2.2 if m.kind in ["scooter", "drone"] else 1.2
				m.yaw = lerp_angle(m.yaw, atan2(wd.x, wd.z), minf(1.0, dt * 4))
				m.pos += wd.normalized() * spd * dt
			if dp < m.aggro * (1.0 if m.boss else u08.aggro_mult()) and state == PLAY and (m.boss or not safe):
				m.st = "chase"
				play_sfx("near", 1.4, -10.0)
		elif m.st == "chase":
			if state != PLAY or from_home > m.leash or (safe and not m.boss):
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
		if m.kind != "wheel":
			m.pos = World.resolve(m.pos, m.radius * 0.8, world.rects, world.circles, world.bounds)
		_animate_mob(m, dt, spd)


func _mob_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	var reach: float = m.radius + 0.9
	match m.kind:
		"drone":
			return _drone_chase(m, dt, to_p, dp)
		"hare":
			return _hare_chase(m, dt, to_p, dp)
		"safe_hare":
			return _safe_hare_flee(m, dt, to_p, dp)
		"koschei":
			return _koschei_chase(m, dt, to_p, dp)
		"autoplay":
			return _autoplay_chase(m, dt, to_p, dp)
		"gorynych":
			return _gorynych_chase(m, dt, to_p, dp)
		"wheel":
			return _wheel_chase(m, dt, to_p, dp)
		"mower", "bag", "duck", "loader":
			return _park_chase(m, dt, to_p, dp)
		"roach", "fly", "cheb", "plunger_mob", "pelmeshek", "sock", "washer", "iron", "bubble", "dough", "drum":
			return u08.chase(m, dt, to_p, dp)
		"rat", "fridge", "mattress", "king":
			return u09.chase(m, dt, to_p, dp)
		"shumodav":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 3))
			_shumodav_special(m, dt)
			if m.tele != null or m.whisper_t > 0.0:
				return 0.0
			if dp > reach + 0.6:
				spd = m.speed * (1.35 if m.phase >= 2 else 1.0)
				m.pos += to_p.normalized() * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				m.flap = 0.6
				hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
				hud.float_text(pos + Vector3(0, 2.8, 0), "БЕТОН-БАМ!", Color("ffb07a"), 22, 40)
				play_sfx("smash", 0.7, -4.0)
			return spd
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
				if m.kind == "gull" and food > 0 and randf() < 0.25:
					food -= 1
					hud.float_text(pos + Vector3(0, 3.2, 0), "Чайка стащила шаурму!", Color("ffd27a"), 22, 40)
			if m.kind == "pakhan":
				_boss_special(m, dt)
	return spd


func _animate_mob(m: Dictionary, dt: float, spd: float) -> void:
	var node: Node3D = m.node
	m.flap = maxf(0.0, m.flap - dt)
	if m.kind in U08.MOB_KINDS:
		u08.animate(m, dt, spd)
	elif m.kind in U09.MOB_KINDS:
		u09.animate(m, dt, spd)
	match m.kind:
		"drone":
			for r in m.wheels:
				r.rotation.y += dt * 40.0
			m.body.position.y = 1.85 + sin(time * 2.4 + m.home.x) * 0.18 + (0.25 if m.flap > 0.0 else 0.0)
			m.body.rotation.x = 0.25 * minf(1.0, spd / 3.0)
			m.head.scale = Vector3.ONE * (1.0 + (0.25 if m.flap > 0.0 else 0.0))
		"autoplay":
			var pulse := maxf(0.0, 0.12 - minf(beat_phase(), 1.0 - beat_phase()) * 0.5)
			m.body.scale = Vector3.ONE * (1.0 + pulse + (0.15 if m.flap > 0.0 else 0.0))
			m.head.scale = Vector3.ONE * (1.0 + pulse * 2.0)
		"gorynych":
			var gx: Dictionary = m.extra
			for i in range(3):
				var awake: bool = _goryn_head_awake(m, i)
				var nk: Node3D = gx.necks[i]
				var want := -0.35 + sin(time * 1.6 + i * 1.3) * 0.12 if awake else 0.45
				if awake and m.flap > 0.0:
					want = -0.7
				nk.rotation.x = lerpf(nk.rotation.x, want, minf(1.0, dt * 4.0))
			for w in m.wings:
				w.rotation.z = sin(time * 3.0) * 0.15 * (1.0 if m.wings.find(w) == 0 else -1.0)
			m.body.position.y = sin(time * 2.0) * 0.06
		"hare", "safe_hare":
			var hop := absf(sin(time * 13.0 + m.home.x)) * 0.3 * minf(1.0, spd / 3.0)
			if m.charge_t > 0.0:
				hop = 0.5 * sin(m.charge_t / 0.45 * PI)
			m.body.position.y = hop
			for e in m.wings:
				e.rotation.x = -0.15 - hop * 1.2
			m.wheels[0].rotation.x = hop * 2.0
			m.wheels[1].rotation.x = hop * 2.0
			m.head.rotation.y = sin(time * 4.0 + m.home.z) * 0.3 if spd < 0.5 else 0.0
		"koschei":
			var kx: Dictionary = m.extra
			kx.carpet.rotation.x = sin(time * 3.0) * 0.06
			kx.carpet.rotation.z = sin(time * 2.3) * 0.05
			kx.dome.visible = m.shield
			var cast: bool = m.flap > 0.0
			m.wings[0].rotation = Vector3(-2.4, 0, -0.3) if cast else Vector3(0.1, 0, -0.1)
			m.wings[1].rotation = Vector3(0.1, 0, 0.1) if not cast else Vector3(-0.6, 0, 0.3)
			m.head.rotation.x = 0.1 if m.stun <= 0.0 else -0.3
			m.alt = lerpf(m.alt, 0.7 + sin(time * 2.0) * 0.12, minf(1.0, dt * 2.0))
		"shumodav":
			var sw := sin(time * 3.0) * 0.3 * minf(1.0, spd)
			if m.flap > 0.0:
				sw = -1.6 * sin(m.flap / 0.6 * PI)
			m.wings[0].rotation.x = sw
			m.wings[1].rotation.x = -sw if m.flap <= 0.0 else sw
			m.head.rotation.x = -0.35 if m.whisper_t > 0.0 else sin(time * 1.5) * 0.06
			m.head.scale = Vector3.ONE * (1.0 + (0.12 if m.whisper_t > 0.0 else 0.0))
		"scooter":
			for w in m.wheels:
				w.rotation.x += dt * spd * 6.0
			m.head.rotation.x = -0.25 if m.charge_t > 0.0 else sin(time * 3.0 + m.home.x) * 0.05
			m.body.rotation.z = sin(time * 8.0) * 0.06 * minf(1.0, spd)
		"vacuum":
			m.head.rotation.y = sin(time * 2.2 + m.home.z) * 0.5
			m.head.rotation.x = -0.4 if m.flap > 0.0 else sin(time * 3.0) * 0.08
			m.body.scale = Vector3.ONE * (1.0 + (sin(time * 30.0) * 0.03 if m.flap > 0.0 else 0.0))
		"mower", "bag", "duck", "loader", "wheel":
			_animate_park_mob(m, dt, spd)
		"roach", "fly", "cheb", "plunger_mob", "pelmeshek", "sock", "washer", "iron", "bubble", "dough", "drum", "rat", "fridge", "mattress", "king":
			pass   # 0.8–0.9: animated by U08 / U09 above
		_:
			var flap := 0.0
			if m.st == "chase" or m.flap > 0.0:
				flap = (sin(time * 22.0) * 0.6 + 0.4) if m.stun <= 0.0 else 0.0
			m.wings[0].rotation.z = -flap
			m.wings[1].rotation.z = flap
			m.head.rotation.x = 0.6 if m.flap > 0.2 else sin(time * 6.0 + m.home.x) * 0.15 * minf(1.0, spd)
			m.body.position.y = absf(sin(time * 10.0 + m.home.z)) * 0.08 * minf(1.0, spd)
	var squash: float = 1.0 + m.hit * (0.12 if m.kind == "wheel" else 0.8)
	node.scale = Vector3(m.scale * squash, m.scale / squash, m.scale * squash)
	node.position = m.pos + Vector3(0, m.alt, 0)
	node.rotation.y = m.yaw
	node.rotation.z = sin(time * 12.0) * 0.15 if m.stun > 0.0 else 0.0


func _boss_special(m: Dictionary, dt: float) -> void:
	if m.tele != null:
		m.tele_t -= dt
		m.flap = 0.4
		if m.tele_t <= 0.0:
			var c: Node3D = m.tele
			if Vector2(pos.x - c.position.x, pos.z - c.position.z).length() < 4.2:
				hurt_player(maxf(60.0, m.dmg * 2.3), m.pos)
				hud.toast("Крылья-ураган! Отбегай из красного круга", Color("ff8080"))
			_ring_fx(c.position + Vector3(0, 0.2, 0), Color("ff2a3a"), 4.4, 0.4)
			play_sfx("smash", 0.8, -2.0)
			c.queue_free()
			m.tele = null
		return
	m.special -= dt
	if m.special <= 0.0:
		m.special = 6.5 if int(m.remix) == 0 else 5.2
		_telegraph(m)
		hud.toast("Пахан машет крыльями — уйди из круга!", Color("ff9a9a"))
		if int(m.remix) > 0:
			for k in range(2):
				_add_trap(pos + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0)), 1.8, 1.4, m.dmg * 1.4)
			hud.float_text(pos + Vector3(0, 3.0, 0), "Перья-сюрикены!", Color("d8c8ff"), 20, 40)
	if int(m.remix) > 0:
		var th := [0.75, 0.5, 0.25]
		if m.phase < 3 and m.hp < m.hp_max * th[m.phase]:
			m.phase += 1
			for o in [Vector3(-3, 0, 2), Vector3(3, 0, 2)]:
				var s2 := _spawn_mob("pigeon", m.pos + o, maxi(2, int(m.lvl) - 2))
				s2.st = "chase"
				s2.temp = true
			hud.toast("Пахан: «Пацаны, сюда! Голубиный рэп!»", Color("ff9a9a"))
		return
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


# ================================================================== 0.3: map moods, quest «Флешка Кощея»
const MOUNT_SCALE := 0.62


func _apply_map_env(id: String) -> void:
	if map_env.is_empty():
		map_env = {"top": sky_mat.sky_top_color, "hor": sky_mat.sky_horizon_color, "ghor": sky_mat.ground_horizon_color,
			"fog": env_world.fog_light_color, "fogd": env_world.fog_density, "amb": env_world.ambient_light_color,
			"ambe": env_world.ambient_light_energy, "sat": env_world.adjustment_saturation, "sun": sun.light_color,
			"sune": sun.light_energy, "sunr": sun.rotation_degrees}
	var e: Dictionary = map_env
	env_world.background_mode = Environment.BG_SKY
	if id == "server":
		# inside the tower: dark server hall, cold light, the iron oak glows
		env_world.background_mode = Environment.BG_COLOR
		env_world.background_color = Color("0a0d16")
		env_world.fog_light_color = Color("1a2236")
		env_world.fog_density = 0.012
		env_world.ambient_light_color = Color("7a8ab8")
		env_world.ambient_light_energy = 1.15
		env_world.adjustment_saturation = 1.08
		sun.light_color = Color("b8ccff")
		sun.light_energy = 0.75
		sun.rotation_degrees = Vector3(-62, 205, 0)
	elif id == "park" and quest6 < 6:
		# a grey pre-dawn: the sun rises, but the birds are silent — the dawn is sold by subscription
		sky_mat.sky_top_color = Color("4a5878")
		sky_mat.sky_horizon_color = Color("c8a8a4")
		sky_mat.ground_horizon_color = Color("b89a98")
		env_world.fog_light_color = Color("a8a0b0")
		env_world.fog_density = 0.011
		env_world.ambient_light_color = Color("9a9ab8")
		env_world.ambient_light_energy = 0.8
		env_world.adjustment_saturation = 0.78
		sun.light_color = Color("e8c8c0")
		sun.light_energy = 1.05
		sun.rotation_degrees = Vector3(-14, 160, 0)
	elif id == "park":
		# the dawn is back (3% of it, but ours): pink sky, warm low sun
		sky_mat.sky_top_color = Color("4a6ac8")
		sky_mat.sky_horizon_color = Color("ffa88a")
		sky_mat.ground_horizon_color = Color("ffa88a")
		env_world.fog_light_color = Color("ffc8b0")
		env_world.fog_density = 0.008
		env_world.ambient_light_color = Color("ffd0c0")
		env_world.ambient_light_energy = 0.95
		env_world.adjustment_saturation = 1.12
		sun.light_color = Color("ffb88a")
		sun.light_energy = 1.7
		sun.rotation_degrees = Vector3(-16, 160, 0)
	elif id == "laundry":
		# «Ромашка»: soft lavender light and soap-bubble pastels — the white tiles must not blind
		sky_mat.sky_top_color = Color("5a6ab8")
		sky_mat.sky_horizon_color = Color("d8b8e8")
		sky_mat.ground_horizon_color = Color("c8a8d8")
		env_world.fog_light_color = Color("c8b8e0")
		env_world.fog_density = 0.008
		env_world.ambient_light_color = Color("a0a8d0")
		env_world.ambient_light_energy = 0.55
		env_world.adjustment_saturation = 1.12
		sun.light_color = Color("ffe0f0")
		sun.light_energy = 0.95
		sun.rotation_degrees = Vector3(-38, 150, 0)
	elif id == "dump":
		# the city dump: warm hazy evening, dust in the air, the bonfire of the inventors
		sky_mat.sky_top_color = Color("4a6a8a")
		sky_mat.sky_horizon_color = Color("e8c8a0")
		sky_mat.ground_horizon_color = Color("c8a880")
		env_world.fog_light_color = Color("c8b89c")
		env_world.fog_density = 0.009
		env_world.ambient_light_color = Color("b8b0a0")
		env_world.ambient_light_energy = 0.75
		env_world.adjustment_saturation = 1.05
		sun.light_color = Color("ffe0b0")
		sun.light_energy = 1.35
		sun.rotation_degrees = Vector3(-26, 120, 0)
	elif id == "cheburek":
		# golden hour by the tram stop: warm and appetising
		sky_mat.sky_top_color = Color("3a5ab0")
		sky_mat.sky_horizon_color = Color("ffc890")
		sky_mat.ground_horizon_color = Color("ffc890")
		env_world.fog_light_color = Color("f0c8a0")
		env_world.fog_density = 0.007
		env_world.ambient_light_color = Color("e8c8a8")
		env_world.ambient_light_energy = 0.8
		env_world.adjustment_saturation = 1.1
		sun.light_color = Color("ffd0a0")
		sun.light_energy = 1.45
		sun.rotation_degrees = Vector3(-24, 215, 0)
	elif id == "stroyka":
		# evening at Koschei's site: lilac sky, orange haze, a bit less colour — the silence is near
		sky_mat.sky_top_color = Color("2c3570")
		sky_mat.sky_horizon_color = Color("ff8a5a")
		sky_mat.ground_horizon_color = Color("ff8a5a")
		env_world.fog_light_color = Color("c8908a")
		env_world.fog_density = 0.010
		env_world.ambient_light_color = Color("8a84c0")
		env_world.ambient_light_energy = 0.66
		env_world.adjustment_saturation = 1.0
		sun.light_color = Color("ffa478")
		sun.light_energy = 1.6
		sun.rotation_degrees = Vector3(-17, 205, 0)
	else:
		sky_mat.sky_top_color = e.top
		sky_mat.sky_horizon_color = e.hor
		sky_mat.ground_horizon_color = e.ghor
		env_world.fog_light_color = e.fog
		env_world.fog_density = e.fogd
		env_world.ambient_light_color = e.amb
		env_world.ambient_light_energy = e.ambe
		env_world.adjustment_saturation = e.sat
		sun.light_color = e.sun
		sun.light_energy = e.sune
		sun.rotation_degrees = e.sunr


func _update_beacon() -> void:
	if world.has("beacon"):
		var b: Node3D = world.beacon
		b.visible = (beat_index() / 2) % 2 == 0


func _boss_cam_extra() -> float:
	# pull the camera back near the big bosses so their heads stay in view
	for m in mobs:
		if m.alive and m.kind in ["shumodav", "gorynych", "wheel"] and m.pos.distance_to(pos) < 26.0:
			return 3.0 if m.kind == "shumodav" else (6.5 if m.kind == "wheel" else 5.5)
		if m.alive and m.kind in ["dough", "drum", "king"] and m.pos.distance_to(pos) < 26.0:
			return u08.cam_extra(m) if m.kind != "king" else u09.cam_extra(m)
	return 0.0


func _boss_near() -> bool:
	for m in mobs:
		if m.boss and m.alive and m.pos.distance_to(pos) < 22.0:
			return true
	return false


func _talk_zina_q3() -> void:
	var close := func(): _close_dialog()
	match quest3:
		0:
			hud.show_dialog("Баба Зина", "Милок, беда! За гаражами Кощей башню строит — Глушилку. Хочет всю музыку в городе выключить и продавать по подписке. А стройку сторожит Шумодав: бетонный, вместо рта рупор…", [
				["Кощей? Тот самый?", func():
					hud.show_dialog("Баба Зина", "Тот самый, костлявый. Мы с ним пятьсот лет соседями в одной сказке были. Иди к Петровичу за путёвкой — без неё на стройку не пустит. А я с тобой пойду, пирожков возьму.", [
						["Идём, баб Зин! (задание «Флешка Кощея»)", func():
							quest3 = 1
							hud.toast("Новое задание: «Флешка Кощея»", Hud.GOLD)
							play_sfx("bank")
							save_game()
							close.call()]])]])
		1:
			hud.show_dialog("Баба Зина", "Петрович в правлении ГК сидит, с печатью в обнимку. Без путёвки он и подвиг не засчитает!", [["Бегу!", close]])
		2, 3, 4:
			hud.show_dialog("Баба Зина", "На стройке я рядом буду, милок. Подлечу пирожком, похлопаю в бит. Попадёшь пять раз подряд — споём песню группы, и Шумодаву несдобровать!", [["Понял!", close]])
		5:
			hud.show_dialog("Баба Зина", "Шумодав сценой был?! Ох, бедолага… Музыку-то он, выходит, любит. Держи награду, заслужил: моя Избушка-Бас! Бас любит, тишину — нет.", [
				["Спасибо! (маунт Избушка-Бас, +400 монет)", func():
					_finish_q3()
					close.call()]])


func _add_site_portal() -> void:
	world.portals.append({"pos": Vector3(-29.6, 0, 0), "r": 1.3, "to": "stroyka", "spawn": "from_garages", "label": "Стройка Глушилки"})
	Chars.ring(world.root, Vector3(-29.6, 0.05, 0), 1.2, Color("ff5a4a"), 0.08, 3.0)
	world.map_rects.append(Rect2(-36, -2, 5, 4))


func _open_site_gate() -> void:
	if quest3 != 1:
		return
	quest3 = 2
	hud.big("ПУТЁВКА НА ПОДВИГ №1", "Западные ворота ГК «Песня» → стройка Глушилки", 4.0)
	play_sfx("bank")
	if map_id == "garages" and world.has("root"):
		_add_site_portal()
	save_game()


func _finish_q3() -> void:
	quest3 = 6
	mount_owned = true
	coins += 400
	gain_xp(400)
	hud.big("НОВЫЙ МАУНТ: ИЗБУШКА-БАС!", "Кнопка с домиком справа вверху · почти вдвое быстрее", 5.0)
	play_sfx("bank")
	save_game()


# ------------------------------------------------------------------ companion: Baba Zina on the site
func _spawn_companion() -> void:
	var h := Chars.granny_npc()
	world.root.add_child(h.root)
	Kit.bake_tree(h.root)
	var at := pos + Vector3(1.6, 0, 1.4)
	h.root.position = at
	companion = {"root": h.root, "body": h.body, "head": h.head, "arms": h.arms, "legs": h.legs, "pos": at, "yaw": facing,
		"heal_cd": 4.0, "clap": 0.0, "walk": 0.0}


func _update_companion(dt: float) -> void:
	if companion.is_empty():
		return
	var c: Dictionary = companion
	var fwd := Vector3(sin(facing), 0, cos(facing))
	var right := Vector3(fwd.z, 0, -fwd.x)
	var want: Vector3 = pos + fwd * 0.4 + right * 2.3
	var d: Vector3 = want - c.pos
	d.y = 0
	var spd := 0.0
	if d.length() > 12.0:
		c.pos = want
	elif d.length() > 0.4:
		spd = minf(d.length() * 2.6, 12.5 if mounted else 9.0)
		c.pos += d.normalized() * spd * dt
		c.yaw = lerp_angle(c.yaw, atan2(d.x, d.z), minf(1.0, dt * 8.0))
	else:
		c.yaw = lerp_angle(c.yaw, facing, minf(1.0, dt * 3.0))
	c.pos = World.resolve(c.pos, 0.4, world.rects, world.circles, world.bounds)
	var k := minf(1.0, spd / 5.0)
	c.walk += dt * 9.0 * k
	var sw := sin(c.walk) * 0.7 * k
	c.legs[0].rotation.x = sw
	c.legs[1].rotation.x = -sw
	c.clap = maxf(0.0, c.clap - dt)
	if c.clap > 0.0:
		c.arms[0].rotation = Vector3(-1.25, 0, -0.45)
		c.arms[1].rotation = Vector3(-1.25, 0, 0.45)
	else:
		c.arms[0].rotation = Vector3(-sw * 0.6, 0, 0)
		c.arms[1].rotation = Vector3(sw * 0.6, 0, 0)
	var bob := maxf(0.0, 0.05 - minf(beat_phase(), 1.0 - beat_phase()) * 0.2)
	c.body.position.y = bob + absf(cos(c.walk)) * 0.05 * k
	c.root.position = c.pos
	c.root.rotation.y = c.yaw
	c.heal_cd -= dt
	if c.heal_cd <= 0.0 and hp < hp_max * 0.6 and state == PLAY:
		c.heal_cd = 12.0
		heal_left += hp_max * 0.18
		hud.float_text(c.pos + Vector3(0, 2.4, 0), "Пирожок от Зины! +18%", Color("ffd27a"), 22, 40)
		_notes_fx(pos + Vector3(0, 1.5, 0), Color("ffd27a"))
		play_sfx("pickup", 1.2)


# ------------------------------------------------------------------ mount: Izbushka-Bass
func toggle_mount() -> void:
	if not mount_owned or state != PLAY:
		return
	if mounted:
		_dismount("")
		return
	for m in mobs:
		if m.alive and m.st == "chase" and m.pos.distance_to(pos) < 14.0:
			hud.toast("Избушка боится драки — сначала разберись с врагами", Hud.CREAM)
			return
	mounted = true
	_create_mount_vis()
	_ring_fx(pos + Vector3(0, 0.2, 0), Kit.TEAL, 3.0, 0.5)
	_notes_fx(pos + Vector3(0, 3.4, 0), Kit.TEAL)
	hud.float_text(pos + Vector3(0, 4.6, 0), "БО-О-ОК!", Kit.TEAL, 30, 40)
	play_sfx("land", 0.6)


func _dismount(msg: String) -> void:
	if not mounted:
		return
	mounted = false
	if not mount_vis.is_empty() and is_instance_valid(mount_vis.root):
		mount_vis.root.queue_free()
	mount_vis = {}
	if msg != "":
		hud.toast(msg, Hud.CREAM)
	play_sfx("land", 0.9, -4.0)


func _create_mount_vis() -> void:
	if not world.has("root"):
		return
	if u09.mount_skin == "cart":
		mount_vis = u09.create_cart()
		return
	var iz := Chars.izba()
	world.root.add_child(iz.root)
	Kit.bake_tree(iz.root)
	iz.root.scale = Vector3.ONE * MOUNT_SCALE
	iz.root.position = pos
	iz["phase"] = 0.0
	mount_vis = iz


func _animate_mount(dt: float, spd: float, beat_bob: float) -> void:
	if mount_vis.has("cart"):
		u09.animate_cart(dt, spd, beat_bob)
		return
	var iz: Dictionary = mount_vis
	iz.phase += dt * 10.0 * spd
	var k := minf(1.0, spd)
	var sw := sin(iz.phase) * 0.55 * k
	var lift := absf(cos(iz.phase)) * 0.25 * k
	iz.root.position = pos
	iz.root.rotation.y = facing
	for i in range(2):
		var L: Dictionary = iz.legs[i]
		var sv := sw if i == 0 else -sw
		L.hip.rotation.x = sv
		L.knee.rotation.x = -absf(sv) * 0.9 + 0.12
		L.ankle.rotation.x = absf(sv) * 0.5
	var hy := 2.4 + lift + beat_bob * 2.5
	iz.hut.position.y = hy
	iz.hut.rotation.z = sin(iz.phase * 0.5) * 0.05 * k
	# the rider stands on the roof between the subwoofers
	hero.root.position = pos + Vector3(0, (hy + 2.95) * MOUNT_SCALE, 0)
	hero.legs[0].rotation.x = 0.15
	hero.legs[1].rotation.x = -0.15
	hero.arms[0].rotation.x = -0.4
	hero.body.position.y = 0.0
	hero.body.rotation.x = 0.05


# ------------------------------------------------------------------ Tishinka drones and their silence bubbles
func _drone_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
	var dir := to_p.normalized()
	var side := Vector3(dir.z, 0, -dir.x) * float(m.strafe)
	var mv := Vector3.ZERO
	if dp > 8.0:
		mv = dir
	elif dp < 4.5:
		mv = -dir * 0.8
	mv += side * 0.45
	m.t -= dt
	if m.t <= 0.0:
		m.t = randf_range(1.5, 3.0)
		m.strafe = -float(m.strafe)
	if mv.length() > 0.01:
		spd = m.speed
		m.pos += mv.normalized() * spd * dt
	if m.atk_cd <= 0.0 and dp < 11.0:
		m.atk_cd = m.atk * randf_range(0.85, 1.2)
		_fire_bubble(m)
	return spd


func _fire_bubble(m: Dictionary) -> void:
	var n := Chars.bubble()
	fx_root.add_child(n)
	var from: Vector3 = m.pos + Vector3(0, 1.85, 0) + Vector3(sin(m.yaw), 0, cos(m.yaw)) * 0.6
	n.position = from
	var aim := pos + Vector3(0, 1.1, 0)
	mob_shots.append({"node": n, "dir": (aim - from).normalized(), "life": 3.2, "dmg": m.dmg})
	m.flap = 0.3
	play_sfx("near", 1.8, -10.0)


func _update_mob_shots(dt: float) -> void:
	for b in mob_shots.duplicate():
		b.life -= dt
		var n: Node3D = b.node
		n.position += b.dir * 7.5 * dt
		n.rotation.y += dt * 2.0
		var near := Vector2(n.position.x - pos.x, n.position.z - pos.z).length() < 0.85 and n.position.y < 2.4 + (3.0 if mounted else 0.0)
		if near and invuln <= 0.0:
			hurt_player(b.dmg * randf_range(0.9, 1.1), n.position)
			if b.get("kind", "bubble") == "quack":
				pull_v = Vector3(b.dir.x, 0, b.dir.z).normalized() * 7.0
				hud.float_text(pos + Vector3(0, 2.9, 0), "КРЯ!", Color("ffe04a"), 24, 40)
			elif b.get("kind", "bubble") == "sock":
				u08.shot_hit(b)
			else:
				_silence_player(2.5)
		if near or b.life <= 0.0 or n.position.y < 0.1:
			_burst(n.position, [Color("d8e0f0"), Color.WHITE], 8)
			n.queue_free()
			mob_shots.erase(b)


func _silence_player(t: float) -> void:
	if silence_t <= 0.0:
		hud.float_text(pos + Vector3(0, 3.0, 0), "ТИШИНА…", Color("c8d0e8"), 26, 40)
	silence_t = maxf(silence_t, t)


# ------------------------------------------------------------------ boss Shumodav
func _shumodav_special(m: Dictionary, dt: float) -> void:
	if m.phase == 0 and m.hp < m.hp_max * 0.6:
		m.phase = 1
		for o in [Vector3(-3, 0, 3), Vector3(3, 0, -3)]:
			var s2 := _spawn_mob("drone", m.pos + o, 8)
			s2.st = "chase"
			s2.temp = true
		hud.toast("Шумодав позвал Тишинок!", Color("ff9a9a"))
	elif m.phase == 1 and m.hp < m.hp_max * 0.3:
		m.phase = 2
		hud.big("ШУМОДАВ ЗЛИТСЯ!", "Атаки чаще — держи ритм!", 2.5)
	if m.whisper_t > 0.0:
		m.whisper_t -= dt
		if m.whisper_t <= 0.0:
			_ring_fx(m.pos + Vector3(0, 0.4, 0), Color("c8d0e8"), 13.0, 0.7)
			_ring_fx(m.pos + Vector3(0, 1.4, 0), Color("9aa4c0"), 10.0, 0.6)
			play_sfx("near", 0.4, 0.0)
			if int(m.remix) > 0:
				_add_wave(m.pos, 15.0, 7.5, m.dmg * 0.8, Color("c8d0e8"))
				hud.float_text(m.pos + Vector3(0, 5.0, 0), "БЕТОННЫЙ БАС!", Color("ffd0a0"), 26, 40)
			if pos.distance_to(m.pos) < 13.0 and invuln <= 0.0:
				hurt_player(maxf(22.0, m.dmg * 0.65), m.pos)
				_silence_player(3.5)
				hud.toast("ШШШШ! Тишина — ударь в бит, чтобы вернуть навыки", Color("c8d0e8"))
			elif invuln > 0.0:
				hud.float_text(pos + Vector3(0, 3.0, 0), "Увернулся!", Kit.TEAL, 24, 40)
		return
	if m.tele != null:
		m.tele_t -= dt
		m.flap = 0.4
		if m.tele_t <= 0.0:
			var c: Node3D = m.tele
			if Vector2(pos.x - c.position.x, pos.z - c.position.z).length() < 5.6:
				hurt_player(maxf(70.0, m.dmg * 2.0), m.pos)
				hud.toast("Громкий рёв! Отбегай из красного круга", Color("ff8080"))
			_ring_fx(c.position + Vector3(0, 0.2, 0), Color("ff2a3a"), 5.8, 0.4)
			play_sfx("smash", 0.6, 0.0)
			c.queue_free()
			m.tele = null
		return
	m.special -= dt
	if m.special <= 0.0:
		m.special = 5.0 if m.phase >= 2 else 6.5
		if randf() < 0.55:
			_telegraph(m, 5.6, 1.8)
			hud.toast("Шумодав набирает воздух — уйди из красного круга!", Color("ff9a9a"))
		else:
			m.whisper_t = 1.4
			hud.toast("Шумодав шепчет «ШШШ…» — рывок спасёт!", Color("c8d0e8"))


# ================================================================== 0.4: «Перепрошивка» — server room, rap door, Koschei
const RAP_BATTLE := ["Твоя подписка — пшик,", "мой бит — бесплатный,", "ты в хоре пел не в такт —", "и это неприятно!",
	"Бессмертный, а скучный,", "богатый, а глухой,", "давай-ка перепрошьём", "тебя на бит живой!"]


func _talk_zina_q4() -> void:
	var close := func(): _close_dialog()
	match quest4:
		0:
			hud.show_dialog("Баба Зина", "Милок, Шумодав-то теперь за нас! А флешку Кощей на последнем этаже Глушилки держит: флешка в яйце, яйцо в утке, утка в зайце, заяц в сундуке, а сундук — на железном дубе.", [
				["И как туда попасть?", func():
					hud.show_dialog("Баба Зина", "Шумодав поднимет — он теперь лифт. Вася с тобой пойдёт: он от тишины не глохнет, работает на энергии скидок. А дверь там, говорят, только рифму понимает.", [
						["Перепрошьём! (задание «Перепрошивка»)", func():
							quest4 = 1
							hud.toast("Новое задание: «Перепрошивка»", Hud.GOLD)
							play_sfx("bank")
							save_game()
							close.call()]])]])
		7:
			hud.show_dialog("Баба Зина", "Перепрошил?! Слышишь — музыка вернулась! Голуби и те подпевают. Держи, милок: флешка теперь твоя. На ней только музыка, ничего лишнего.", [
				["Спасибо, баб Зин! (Флешка «ПЕСНЯ_ФИНАЛ», +600 монет)", func():
					_finish_q4()
					close.call()]])
		_:
			hud.show_dialog("Баба Зина", "Кощею в баттле в долю попадай — он этого не умеет! В 1205-м в хоре пел — ни разу не попал. Я-то помню, рядом стояла.", [["Понял, баб Зин!", close]])


func _finish_q4() -> void:
	if quest4 != 7:
		return
	quest4 = 8
	add_item("flash")
	coins += 600
	gain_xp(600)
	hud.big("ЧАСТЬ ПЕРВАЯ ПРОЙДЕНА!", "Музыка вернулась в город. Продолжение следует…", 6.0)
	_notes_fx(pos + Vector3(0, 2, 0), Kit.GOLD)
	_ring_fx(pos + Vector3(0, 0.2, 0), Kit.GOLD, 5.0, 0.8)
	play_sfx("bank")
	save_game()


func _talk_shumodav() -> void:
	state = DIALOG
	var close := func(): _close_dialog()
	if quest4 == 0:
		hud.show_dialog("Шумодав", "Я… БЫЛ… СЦЕНОЙ. ТЕПЕРЬ — ЛИФТ. НО ЗИНА… ЕЩЁ… НЕ ВЕЛЕЛА… ВВЕРХ.", [["Понял, загляну к Зине", close]])
		return
	var t := "ВВЕРХ? НА КРЫШУ… ГЛУШИЛКИ. ДЕРЖИСЬ… ЗА КОНУС." if quest4 < 8 else "Я… СНОВА… СЦЕНА. ПО СУББОТАМ — КОНЦЕРТЫ. НО ЕСЛИ НАДО — ВВЕРХ."
	hud.show_dialog("Шумодав", t, [
		["Вверх, в серверную!", func():
			close.call()
			save_game()
			_travel("server", "from_stroyka")],
		["Пока нет", close]])


# ------------------------------------------------------------------ the rap-code door
func _start_rap_lock() -> void:
	if quest4 != 2:
		return
	lock_active = true
	lock_hits = 0
	hud.big("РЭП-КОД", "Атакуй точно в бит %d раза подряд" % GameData.RAP_LOCK, 3.0)
	hud.toast("Пароль «тишина123» не подошёл. Дверь хочет рифму!", Hud.CREAM)


func _rap_lock_hit(ok: bool) -> void:
	if Vector2(pos.x - ServerRoom.DOOR_X, pos.z).length() > 9.0:
		lock_active = false
		hud.toast("Отошёл от двери — рэп-код сброшен", Hud.CREAM)
		return
	if ok:
		lock_hits += 1
		var line: String = GameData.RAP_LINES[mini(lock_hits, GameData.RAP_LINES.size()) - 1]
		hud.float_text(Vector3(ServerRoom.DOOR_X + 0.6, 4.4, 0), line, Kit.GOLD, 28, 30)
		_ring_fx(Vector3(ServerRoom.DOOR_X + 0.8, 0.2, 0), Kit.GOLD, 3.0, 0.4)
		if lock_hits >= GameData.RAP_LOCK:
			lock_active = false
			_open_door(true)
	elif lock_hits > 0:
		lock_hits = 0
		hud.toast("Сбился с бита — дверь не поверила. Заново!", Color("ff9a9a"))


func _open_door(anim: bool) -> void:
	if not world.has("door"):
		return
	world.rects.erase(world.door_rect)
	var door: Node3D = world.door
	if is_instance_valid(world.door_lamp):
		world.door_lamp.visible = false
	if anim:
		quest4 = 3
		var tw := create_tween()
		tw.tween_property(door, "position:y", -6.0, 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		hud.big("ДВЕРЬ ВЗЛОМАНА РИФМОЙ!", "Заглуши %d робо-зайцев" % GameData.Q4_HARES, 3.5)
		_notes_fx(Vector3(ServerRoom.DOOR_X, 3.0, 0), Kit.GOLD)
		play_sfx("smash", 0.8)
		play_sfx("bank")
		save_game()
	else:
		door.visible = false


# ------------------------------------------------------------------ the chest on the iron oak and the safe hare
func _open_chest() -> void:
	if quest4 != 4 or not world.has("chest"):
		return
	quest4 = 5
	var ch: Node3D = world.chest
	var tw := create_tween()
	tw.tween_property(ch, "position:y", 0.45, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if is_instance_valid(ch):
			_burst(ch.position + Vector3(0, 0.5, 0), [Color("e8b84a"), Color.WHITE], 24)
			play_sfx("smash", 1.1, -2.0)
			ch.visible = false
		if map_id == "server" and quest4 == 5:
			var h := _spawn_mob("safe_hare", ServerRoom.CHEST + Vector3(0, 0, 1.5), 10)
			h.st = "chase"
			hud.float_text(h.pos + Vector3(0, 3.4, 0), "Не догонишь!", Color("ffb0c8"), 26, 40))
	hud.big("ЗАЯЦ-СЕЙФ УДИРАЕТ!", "Догони его — внутри утка, яйцо и флешка", 3.5)
	save_game()


func _hare_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var reach: float = m.radius + 0.8
	if m.charge_t > 0.0:
		m.charge_t -= dt
		m.pos += m.charge_dir * 10.0 * dt
		if dp < reach + 0.2:
			hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
			m.charge_t = 0.0
			hud.float_text(pos + Vector3(0, 2.8, 0), "Прыг-БАМ!", Color("ffb0c8"), 20, 40)
		return 10.0
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
	if m.atk_cd <= 0.0 and dp < 5.5:
		m.atk_cd = m.atk
		m.charge_dir = to_p.normalized()
		m.charge_t = 0.45
		play_sfx("jump", 1.3, -6.0)
		return 0.0
	if dp > 2.5:
		m.pos += to_p.normalized() * m.speed * dt
		return m.speed
	return 0.0


func _safe_hare_flee(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var was: float = m.t
	m.t -= dt
	if m.t <= 0.0 and was > 0.0:
		hud.float_text(m.pos + Vector3(0, 3.6, 0), "Уф, устал…", Color("ffd0e0"), 22, 30)
	if m.t < -1.4:
		m.t = randf_range(3.0, 4.5)
	if m.t < 0.0:
		m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
		return 0.0
	var away := -to_p.normalized()
	var center: Vector3 = Vector3(-12, 0, 0) - m.pos
	center.y = 0
	var dir: Vector3 = (away + center.normalized() * 0.7).normalized()
	m.yaw = lerp_angle(m.yaw, atan2(dir.x, dir.z), minf(1.0, dt * 8))
	var spd: float = m.speed * (1.0 if dp < 12.0 else 0.5)
	m.pos += dir * spd * dt
	if dp < m.radius + 1.0 and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		hurt_player(m.dmg, m.pos)
		hud.float_text(pos + Vector3(0, 2.8, 0), "Пинок задней лапой!", Color("ffb0c8"), 20, 40)
	return spd


func _duck_fx(at: Vector3) -> void:
	var d := Chars.duck()
	fx_root.add_child(d)
	d.position = at + Vector3(0, 1.0, 0)
	fx.append({"node": d, "t": 0.0, "life": 2.5, "kind": "rise"})
	hud.float_text(at + Vector3(0, 2.6, 0), "ПИИ-ИК!", Color("ffd21a"), 34, 50)


# ------------------------------------------------------------------ boss Koschei
func _spawn_koschei(entrance: bool) -> void:
	for m in mobs:
		if m.kind == "koschei" and m.alive:
			return
	var k := _spawn_mob("koschei", ServerRoom.BOSS_SPOT, 12)
	k.st = "chase"
	k.yaw = PI / 2
	if entrance:
		k.alt = 9.0
		hud.big("КОЩЕЙ БЕССМЕРТНЫЙ", "«Спасибо за тишину.» · Рэп-баттл: 3 удара в бит подряд", 4.0)
		play_sfx("laser", 0.4)


func _koschei_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 5))
	if not m.shield:
		m.shield_t -= dt
		if m.shield_t <= 0.0:
			m.shield = true
			m.rap = 0
			hud.toast("Кощей снова оформил подписку! Рэп-баттл: 3 раза в бит", Color("c8d0e8"))
	if m.phase == 0 and m.hp < m.hp_max * 0.66:
		m.phase = 1
		_koschei_summon(m)
	elif m.phase == 1 and m.hp < m.hp_max * 0.33:
		m.phase = 2
		_koschei_summon(m)
	if not m.chast and m.hp < m.hp_max * 0.25 and not companion.is_empty():
		m.chast = true
		m.stun = 4.0
		m.shield = false
		m.shield_t = 10.0
		hud.big("ЗИНА ПОЁТ ЧАСТУШКУ!", "«Кощей в хоре пел в 1205-м — не попал ни разу в долю!»", 4.0)
		_notes_fx(companion.pos + Vector3(0, 2, 0), Kit.GOLD)
		companion.clap = 2.0
		hud.float_text(m.pos + Vector3(0, 3.6, 0), "*краснеет*", Color("ff9ab0"), 24, 30)
		return 0.0
	# flying carpet: changes position from time to time
	if m.fly_to != null:
		var d: Vector3 = m.fly_to - m.pos
		d.y = 0
		if d.length() < 0.5:
			m.fly_to = null
		else:
			spd = 9.0
			m.pos += d.normalized() * spd * dt
			m.yaw = lerp_angle(m.yaw, atan2(d.x, d.z), minf(1.0, dt * 6))
		return spd
	m.fly_t -= dt
	if m.fly_t <= 0.0 and m.tele == null:
		m.fly_t = randf_range(9.0, 12.0)
		var a := randf() * TAU
		m.fly_to = ServerRoom.OAK + Vector3(cos(a) * 8.5, 0, sin(a) * 8.5)
		hud.float_text(m.pos + Vector3(0, 3.6, 0), "Ковёр-самолёт!", Color("e8b84a"), 22, 40)
		return 0.0
	# bills for the silence: red circles under the player's feet
	if m.tele != null:
		m.tele_t -= dt
		m.flap = 0.3
		if m.tele_t <= 0.0:
			var c: Node3D = m.tele
			if Vector2(pos.x - c.position.x, pos.z - c.position.z).length() < 2.9:
				hurt_player(maxf(52.0, m.dmg * 1.7), c.position)
				hud.toast("Счёт за тишину оплачен… здоровьем. Отбегай из круга!", Color("ff8080"))
			_ring_fx(c.position + Vector3(0, 0.2, 0), Color("ff2a3a"), 3.0, 0.35)
			play_sfx("smash", 1.3, -4.0)
			c.queue_free()
			m.tele = null
	else:
		m.special -= dt
		if m.special <= 0.0:
			m.special = 3.6 if m.phase >= 2 else 4.6
			_telegraph(m, 2.8, 1.3, pos)
			hud.float_text(pos + Vector3(0, 2.6, 0), "Счёт за тишину!", Color("ff9a9a"), 20, 40)
	var reach: float = m.radius + 1.0
	if dp > 7.0:
		spd = m.speed
		m.pos += to_p.normalized() * spd * dt
	elif dp < reach and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.4
		hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
		hud.float_text(pos + Vector3(0, 2.8, 0), "Щелчок по носу!", Color("c8f0d0"), 20, 40)
	return spd


func _koschei_summon(m: Dictionary) -> void:
	for o in [Vector3(-3, 0, 3), Vector3(3, 0, -3)]:
		var s2 := _spawn_mob("drone", m.pos + o, 10)
		s2.st = "chase"
		s2.temp = true
	hud.toast("Кощей: «Отписка!» — прилетели Тишинки", Color("ff9a9a"))


func _rap_battle_hit(m: Dictionary, ok: bool) -> void:
	if not m.shield:
		return
	if ok:
		m.rap += 1
		hud.float_text(pos + Vector3(0, 3.4, 0), RAP_BATTLE[randi() % RAP_BATTLE.size()], Kit.GOLD, 22, 40)
		if m.rap >= (5 if int(m.remix) > 0 else 3):
			m.shield = false
			m.shield_t = 8.0
			m.rap = 0
			hud.big("РЭП-БАТТЛ ВЫИГРАН!", "Подписка отменена на 8 секунд — бей!", 2.5)
			_ring_fx(m.pos + Vector3(0, 0.3, 0), Kit.GOLD, 4.0, 0.5)
			play_sfx("smash", 1.2, -2.0)
	elif m.rap > 0:
		m.rap = 0
		hud.float_text(m.pos + Vector3(0, 3.6, 0), "«Не в долю!» — смеётся Кощей", Color("c8d0e8"), 20, 40)


# ------------------------------------------------------------------ companion: Vasya-3000 in the server room
func _spawn_vasya() -> void:
	if quest4 < 1:
		return
	var r := Chars.robot()
	world.root.add_child(r.root)
	Kit.bake_tree(r.root)
	var at := pos + Vector3(-1.6, 0, 1.4)
	r.root.position = at
	vasya_mate = {"root": r.root, "body": r.body, "head": r.head, "arms": r.arms, "legs": r.legs, "pos": at, "yaw": facing, "cd": 2.0, "walk": 0.0}


func _update_vasya(dt: float) -> void:
	if vasya_mate.is_empty():
		return
	var v: Dictionary = vasya_mate
	var fwd := Vector3(sin(facing), 0, cos(facing))
	var right := Vector3(fwd.z, 0, -fwd.x)
	var want: Vector3 = pos - fwd * 1.0 - right * 2.4
	var d: Vector3 = want - v.pos
	d.y = 0
	var spd := 0.0
	if d.length() > 12.0:
		v.pos = want
	elif d.length() > 0.4:
		spd = minf(d.length() * 2.6, 12.5 if mounted else 9.0)
		v.pos += d.normalized() * spd * dt
		v.yaw = lerp_angle(v.yaw, atan2(d.x, d.z), minf(1.0, dt * 8.0))
	else:
		v.yaw = lerp_angle(v.yaw, facing, minf(1.0, dt * 3.0))
	v.pos = World.resolve(v.pos, 0.45, world.rects, world.circles, world.bounds)
	var k := minf(1.0, spd / 5.0)
	v.walk += dt * 9.0 * k
	var sw := sin(v.walk) * 0.6 * k
	v.legs[0].rotation.x = sw
	v.legs[1].rotation.x = -sw
	v.arms[0].rotation.x = -sw * 0.5
	v.body.position.y = maxf(0.0, 0.04 - minf(beat_phase(), 1.0 - beat_phase()) * 0.15)
	v.root.position = v.pos
	v.root.rotation.y = v.yaw
	v.cd -= dt
	if v.cd <= 0.0 and target != null and target.alive and target.pos.distance_to(v.pos) < 14.0 and state == PLAY:
		v.cd = 2.6
		var from: Vector3 = v.pos + Vector3(0, 1.6, 0)
		var to: Vector3 = target.pos + Vector3(0, target.height * 0.55 + target.alt, 0)
		var b := Chars.beam(fx_root, from, to, Kit.GOLD, 0.06, 3.0)
		fx.append({"node": b, "t": 0.0, "life": 0.18, "kind": "none"})
		v.arms[1].rotation.x = -1.6
		damage_mob(target, _base_dmg() * 0.4, false)
		hud.float_text(v.pos + Vector3(0, 2.6, 0), "АКЦИЯ! −40%", Kit.GOLD, 18, 40)
	else:
		v.arms[1].rotation.x = lerpf(v.arms[1].rotation.x, sw * 0.5, minf(1.0, dt * 6.0))


# ================================================================== 0.5: concert in ГК «Песня», the embankment, Zmey Gorynych
const STAGE_POS := Vector3(-19.2, 0, -3.8)
const CONCERT_FRONT := Vector3(-18.6, 0, -0.6)
const RATING := ["ПУБЛИКА ЗЕВАЕТ…", "НЕПЛОХО!", "ХОРОШО ЗАШЛО!", "ОВАЦИИ!"]


func _build_concert_stage() -> void:
	var g := Node3D.new()
	g.name = "ConcertStage"
	world.root.add_child(g)
	Kit.part(g, Kit.BOX, Kit.mat(Color("3a2a22"), 0.7), Vector3(4.4, 0.6, 3.4), STAGE_POS + Vector3(-0.1, 0.3, 0))
	Kit.part(g, Kit.BOX, Kit.neon(Kit.GOLD, 1.6), Vector3(4.4, 0.05, 0.05), STAGE_POS + Vector3(-0.1, 0.6, 1.7))
	for sz in [-1.4, 1.4]:
		Kit.part(g, Kit.BOX, Kit.mat(Color("1a1b22"), 0.5), Vector3(0.7, 1.2, 0.7), STAGE_POS + Vector3(-1.6, 1.2, sz))
		Kit.part(g, Kit.CYL, Kit.neon(Kit.TEAL, 2.6), Vector3(0.44, 0.04, 0.44), STAGE_POS + Vector3(-1.24, 1.3, sz), Vector3(0, 0, PI / 2))
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL, Color("c38bff")]
	for k in range(14):
		var t := k / 13.0
		Kit.part(g, Kit.SPH, Kit.neon(cols[k % 4], 4.0), Vector3.ONE * 0.12, STAGE_POS + Vector3(-0.6, 3.4 - sin(t * PI) * 0.4, -2.0 + t * 4.0))
	var gm := Chars.golem()
	g.add_child(gm.root)
	gm.root.position = STAGE_POS + Vector3(-3.2, -0.3, 0)
	gm.root.rotation = Vector3(0.15, PI / 2, 0)
	gm.root.scale = Vector3.ONE * 0.5
	gm.arms[0].rotation = Vector3(-0.6, 0, -0.5)
	gm.arms[1].rotation = Vector3(-0.6, 0, 0.5)
	var l := Chars.label(world.root, "СЦЕНА ГК «ПЕСНЯ»", 80, Color(3.0, 2.4, 1.4), STAGE_POS + Vector3(-0.6, 4.2, 0), Vector3(0, PI / 2, 0), 0.008, 8)
	l.name = "StageSign"
	Kit.bake_tree(g)
	world.rects.append(Rect2(STAGE_POS.x - 2.3, STAGE_POS.z - 1.7, 4.4, 3.4))


## 0.8: the neighbours come to the concert too — everyone whose place is already open stands in the crowd and dances.
func _add_neighbour_audience() -> void:
	var spots := [Vector3(-12.4, 0, -4.6), Vector3(-12.6, 0, -2.6), Vector3(-12.2, 0, -0.6), Vector3(-12.6, 0, 1.4), Vector3(-12.2, 0, 3.4),
		Vector3(-10.4, 0, -3.6), Vector3(-10.6, 0, -1.6), Vector3(-10.2, 0, 0.4), Vector3(-10.6, 0, 2.4), Vector3(-10.4, 0, 4.4),
		Vector3(-8.6, 0, -2.6), Vector3(-8.4, 0, 1.4)]
	var k := 0
	for id in SideQ.NPCS:
		if k >= spots.size():
			break
		var sn: Dictionary = SideQ.NPCS[id]
		if not sn.get("neighbour", false) or not map_open(sn.map):
			continue
		var h := Npcs.build(id)
		world.root.add_child(h.root)
		h.root.position = spots[k]
		h.root.rotation.y = -PI / 2 + randf_range(-0.25, 0.25)
		Kit.bake_tree(h.root)
		concert_nodes.append({"node": h.root, "body": h.body, "arms": h.get("arms", []), "base": spots[k], "ph": randf() * 0.4, "rot": h.root.rotation.y, "neighbour": true})
		k += 1


func _concert_cleanup() -> void:
	for n in concert_nodes:
		if is_instance_valid(n.node):
			n.node.queue_free()
	concert_nodes.clear()


func start_concert() -> void:
	if state != PLAY or quest4 < 8:
		return
	if mounted:
		_dismount("")
	_concert_cleanup()
	var aud := [[Chars.granny_npc(), Vector3(-15.4, 0, -1.6)], [Chars.lyuba_npc(), Vector3(-15.6, 0, -4.2)], [Chars.misha_npc(), Vector3(-14.2, 0, -0.4)],
		[Chars.petrovich_npc(), Vector3(-14.4, 0, -3.0)]]
	for a in aud:
		var h: Dictionary = a[0]
		world.root.add_child(h.root)
		h.root.position = a[1]
		h.root.rotation.y = -PI / 2
		Kit.bake_tree(h.root)
		concert_nodes.append({"node": h.root, "body": h.body, "arms": h.arms, "base": a[1], "ph": randf() * 0.4})
	for x in [-17.0, -14.5, -12.0, -9.5]:
		var pg := Chars.pigeon(false, false)
		world.root.add_child(pg.root)
		pg.root.scale = Vector3.ONE * 0.42
		pg.root.position = Vector3(x, 2.92, -7.4)
		Kit.bake_tree(pg.root)
		concert_nodes.append({"node": pg.root, "body": pg.body, "arms": [], "base": pg.root.position, "ph": randf() * 0.4})
	if mount_owned:
		var iz := Chars.izba()
		world.root.add_child(iz.root)
		iz.root.scale = Vector3.ONE * 0.5
		iz.root.position = Vector3(-10.4, 0, 3.0)
		iz.root.rotation.y = -PI / 2 - 0.5
		Kit.bake_tree(iz.root)
		concert_nodes.append({"node": iz.root, "body": iz.hut, "arms": [], "base": iz.root.position, "ph": 0.0, "hut": true})
	_add_neighbour_audience()
	start_rhythm({"kind": "concert", "title": "КОНЦЕРТ В ГК «ПЕСНЯ»", "notes": GameData.CONCERT_NOTES, "lines": GameData.CONCERT_LINES,
		"big": "КОНЦЕРТ!"})


## 0.8: the rhythm game of the concert, reused for quest mini-games (tickling the dumpling, film takes, the stream…).
## cfg: kind, title, notes (beats from the start), lines (lyrics by 8 beats), big, hint, meter, on_end(stars: int) for quest games.
func start_rhythm(cfg: Dictionary) -> void:
	if mounted:
		_dismount("")
	var bt := beat_time()
	var start_beat := (int(ceil(bt / beat_len)) / 4 + 2) * 4
	var t0 := start_beat * beat_len
	var times := []
	var judged := []
	for n in cfg.notes:
		times.append(t0 + float(n) * beat_len)
		judged.append(false)
	var end_t := float(times[times.size() - 1]) + beat_len * 2.0
	concert = {"start": t0, "notes": times, "judged": judged, "score": 0, "combo": 0, "max_combo": 0, "perfect": 0, "good": 0, "miss": 0,
		"hype": 20.0, "fb": "", "fb_col": Hud.CREAM, "fb_t": 0.0, "end": end_t, "lyric": "",
		"kind": str(cfg.get("kind", "game")), "title": str(cfg.get("title", "")), "lines": cfg.get("lines", []), "meter": str(cfg.get("meter", "Зал качает")),
		"hint": str(cfg.get("hint", "Жми в любом месте экрана, когда нота в золотом круге · розовые — между долями")),
		"on_end": cfg.get("on_end", Callable()), "back": pos,
		# safety net by the wall clock: even if the music clock misbehaves, the game ends on time
		"wall_end": time + (end_t - bt) + 3.0}
	state = CONCERT
	joy_vec = Vector2.ZERO
	joy_idx = -1
	cam_idx = -1
	target = null
	hud.big(str(cfg.get("big", cfg.get("title", ""))), "Жми в любом месте экрана, когда нота в круге", 3.0)
	play_sfx("bank", 1.2)


func concert_tap() -> void:
	if concert.is_empty():
		return
	var now := beat_time()
	var best := -1
	var bd := 0.35
	for i in range(concert.notes.size()):
		if concert.judged[i]:
			continue
		var d := absf(now - float(concert.notes[i]))
		if d < bd:
			bd = d
			best = i
	attack_anim = 0.3
	if best < 0:
		concert.combo = 0
		concert.fb = "Мимо нот"
		concert.fb_col = Color("c8ccd8")
		concert.fb_t = 0.6
		return
	if bd > 0.2:
		return
	concert.judged[best] = true
	if bd <= 0.075:
		concert.perfect += 1
		concert.combo += 1
		concert.score += 100 + int(concert.combo) * 2
		concert.hype = minf(100.0, concert.hype + 6.0)
		concert.fb = "ИДЕАЛЬНО!"
		concert.fb_col = Hud.GOLD
		_notes_fx(STAGE_POS + Vector3(0, 2.6, 0), Kit.GOLD)
		play_sfx("beat", 1.0 + minf(concert.combo, 10) * 0.03, -2.0)
	elif bd <= 0.15:
		concert.good += 1
		concert.combo += 1
		concert.score += 60
		concert.hype = minf(100.0, concert.hype + 3.0)
		concert.fb = "В БИТ!"
		concert.fb_col = Hud.TEAL
		play_sfx("beat", 0.95, -4.0)
	else:
		concert.miss += 1
		concert.combo = 0
		concert.hype = maxf(0.0, concert.hype - 3.0)
		concert.fb = "РАНО!" if now < float(concert.notes[best]) else "ПОЗДНО!"
		concert.fb_col = Color("ff8a8a")
	concert.max_combo = maxi(concert.max_combo, concert.combo)
	concert.fb_t = 0.6


func _update_concert(dt: float) -> void:
	if concert.is_empty():
		state = PLAY
		return
	var now := beat_time()
	for i in range(concert.notes.size()):
		if not concert.judged[i] and now - float(concert.notes[i]) > 0.2:
			concert.judged[i] = true
			concert.miss += 1
			concert.combo = 0
			concert.hype = maxf(0.0, concert.hype - 4.0)
			concert.fb = "МИМО"
			concert.fb_col = Color("ff6a6a")
			concert.fb_t = 0.5
	concert.fb_t = maxf(0.0, concert.fb_t - dt)
	var phrase := int(floor((now - concert.start) / (8.0 * beat_len)))
	var lines: Array = concert.lines
	concert.lyric = str(lines[phrase % lines.size()]) if phrase >= 0 and lines.size() > 0 else ""
	var bob := maxf(0.0, 0.12 - minf(beat_phase(), 1.0 - beat_phase()) * 0.45)
	var amp: float = 0.6 + concert.hype / 60.0
	if str(concert.get("kind", "concert")) != "concert":
		# a quest mini-game: the hero dances where he stands, the camera stays behind him
		attack_anim = maxf(0.0, attack_anim - dt)
		_animate_hero(dt, 0.0)
		hero.body.position.y = bob * amp * 0.8
		hero.arms[0].rotation.x = -2.4 if bob > 0.05 else -0.4
		hero.arms[1].rotation.x = -0.4 if bob > 0.05 else -2.4
		_update_npcs(dt)
		_update_camera(dt)
	else:
		# the hero on stage, the crowd jumping with the hype
		pos = STAGE_POS
		facing = PI / 2
		attack_anim = maxf(0.0, attack_anim - dt)
		_animate_hero(dt, 0.0)
		hero.root.position = STAGE_POS + Vector3(0.3, 0.6, 0)
		for n in concert_nodes:
			if not is_instance_valid(n.node):
				continue
			n.node.position = n.base + Vector3(0, bob * amp * (1.6 if n.has("hut") else 1.0), 0)
			n.node.rotation.y = n.get("rot", n.node.rotation.y) + sin(time * PI / beat_len + float(n.ph) * 6.0) * 0.18 * minf(1.0, amp - 0.4)
			for a in n.arms:
				a.rotation.x = -2.6 if concert.hype > 50.0 and bob > 0.04 else -0.3
		cam.global_position = cam.global_position.lerp(Vector3(-10.2, 4.3, 4.4), minf(1.0, dt * 3.0))
		cam.fov = 58
		cam.look_at(STAGE_POS + Vector3(0.6, 1.6, 0.4), Vector3.UP)
	if now > float(concert.end) or time > float(concert.wall_end):
		_finish_concert(false)


func _finish_concert(cancel: bool) -> void:
	if concert.is_empty():
		return
	var c: Dictionary = concert
	concert = {}
	_concert_cleanup()
	state = PLAY
	var total: int = c.notes.size()
	var acc: float = (float(c.perfect) + 0.6 * float(c.good)) / float(total)
	var stars := 3 if acc >= 0.85 else (2 if acc >= 0.6 else (1 if acc >= 0.3 else 0))
	if str(c.get("kind", "concert")) != "concert":
		pos = c.back
		if cancel:
			hud.toast("Прервано — можно начать заново", Hud.CREAM)
			stars = -1
		var cb: Callable = c.on_end
		if cb.is_valid():
			cb.call(stars)
		return
	pos = CONCERT_FRONT + Vector3(1.0, 0, 0.8)
	facing = -PI / 2
	yaw = facing + PI
	if cancel:
		hud.toast("Концерт прерван", Hud.CREAM)
		return
	var first: bool = not bool(daily.get("concert", false))
	var gain: int = (40 * stars + int(c.perfect)) * (2 if first and stars > 0 else 1) * u09.concert_mult()
	coins += gain
	gain_xp(50 * stars)
	if stars > 0:
		daily["concert"] = true
	var dots := ""
	for i in range(3):
		dots += "●" if i < stars else "○"
	hud.big("%s  %s" % [RATING[stars], dots], "Идеально %d · В бит %d · Мимо %d · +%d монет%s" % [c.perfect, c.good, c.miss, gain, " (×2 за первый концерт дня)" if first and stars > 0 else ""], 5.0)
	play_sfx("bank")
	if stars == 3:
		_burst(STAGE_POS + Vector3(2, 3, 0), [Kit.GOLD, Color("ff5d7a"), Kit.TEAL, Color.WHITE], 60)
	save_game()
	if quest5 == 1:
		if stars >= 1:
			get_tree().create_timer(2.0).timeout.connect(func():
				if state == PLAY and quest5 == 1:
					_phone_call())
		else:
			hud.toast("Публика не впечатлена — нужна хотя бы одна оценка. Ещё раз!", Hud.CREAM)


func _phone_call() -> void:
	quest5 = 2
	save_game()
	music.pitch_scale = 0.55
	var tw := create_tween()
	tw.tween_property(music, "pitch_scale", 1.0, 1.8)
	play_sfx("near", 0.5, 0.0)
	state = DIALOG
	var close := func(): _close_dialog()
	hud.show_dialog("Кощей (по телефону)", "…Горыныч? Это я. Бэкап загрузился? …Отлично. Пусть они там поют. Недолго осталось.", [
		["Это что сейчас было?!", func():
			hud.show_dialog("Петрович", "Граждане, музыка заикается! Опять Кощеевы фокусы. Бегом к Зинаиде Ивановне!", [["Бегу к Зине!", close]])]])


func _add_river_portal() -> void:
	world.portals.append({"pos": Vector3(0, 0, 17.4), "r": 1.3, "to": "embankment", "spawn": "from_yard", "label": "Набережная"})
	Chars.ring(world.root, Vector3(0, 0.05, 17.4), 1.2, Color("4ad8ff"), 0.08, 3.0)


func _talk_zina_q5() -> void:
	var close := func(): _close_dialog()
	match quest5:
		2:
			hud.show_dialog("Баба Зина", "Слышал? Музыка заикается! Это Кощей бэкап у Горыныча спрятал. Горыныч — три головы, а ума на полторы. Живёт под Калиновым мостом, на набережной.", [
				["Как туда пройти?", func():
					hud.show_dialog("Баба Зина", "Через южную калитку двора, милок. Только там колонки орут одну песню по кругу — это хуже тишины! Выключай их, а кольца звука рывком перепрыгивай.", [
						["Иду к мосту! (задание «Бэкап Горыныча»)", func():
							_accept_q5()
							close.call()]])]])
		6:
			hud.show_dialog("Баба Зина", "Бэкап удалён?! Ну, милок, ты теперь главный по музыке во всём районе. Держи от всего двора — «Золотой бит»!", [
				["Спасибо, баб Зин! (Микрофон «Золотой бит», +700 монет)", func():
					_finish_q5()
					close.call()]])
		_:
			hud.show_dialog("Баба Зина", "Горыныч трёхголовый: одна голова рекламу крутит, другая одну песню по кругу, третья бэкап грузит. Третью в бит перебивай — она этого не любит!", [["Понял!", close]])


func _accept_q5() -> void:
	if quest5 != 2:
		return
	quest5 = 3
	hud.toast("Новое задание: «Бэкап Горыныча» — южная калитка двора", Hud.GOLD)
	play_sfx("bank")
	if map_id == "yard" and world.has("root"):
		_add_river_portal()
	save_game()


func _finish_q5() -> void:
	if quest5 != 6:
		return
	quest5 = 7
	add_item("golden_mic")
	coins += 700
	gain_xp(700)
	hud.big("ВТОРАЯ ЧАСТЬ НАЧАЛАСЬ!", "Бэкап удалён · концерт в ГК — каждый день · продолжение следует…", 6.0)
	_notes_fx(pos + Vector3(0, 2, 0), Kit.GOLD)
	play_sfx("bank")
	save_game()


func _talk_gorynych() -> void:
	state = DIALOG
	var close := func(): _close_dialog()
	var lines := ["Три головы — три мнения. Но сейчас все три за музыку!", "Реклама, автоплей, бэкап… Я теперь просто пою. В три голоса!",
		"Кощей звонил. Я сбросил. Три раза — каждой головой.", "На концерт в ГК приду. Билеты нужны? Три."]
	hud.show_dialog("Змей Горыныч", lines[randi() % lines.size()], [["Ага", close]])


# ------------------------------------------------------------------ speakers on autoplay and Zmey Gorynych
func _autoplay_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 3))
	if m.atk_cd <= 0.0 and dp < 12.0:
		m.atk_cd = m.atk * randf_range(0.9, 1.15)
		m.flap = 0.3
		_add_wave(m.pos, 9.0, 6.5, m.dmg, Color("ff5d7a"))
		hud.float_text(m.pos + Vector3(0, 2.8, 0), ["ТЫЦ-ТЫЦ!", "Хит недели!", "Ещё разок!", "На повторе!"][randi() % 4], Color("ff9ad0"), 18, 40)
	return 0.0


func _goryn_head_awake(m: Dictionary, i: int) -> bool:
	# heads fall asleep one by one: «Реклама» at 66%, «Бэкап» at 33%, «Автоплей» stays to the end
	var f: float = m.hp / m.hp_max
	match i:
		0: return f > 0.66
		2: return f > 0.33
	return true


func _gorynych_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 2.5))
	var f: float = m.hp / m.hp_max
	var heads := 3 if f > 0.66 else (2 if f > 0.33 else 1)
	if heads < int(m.heads):
		m.heads = heads
		m.loading = 0.0
		if heads == 2:
			hud.big("ГОЛОВА «РЕКЛАМА» УСНУЛА!", "Zzz… Осталось две", 2.5)
		else:
			hud.big("ГОЛОВА «БЭКАП» УСНУЛА!", "Осталась «Автоплей» — самая упрямая", 2.5)
	if m.loading > 0.0:
		m.loading -= dt
		m.flap = 0.2
		if m.loading <= 0.0:
			m.hp = minf(m.hp_max, m.hp + m.hp_max * 0.05)
			hud.float_text(m.pos + Vector3(0, 7.2, 0), "Бэкап восстановлен: +5%", Color("4ad8ff"), 24, 40)
		return 0.0
	if _goryn_head_awake(m, 2):
		m.shield_t -= dt
		if m.shield_t <= 0.0:
			m.shield_t = 12.0
			m.loading = 3.0
			hud.toast("Голова «Бэкап» грузит копию… ударь в бит, чтобы прервать!", Color("9ad8ff"))
			return 0.0
	if _goryn_head_awake(m, 0) or int(m.remix) > 0:
		m.fly_t -= dt
		if m.fly_t <= 0.0:
			m.fly_t = 6.5 if int(m.remix) == 0 else 4.5
			m.flap = 0.4
			for k in range(3):
				var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
				_add_trap(pos + off, 2.2, 1.5, maxf(44.0, m.dmg * 1.3))
			hud.float_text(pos + Vector3(0, 2.8, 0), "РЕКЛАМНАЯ ПАУЗА!", Color("ffd23a"), 22, 40)
	m.special -= dt
	if m.special <= 0.0:
		m.special = 5.0 if heads > 1 else 3.6
		m.flap = 0.4
		_add_wave(m.pos, 15.0, 8.0, maxf(30.0, m.dmg * 0.9), Color("ff5d7a"))
		hud.float_text(m.pos + Vector3(0, 7.0, 0), "ТЫЦ-ТЫЦ-ТЫЦ!", Color("ff9ad0"), 26, 40)
	var reach: float = m.radius + 1.4
	if dp > 6.0:
		spd = m.speed
		m.pos += to_p.normalized() * spd * dt
	elif dp < reach and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.5
		hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
		hud.float_text(pos + Vector3(0, 2.8, 0), "Хвостом — БАЦ!", Color("9af0a0"), 22, 40)
	return spd


# ------------------------------------------------------------------ noise waves and ground traps
func _add_wave(center: Vector3, max_r: float, speed: float, dmg: float, col: Color) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	n.position = Vector3(center.x, 0.35, center.z)
	Chars.ring(n, Vector3.ZERO, 1.0, col, 0.045, 2.2)
	n.scale = Vector3.ONE * 0.3
	waves.append({"node": n, "c": center, "r": 0.3, "max": max_r, "spd": speed, "dmg": dmg, "hit": false})


func _update_waves(dt: float) -> void:
	for w in waves.duplicate():
		w.r += w.spd * dt
		var n: Node3D = w.node
		n.scale = Vector3.ONE * w.r
		var d := Vector2(pos.x - w.c.x, pos.z - w.c.z).length()
		if not w.hit and absf(d - w.r) < 0.7 and state == PLAY:
			w.hit = true
			if invuln <= 0.0:
				hurt_player(w.dmg * randf_range(0.9, 1.1), w.c)
				var away := Vector3(pos.x - w.c.x, 0, pos.z - w.c.z)
				if away.length() > 0.01:
					pull_v = away.normalized() * 9.0
				hud.float_text(pos + Vector3(0, 2.8, 0), "ТЫЦ-ТЫЦ!", Color("ff9ad0"), 22, 40)
			else:
				hud.float_text(pos + Vector3(0, 2.8, 0), "Перепрыгнул!", Kit.TEAL, 22, 40)
		if w.r >= w.max:
			n.queue_free()
			waves.erase(w)


func _add_trap(at: Vector3, r: float, t: float, dmg: float) -> void:
	var n := Node3D.new()
	fx_root.add_child(n)
	n.position = Vector3(at.x, 0.09, at.z)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.75, 0.1, 0.3)
	Kit.part(n, Kit.DISC, mat, Vector3(r * 2.0, 1, r * 2.0))
	Chars.ring(n, Vector3(0, 0.02, 0), r, Color("ffb02a"), 0.1, 4.0)
	traps.append({"node": n, "c": at, "r": r, "t": t, "dmg": dmg})


func _update_traps(dt: float) -> void:
	for t in traps.duplicate():
		t.t -= dt
		if t.t <= 0.0:
			if Vector2(pos.x - t.c.x, pos.z - t.c.z).length() < t.r and state == PLAY:
				hurt_player(t.dmg, t.c)
				hud.float_text(pos + Vector3(0, 2.8, 0), "Баннером по голове!", Color("ffd23a"), 20, 40)
			_ring_fx(t.c + Vector3(0, 0.2, 0), Color("ffb02a"), t.r + 0.4, 0.3)
			_burst(t.c + Vector3(0, 0.6, 0), [Color("ffd23a"), Color.WHITE], 10)
			t.node.queue_free()
			traps.erase(t)


# ================================================================== 0.7: парк «Заря», «Рассвет по подписке», Колесо Обновлений
func _stones_found() -> int:
	var n := 0
	for i in range(3):
		if q6_stones & (1 << i):
			n += 1
	return n


func _add_park_portal() -> void:
	world.portals.append({"pos": Vector3(-16.0, 0, 5.0), "r": 1.3, "to": "park", "spawn": "from_embankment", "label": "Парк «Заря» (через мост)"})
	world.spawns["from_park"] = [Vector3(-16.0, 0, 2.0), PI]
	Chars.ring(world.root, Vector3(-16.0, 0.05, 5.0), 1.2, Color("ff9a5a"), 0.08, 3.0)
	world.map_rects.append(Rect2(-17.6, 3.4, 3.2, 3.2))


func _enter_park() -> void:
	if quest6 == 1:
		quest6 = 2
		hud.big("ПАРК «ЗАРЯ»", "Рассвет по подписке… Поговори с охранником у входа", 4.0)
		play_sfx("bank")
		save_game()
	if quest6 == 5:
		_spawn_wheel_boss()
	else:
		_make_wheel_deco()
	if quest6 >= 5:
		_stage_stones_vis()
	_refresh_stones()


func _make_wheel_deco() -> void:
	var w := Park.wheel()
	world.root.add_child(w.root)
	w.root.position = Park.WHEEL
	Kit.bake_tree(w.root)
	w.spinner.visible = quest6 < 6
	wheel_deco = w
	Park.turn_wheel(w, wheel_t, 0.0)


func _update_wheel_deco(dt: float) -> void:
	if wheel_deco.is_empty() or not is_instance_valid(wheel_deco.root) or not wheel_deco.root.visible:
		return
	wheel_t += dt * (0.06 if quest6 >= 6 else 0.16)
	Park.turn_wheel(wheel_deco, wheel_t, time * 4.0)


func _spawn_wheel_boss() -> void:
	for m in mobs:
		if m.kind == "wheel" and m.alive:
			return
	if not wheel_deco.is_empty():
		wheel_deco.root.visible = false
	var w := _spawn_mob("wheel", Park.WHEEL, 18)
	w.st = "chase"
	w.spin_a = wheel_t


func _stage_stones_vis() -> void:
	for k in range(3):
		var p := Park.STAGE + Vector3(-2.0 + k * 2.0, 1.3, -1.6)
		Kit.part(world.root, Kit.SPH, Kit.neon(Color("ffb07a"), 2.4), Vector3(0.6, 0.45, 0.5), p)
	Chars.glow(world.root, Park.STAGE + Vector3(0, 1.6, -1.6), Color("ffb07a"), 4.0, 0.5)


func _refresh_stones() -> void:
	for n in stone_marks:
		if is_instance_valid(n):
			n.queue_free()
	stone_marks = []
	if map_id != "park" or quest6 != 3 or not world.has("root"):
		return
	for i in range(3):
		if q6_stones & (1 << i):
			continue
		var n := Node3D.new()
		world.root.add_child(n)
		n.position = Park.STONES[i][0]
		Chars.loot_beam(n, Vector3.ZERO, Color("ff9a5a"), 6.0)
		Kit.part(n, Kit.SPH, Kit.neon(Color("ffb07a"), 2.6), Vector3(0.5, 0.36, 0.42), Vector3(0, 0.3, 0))
		stone_marks.append(n)


func _take_stone(i: int) -> void:
	if quest6 != 3 or (q6_stones & (1 << i)):
		return
	var st: Array = Park.STONES[i]
	open_dialog(st[1], st[2], [["Забрать камень рассвета", func():
		q6_stones |= (1 << i)
		_close_dialog()
		play_sfx("pickup", 1.2)
		_notes_fx(pos + Vector3(0, 1.5, 0), Color("ffb07a"))
		if _stones_found() >= 3:
			quest6 = 4
			hud.big("ТРИ КАМНЯ РАССВЕТА!", "Они поют вместе. Отнеси их на летнюю сцену «Заря»", 4.0)
		else:
			hud.toast("Камни рассвета: %d / 3" % _stones_found(), Hud.GOLD)
		_refresh_stones()
		save_game()]])


func _stage_stones() -> void:
	if quest6 != 4:
		return
	open_dialog("Летняя сцена «Заря»", "Ты кладёшь три камня рассвета на сцену. Они тихо поют: «ля», «до», «ми»… Небо над парком розовеет — и вдруг колесо обозрения взвизгивает: «ОБНОВЛЕНИЕ 2.0. ЗАГРУЗКА 3%. НЕ ВЫКЛЮЧАЙТЕ УСТРОЙСТВО».", [
		["Остановить колесо!", func():
			_close_dialog()
			quest6 = 5
			_stage_stones_vis()
			_spawn_wheel_boss()
			hud.big("КОЛЕСО ОБНОВЛЕНИЙ ПРОСНУЛОСЬ!", "Жёлтые круги — отбегай · «Не выключайте» — 4 удара в бит", 4.5)
			play_sfx("laser", 0.4)
			save_game()]])


func _wheel_defeated(m: Dictionary) -> void:
	if quest6 == 5:
		quest6 = 6
		hud.big("КОЛЕСО ОСТАНОВИЛОСЬ!", "Загрузка отменена — над парком рассвет! Вернись к Мыслителю Зари", 5.0)
		_apply_map_env("park")
		_notes_fx(m.pos + Vector3(0, 9.0, 0), Kit.GOLD)
	hud.float_text(m.pos + Vector3(0, 9.0, 0), "Ошибка 404: подписка не найдена…", Color("9ad8ff"), 26, 30)
	save_game()


func _zari_main() -> bool:
	if side.has_talk_for("zari"):
		return false
	var close := func(): _close_dialog()
	if quest6 == 0:
		if quest5 < 7 or not side.is_done("treasure"):
			return false
		open_dialog("Мыслитель Зари", "Карта из покрышек… Видишь? Парк «Заря», за Калиновым мостом. Там, на летней сцене, каждое утро пела Жар-птица — поэтому утро в районе всегда было добрым. Пока Кощей не продал рассвет по подписке.", [
			["Рассвет по подписке?!", func():
				hud.show_dialog("Мыслитель Зари", "Шестьсот лет живу — такого не видел. Хотя нет, видел. Тоже Кощей. Перейди мост и найди три камня рассвета: в них осталась песня Жар-птицы. Положишь их на сцену — посмотрим, кто кого.", [
					["Иду в парк! (задание «Рассвет по подписке»)", func():
						quest6 = 1
						hud.toast("Новое задание: «Рассвет по подписке» — Калинов мост", Hud.GOLD)
						play_sfx("bank")
						if map_id == "embankment" and world.has("root"):
							_add_park_portal()
						save_game()
						close.call()]])]])
		return true
	if quest6 >= 1 and quest6 <= 5:
		var t: String = ["", "Калинов мост — вон он. Иди, пока заря не передумала.",
			"Охранник у входа проверяет подписку. Подписки у тебя нет. Зато есть ты.",
			"Камни рассвета тёплые, даже ночью. Ищи там, где утро бывает первым: у воды, у фонтана, на траве.",
			"Нашёл камни? На сцену их! Где пела птица — там и запоёт.",
			"Колесо крутит загрузку. Любая загрузка боится одного — ритма. Когда оно «устанавливается» — бей в бит."][quest6]
		open_dialog("Мыслитель Зари", t, [["Понял!", close]])
		return true
	if quest6 == 6:
		open_dialog("Мыслитель Зари", "Колесо остановилось? И слышишь — птица… нет, птицы ещё нет. Но рассвет — да! Три процента рассвета, зато наших. Держи, ты заслужил.", [
			["Спасибо! (+900 монет, +2000 опыта)", func(): _finish_q6()]])
		return true
	return false


func _finish_q6() -> void:
	if quest6 != 6:
		return
	quest6 = 7
	coins += 900
	gain_xp(2000)
	hud.big("АКТ 1 ЧАСТИ 2 ПРОЙДЕН!", "Рассвет вернулся — на 3%. Но это наши 3%!", 5.0)
	_notes_fx(pos + Vector3(0, 2, 0), Kit.GOLD)
	play_sfx("bank")
	save_game()
	state = DIALOG
	hud.show_dialog("Кощей (по громкоговорителю)", "Алло, район. Это Кощей. Парк «Заря» по документам мой: ООО «Тишина Плюс», всё законно. Хотите обратно — выкупайте. Стартовая цена — миллион. Плюс инфляция бессмертия.", [
		["Миллион?!", func():
			hud.show_dialog("Мыслитель Зари", "Выкупим. Всем районом: Чебуречная, Прачечная, сериал, Олимпиада — каждый поможет. А пока в парке рассвет на три процента. Это уже не ноль.", [
				["Выкупим! (продолжение — в 0.8)", func(): _close_dialog()]])]])


func _talk_guard() -> void:
	state = DIALOG
	var close := func(): _close_dialog()
	if quest6 == 2:
		hud.show_dialog("Охранник Подписочкин", "Стоять. Парк «Заря» — частная собственность ООО «Тишина Плюс». Рассвет — по подписке: девятьсот девяносто девять монет за утро. Подписка есть? Нет? Тогда закат — бесплатно, смотри сколько влезет.", [
			["А можно просто погулять?", func():
				hud.show_dialog("Охранник Подписочкин", "Гулять — бесплатно. Пока. Только птицы молчат по договору, газонокосилки стригут «ОБНОВИСЬ», пакеты шуршат, а колесо крутит загрузку. «Обновление 2.0», слышал? Я сам не слышал — у меня подписки нет.", [
					["Я осмотрюсь (камни рассвета)", func():
						quest6 = 3
						hud.toast("Задание обновлено: найди 3 камня рассвета", Hud.GOLD)
						play_sfx("bank")
						_refresh_stones()
						save_game()
						close.call()]])]])
		return
	var lines := ["Я не охранник. Я — специалист по подпискам. Зарплату мне, кстати, тоже дают по подписке.",
		"Камни? Какие камни? Я ничего не видел. Я на смене сплю — это входит в тариф.", "Колесо обозрения не крутится. Оно ОБНОВЛЯЕТСЯ. Это разные вещи."]
	if quest6 >= 6:
		lines = ["Я увольняюсь. Рассвет взошёл без подписки — значит, и я могу без неё.", "Теперь я просто Подписочкин. Без охраны. Гуляю. Оказывается, гулять — приятно.",
			"Если что — я за парк. Только никому не говори: у меня ещё неделя отработки."]
	elif quest6 < 2:
		lines = ["Вход — по подписке. Выход — тоже по подписке. Шучу. Выход бесплатный."]
	hud.show_dialog("Охранник Подписочкин", lines[randi() % lines.size()], [["Ага", close]])


func _interactables07() -> Array:
	var out := []
	if map_id == "park":
		if quest6 == 3:
			for i in range(3):
				if not (q6_stones & (1 << i)):
					out.append({"label": "Камень", "kind": "stone", "id": str(i), "pos": Park.STONES[i][0], "r": 2.6})
		if quest6 == 4:
			out.append({"label": "Сцена", "kind": "stage", "id": "stage", "pos": Park.STAGE_FRONT, "r": 3.4})
	for b in world.get("consoles", []):
		out.append({"label": "Ремикс", "kind": "remix", "id": b, "pos": GameData.REMIX[b].console, "r": 2.8})
	return out


func _labels07() -> Array:
	var out := []
	if map_id == "park":
		if quest6 == 3:
			for i in range(3):
				if not (q6_stones & (1 << i)):
					out.append([Park.STONES[i][0] + Vector3(0, 2.6, 0), Park.STONES[i][1], 17, Color("ffb07a")])
		if quest6 == 4:
			out.append([Park.STAGE_FRONT + Vector3(0, 2.8, 0), "Положи камни на сцену", 18, Hud.GOLD])
	for b in world.get("consoles", []):
		var r: Dictionary = GameData.REMIX[b]
		out.append([r.console + Vector3(0, 2.7, 0), "Ремикс «%s»" % r.title, 16, Color("d8a8ff")])
	if not prince_npc.is_empty():
		out.append([prince_npc.pos + Vector3(0, 3.5, 0), "Пуф! Исчезнет через %s" % _mmss(prince.left), 16, Color("d8a8ff")])
	return out


# ------------------------------------------------------------------ the boss «Колесо Обновлений»
func _shielded_wheel():
	for m in mobs:
		if m.alive and m.kind == "wheel" and m.shield and m.pos.distance_to(pos) < 26.0:
			return m
	return null


func _wheel_beat(m: Dictionary, ok: bool) -> void:
	if ok:
		m.rap = int(m.rap) + 1
		hud.float_text(pos + Vector3(0, 3.4, 0), ["Отмена!", "Напомнить позже!", "Нет, спасибо!", "Не сейчас!"][randi() % 4], Kit.GOLD, 22, 40)
		if int(m.rap) >= 4:
			m.shield = false
			m.rap = 0
			m.fly_t = 18.0
			m.stun = 3.0
			hud.big("ОБНОВЛЕНИЕ ОТМЕНЕНО!", "Колесо зависло на 3 секунды — бей!", 2.5)
			_ring_fx(m.pos + Vector3(0, 0.3, 0), Kit.GOLD, 6.0, 0.5)
			play_sfx("smash", 1.2, -2.0)
	elif int(m.rap) > 0:
		m.rap = 0
		hud.float_text(m.pos + Vector3(0, 9.5, 0), "Ошибка… установка начата заново", Color("9ad8ff"), 20, 40)


func _wheel_install(m: Dictionary) -> void:
	m.shield = true
	m.shield_t = 10.0
	m.rap = 0
	hud.big("УСТАНОВКА ОБНОВЛЕНИЯ… НЕ ВЫКЛЮЧАЙТЕ!", "4 удара в бит подряд — отменить. Пока ставится — Колесо лечится", 3.5)
	play_sfx("laser", 0.6)


func _wheel_summon(m: Dictionary, n: int) -> void:
	for k in range(n):
		var a := PI + (k - (n - 1) * 0.5) * 0.7
		var s2 := _spawn_mob("loader", m.pos + Vector3(sin(a) * 5.0, 0, cos(a) * 5.0), maxi(14, int(m.lvl) - 1))
		s2.st = "chase"
		s2.temp = true
	hud.toast("Колесо: «Загружаем дополнительные кружочки…»", Color("9ad8ff"))


func _wheel_chase(m: Dictionary, dt: float, _to_p: Vector3, dp: float) -> float:
	var f: float = m.hp / m.hp_max
	if m.phase == 0 and f < 0.75:
		m.phase = 1
		_wheel_summon(m, 2)
	elif m.phase == 1 and f < 0.5:
		m.phase = 2
		_wheel_install(m)
	elif m.phase == 2 and f < 0.3:
		m.phase = 3
		_wheel_summon(m, 3)
	if m.shield:
		m.shield_t -= dt
		m.hp = minf(m.hp_max, m.hp + m.hp_max * 0.012 * dt)
		if m.shield_t <= 0.0:
			m.shield = false
			m.fly_t = 18.0
			hud.toast("Обновление установилось криво — Колесо подлечилось", Color("9ad8ff"))
	elif m.phase >= 2:
		m.fly_t -= dt
		if m.fly_t <= 0.0:
			_wheel_install(m)
	m.special -= dt
	if m.special <= 0.0 and dp < 26.0:
		m.special = 3.6 if m.phase >= 2 else 4.6
		m.flap = 0.5
		for k in range(3):
			var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-3.2, 3.2), 0, randf_range(-3.2, 3.2))
			_add_trap(pos + off, 2.3, 1.4, m.dmg * 1.3)
		hud.float_text(pos + Vector3(0, 2.8, 0), "Установка… %d%%" % randi_range(3, 99), Color("9ad8ff"), 22, 40)
	m.pull_cd -= dt
	if m.pull_cd <= 0.0 and dp < 26.0:
		m.pull_cd = 6.5 if m.phase >= 2 else 8.0
		m.flap = 0.5
		_add_wave(m.pos, 22.0, 8.5, m.dmg * 0.9, Color("4ad8ff"))
		hud.float_text(m.pos + Vector3(0, 10.5, 0), "ОБНОВИСЬ!", Color("9ad8ff"), 30, 40)
	if int(m.remix) > 0:
		m.whisper_t -= dt
		if m.whisper_t <= 0.0:
			m.whisper_t = 16.0
			_wheel_summon(m, 2)
			for k in range(8):
				var a := k * TAU / 8.0 + randf() * 0.3
				_add_trap(m.pos + Vector3(sin(a) * 9.0, 0, cos(a) * 9.0), 2.2, 1.8, m.dmg * 1.2)
			hud.float_text(m.pos + Vector3(0, 10.5, 0), "БЕСКОНЕЧНАЯ ЗАГРУЗКА!", Color("9ad8ff"), 28, 40)
	if dp < m.radius + 1.6 and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.4
		hurt_player(m.dmg * randf_range(0.9, 1.1), m.pos)
		hud.float_text(pos + Vector3(0, 2.8, 0), "Кабинкой — БАЦ!", Color("ff9ad0"), 22, 40)
	return 0.0


# ------------------------------------------------------------------ park mobs: mower, ghost bag, robo-duck, loading circle
func _park_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	var reach: float = m.radius + 0.9
	match m.kind:
		"mower":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				spd = 9.5
				m.pos += m.charge_dir * spd * dt
				if dp < reach + 0.3:
					hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
					pull_v = m.charge_dir * 7.0
					m.charge_t = 0.0
					m.atk_cd = m.atk
					hud.float_text(pos + Vector3(0, 2.8, 0), "ВЖЖЖ — стрижка!", Color("8aff7a"), 22, 40)
				return spd
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
			if m.atk_cd <= 0.0 and dp < 8.0:
				m.charge_dir = to_p.normalized()
				m.charge_t = 0.9
				m.flap = 0.3
				play_sfx("dash", 1.2, -6.0)
			elif dp > 3.5:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
		"bag":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 5))
			var dir := to_p.normalized()
			var sway := Vector3(dir.z, 0, -dir.x) * sin(time * 2.2 + m.home.x) * 0.7
			if dp > reach:
				spd = m.speed
				m.pos += (dir + sway).normalized() * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				m.flap = 0.4
				hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
				if randf() < 0.3:
					_silence_player(1.6)
					hud.float_text(pos + Vector3(0, 3.2, 0), "Шшшурх!", Color("e8eeff"), 22, 40)
		"duck":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
			if dp > 9.0:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
			elif dp < 4.0:
				spd = m.speed * 0.6
				m.pos -= to_p.normalized() * spd * dt
			if m.atk_cd <= 0.0 and dp < 12.0:
				m.atk_cd = m.atk * randf_range(0.9, 1.2)
				_fire_quack(m)
		"loader":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 12.0 * dt
				if dp < reach + 0.2:
					hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
					m.charge_t = 0.0
					hud.float_text(pos + Vector3(0, 2.8, 0), "99%… БАЦ!", Color("9ad8ff"), 20, 40)
				return 12.0
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
			if m.atk_cd <= 0.0 and dp < 6.0:
				m.atk_cd = m.atk
				m.charge_dir = to_p.normalized()
				m.charge_t = 0.42
				play_sfx("jump", 1.5, -6.0)
				return 0.0
			if dp > 2.2:
				spd = m.speed
				m.pos += to_p.normalized() * spd * dt
	return spd


func _fire_quack(m: Dictionary) -> void:
	var n := Mobs07.quack()
	fx_root.add_child(n)
	var from: Vector3 = m.pos + Vector3(0, 1.4, 0) + Vector3(sin(m.yaw), 0, cos(m.yaw)) * 0.7
	n.position = from
	var aim := pos + Vector3(0, 1.1, 0)
	mob_shots.append({"node": n, "dir": (aim - from).normalized(), "life": 3.0, "dmg": m.dmg, "kind": "quack"})
	m.flap = 0.35
	hud.float_text(m.pos + Vector3(0, 2.4, 0), "КРЯ!", Color("ffe04a"), 18, 30)
	play_sfx("near", 2.0, -10.0)


func _animate_park_mob(m: Dictionary, dt: float, spd: float) -> void:
	match m.kind:
		"mower":
			for w in m.wheels:
				w.rotation.x += dt * spd * 4.0
			for b in m.wings:
				b.rotation.y += dt * (40.0 if m.st == "chase" else 10.0)
			m.body.position.y = sin(time * 40.0) * (0.02 if m.st == "chase" else 0.006)
			m.head.rotation.x = -0.2 if m.charge_t > 0.0 else 0.0
		"bag":
			m.body.position.y = 1.3 + sin(time * 2.0 + m.home.x) * 0.25 + (0.2 if m.flap > 0.0 else 0.0)
			m.body.rotation.z = sin(time * 1.7 + m.home.z) * 0.15
			for i in range(m.wings.size()):
				m.wings[i].rotation.z = sin(time * 6.0 + i * 1.5) * 0.3
			m.head.scale = Vector3.ONE * (1.0 + (0.3 if m.flap > 0.0 else 0.0))
		"duck":
			var k := minf(1.0, spd / 2.0)
			m.body.rotation.z = sin(time * 9.0 + m.home.x) * 0.12 * k
			var fl := sin(time * 26.0) * 0.6 if m.flap > 0.0 else 0.0
			m.wings[0].rotation.z = -0.2 - fl
			m.wings[1].rotation.z = 0.2 + fl
			m.wheels[0].rotation.x = sin(time * 9.0) * 0.5 * k
			m.wheels[1].rotation.x = -sin(time * 9.0) * 0.5 * k
			m.head.rotation.x = -0.35 if m.flap > 0.0 else sin(time * 2.0 + m.home.z) * 0.12
		"loader":
			# the loading circle always shows its face to the hero
			m.yaw = lerp_angle(m.yaw, atan2(pos.x - m.pos.x, pos.z - m.pos.z), minf(1.0, dt * 6.0))
			m.wheels[0].rotation.z -= dt * (7.0 + spd)
			var hop := 0.0
			if m.charge_t > 0.0:
				hop = 0.6 * sin(m.charge_t / 0.42 * PI)
			m.body.position.y = 1.0 + absf(sin(time * 3.0 + m.home.x)) * 0.15 + hop
		"wheel":
			var rate := 0.25 if m.phase < 2 else 0.45
			if m.shield:
				rate = 1.4
			if m.stun > 0.0:
				rate = 0.0
			m.spin_a += dt * rate
			Park.turn_wheel(m.extra, m.spin_a, time * (12.0 if m.shield else 6.0))


# ================================================================== 0.7: boss remixes and golden singles
func remix_open(b: String) -> bool:
	var need: Array = GameData.REMIX[b].need
	return int(get(need[0])) >= int(need[1])


func _add_remix_consoles() -> void:
	var list := []
	for b in GameData.REMIX_ORDER:
		var r: Dictionary = GameData.REMIX[b]
		if r.map == map_id and remix_open(b):
			Park.console(world.root, r.console, float(r.rot))
			world.circles.append(Vector3(r.console.x, r.console.z, 0.9))
			list.append(b)
	world["consoles"] = list


func _check_remix_day() -> void:
	var today := Time.get_date_string_from_system()
	if remix.day != today:
		remix.day = today
		remix.looted = []


func _remix_max_diff(b: String) -> int:
	return mini(3, int(remix.best.get(b, -1)) + 1)


func _remix_busy() -> bool:
	for m in mobs:
		if m.alive and m.boss:
			return true
	return false


func _singles_word(n: int) -> String:
	var a := n % 100
	var b := n % 10
	if a >= 11 and a <= 14:
		return "золотых синглов"
	if b == 1:
		return "золотой сингл"
	if b >= 2 and b <= 4:
		return "золотых сингла"
	return "золотых синглов"


func _list_remix(b: String) -> void:
	_check_remix_day()
	var r: Dictionary = GameData.REMIX[b]
	var best := int(remix.best.get(b, -1))
	var looted: bool = b in remix.looted
	var busy := _remix_busy()
	var rows := []
	rows.append({"text": "Фишка ремикса", "sub": str(r.twist), "color": Hud.GOLD})
	for i in range(4):
		var d: Array = GameData.REMIX_DIFF[i]
		var open := i <= _remix_max_diff(b)
		var lv: int = maxi(level, int(r.lvl)) + int(d[3])
		var sub := "Босс ур. %d · здоровье ×%.2f · урон ×%.2f · награда: %d %s" % [lv, float(d[1]), float(d[2]), int(d[4]), _singles_word(int(d[4]))]
		if not open:
			sub += "\nОткроется после победы на сложности «%s»" % GameData.REMIX_DIFF[i - 1][0]
		var idx := i
		rows.append({"text": "%s%s" % [d[0], " (пройдено)" if best >= i else ""], "sub": sub, "btn": "Начать" if open else "Закрыто",
			"enabled": open and not busy, "cb": func(): _start_remix(b, idx), "color": Color("e0c8ff") if open else Color(0.6, 0.62, 0.7)})
	var loot_txt: String = ("уже получена — бой для удовольствия (пропусков в ремикс: %d)" % int(remix.passes)) if looted else "ещё доступна"
	hud.show_list("РЕМИКС «%s»" % r.title, "Босс: %s · %s\nДобыча сегодня: %s · золотых синглов у тебя: %d%s" % [GameData.MOBS[b].name, r.where, loot_txt, singles,
		"\nСначала разберись с тем, кто уже на арене!" if busy else ""], rows)


func _start_remix(b: String, i: int) -> void:
	close_list()
	var r: Dictionary = GameData.REMIX[b]
	if _remix_busy() or map_id != r.map:
		return
	var d: Array = GameData.REMIX_DIFF[i]
	if r.has("npc"):
		for e in npcs.duplicate():
			if e.id == r.npc:
				e.node.visible = false
				npcs.erase(e)
				remix_hidden[r.npc] = e
	if b == "wheel" and not wheel_deco.is_empty():
		wheel_deco.root.visible = false
	var lv: int = maxi(level, int(r.lvl)) + int(d[3])
	var m := _spawn_mob(b, r.pos, lv)
	var md: Dictionary = GameData.MOBS[b]
	var ref := (20.0 + 21.0 * lv) * 1.55
	m.hp_max = 48.0 * ref * float(GameData.REMIX_HP[b]) * float(d[1])
	m.hp = m.hp_max
	m.dmg = float(md.dmg[0]) * (1.0 + 0.07 * maxf(0.0, float(lv) - float(r.lvl))) * float(d[2])
	m.xp = int((300 + lv * 40) * (1.0 + i * 0.35))
	m.remix = i + 1
	m.remix_id = b
	m.st = "chase"
	if b == "wheel":
		m.spin_a = wheel_t
	hud.big("РЕМИКС «%s» · %s" % [r.title, d[0]], str(r.twist), 4.0)
	_ring_fx(r.pos + Vector3(0, 0.3, 0), Color("b06eff"), 6.0, 0.6)
	play_sfx("laser", 0.5)


func _remix_win(m: Dictionary) -> void:
	_check_remix_day()
	var b: String = str(m.remix_id)
	var i := int(m.remix) - 1
	var d: Array = GameData.REMIX_DIFF[i]
	var r: Dictionary = GameData.REMIX[b]
	var was := int(remix.best.get(b, -1))
	remix.best[b] = maxi(was, i)
	remix.wins = int(remix.wins) + 1
	var got := 0
	var note := ""
	if not (b in remix.looted):
		remix.looted.append(b)
		got = int(d[4])
	elif int(remix.passes) > 0:
		remix.passes = int(remix.passes) - 1
		got = int(d[4])
		note = " · пропуск в ремикс"
	var c := 150 + 60 * i + int(m.lvl) * 6
	coins += c
	var mat: String = u09.remix_mats(b, i, m.pos)
	if mat != "":
		note += " · " + mat
	if got > 0:
		singles += got
		if randf() < 0.35 + 0.15 * i or autotest:
			var pool: Array = r.items
			_loot_at(str(pool[randi() % pool.size()]), m.pos + (Vector3(0, 0, -4.0) if b == "wheel" else Vector3.ZERO))
		hud.big("РЕМИКС «%s» ПРОЙДЕН · %s" % [r.title, d[0]], "+%d %s%s · +%d монет" % [got, _singles_word(got), note, c], 4.5)
	else:
		hud.big("РЕМИКС «%s» ПРОЙДЕН · %s" % [r.title, d[0]], "Синглы сегодня уже получены · +%d монет%s" % [c, note], 4.5)
	if i < 3 and was < i:
		hud.toast("Открыта сложность «%s»" % GameData.REMIX_DIFF[i + 1][0], Color("d8a8ff"))
	_notes_fx(m.pos + Vector3(0, 3, 0), Color("b06eff"))
	play_sfx("bank")
	save_game()
	var mp := map_id
	get_tree().create_timer(2.5).timeout.connect(func():
		if map_id == mp and world.has("root") and state in [PLAY, DIALOG, LIST]:
			_prince_appear("remix"))


## After a remix boss falls: hide it after a moment and bring back the NPC / the decorative wheel.
func _remix_after(m: Dictionary) -> void:
	if int(m.remix) == 0 or m.restored or m.dead_t < 3.0:
		return
	m.restored = true
	m.node.visible = false
	_remix_restore(str(m.remix_id))


func _remix_restore(b: String) -> void:
	var r: Dictionary = GameData.REMIX[b]
	if r.has("npc") and remix_hidden.has(r.npc):
		var e: Dictionary = remix_hidden[r.npc]
		if is_instance_valid(e.node):
			e.node.visible = true
		npcs.append(e)
		remix_hidden.erase(r.npc)
	if b == "wheel" and not wheel_deco.is_empty():
		wheel_deco.root.visible = true


func _journal_rows07() -> Array:
	var out := []
	var open := []
	for b in GameData.REMIX_ORDER:
		if remix_open(b):
			open.append(b)
	if open.size() > 0:
		_check_remix_day()
		var parts := []
		for b in open:
			var r: Dictionary = GameData.REMIX[b]
			parts.append("«%s» (%s)%s" % [r.title, r.where, " — взято" if b in remix.looted else ""])
		out.append({"text": "Ремиксы боссов: %d" % open.size(), "sub": "Пульт «РЕМИКС» у арены: повторный бой с новой фишкой, 4 сложности. Раз в сутки с каждого босса — золотые синглы («взято» — уже получено сегодня), а спецматериал для мастерской «Идея» — за каждую победу.\n" + " · ".join(parts),
			"color": Color("d8a8ff")})
	if prince.met:
		out.append({"text": "Сингл Принц · золотых синглов: %d" % singles, "sub": "Появляется сам: примерно раз в 30–40 минут игры, после каждой победы в ремиксе и по пятницам у Калинова моста. Лавка открыта 3 минуты.",
			"color": Color("d8a8ff")})
	return out


# ================================================================== 0.7: Сингл Принц
func _prince_stock() -> void:
	var keys: Array = GameData.PRINCE_SHOP.keys()
	keys.shuffle()
	prince.stock = keys.slice(0, 4)
	prince.hit = str(prince.stock[randi() % prince.stock.size()])


func _prince_price(id: String) -> int:
	var p := int(GameData.PRINCE_SHOP[id].price)
	return maxi(1, int(floor(p * 0.7))) if id == prince.hit else p


func _prince_appear(reason: String) -> void:
	if not prince_npc.is_empty() or not world.has("root"):
		return
	var at: Vector3
	var rot: float
	if reason == "friday" and map_id == "embankment":
		at = Vector3(-12.0, 0, 3.4)
		rot = PI
	else:
		var fwd := Vector3(sin(facing), 0, cos(facing))
		at = World.resolve(pos + fwd * 4.5, 1.3, world.rects, world.circles, world.bounds)
		rot = atan2(pos.x - at.x, pos.z - at.z)
	_spawn_npc("prince", at, rot)
	prince_npc = npcs[npcs.size() - 1]
	prince.left = GameData.PRINCE_TIME
	prince.map = map_id
	_prince_stock()
	_burst(at + Vector3(0, 1.4, 0), [Color("b06eff"), Kit.GOLD, Color.WHITE], 30)
	_ring_fx(at + Vector3(0, 0.2, 0), Color("b06eff"), 3.0, 0.5)
	hud.float_text(at + Vector3(0, 3.0, 0), "ПУФ!", Color("d8a8ff"), 40, 50)
	hud.toast("Сингл Принц: «Один. Неповторимый. Только сегодня» · 3 минуты!", Color("d8a8ff"))
	play_sfx("bank", 1.4)


func _prince_leave(msg: String) -> void:
	if prince_npc.is_empty():
		return
	var e: Dictionary = prince_npc
	prince_npc = {}
	if is_instance_valid(e.node):
		_burst(e.pos + Vector3(0, 1.4, 0), [Color("b06eff"), Kit.GOLD], 24)
		e.node.queue_free()
	npcs.erase(e)
	hud.toast(msg, Color("d8a8ff"))
	if state == LIST and list_kind == "prince":
		close_list()
	elif state == DIALOG and hud.dialog_name.text == "Сингл Принц":
		_close_dialog()


func _update_prince(dt: float) -> void:
	if not prince_npc.is_empty():
		prince.left = float(prince.left) - dt
		if prince.left <= 0.0:
			_prince_leave("Сингл Принц покинул чат. «Сингл — он и есть сингл»")
		return
	if not prince.met or state != PLAY or not world.has("root"):
		return
	prince.next = float(prince.next) - dt
	if prince.next <= 0.0:
		if _boss_near():
			prince.next = 30.0
			return
		prince.next = randf_range(GameData.PRINCE_EVERY[0], GameData.PRINCE_EVERY[1])
		_prince_appear("random")


func _talk_prince() -> void:
	if prince.met:
		open_list("prince")
		return
	open_dialog("Сингл Принц", "Пуф! Сингл Принц. Один. Неповторимый. Только сегодня. Видел твой ремикс — это был хит. Держи золотой сингл: первый — бесплатно. Как демо.", [
		["А что такое синглы?", func():
			hud.show_dialog("Сингл Принц", "Золотые синглы — валюта для ценителей. Они выпадают, когда побеждаешь боссов в ремиксах: пульт «РЕМИКС» стоит у каждой арены, раз в сутки с каждого босса. А я появляюсь… когда появляюсь. Три минуты — и «Сингл Принц покинул чат».", [
				["Покажи релизы! (+1 золотой сингл)", func():
					prince.met = true
					singles += 1
					prince.next = randf_range(GameData.PRINCE_EVERY[0], GameData.PRINCE_EVERY[1])
					hud.toast("Новое знакомство: Сингл Принц · +1 золотой сингл", Color("d8a8ff"))
					save_game()
					_close_dialog()
					open_list("prince")]])]])


func _list_prince() -> void:
	var rows := []
	for id in prince.stock:
		var d: Dictionary = GameData.PRINCE_SHOP[id]
		var price := _prince_price(id)
		var nm: String
		var desc: String
		var owned := false
		if d.kind == "item":
			var it: Dictionary = GameData.ITEMS[id]
			nm = it.name
			var st2 := GameData.stats_text(GameData.item_stats(it))
			desc = "%s · ур. %d · %s · +%d силы%s\n%s" % [Hud.RARITY_NAME[it.rarity], GameData.item_level(it), GameData.SLOT_NAMES.get(it.slot, ""), it.power, (" · " + st2) if st2 != "" else "", it.desc]
			owned = count_item(id) > 0
		else:
			nm = d.name
			desc = d.desc
		var hit: bool = id == prince.hit
		var item_id: String = id
		rows.append({"text": ("ХИТ ДНЯ -30% · " if hit else "") + nm, "sub": desc, "btn": ("Уже есть" if owned else "Купить · %d" % price),
			"enabled": (not owned) and singles >= price, "cb": func(): _prince_buy(item_id), "color": Hud.GOLD if hit else Color("e8d0ff")})
	var tail := ""
	if metro_until > now():
		tail = "\nМетроном Сингл Принца работает ещё %s" % _mmss(metro_until - now())
	hud.show_list("СИНГЛ ПРИНЦ · ЛАВКА", "«Я не продаю. Я выпускаю релизы.» · Золотых синглов: %d · исчезнет через %s\nСинглы — с ремиксов боссов: пульт «РЕМИКС» у каждой арены%s" % [singles, _mmss(prince.left), tail], rows)


func _prince_buy(id: String) -> void:
	if prince_npc.is_empty() or not (id in prince.stock):
		return
	var price := _prince_price(id)
	if singles < price:
		return
	var d: Dictionary = GameData.PRINCE_SHOP[id]
	match str(d.kind):
		"item":
			if count_item(id) > 0:
				return
			add_item(id)
		"buff":
			metro_until = maxf(now(), metro_until) + GameData.METRONOME_SECS
			hud.toast("Метроном Сингл Принца: окно бита шире на 10 минут", Color("d8a8ff"))
		"pass":
			remix.passes = int(remix.passes) + 1
			hud.toast("Пропуск в ремикс: +1 бой с добычей", Color("d8a8ff"))
		"food":
			food += 3
			hud.toast("Шаурма «Королевская» ×3", Color("ffd27a"))
	singles -= price
	play_sfx("bank", 1.2)
	hud.float_text(pos + Vector3(0, 3.0, 0), "Это не скидка — это ремикс цены!", Color("d8a8ff"), 20, 40)
	save_game()
	_refresh_list()


# ================================================================== 0.7: the city map and Pilot's aerotaxi
func unlock(kind: String) -> void:
	if kind == "taxi":
		taxi = true
		hud.toast("Аэротакси «Ложка» открыто: карта Рубина → место → «Лететь» · от %d монет" % GameData.TAXI_BASE, Hud.GOLD)
	else:
		u08.unlock(kind)
		u09.unlock(kind)


func map_open(m: String) -> bool:
	match m:
		"yard", "garages":
			return true
		"stroyka":
			return quest3 >= 2
		"server":
			return quest4 >= 1
		"embankment":
			return quest5 >= 3
		"park":
			return quest6 >= 1
		"cheburek":
			return u08.map_open_cheb()
		"laundry":
			return u08.map_open_laundry()
		"dump":
			return u09.map_open()
	return false


func open_map() -> void:
	if state != PLAY:
		return
	state = LIST
	list_kind = "map"
	hud.city_map.open()


## «!» or «?» when somebody on that map has something for the hero.
func map_marker(m: String) -> String:
	var mk := ""
	var ids := []
	for id in SideQ.NPCS:
		if SideQ.NPCS[id].map == m:
			ids.append(id)
	ids += {"yard": ["zina", "misha"], "garages": ["petrovich"], "stroyka": ["shumodav"], "park": ["guard"]}.get(m, [])
	for id in ids:
		var x := npc_marker(id)
		if x == "?":
			return "?"
		if x == "!":
			mk = "!"
	return mk


func fly_to(m: String) -> void:
	if not taxi or not map_open(m) or m == map_id:
		return
	var price := GameData.taxi_price(map_id, m)
	if coins < price:
		hud.toast("На аэротакси нужно %d монет" % price, Hud.CREAM)
		return
	for mb in mobs:
		if mb.alive and mb.st == "chase" and mb.pos.distance_to(pos) < 20.0:
			hud.toast("Кукурузник в бою не садится — сначала разберись с врагами", Hud.CREAM)
			return
	coins -= price
	close_list()
	_dismount("")
	save_game()
	await _travel(m, "start")
	hud.big("АЭРОТАКСИ «ЛОЖКА»", "Взлёт через пять минут… шучу, уже прилетели!", 3.0)
	play_sfx("land", 0.8)


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
				var rap: bool = t.kind == "koschei"
				if frames % 3 == 0 and (not rap or on_beat()):
					press("attack")
				if frames % 50 == 0 and not rap:
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


## Step on a portal until the map really changes (re-teleports if a mob pushed the hero off or the hero died).
func _at_portal(p: Vector3, m: String) -> void:
	var guard := 0
	while (map_id != m or state != PLAY) and guard < 900:
		if state == DEAD:
			_respawn()
		if state == PLAY and map_id != m:
			pos = p
			portal_cd = 0.0
			hp = hp_max
			invuln = 1.0
		await get_tree().process_frame
		guard += 1


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
	if args.has("--test07"):
		for q in SideQ.ORDER.slice(0, 12):
			side.st[q] = {"s": 0, "n": 0, "t": 0.0, "done": true}
		await _autotest_07(lg, shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only07"):
		await _shots07(shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--test08"):
		await _autotest_08(lg, shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only08"):
		await _shots08(shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--test09"):
		await _autotest_09(lg, shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only09"):
		await _shots09(shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only06"):
		await _shots06(shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only05"):
		await _shots05(shots_dir)
		_finish_report(lg, t0)
		return
	if args.has("--only04"):
		await _shots04(shots_dir)
		_finish_report(lg, t0)
		return
	# chain 1
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_accept_quest()
	_close_dialog()
	var f1 := await _bot_fight(150 if quick else (240 if args.has("--skip1") else 3000), func(): return quest >= 4)
	_lg(lg, "chain1 quest=%d frames=%d" % [quest, f1])
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
	_lg(lg, "shop open=%s" % str(state == LIST and list_kind == "shop"))
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
	_lg(lg, "dailies claimed=%d" % daily.claimed.size())
	close_list()
	# travel to the garages through the arch
	await _at_portal(Vector3(15.6, 0, -27.6), "garages")
	_lg(lg, "map=%s npcs=%d" % [map_id, npcs.size()])
	await _go_interact(Vector3(10.2, 0, 4.6))
	_close_dialog()
	quest2 = 2
	_refresh_robot()
	await _go_interact(Base.ROBOT_HOME)
	_send_robot("ezhik")
	_lg(lg, "robot task=%s quest2=%d" % [robot_task.task, quest2])
	for k in range(60):
		await get_tree().process_frame
	if shots_dir != "":
		await _snap(shots_dir, "3_garages_robot_leaving")
	time_shift += 200.0
	await get_tree().process_frame
	await _go_interact(Base.ROBOT_HOME)
	_collect_robot()
	close_list()
	_lg(lg, "after robot quest2=%d planks=%d food=%d" % [quest2, res.planks, food])
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
	_lg(lg, "buildings=%s quest2=%d hp_max=%d" % [str(buildings), quest2, int(hp_max)])
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
	_lg(lg, "save roundtrip coins=%d==%d len=%d" % [coins, c0, before])
	# back to the yard
	await _at_portal(Vector3(29.6, 0, 0), "yard")
	await _bot_fight(120 if shots_dir != "" else 400, func(): return false)
	if shots_dir != "":
		open_bag()
		await _snap(shots_dir, "5_bag")
		close_bag()
	await _autotest_q3(lg, shots_dir)
	await _autotest_q4(lg, shots_dir)
	await _autotest_q5(lg, shots_dir)
	await _autotest_side(lg, shots_dir)
	await _autotest_07(lg, shots_dir)
	await _autotest_08(lg, shots_dir)
	await _autotest_09(lg, shots_dir)
	_lg(lg, "final level=%d coins=%d food=%d items=%d" % [level, coins, food, inventory.size()])
	_finish_report(lg, t0)


func _autotest_q3(lg: Array, shots_dir: String) -> void:
	quest2 = 6
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_lg(lg, "q3 zina dialog=%s marker=%s" % [str(state == DIALOG), "ok"])
	_close_dialog()
	quest3 = 1
	await _at_portal(Vector3(15.6, 0, -27.6), "garages")
	await _go_interact(Vector3(10.2, 0, 4.6))
	_close_dialog()
	_open_site_gate()
	_lg(lg, "q3 gate quest3=%d portals=%d" % [quest3, world.portals.size()])
	await _at_portal(Vector3(-29.6, 0, 0), "stroyka")
	_lg(lg, "stroyka quest3=%d mobs=%d companion=%s" % [quest3, mobs.size(), str(not companion.is_empty())])
	for k in range(30):
		await get_tree().process_frame
	if shots_dir != "":
		pos = Vector3(16, 0, 1)
		facing = -PI / 2
		yaw = facing + PI
		await _bot_fight(90, func(): return false)
		await _snap(shots_dir, "6_stroyka_drones")
	var f2 := await _bot_fight(4000, func(): return quest3 >= 4)
	_lg(lg, "drones quest3=%d kills=%d frames=%d silence_seen=%s" % [quest3, q3_kills, f2, str(silence_t >= 0.0)])
	if quest3 < 4:
		q3_kills = GameData.Q3_DRONES
		quest3 = 4
		_spawn_mob("shumodav", Stroyka.BOSS_HOME, 10)
	# isolate the boss fight
	for m in mobs:
		if m.kind != "shumodav" and m.alive:
			m.alive = false
			m.node.visible = false
			m.respawn = 1.0e9
	pos = Stroyka.ARENA + Vector3(7, 0, 0)
	facing = -PI / 2
	yaw = facing + PI
	var boss = null
	for m in mobs:
		if m.kind == "shumodav":
			boss = m
	var fb := await _bot_fight(2500, func(): return boss == null or boss.hp < boss.hp_max * 0.55)
	if shots_dir != "":
		await _snap(shots_dir, "7_shumodav")
	fb += await _bot_fight(4000, func(): return quest3 >= 5)
	_lg(lg, "boss quest3=%d frames=%d level=%d" % [quest3, fb, level])
	if quest3 < 5:
		quest3 = 5
	for k in range(40):
		await get_tree().process_frame
	# back to Zina for the mount
	await _at_portal(Vector3(26.6, 0, 0), "garages")
	await _at_portal(Vector3(29.8, 0, 0), "yard")
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_finish_q3()
	_close_dialog()
	for m in mobs:
		if m.alive:
			m.st = "idle"
			m.pos = m.home
	pos = Vector3(0, 0, 12)
	facing = PI
	yaw = facing + PI
	await get_tree().process_frame
	var p0 := pos
	toggle_mount()
	var m0 := mounted
	joy_vec = Vector2(0, -1)
	for k in range(20):
		await get_tree().process_frame
	joy_vec = Vector2.ZERO
	_lg(lg, "mount owned=%s mounted=%s/%s speed=%.1f m/s" % [str(mount_owned), str(m0), str(mounted), pos.distance_to(p0) / (20.0 / 30.0)])
	if shots_dir != "":
		pos = Vector3(0, 0, 6)
		facing = PI * 0.85
		yaw = facing + PI * 0.75
		for k in range(10):
			await get_tree().process_frame
		await _snap(shots_dir, "8_mount")
	press("attack")
	_lg(lg, "after attack mounted=%s" % str(mounted))
	save_game()
	var d := _read_save()
	_lg(lg, "save q3=%s mount=%s" % [str(d.get("quest3")), str(d.get("mount"))])


func _autotest_q4(lg: Array, shots_dir: String) -> void:
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_lg(lg, "q4 zina dialog=%s" % str(state == DIALOG))
	_close_dialog()
	quest4 = 1
	await _at_portal(Vector3(15.6, 0, -27.6), "garages")
	await _at_portal(Vector3(-29.6, 0, 0), "stroyka")
	var shu := false
	for n in npcs:
		if n.id == "shumodav":
			shu = true
	_lg(lg, "stroyka shumodav_npc=%s boss_alive=%s" % [str(shu), str(_boss_near())])
	await _go_interact(Stroyka.BOSS_HOME + Vector3(1.0, 0, 0))
	_lg(lg, "shumodav lift dialog=%s" % str(state == DIALOG))
	_close_dialog()
	await _travel("server", "from_stroyka")
	_lg(lg, "server quest4=%d mobs=%d vasya=%s zina=%s rects=%d" % [quest4, mobs.size(), str(not vasya_mate.is_empty()), str(not companion.is_empty()), world.rects.size()])
	pos = Vector3(ServerRoom.DOOR_X + 2.2, 0, 0)
	facing = -PI / 2
	yaw = facing + PI
	for k in range(3):
		await get_tree().process_frame
	interact()
	for k in range(8):
		await get_tree().process_frame
	if shots_dir != "":
		await _snap(shots_dir, "9_server_door")
	var fr := 0
	var best := 0
	while quest4 < 3 and fr < 900:
		await get_tree().process_frame
		fr += 1
		best = maxi(best, lock_hits)
		if on_beat() and cd.attack <= 0.0:
			press("attack")
	_lg(lg, "door quest4=%d frames=%d best_hits=%d" % [quest4, fr, best])
	if quest4 < 3:
		_open_door(true)
	var f := await _bot_fight(4000, func(): return quest4 >= 4)
	_lg(lg, "hares quest4=%d kills=%d frames=%d" % [quest4, q4_kills, f])
	if quest4 < 4:
		q4_kills = GameData.Q4_HARES
		quest4 = 4
	await _go_interact(ServerRoom.CHEST)
	for k in range(40):
		await get_tree().process_frame
	if shots_dir != "":
		facing = PI * 0.75
		yaw = facing + PI
		for k in range(4):
			await get_tree().process_frame
		await _snap(shots_dir, "10_server_oak")
	f = await _bot_fight(4000, func(): return quest4 >= 6)
	_lg(lg, "safe hare quest4=%d frames=%d" % [quest4, f])
	if quest4 < 6:
		quest4 = 6
		_spawn_koschei(false)
	var boss = null
	var w := 0
	while boss == null and w < 200:
		await get_tree().process_frame
		w += 1
		for m in mobs:
			if m.kind == "koschei" and m.alive:
				boss = m
	if boss == null:
		_spawn_koschei(false)
		for m in mobs:
			if m.kind == "koschei":
				boss = m
	f = await _bot_fight(3000, func(): return boss.hp < boss.hp_max * 0.8)
	if shots_dir != "":
		await _snap(shots_dir, "11_koschei")
	f += await _bot_fight(9000, func(): return quest4 >= 7)
	_lg(lg, "koschei quest4=%d frames=%d hp=%d%% chast=%s" % [quest4, f, int(100.0 * boss.hp / boss.hp_max), str(boss.chast)])
	if quest4 < 7:
		quest4 = 7
	for k in range(30):
		await get_tree().process_frame
	await _at_portal(Vector3(32.4, 0, 0), "stroyka")
	await _at_portal(Vector3(26.6, 0, 0), "garages")
	await _at_portal(Vector3(29.8, 0, 0), "yard")
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_finish_q4()
	_close_dialog()
	var has_flash := false
	for it in inventory:
		if it.id == "flash":
			has_flash = true
	_lg(lg, "q4 done quest4=%d flash=%s" % [quest4, str(has_flash)])


## Quick visual check of the 0.4 content (used with --shots for screenshots)
func _shots04(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 1
	level = 10
	for id in ["megaphone", "pakhan_cap", "vest"]:
		add_item(id)
	_recalc_stats()
	hp = hp_max
	await _travel("server", "from_stroyka")
	pos = Vector3(ServerRoom.DOOR_X + 3.0, 0, 0.6)
	facing = -PI / 2
	yaw = facing + PI - 0.3
	for k in range(4):
		await get_tree().process_frame
	_start_rap_lock()
	lock_hits = 2
	for k in range(6):
		await get_tree().process_frame
	await _snap(dir, "9_server_door")
	lock_active = false
	_open_door(true)
	for m in mobs:
		m.alive = false
		m.node.visible = false
		m.respawn = 1.0e9
	pos = ServerRoom.OAK + Vector3(9, 0, 4)
	facing = atan2(-9, -4)
	yaw = facing + PI
	pitch = 0.32
	for k in range(50):
		await get_tree().process_frame
	await _snap(dir, "10_server_oak")
	quest4 = 6
	_spawn_koschei(true)
	pos = ServerRoom.BOSS_SPOT + Vector3(6, 0, 3)
	facing = atan2(-6, -3)
	yaw = facing + PI + 0.2
	pitch = 0.4
	await _bot_fight(70, func(): return false)
	await _snap(dir, "11_koschei")


func _play_concert_bot(accuracy: float) -> void:
	# taps exactly on the notes (with a given share of hits) until the concert ends
	# the song runs on the music clock (real time), so wait by the wall clock, not by frames
	var t_end := Time.get_ticks_msec() + 80000
	while state == CONCERT and Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		if concert.is_empty():
			break
		var now := beat_time()
		for i in range(concert.notes.size()):
			if not concert.judged[i] and absf(now - float(concert.notes[i])) < 0.04:
				if randf() < accuracy:
					concert_tap()
				break


func _autotest_q5(lg: Array, shots_dir: String) -> void:
	await _at_portal(Vector3(15.6, 0, -27.6), "garages")
	_lg(lg, "q5 petrovich marker=%s stage=%s" % [npc_marker("petrovich"), str(world.root.has_node("ConcertStage"))])
	await _go_interact(Vector3(10.2, 0, 4.6))
	_close_dialog()
	quest5 = 1
	await _go_interact(CONCERT_FRONT)
	_lg(lg, "concert started=%s notes=%d" % [str(state == CONCERT), concert.get("notes", []).size()])
	await _play_concert_bot(0.95)
	_lg(lg, "concert done state=%d coins=%d quest5=%d" % [state, coins, quest5])
	var w := 0
	while quest5 < 2 and w < 200:
		await get_tree().process_frame
		w += 1
	_lg(lg, "phone call quest5=%d dialog=%s" % [quest5, str(state == DIALOG)])
	_close_dialog()
	await _at_portal(Vector3(29.8, 0, 0), "yard")
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_close_dialog()
	_accept_q5()
	_lg(lg, "q5 accepted quest5=%d portals=%d" % [quest5, world.portals.size()])
	await _at_portal(Vector3(0, 0, 17.4), "embankment")
	_lg(lg, "embankment quest5=%d mobs=%d zina=%s" % [quest5, mobs.size(), str(not companion.is_empty())])
	var f := await _bot_fight(5000, func(): return quest5 >= 5)
	_lg(lg, "speakers quest5=%d kills=%d frames=%d hp_min_ok=%s" % [quest5, q5_kills, f, str(hp > 0)])
	if quest5 < 5:
		q5_kills = GameData.Q5_SPEAKERS
		quest5 = 5
		_spawn_mob("gorynych", Embankment.BOSS_HOME, 12)
	for m in mobs:
		if m.kind != "gorynych" and m.alive:
			m.alive = false
			m.node.visible = false
			m.respawn = 1.0e9
	pos = Embankment.BOSS_HOME + Vector3(8, 0, -2)
	f = await _bot_fight(9000, func(): return quest5 >= 6)
	var gb = null
	for m in mobs:
		if m.kind == "gorynych":
			gb = m
	_lg(lg, "gorynych quest5=%d frames=%d heads=%d" % [quest5, f, int(gb.heads) if gb != null else -1])
	if quest5 < 6:
		quest5 = 6
	await _at_portal(Vector3(32.2, 0, 0), "yard")
	await _go_interact(Vector3(-5.9, 0, -5.0))
	_finish_q5()
	_close_dialog()
	var mic := false
	for it in inventory:
		if it.id == "golden_mic":
			mic = true
	_lg(lg, "q5 done quest5=%d golden_mic=%s" % [quest5, str(mic)])


## Quick visual check of the 0.5 content (used with --shots for screenshots)
func _shots05(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 1
	level = 10
	mount_owned = true
	for id in ["megaphone", "pakhan_cap", "vest"]:
		add_item(id)
	_recalc_stats()
	hp = hp_max
	await _travel("garages", "start")
	pos = CONCERT_FRONT + Vector3(1.2, 0, 0.6)
	await get_tree().process_frame
	start_concert()
	var t_end := Time.get_ticks_msec() + 120000
	while state == CONCERT and Time.get_ticks_msec() < t_end:
		await get_tree().process_frame
		var now := beat_time()
		for i in range(concert.notes.size()):
			if not concert.judged[i] and absf(now - float(concert.notes[i])) < 0.2:
				concert_tap()
				break
		if now > float(concert.start) + 9.0 * beat_len:
			# the software renderer in tests is too slow to tap in time — show a typical mid-song state
			concert.hype = 80.0
			concert.perfect = 7
			concert.good = 2
			concert.miss = 1
			concert.combo = 6
			concert.score = 1020
			await _snap(dir, "12_concert")
			break
	_finish_concert(true)
	quest5 = 4
	await _travel("embankment", "from_yard")
	pos = Vector3(16, 0, 1)
	facing = -PI / 2
	yaw = facing + PI
	await _bot_fight(60, func(): return false)
	await _snap(dir, "13_embankment")
	for m in mobs:
		m.alive = false
		m.node.visible = false
		m.respawn = 1.0e9
	quest5 = 5
	_spawn_mob("gorynych", Embankment.BOSS_HOME, 12)
	pos = Embankment.BOSS_HOME + Vector3(9, 0, -3)
	facing = -PI / 2
	yaw = facing + PI - 0.3
	await _bot_fight(70, func(): return false)
	await _snap(dir, "14_gorynych")


# ================================================================== 0.6 autotest: the new neighbours
const _AT_PLACES := {"zina": ["yard", Vector3(-5.9, 0, -5.0)], "misha": ["yard", Vector3(4.6, 0, 13.6)], "lyuba": ["yard", Vector3(-9.7, 0, -13.1)],
	"petrovich": ["garages", Vector3(10.2, 0, 4.6)], "gorynych": ["embankment", Vector3(-11.0, 0, 2.5)], "guard": ["park", Vector3(5.0, 0, -18.8)]}


func _at_place(id: String) -> Array:
	if SideQ.NPCS.has(id):
		if not u08.npc_shown(id):
			for e in U08.GUESTS:
				if e[0] == id:
					return [e[1], e[2]]
		return [SideQ.NPCS[id].map, u08.npc_place(id)[0]]
	return _AT_PLACES[id]


func _at_goto_map(m: String) -> void:
	if map_id != m:
		await _travel(m, "start")
	invuln = 9999.0
	hp = hp_max
	for k in range(3):
		await get_tree().process_frame


func _at_talk(id: String) -> void:
	var pl := _at_place(id)
	await _at_goto_map(pl[0])
	if state == DIALOG:
		_close_dialog()
	var p: Vector3 = pl[1]
	await _go_interact(Vector3(p.x, 0, p.z))


func _at_press(i := 0) -> bool:
	if state != DIALOG:
		return false
	var live := []
	for c in hud.dialog_opts.get_children():
		if not c.is_queued_for_deletion():
			live.append(c)
	if i >= live.size():
		return false
	(live[i] as Button).pressed.emit()
	await get_tree().process_frame
	return true


func _at_kill_kind(kind: String, until: Callable, max_frames := 6000) -> int:
	var frames := 0
	while frames < max_frames and not until.call():
		var found = null
		for m in mobs:
			if m.alive and m.kind == kind:
				found = m
				break
		if found != null:
			pos = found.pos + Vector3(1.5, 0, 0)
			target = found
			damage_mob(found, 999999.0, false)
		else:
			pos = world.spawns.start[0]
		await get_tree().process_frame
		frames += 1
		hp = hp_max
	return frames


func _at_side_quest(lg: Array, q: String) -> void:
	var qd: Dictionary = SideQ.QUESTS[q]
	var npc: String = qd.npc
	var r: Array = qd.req
	if int(get(r[0])) < int(r[1]):
		set(r[0], int(r[1]))
	while level < int(qd.lvl):
		gain_xp(xp_next() - xp)
	await _at_talk(npc)
	var mk_ok: bool = state == DIALOG and hud.dialog_name.text == SideQ.NPCS[npc].name
	await _at_press(0)   # accept
	var guard := 0
	while side.is_active(q) and guard < 12:
		guard += 1
		var s := side.step(q)
		match s.type:
			"kill", "collect":
				await _at_goto_map(_kill_map(s.mob))
				var si := int(side.st[q].s)
				await _at_kill_kind(s.mob, func(): return int(side.st[q].s) != si or not side.is_active(q))
			"give_items":
				for id in s.items:
					while count_item(id) < int(s.items[id]):
						add_item(id)
				await _at_talk(npc)
				await _at_press(0)
				if state == DIALOG:
					_close_dialog()
			"give_res":
				if s.res == "food":
					food += int(s.n)
				else:
					res[s.res] += int(s.n)
				await _at_talk(npc)
				await _at_press(0)
				if state == DIALOG:
					_close_dialog()
			"talk":
				await _at_talk(s.npc)
				await _at_press(0)
			"find":
				await _at_goto_map(s.map)
				var fp: Vector3 = s.pos
				pos = fp + Vector3(0.8, 0, 0.8)
				await get_tree().process_frame
				await get_tree().process_frame
				var beams := side.marks.size()
				interact()
				await _at_press(0)
				_lg(lg, "side %s find %s beams=%d" % [q, s.label, beams])
			"combo":
				side.on_combo(int(s.n))
			"timer":
				time_shift += float(s.secs) + 5.0
				await get_tree().process_frame
				await get_tree().process_frame
			"waves":
				await _at_goto_map(s.map)
				var wi := int(side.st[q].s)
				var wg := 0
				while side.is_active(q) and int(side.st[q].s) == wi and wg < 3000:
					wg += 1
					pos = s.pos + Vector3(0, 0, -2.0)
					for wm in mobs:
						if wm.alive and wm.temp and wm.kind == s.mob:
							damage_mob(wm, 999999.0, false)
					hp = hp_max
					await get_tree().process_frame
				_lg(lg, "side %s waves frames=%d" % [q, wg])
			"return":
				await _at_talk(npc)
				await _at_press(0)
			"rhythm":
				var ri := int(side.st[q].s)
				await _at_talk(s.npc)
				await _at_press(0)
				var started: bool = state == CONCERT
				await _play_concert_bot(1.0)
				await _frames(3)
				_lg(lg, "side %s rhythm %s started=%s passed=%s" % [q, s.game, str(started), str(int(side.st[q].s) != ri or not side.is_active(q))])
			"boss":
				await _at_goto_map(s.map)
				var bi := int(side.st[q].s)
				var bpos: Vector3 = s.pos
				pos = bpos + Vector3(0, 0, 9.0)
				await _frames(3)
				var spawned := _find_mob(s.boss) != null
				var bg := 0
				while side.is_active(q) and int(side.st[q].s) == bi and bg < 3000:
					bg += 1
					var bm = _find_mob(s.boss)
					if bm != null and int(bm.remix) == 0:
						pos = bm.pos + Vector3(0, 0, bm.radius + 2.0)
						damage_mob(bm, 999999999.0, false)
					else:
						pos = bpos + Vector3(0, 0, 9.0)
					hp = hp_max
					await get_tree().process_frame
				_lg(lg, "side %s boss %s spawned=%s frames=%d loot=%d" % [q, s.boss, str(spawned), bg, loots.size()])
				for l in loots.duplicate():
					pos = l.pos
					await _frames(20)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "side %s «%s» done=%s dialog_ok=%s level=%d" % [q, qd.title, str(side.is_done(q)), str(mk_ok), level])


func _kill_map(kind: String) -> String:
	match kind:
		"scooter", "vacuum", "pigeon": return "yard"
		"drone": return "stroyka"
		"hare": return "server"
		"gull", "autoplay": return "embankment"
		"mower", "bag", "duck", "loader": return "park"
		"roach", "fly", "cheb", "plunger_mob", "pelmeshek": return "cheburek"
		"sock", "washer", "iron", "bubble": return "laundry"
		"rat", "fridge", "mattress": return "dump"
	return map_id


func _autotest_side(lg: Array, shots_dir: String) -> void:
	await _at_goto_map("yard")
	# markers and journal before anything is accepted
	var mk := npc_marker("pavlin")
	open_journal()
	var rows := hud.list_box.get_child_count()
	close_list()
	_lg(lg, "side start marker_pavlin=%s journal_rows=%d npcs_in_yard=%d" % [mk, rows, npcs.size()])
	# quiet zone: an idle hero next to Baba Zina is ignored by a pigeon
	pos = Vector3(-4.0, 0, -4.0)
	idle_t = 10.0
	invuln = 0.0
	var pg = null
	for m in mobs:
		if m.alive and m.kind == "pigeon":
			pg = m
			break
	pg.pos = pos + Vector3(2.0, 0, 0)
	pg.st = "idle"
	for k in range(30):
		await get_tree().process_frame
		idle_t = 10.0
	var quiet_ok: bool = pg.st != "chase"
	pg.pos = pg.home
	pos = pg.home + Vector3(2.5, 0, 0)
	idle_t = 0.0
	pg.st = "idle"
	for k in range(10):
		await get_tree().process_frame
	var outside_ok: bool = pg.st == "chase"
	# respawn waits while the hero stands near the mob's home
	damage_mob(pg, 999999.0, false)
	pos = pg.home + Vector3(1, 0, 1)
	pg.respawn = 0.05
	for k in range(20):
		await get_tree().process_frame
	var deferred: bool = not pg.alive
	pos = pg.home + Vector3(0, 0, 30)
	pos = World.resolve(pos, 0.45, world.rects, world.circles, world.bounds)
	var far_enough := Vector2(pos.x - pg.home.x, pos.z - pg.home.z).length() >= 14.0
	pg.respawn = 0.05
	for k in range(140):
		await get_tree().process_frame
	_lg(lg, "quiet_zone ignored=%s outside_aggro=%s respawn_deferred=%s respawned_later=%s(far=%s) respawn_t=%d" % [str(quiet_ok), str(outside_ok), str(deferred), str(pg.alive), str(far_enough), int(RESPAWN_T)])
	invuln = 9999.0
	for q in SideQ.ORDER.slice(0, 12):
		await _at_side_quest(lg, q)
	# reserved items survive «sell junk», unique rewards are never junk
	add_item("dust")
	side.st["clean"] = {"s": 1, "n": 0, "t": 0.0, "done": false}
	var before := count_item("dust")
	_sell_junk()
	var kept := count_item("dust")
	side.st["clean"].done = true
	var lant := count_item("lantern")
	# item level gating
	var lv := level
	level = 5
	var w = equipped.get("weapon", null)
	for it in inventory:
		if it.id == "lantern":
			equip(it)
	var gated: bool = is_same(equipped.get("weapon", null), w)
	level = lv
	for it in inventory:
		if it.id == "lantern":
			equip(it)
	var worn: bool = equipped.get("weapon", {}).get("id", "") == "lantern"
	_lg(lg, "side summary done=%d/18 dust_kept=%d/%d lantern=%d gated_at5=%s worn=%s stats=%s beat_win=%.3f hp_max=%d" % [side.done_count(), kept, before, lant, str(gated), str(worn), str(stats), beat_win, int(hp_max)])
	var total := 0
	for l in range(1, GameData.MAX_LEVEL):
		total += GameData.xp_for_level(l)
	_lg(lg, "xp curve L10=%d L20=%d L40=%d L69=%d total_to_70=%d" % [GameData.xp_for_level(10), GameData.xp_for_level(20), GameData.xp_for_level(40), GameData.xp_for_level(69), total])
	# save round trip keeps side progress
	save_game()
	var keep := side.done_count()
	side.reset()
	load_game()
	_lg(lg, "side save roundtrip done=%d==%d ver=%d" % [side.done_count(), keep, GameData.SAVE_VERSION])
	invuln = 0.0


## Screenshots of the new neighbours (run with --only06 --shots DIR under xvfb).
func _shots06(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	mount_owned = true
	level = 12
	_recalc_stats()
	invuln = 9999.0
	var shots := [["yard", "pavlin", 0.0], ["yard", "lis", 0.0], ["garages", "pilot", 0.0], ["garages", "kent", 0.0], ["garages", "jack", 0.0],
		["stroyka", "klyukva", 0.0], ["server", "maloy", 0.0], ["embankment", "chef", 0.0], ["embankment", "melnik", 0.0],
		["embankment", "zari", 0.0], ["embankment", "yarik", 0.0], ["stroyka", "shcheben", 0.0]]
	for e in shots:
		await _at_goto_map(e[0])
		for m in mobs:
			m.alive = false
			m.node.visible = false
			m.respawn = 9999.0
		var sn: Dictionary = SideQ.NPCS[e[1]]
		var p: Vector3 = sn.pos
		var fwd := Vector3(sin(sn.rot), 0, cos(sn.rot))
		var right := Vector3(fwd.z, 0, -fwd.x)
		var jack: bool = e[1] == "jack"
		pos = Vector3(p.x, 0, p.z) + fwd * (6.0 if jack else 2.4) + right * (0.0 if jack else 1.0)
		pos = World.resolve(pos, 0.45, world.rects, world.circles, world.bounds)
		facing = atan2(p.x - pos.x, p.z - pos.z)
		yaw = facing + PI + (0.0 if jack else 0.3)
		dist = 4.2 if jack else 3.2
		pitch = 0.04 if jack else 0.16
		hud.big_t = 0.0
		for k in range(40):
			if hero.has("root"):
				hero.root.scale = Vector3.ONE * 0.001
			if not companion.is_empty():
				companion.root.visible = false
			await get_tree().process_frame
		await _snap(dir, "npc_" + e[1])
	# dialog, journal, tracker and the bag
	dist = 7.6
	if hero.has("root"):
		hero.root.scale = Vector3.ONE
	await _at_goto_map("embankment")
	side.st = {"soup": {"s": 0, "n": 2, "t": 0.0, "done": false}, "kvass": {"s": 2, "n": 0, "t": now() + 420.0, "done": false}}
	var cp: Vector3 = SideQ.NPCS.yarik.pos
	pos = cp + Vector3(-2.2, 0, -2.0)
	facing = atan2(cp.x - pos.x, cp.z - pos.z)
	yaw = facing + PI
	pitch = 0.35
	for k in range(20):
		await get_tree().process_frame
	await _snap(dir, "tracker")
	interact()
	await get_tree().process_frame
	await _snap(dir, "dialog_yarik")
	_close_dialog()
	open_journal()
	await get_tree().process_frame
	await _snap(dir, "journal")
	close_list()
	for id in ["ladle", "compass", "mill_cap", "boots_pavlin", "lantern", "crumbs", "crumbs", "seeds"]:
		add_item(id)
	open_bag()
	await get_tree().process_frame
	await _snap(dir, "bag")
	close_bag()


# ================================================================== 0.7 autotest: парк «Заря», Колесо, соседи, ремиксы, Принц, карта
func _frames(n: int) -> void:
	for k in range(n):
		await get_tree().process_frame


func _find_mob(kind: String):
	for m in mobs:
		if m.alive and m.kind == kind:
			return m
	return null


func _autotest_07(lg: Array, shots_dir: String) -> void:
	invuln = 9999.0
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	mount_owned = true
	if not side.is_done("treasure"):
		side.st["treasure"] = {"s": 3, "n": 0, "t": 0.0, "done": true}
	while level < 15:
		gain_xp(xp_next() - xp)
	# Мыслитель Зари starts «Рассвет по подписке»
	await _at_talk("zari")
	var z_ok: bool = state == DIALOG and hud.dialog_name.text == "Мыслитель Зари"
	var mk_z := npc_marker("zari")
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	var portal_ok := false
	for pt in world.portals:
		if pt.to == "park":
			portal_ok = true
	_lg(lg, "q6 zari dialog=%s marker=%s quest6=%d bridge_portal=%s" % [str(z_ok), mk_z, quest6, str(portal_ok)])
	await _at_portal(Vector3(-16.0, 0, 5.0), "park")
	_lg(lg, "park entered quest6=%d mobs=%d npcs=%d wheel_deco=%s" % [quest6, mobs.size(), npcs.size(), str(not wheel_deco.is_empty())])
	# the guard
	await _at_talk("guard")
	var g_ok: bool = state == DIALOG and hud.dialog_name.text == "Охранник Подписочкин"
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "guard dialog=%s quest6=%d stone_marks=%d" % [str(g_ok), quest6, stone_marks.size()])
	# dawn stones
	for i in range(3):
		var sp: Vector3 = Park.STONES[i][0]
		pos = sp + Vector3(0.8, 0, 0.8)
		await _frames(2)
		interact()
		await _at_press(0)
	_lg(lg, "stones found=%d quest6=%d" % [_stones_found(), quest6])
	# the stage wakes the wheel
	pos = Park.STAGE_FRONT + Vector3(0.6, 0, -0.6)
	await _frames(2)
	interact()
	await _at_press(0)
	var wb = _find_mob("wheel")
	_lg(lg, "stage quest6=%d wheel_boss=%s deco_hidden=%s" % [quest6, str(wb != null), str(wheel_deco.is_empty() or not wheel_deco.root.visible)])
	if wb != null:
		# «не выключайте»: 4 on-beat hits cancel the update
		_wheel_install(wb)
		var shield_on: bool = wb.shield
		for k in range(4):
			_wheel_beat(wb, true)
		_lg(lg, "wheel shield_on=%s cancelled=%s stun=%.1f" % [str(shield_on), str(not wb.shield), wb.stun])
		pos = Park.WHEEL + Vector3(0, 0, -6.5)
		var fw := await _bot_fight(6000, func(): return quest6 >= 6)
		await _frames(40)
		for l in loots.duplicate():
			pos = l.pos
			await _frames(25)
		_lg(lg, "wheel fight quest6=%d frames=%d wheel_mic=%d level=%d" % [quest6, fw, count_item("wheel_mic"), level])
	if quest6 < 6:
		quest6 = 6
	if shots_dir != "":
		await _snap(shots_dir, "07_wheel_down")
	# back to Zari
	await _at_talk("zari")
	await _at_press(0)
	var k_ok: bool = state == DIALOG and hud.dialog_name.text.begins_with("Кощей")
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "q6 done quest6=%d koschei_call=%s coins=%d" % [quest6, str(k_ok), coins])
	# the second quests of the neighbours
	for q in ["match", "general", "patrol", "flag", "drill2", "stream"]:
		await _at_side_quest(lg, q)
	_lg(lg, "side07 done=%d/18 taxi=%s boomerang=%d ring_lamp=%d" % [side.done_count(), str(taxi), count_item("boomerang"), count_item("ring_lamp")])
	# boss remix: Pakhan, Demo
	await _at_goto_map("yard")
	var cons: Array = world.get("consoles", [])
	open_list("remix", "pakhan")
	var list_ok: bool = state == LIST and hud.list_box.get_child_count() > 4
	var s0 := singles
	_start_remix("pakhan", 0)
	var pk = _find_mob("pakhan")
	var pk_hp: float = pk.hp_max if pk != null else 0.0
	if pk != null:
		pos = pk.pos + Vector3(2, 0, 2)
		damage_mob(pk, 999999999.0, false)
	await _frames(110)
	_lg(lg, "remix pakhan consoles=%s list=%s hp=%d quest=%d best=%d singles=%d->%d prince=%s" % [str(cons), str(list_ok), int(pk_hp), quest,
		int(remix.best.get("pakhan", -1)), s0, singles, str(not prince_npc.is_empty())])
	# Сингл Принц: the first meeting and the shop
	if not prince_npc.is_empty():
		pos = prince_npc.pos + Vector3(1.0, 0, 1.0)
		await _frames(2)
		interact()
		await _at_press(0)
		await _at_press(0)
	_lg(lg, "prince met=%s singles=%d stock=%d list=%s" % [str(prince.met), singles, prince.stock.size(), str(state == LIST and list_kind == "prince")])
	if shots_dir != "":
		await _snap(shots_dir, "07_prince_shop")
	singles += 60
	for id in prince.stock.duplicate():
		_prince_buy(id)
	_lg(lg, "prince bought singles=%d stock=%s passes=%d metro=%s" % [singles, str(prince.stock), int(remix.passes), str(now() < metro_until)])
	if state == LIST:
		close_list()
	# again the same day: no singles unless a pass
	remix.passes = 0
	s0 = singles
	_start_remix("pakhan", 1)
	pk = _find_mob("pakhan")
	if pk != null:
		damage_mob(pk, 999999999.0, false)
	await _frames(10)
	_lg(lg, "remix again singles=%d->%d best=%d" % [s0, singles, int(remix.best.get("pakhan", -1))])
	# the Prince leaves after his three minutes; then comes by himself
	prince.left = 0.2
	await _frames(20)
	var gone := prince_npc.is_empty()
	prince.next = 0.1
	await _frames(10)
	_lg(lg, "prince gone=%s random_visit=%s" % [str(gone), str(not prince_npc.is_empty())])
	_prince_leave("test")
	# remixes on the other maps: the NPC hides during the fight and comes back
	for b in ["shumodav", "koschei", "gorynych", "wheel"]:
		await _at_goto_map(GameData.REMIX[b].map)
		var npc_id: String = GameData.REMIX[b].get("npc", "")
		_start_remix(b, 0)
		var bm = _find_mob(b)
		var hidden := npc_id != "" and remix_hidden.has(npc_id)
		if bm != null:
			damage_mob(bm, 999999999.0, false)
		await _frames(120)
		var back := true
		if npc_id != "":
			back = false
			for n in npcs:
				if n.id == npc_id:
					back = true
		_lg(lg, "remix %s spawned=%s hidden=%s back=%s best=%d" % [b, str(bm != null), str(hidden), str(back), int(remix.best.get(b, -1))])
		_prince_leave("test")
	# the city map and the aerotaxi
	open_map()
	var map_ok: bool = state == LIST and list_kind == "map" and hud.city_map.visible
	hud.city_map.select("garages")
	var c0 := coins
	var from := map_id
	await fly_to("garages")
	_lg(lg, "city map=%s taxi=%s fly %s->%s coins=%d->%d" % [str(map_ok), str(taxi), from, map_id, c0, coins])
	# save round trip
	save_game()
	var keep := [quest6, singles, taxi, int(remix.best.get("wheel", -1)), prince.met]
	quest6 = 0
	singles = 0
	taxi = false
	remix = {"best": {}, "day": "", "looted": [], "passes": 0, "wins": 0}
	load_game()
	_lg(lg, "save07 roundtrip %s==%s ver=%d" % [str(keep), str([quest6, singles, taxi, int(remix.best.get("wheel", -1)), prince.met]), GameData.SAVE_VERSION])
	invuln = 0.0


## Screenshots of 0.7 (run with --only07 --shots DIR under xvfb).
func _shots07(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	quest6 = 3
	mount_owned = true
	side.st["treasure"] = {"s": 3, "n": 0, "t": 0.0, "done": true}
	while level < 17:
		gain_xp(xp_next() - xp)
	for id in ["lantern", "compass", "ladle", "mill_cap", "boots_pavlin"]:
		add_item(id)
	invuln = 9999.0
	await _at_goto_map("park")
	# the gate with the guard and the subscription sign
	pos = Vector3(-1.5, 0, -27.0)
	facing = 0.15
	yaw = facing + PI
	pitch = 0.22
	await _frames(40)
	await _snap(dir, "p01_gate")
	# overview from the alley: fountain, stage, the wheel
	pos = Vector3(-3.0, 0, -15.0)
	facing = 0.35
	yaw = facing + PI
	pitch = 0.3
	dist = 11.0
	await _frames(30)
	await _snap(dir, "p02_alley")
	dist = 7.6
	# mobs close up
	for kind in ["mower", "bag", "duck", "loader"]:
		var m = _find_mob(kind)
		if m == null:
			continue
		for o in mobs:
			o.st = "idle"
		m.stun = 99.0
		pos = m.pos + Vector3(2.6, 0, -3.2)
		pos = World.resolve(pos, 0.45, world.rects, world.circles, world.bounds)
		facing = atan2(m.pos.x - pos.x, m.pos.z - pos.z)
		yaw = facing + PI + 0.4
		pitch = 0.28
		target = m
		await _frames(24)
		await _snap(dir, "p03_" + kind)
		m.stun = 0.0
	target = null
	# a dawn stone
	pos = Park.STONES[1][0] + Vector3(-3.0, 0, -3.5)
	facing = atan2(3.0, 3.5)
	yaw = facing + PI
	await _frames(20)
	await _snap(dir, "p04_stone")
	# the wheel boss
	quest6 = 5
	_spawn_wheel_boss()
	var wb = _find_mob("wheel")
	pos = Vector3(19.5, 0, 3.0)
	facing = 0.18
	yaw = facing + PI
	pitch = 0.1
	dist = 9.5
	target = wb
	for k in range(40):
		await get_tree().process_frame
		hp = hp_max
	_wheel_install(wb)
	await _frames(12)
	await _snap(dir, "p05_wheel_boss")
	damage_mob(wb, 999999999.0, false)
	await _frames(60)
	dist = 7.6
	await _at_goto_map("park")
	pos = Vector3(-2.0, 0, 1.0)
	facing = 0.45
	yaw = facing + PI
	pitch = 0.22
	dist = 10.0
	await _frames(40)
	await _snap(dir, "p06_dawn")
	dist = 7.6
	# remix console + remix fight in the yard
	await _at_goto_map("yard")
	pos = Vector3(-6.0, 0, -22.0)
	facing = PI + 0.4
	yaw = facing + PI
	pitch = 0.3
	await _frames(20)
	open_list("remix", "pakhan")
	await _frames(2)
	await _snap(dir, "p07_remix_list")
	close_list()
	_start_remix("pakhan", 2)
	var pk = _find_mob("pakhan")
	target = pk
	pos = pk.pos + Vector3(-3.0, 0, 6.0)
	facing = atan2(3.0, -6.0)
	yaw = facing + PI
	for k in range(50):
		await get_tree().process_frame
		hp = hp_max
	await _snap(dir, "p08_remix_fight")
	damage_mob(pk, 999999999.0, false)
	await _frames(100)
	if not prince_npc.is_empty():
		pos = prince_npc.pos + Vector3(2.2, 0, 2.6)
		facing = atan2(prince_npc.pos.x - pos.x, prince_npc.pos.z - pos.z)
		yaw = facing + PI + 0.35
		pitch = 0.3
		await _frames(20)
		await _snap(dir, "p09_prince")
		pos = prince_npc.pos + Vector3(1.0, 0, 1.2)
		await _frames(2)
		interact()
		await _frames(2)
		await _snap(dir, "p10_prince_dialog")
		await _at_press(0)
		await _at_press(0)
		await _frames(2)
		await _snap(dir, "p11_prince_shop")
		close_list()
	# the city map
	taxi = true
	open_map()
	hud.city_map.select("park")
	await _frames(3)
	await _snap(dir, "p12_city_map")
	close_list()
	# a new quest offer and the journal
	side.st["lawn"] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	await _at_talk("pavlin")
	await _frames(2)
	await _snap(dir, "p13_offer_match")
	if state == DIALOG:
		_close_dialog()
	open_journal()
	await _frames(2)
	await _snap(dir, "p14_journal")
	close_list()


## 0.8 «Мыльная опера»: music clock, the story, both new places with their quests and bosses, Бог Здорово, medics, taxi price, save v8.
func _autotest_08(lg: Array, shots_dir: String) -> void:
	invuln = 9999.0
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	quest6 = maxi(quest6, 7)
	mount_owned = true
	for q in SideQ.ORDER.slice(0, 18):
		if not side.is_done(q):
			side.st[q] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	while level < 16:
		gain_xp(xp_next() - xp)
	# music: six tracks of whole beats; a finished track moves the beat clock by its length and the next one starts
	var lens := []
	var whole := true
	for t in tracks:
		lens.append(snappedf(float(t.len), 0.01))
		var nb: float = float(t.len) / beat_len
		if absf(nb - round(nb)) > 0.02:
			whole = false
	await _at_goto_map("cheburek")
	music_on = true
	_start_track(0, false)
	var b0 := _mclock_base
	var ti0 := track_i
	_on_track_finished()
	_lg(lg, "music tracks=%d lens=%s whole_beats=%s clock %.2f->%.2f track %d->%d cheb_theme=%s" % [tracks.size(), str(lens), str(whole), b0, _mclock_base, ti0, track_i,
		tracks[track_i].id])
	# the rhythm game ends by the wall clock even if the music clock stands still (the concert bug of 0.7)
	start_rhythm({"kind": "tickle", "title": "TEST", "notes": [0, 1, 2], "lines": ["x"]})
	concert.end = 1.0e9
	var rf := 0
	while state == CONCERT and rf < 600:
		rf += 1
		await get_tree().process_frame
	_lg(lg, "rhythm wall-clock end play=%s frames=%d" % [str(state == PLAY), rf])
	# the concert in the GK still counts and ends
	await _at_goto_map("garages")
	pos = CONCERT_FRONT + Vector3(0.6, 0, 0.4)
	await _frames(2)
	interact()
	var c_on: bool = state == CONCERT
	var neigh := 0
	for n in concert_nodes:
		if n.get("neighbour", false):
			neigh += 1
	await _play_concert_bot(1.0)
	await _frames(5)
	_lg(lg, "concert started=%s neighbours_in_crowd=%d ended=%s daily=%s" % [str(c_on), neigh, str(state == PLAY), str(daily.get("concert", false))])
	# «Мыльная опера» starts at Мыслитель Зари
	var mk_z := npc_marker("zari")
	await _at_talk("zari")
	var z_ok: bool = state == DIALOG and hud.dialog_name.text == "Мыслитель Зари"
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "q7 zari marker=%s dialog=%s quest7=%d cheb_open=%s" % [mk_z, str(z_ok), quest7, str(map_open("cheburek"))])
	await _at_goto_map("yard")
	var yp := []
	for pt in world.portals:
		yp.append(pt.to)
	await _at_portal(Vector3(-18.2, 0, 9.0), "cheburek")
	var guests := 0
	for n in npcs:
		if n.has("guest"):
			guests += 1
	_lg(lg, "cheburek yard_portals=%s quest7=%d mobs=%d npcs=%d guests=%d bench=%s consoles=%s" % [str(yp), quest7, mobs.size(), npcs.size(), guests,
		str(not u08.bench_node.is_empty()), str(world.get("consoles", []))])
	# every new mob runs its AI for a while
	for mk in ["cheburek"]:
		for m in mobs:
			m.st = "chase"
		pos = Vector3(0, 0, 8.0)
		var kills0 := 0
		await _bot_fight(450, func(): return false)
		for m in mobs:
			if not m.alive:
				kills0 += 1
		_lg(lg, "ai %s alive=%d dead=%d coins=%d slow=%.1f" % [mk, mobs.size() - kills0, kills0, coins, slow_t])
	# the Чебуречная chain
	for q in ["who_left", "toilet", "duel", "inside", "dough_q", "ambulance"]:
		await _at_side_quest(lg, q)
	_lg(lg, "cheb chain quest7=%d fusion=%s medics=%s kits=%d warehouse_key=%d dough_mat=%d singles=%d laundry_open=%s" % [quest7, str(fusion), str(medics), kits,
		count_item("warehouse_key"), count_item("dough_mat"), singles, str(map_open("laundry"))])
	if state == DIALOG:
		_close_dialog()
	# fusion: shawarma speeds up
	food += 1
	cd.food = 0.0
	hp = hp_max * 0.5
	_eat()
	_lg(lg, "fusion eat fusion_t=%.1f speed_mult=%.2f" % [fusion_t, u08.speed_mult()])
	# the yard has the ambulance and the medics now
	await _at_goto_map("yard")
	var medic_ids := []
	for n in npcs:
		if n.id in ["chel", "osob"]:
			medic_ids.append(n.id)
	_lg(lg, "yard medics=%s" % str(medic_ids))
	# the Прачечная
	await _at_portal(Vector3(18.2, 0, 2.0), "laundry")
	_lg(lg, "laundry quest7=%d mobs=%d npcs=%d" % [quest7, mobs.size(), npcs.size()])
	for m in mobs:
		m.st = "chase"
	pos = Vector3(-8.0, 0, -5.5)
	await _bot_fight(600, func(): return false)
	var dead2 := 0
	for m in mobs:
		if not m.alive:
			dead2 += 1
	_lg(lg, "ai laundry dead=%d" % dead2)
	for q in ["ticket", "stunt", "clean_shot", "star", "forget"]:
		await _at_side_quest(lg, q)
	_lg(lg, "laundry chain quest7=%d premiere=%d drum_mat=%d clapper=%d detective=%d" % [quest7, u08.premiere.size(), count_item("drum_mat"), count_item("clapper"),
		count_item("detective_glasses")])
	# Бог Здорово appears
	var gw := 0
	while not (state == DIALOG and hud.dialog_name.text == "Бог Здорово") and gw < 400:
		gw += 1
		if state == DIALOG:
			_close_dialog()
		await get_tree().process_frame
	var god_ok: bool = state == DIALOG
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "god event dialog=%s frames=%d quest7=%d" % [str(god_ok), gw, quest7])
	# a bench in the yard: rest, blessing, gifts
	await _at_goto_map("yard")
	hp = hp_max * 0.3
	pos = u08.bench_front()
	await _frames(2)
	var lab := interact_label()
	interact()
	var b_ok: bool = state == LIST and list_kind == "bench"
	_lg(lg, "bench label=%s list=%s rows=%d hp_full=%s quest7=%d" % [lab, str(b_ok), hud.list_box.get_child_count(), str(hp >= hp_max - 1.0), quest7])
	u08._bless()
	var bk: String = blessing.kind
	grace += 120
	var g0 := grace
	open_list("bench")
	u08._gift("hp")
	u08._gift("luck")
	u08._gift("beat")
	if state == LIST:
		close_list()
	_lg(lg, "blessing=%s grace %d->%d gifts=%s luck=%d beat_win=%.3f hp_max=%d" % [bk, g0, grace, str(gifts), stat("luck"), beat_win_now(), int(hp_max)])
	# greetings: «Скажи «здорово»»
	daily["greet"] = []
	var gr0 := grace
	for id in ["zina", "misha", "lyuba", "pavlin", "lis", "petrovich", "pilot", "kent", "jack", "klyukva", "maloy"]:
		u08.greet(id)
	u08.greet("zina")
	_lg(lg, "greet count=%d grace %d->%d status=%s" % [daily.greet.size(), gr0, grace, u08.status_line()])
	# the bench of the other places
	var benches := []
	for m in ["garages", "stroyka", "embankment", "park", "cheburek", "laundry"]:
		await _at_goto_map(m)
		benches.append("%s:%s" % [m, str(not u08.bench_node.is_empty() and u08.bench_node.node.visible)])
	_lg(lg, "benches %s" % " ".join(benches))
	# guests of the park after the dawn
	await _at_goto_map("park")
	var pg := []
	for n in npcs:
		if n.has("guest"):
			pg.append(n.id)
	_lg(lg, "park guests=%s" % str(pg))
	# medics: kits auto-heal, the second wind, respawn at the ambulance
	await _at_goto_map("yard")
	invuln = 0.0
	kits = 2
	kit_cd = 0.0
	hp = hp_max * 0.2
	for k in range(3):
		await get_tree().process_frame
	_lg(lg, "kits left=%d heal_left=%d cd=%.1f" % [kits, int(heal_left), kit_cd])
	wind_day = ""
	heal_left = 0.0
	hurt_player(hp_max * 5.0, pos)
	var wind_ok: bool = state == PLAY and hp > 0.0
	invuln = 0.0
	hurt_player(hp_max * 5.0, pos)
	var dead_ok: bool = state == DEAD
	var dtxt: String = hud.dead_text.text
	var dw := 0
	while state == DEAD and dw < 300:
		dw += 1
		await get_tree().process_frame
	_lg(lg, "second_wind=%s died=%s text_medics=%s respawn=(%.1f,%.1f) hp=%d%%" % [str(wind_ok), str(dead_ok), str(dtxt.contains("Отлично-03")), pos.x, pos.z,
		int(hp * 100.0 / hp_max)])
	invuln = 9999.0
	# the box office at Мыслитель Зари
	var mk7 := npc_marker("zari")
	await _at_talk("zari")
	await _at_press(0)
	var box_ok: bool = state == DIALOG and hud.dialog_name.text.begins_with("Касса")
	await _at_press(0)
	var k_ok: bool = state == DIALOG and hud.dialog_name.text.begins_with("Кощей")
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "q7 final marker=%s box=%s koschei=%s quest7=%d lines=%s" % [mk7, str(box_ok), str(k_ok), quest7, str(main_quest_lines())])
	# remixes of the new bosses
	for b in ["dough", "drum"]:
		await _at_goto_map(GameData.REMIX[b].map)
		var open_r := remix_open(b)
		_start_remix(b, 0)
		var bm = _find_mob(b)
		if bm != null:
			damage_mob(bm, 999999999.0, false)
		await _frames(120)
		_lg(lg, "remix %s open=%s spawned=%s best=%d" % [b, str(open_r), str(bm != null), int(remix.best.get(b, -1))])
		_prince_leave("test")
	# the drum: «ОТЖИМ» and 4 hits on the beat
	await _at_goto_map("laundry")
	var dm := _spawn_mob("drum", Laundry.DRUM_HOME, 20)
	u08._drum_spin(dm)
	pos = Laundry.DRUM_HOME + Vector3(0, 0, 6.0)
	var hp0: float = dm.hp
	damage_mob(dm, 1000.0, false)
	var cut: float = hp0 - dm.hp
	var sh_on: bool = dm.shield
	for k in range(4):
		u08.beat(true)
	_lg(lg, "drum shield=%s dmg_in_spin=%d broken=%s stun=%.1f" % [str(sh_on), int(cut), str(not dm.shield), dm.stun])
	dm.alive = false
	dm.node.visible = false
	# the dough splits off-beat
	await _at_goto_map("cheburek")
	var dg := _spawn_mob("dough", Cheb.DOUGH_HOME, 18)
	var p0 := 0
	for m in mobs:
		if m.alive and m.kind == "pelmeshek":
			p0 += 1
	for k in range(12):
		damage_mob(dg, 100.0, false)
	var p1 := 0
	for m in mobs:
		if m.alive and m.kind == "pelmeshek":
			p1 += 1
	_lg(lg, "dough split pelmeshki %d->%d" % [p0, p1])
	dg.alive = false
	dg.node.visible = false
	# the aerotaxi price: from 170, more for longer flights
	_lg(lg, "taxi yard->garages=%d yard->park=%d cheburek->laundry=%d garages->park=%d" % [GameData.taxi_price("yard", "garages"), GameData.taxi_price("yard", "park"),
		GameData.taxi_price("cheburek", "laundry"), GameData.taxi_price("garages", "park")])
	# save v8 round trip
	save_game()
	var keep := [quest7, grace, str(gifts), blessing.kind, medics, fusion, kits, wind_day != ""]
	quest7 = 0
	grace = 0
	gifts = {"hp": 0, "luck": 0, "beat": 0, "qxp": 0}
	medics = false
	fusion = false
	kits = 0
	load_game()
	_lg(lg, "save08 roundtrip %s==%s ver=%d" % [str(keep), str([quest7, grace, str(gifts), blessing.kind, medics, fusion, kits, wind_day != ""]), GameData.SAVE_VERSION])
	_lg(lg, "side08 done=%d/%d" % [side.done_count(), SideQ.ORDER.size()])
	invuln = 0.0


## 0.9 «Своё дело»: the dump, the inventors' chain with the King of Junk, the neighbours' quests, the idea shop, building levels 4–5,
## crafting, remix materials, the workshop in box №13 with the party, the cart skin, save v9.
func _autotest_09(lg: Array, shots_dir: String) -> void:
	invuln = 9999.0
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	quest6 = maxi(quest6, 7)
	quest7 = maxi(quest7, 7)
	mount_owned = true
	for q in SideQ.ORDER.slice(0, 29):
		if not side.is_done(q):
			side.st[q] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	while level < 18:
		gain_xp(xp_next() - xp)
	var wind := -1
	for i in range(tracks.size()):
		if tracks[i].id == "music_wind":
			wind = i
	_lg(lg, "music09 tracks=%d wind=%d len=%.1f dump_theme=%s" % [tracks.size(), wind, float(tracks[wind].len) if wind >= 0 else 0.0, GameData.MAP_TRACK.get("dump", "")])
	# «Своё дело» starts at Мыслитель Зари
	var mk := npc_marker("zari")
	await _at_talk("zari")
	var z_ok: bool = state == DIALOG and hud.dialog_name.text == "Мыслитель Зари"
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "q8 zari marker=%s dialog=%s quest8=%d dump_open=%s" % [mk, str(z_ok), quest8, str(map_open("dump"))])
	await _at_goto_map("stroyka")
	var sp := []
	for pt in world.portals:
		sp.append(pt.to)
	await _at_portal(Vector3(22.0, 0, 16.4), "dump")
	var guests := []
	for n in npcs:
		if n.has("guest"):
			guests.append(n.id)
	_lg(lg, "dump stroyka_portals=%s quest8=%d mobs=%d npcs=%d guests=%s bench=%s" % [str(sp), quest8, mobs.size(), npcs.size(), str(guests), str(not u08.bench_node.is_empty())])
	# every new mob runs its AI
	for m in mobs:
		m.st = "chase"
	pos = Vector3(4.0, 0, 6.0)
	coins += 300
	var c0 := coins
	await _bot_fight(600, func(): return false)
	var dead := 0
	for m in mobs:
		if not m.alive:
			dead += 1
	_lg(lg, "ai dump dead=%d coins %d->%d slow=%.1f" % [dead, c0, coins, slow_t])
	# the inventors' chain
	for q in ["vasya_who", "idea_q", "fridge", "utilization"]:
		await _at_side_quest(lg, q)
	_lg(lg, "dump chain quest8=%d shop=%s ideas=%s atom=%d cart=%s singles=%d" % [quest8, str(u09.shop_open), str(u09.ideas), count_item("atom_mat"), str(u09.cart_skin), singles])
	# the neighbours at the dump
	for q in ["propeller", "barrel", "console"]:
		await _at_side_quest(lg, q)
	_lg(lg, "side09 propeller_cap=%d hoop=%d joystick=%d done=%d/%d" % [count_item("propeller_cap"), count_item("hoop_neck"), count_item("joystick"), side.done_count(), SideQ.ORDER.size()])
	# the idea shop at the dump
	await _at_goto_map("dump")
	pos = Dump.IDEA_TABLE + Vector3(0.6, 0, 1.6)
	await _frames(2)
	var lab := interact_label()
	interact()
	var shop_ok: bool = state == LIST and list_kind == "ideas"
	var rows: int = hud.list_box.get_child_count()
	coins += 20000
	u09._buy_idea("gym4")
	u09._buy_idea("solar5")
	if state == LIST:
		close_list()
	_lg(lg, "idea shop label=%s list=%s rows=%d ideas=%s" % [lab, str(shop_ok), rows, str(u09.ideas)])
	# Петрович gives box №13
	var pm := npc_marker("petrovich")
	await _at_talk("petrovich")
	await _at_press(0)
	await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "petrovich marker=%s quest8=%d" % [pm, quest8])
	# build the workshop
	res.planks += 40
	res.brick += 40
	res.wires += 40
	res.cement += 40
	if count_item("atom_mat") < 1:
		add_item("atom_mat")
	await _at_goto_map("garages")
	pos = GameData.BOX13 + Vector3(0.4, 0, -1.6)
	await _frames(2)
	var wl := interact_label()
	interact()
	var ws_ok: bool = state == LIST and list_kind == "workshop13"
	u09._build_workshop()
	await _frames(3)
	var dancers := 0
	for n in u09.party:
		if not n.has("bulb"):
			dancers += 1
	var gk_guests := []
	for n in npcs:
		if n.has("guest"):
			gk_guests.append(n.id)
	_lg(lg, "workshop label=%s list=%s quest8=%d dancers=%d guests=%s" % [wl, str(ws_ok), quest8, dancers, str(gk_guests)])
	if shots_dir != "":
		await _snap(shots_dir, "09_party")
	# Кеша's finale
	pos = Vector3(-19.0, 0, 4.4) + Vector3(0.8, 0, -1.2)
	await _frames(2)
	interact()
	var fin_ok: bool = state == DIALOG and hud.dialog_name.text == "Кеша Вторсырьё"
	for k in range(6):
		await _at_press(0)
	if state == DIALOG:
		_close_dialog()
	_lg(lg, "q8 finale dialog=%s quest8=%d lines=%s" % [str(fin_ok), quest8, str(main_quest_lines())])
	# building levels 4–5: ideas + special materials
	for id in GameData.BUILD_ORDER:
		buildings[id] = 3
	coins += 40000
	res.planks += 300
	res.brick += 300
	res.wires += 300
	res.cement += 300
	singles += 5
	for id in ["grill4", "grill5", "garden4", "garden5", "gym4", "gym5", "stage4", "stage5", "studio4", "studio5", "solar4", "solar5"]:
		if not (id in u09.ideas):
			u09.ideas.append(id)
	for k in GameData.MAT_ORDER:
		if k == "light_mat":
			continue
		for j in range(8):
			inventory.append(u09._item(k))
	var hp3 := hp_max
	var heal3: float = u08.food_heal()
	for id in GameData.BUILD_ORDER:
		_build(id)
		_build(id)
	close_list()
	_recalc_stats()
	_lg(lg, "buildings %s hp_max %d->%d food_heal %.2f->%.2f concert_x=%d grill_cap=%d solar=%d errand=%ds" % [str(buildings), int(hp3), int(hp_max), heal3, u08.food_heal(),
		u09.concert_mult(), u09.cap("grill"), buildings.solar, int(_errand_time("dump"))])
	open_list("slot", "solar")
	var slot_rows: int = hud.list_box.get_child_count()
	close_list()
	_lg(lg, "slot solar rows=%d (lvl 5 waits for 0.10)" % slot_rows)
	# crafting
	for id in ["crust", "crust", "crust", "scale_bit", "scale_bit", "wrapper", "wrapper"]:
		inventory.append(u09._item(id))
	var ph := count_item("pot_helmet")
	u09._craft("pot_helmet")
	var crown0 := count_item("inventor_crown")
	u09._craft("inventor_crown")
	_lg(lg, "craft pot_helmet %d->%d crown %d->%d" % [ph, count_item("pot_helmet"), crown0, count_item("inventor_crown")])
	# remixes give special materials (King of Junk and Pakhan)
	for b in ["king", "pakhan"]:
		await _at_goto_map(GameData.REMIX[b].map)
		var mat: String = GameData.REMIX_MAT[b]
		var n0 := count_item(mat)
		_start_remix(b, 2)
		var bm = _find_mob(b)
		if bm != null:
			damage_mob(bm, 999999999.0, false)
		await _frames(120)
		_lg(lg, "remix %s open=%s spawned=%s %s %d->%d" % [b, str(remix_open(b)), str(bm != null), mat, n0, count_item(mat)])
		_prince_leave("test")
	# the King: the charge lane, the press, «Кеша взламывает» with combo ×8
	await _at_goto_map("dump")
	var km := _spawn_mob("king", Dump.KING_HOME, 22)
	km.st = "chase"
	pos = Dump.KING_HOME + Vector3(0, 0, 6.0)
	km.special = 0.0
	await _frames(3)
	var lane_ok: bool = u09.lane != null
	var fr := 0
	while km.charge_t <= 0.0 and fr < 120:
		fr += 1
		await get_tree().process_frame
	var drove: bool = km.charge_t > 0.0
	await _frames(60)
	u09._press(km)
	var hp0: float = km.hp
	damage_mob(km, 1000.0, false)
	var cut: float = hp0 - km.hp
	combo = 8
	u09.beat(true)
	_lg(lg, "king lane=%s drove=%s press_dmg=%d broken=%s stun=%.1f" % [str(lane_ok), str(drove), int(cut), str(not km.shield), km.stun])
	km.alive = false
	km.node.visible = false
	u09._clear_lane()
	# the rat steals coins and gives them back twice when caught
	invuln = 0.0
	coins = 500
	var rm := _spawn_mob("rat", pos + Vector3(1.0, 0, 0), 18)
	rm.st = "chase"
	rm.atk_cd = 0.0
	var rf := 0
	while int(rm.loot_coins) == 0 and rf < 200:
		rf += 1
		hp = hp_max
		await get_tree().process_frame
	var stolen: int = rm.loot_coins
	var c1 := coins
	damage_mob(rm, 999999.0, false)
	_lg(lg, "rat stole=%d coins %d->%d" % [stolen, c1, coins])
	invuln = 9999.0
	# the cart skin
	u09.mount_skin = "cart"
	mounted = true
	if not mount_vis.is_empty() and is_instance_valid(mount_vis.root):
		mount_vis.root.queue_free()
	mount_vis = {}
	_create_mount_vis()
	await _frames(10)
	_lg(lg, "cart skin=%s mounted=%s" % [str(mount_vis.has("cart")), str(mounted)])
	_dismount("")
	# the aerotaxi to the dump
	_lg(lg, "taxi garages->dump=%d yard->dump=%d" % [GameData.taxi_price("garages", "dump"), GameData.taxi_price("yard", "dump")])
	# save v9 round trip
	save_game()
	var keep := [quest8, u09.ideas.size(), u09.shop_open, u09.cart_skin, u09.mount_skin, buildings.grill]
	quest8 = 0
	u09.ideas = []
	u09.shop_open = false
	u09.cart_skin = false
	buildings.grill = 0
	load_game()
	_lg(lg, "save09 roundtrip %s==%s ver=%d" % [str(keep), str([quest8, u09.ideas.size(), u09.shop_open, u09.cart_skin, u09.mount_skin, buildings.grill]), GameData.SAVE_VERSION])
	_lg(lg, "side09 total done=%d/%d" % [side.done_count(), SideQ.ORDER.size()])
	invuln = 0.0


## Screenshots of 0.9 (run with --only09 --shots DIR under xvfb).
func _shots09(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	quest6 = 7
	quest7 = 7
	quest8 = 2
	mount_owned = true
	for q in SideQ.ORDER.slice(0, 29):
		side.st[q] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	while level < 21:
		gain_xp(xp_next() - xp)
	for id in ["junk_crown", "press_gauntlets", "tarp_cape", "spring_sneakers"]:
		add_item(id)
	for it in inventory:
		if it.id in ["junk_crown", "press_gauntlets", "tarp_cape", "spring_sneakers"]:
			equip(it)
	invuln = 9999.0
	await _at_goto_map("stroyka")
	_look(Vector3(20.0, 0, 11.0), Vector3(22.0, 0, 18.0), 0.2, 7.0)
	await _frames(30)
	await _snap(dir, "r01_stroyka_gate")
	await _at_goto_map("dump")
	_look(Vector3(0, 0, 17.0), Vector3(0, 0, 0), 0.34, 12.0)
	await _frames(40)
	await _snap(dir, "r02_dump_entrance")
	_look(Vector3(-6.0, 0, 7.0), Vector3(-13.0, 0, 1.0), 0.24, 7.5)
	await _frames(30)
	await _snap(dir, "r03_camp")
	var kp: Vector3 = SideQ.NPCS.kesha.pos
	_look(kp + Vector3(1.6, 0, 3.0), kp + Vector3(-2.4, 0, -1.0), 0.16, 5.5)
	await _frames(20)
	await _snap(dir, "r04_inventors")
	_look(Vector3(-14.0, 0, -3.0), Vector3(-24.0, 0, -12.0), 0.28, 8.0)
	await _frames(20)
	await _snap(dir, "r05_fridge_graveyard")
	for kind in ["rat", "fridge", "mattress"]:
		await _shot_mob(dir, kind)
	var km := _spawn_mob("king", Dump.KING_HOME, 22)
	_look(Dump.KING_HOME + Vector3(-4.0, 0, 9.5), Dump.KING_HOME, 0.18, 9.5)
	target = km
	km.st = "chase"
	for k in range(50):
		await get_tree().process_frame
		hp = hp_max
	await _snap(dir, "r06_king")
	km.special = 0.0
	await _frames(12)
	await _snap(dir, "r07_king_lane")
	await _frames(70)
	u09._press(km)
	await _frames(30)
	await _snap(dir, "r08_king_press")
	km.alive = false
	km.node.visible = false
	u09._clear_lane()
	target = null
	u09.shop_open = true
	pos = Dump.IDEA_TABLE + Vector3(0.6, 0, 1.6)
	await _frames(2)
	interact()
	await _frames(3)
	await _snap(dir, "r09_idea_shop")
	close_list()
	# the workshop with the party and upgraded buildings
	quest8 = 5
	for id in GameData.BUILD_ORDER:
		buildings[id] = 4 if id in ["gym", "solar"] else 5
	await _at_goto_map("garages")
	_look(GameData.BOX13 + Vector3(2.0, 0, -4.0), GameData.BOX13 + Vector3(0, 0, 1.0), 0.62, 7.0)
	await _frames(40)
	await _snap(dir, "r10_workshop_party")
	_look(Vector3(2.0, 0, 0.0), Vector3(-4.8, 0, -3.0), 0.3, 9.0)
	await _frames(20)
	await _snap(dir, "r11_buildings_45")
	_look(Vector3(-2.0, 0, 0.5), Vector3(3.4, 0, -5.0), 0.3, 8.5)
	await _frames(20)
	await _snap(dir, "r12_buildings_45b")
	open_list("slot", "grill")
	await _frames(2)
	await _snap(dir, "r13_slot_grill")
	close_list()
	# the cart skin
	u09.cart_skin = true
	u09.mount_skin = "cart"
	toggle_mount()
	_look(Vector3(8.0, 0, 0.0), Vector3(12.0, 0, 0.0), 0.2, 6.5)
	facing = -PI / 2 + 0.6
	await _frames(30)
	await _snap(dir, "r14_cart")
	_dismount("")
	taxi = true
	open_map()
	hud.city_map.select("dump")
	await _frames(3)
	await _snap(dir, "r15_city_map")
	close_list()

func _look(p: Vector3, at: Vector3, pt := 0.26, d := 7.6) -> void:
	pos = World.resolve(p, 0.45, world.rects, world.circles, world.bounds)
	facing = atan2(at.x - pos.x, at.z - pos.z)
	yaw = facing + PI
	pitch = pt
	dist = d


## Screenshots of 0.8 (run with --only08 --shots DIR under xvfb).
func _shots08(dir: String) -> void:
	quest = 5
	quest2 = 6
	quest3 = 6
	quest4 = 8
	quest5 = 7
	quest6 = 7
	quest7 = 2
	mount_owned = true
	for q in SideQ.ORDER.slice(0, 18):
		side.st[q] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	while level < 19:
		gain_xp(xp_next() - xp)
	for id in ["rolling_pin", "chef_hat", "dough_apron", "foam_sneakers"]:
		add_item(id)
	for it in inventory:
		if it.id in ["rolling_pin", "chef_hat", "dough_apron", "foam_sneakers"]:
			equip(it)
	invuln = 9999.0
	# the Павлин Футболист humanoid and the server corridor (fixes)
	await _at_goto_map("yard")
	var pv: Vector3 = SideQ.NPCS.pavlin.pos
	_look(pv + Vector3(-2.2, 0, -2.6), pv, 0.18, 5.2)
	await _frames(30)
	await _snap(dir, "q01_pavlin")
	await _at_goto_map("server")
	_look(Vector3(9.0, 0, 1.6), Vector3(20.0, 0, 2.0), 0.16, 6.0)
	await _frames(30)
	await _snap(dir, "q02_server_corridor")
	_look(Vector3(7.5, 0, -1.4), Vector3(13.0, 0, 2.9), 0.1, 3.2)
	await _frames(20)
	await _snap(dir, "q03_server_posters")
	# the Чебуречная
	await _at_goto_map("cheburek")
	_look(Vector3(0, 0, 15.0), Vector3(0, 0, 0), 0.32, 12.0)
	await _frames(40)
	await _snap(dir, "q04_cheburek_street")
	_look(Vector3(-1.0, 0, 6.0), Vector3(0, 0, -5.0), 0.24, 7.0)
	await _frames(20)
	await _snap(dir, "q05_cheburek_hall")
	_look(Vector3(18.0, 0, -3.0), Vector3(22.0, 0, -15.0), 0.3, 8.0)
	await _frames(20)
	await _snap(dir, "q06_toilet_maze")
	for kind in ["roach", "fly", "cheb", "plunger_mob"]:
		await _shot_mob(dir, kind)
	var dg := _spawn_mob("dough", Cheb.DOUGH_HOME, 18)
	_look(Cheb.DOUGH_HOME + Vector3(3.0, 0, 9.0), Cheb.DOUGH_HOME, 0.18, 9.0)
	target = dg
	dg.st = "chase"
	for k in range(60):
		await get_tree().process_frame
		hp = hp_max
	await _snap(dir, "q07_dough_boss")
	for k in range(10):
		damage_mob(dg, 50.0, false)
	await _frames(20)
	await _snap(dir, "q08_dough_split")
	dg.alive = false
	dg.node.visible = false
	for m in mobs:
		if m.temp:
			m.alive = false
			m.node.visible = false
	target = null
	await _shot_mob(dir, "pelmeshek")
	# the Прачечная with the premiere
	quest7 = 4
	side.st["ticket"] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	side.st["stunt"] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	side.st["star"] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	side.st["forget"] = {"s": 1, "n": 0, "t": 0.0, "done": false}
	await _at_goto_map("laundry")
	_look(Vector3(0, 0, 15.5), Vector3(0, 0, 4.0), 0.3, 11.0)
	await _frames(40)
	await _snap(dir, "q09_laundry_front")
	_look(Vector3(-14.0, 0, 2.0), Vector3(-14.0, 0, -12.0), 0.3, 8.0)
	await _frames(20)
	await _snap(dir, "q10_washer_hall")
	for kind in ["sock", "washer", "iron", "bubble"]:
		await _shot_mob(dir, kind)
	_look(Vector3(0, 0, -1.0), Vector3(0, 0, -15.0), 0.2, 9.5)
	for k in range(40):
		await get_tree().process_frame
		hp = hp_max
	var dr = _find_mob("drum")
	target = dr
	await _frames(20)
	await _snap(dir, "q11_premiere_drum")
	if dr != null:
		u08._drum_spin(dr)
		await _frames(30)
		await _snap(dir, "q12_drum_spin")
		dr.alive = false
		dr.node.visible = false
	target = null
	# Бог Здорово and a bench; the ambulance in the yard
	side.st["toilet"] = {"s": 0, "n": 0, "t": 0.0, "done": true}
	quest7 = 6
	await _at_goto_map("yard")
	var bp: Vector3 = u08.bench_node.pos
	_look(bp + Vector3(5.0, 0, 3.5), bp, 0.2, 7.0)
	await _frames(20)
	u08.show_god(pos, 30.0)
	pitch = 0.05
	await _frames(70)
	await _snap(dir, "q13_bench_god")
	pos = u08.bench_front()
	await _frames(2)
	interact()
	await _frames(3)
	await _snap(dir, "q14_bench_list")
	close_list()
	_look(Vector3(-8.0, 0, 7.5), Vector3(-13.0, 0, 6.5), 0.22, 7.0)
	await _frames(30)
	await _snap(dir, "q15_ambulance")
	_look(Vector3(-14.5, 0, 9.5), Vector3(-19.0, 0, 9.0), 0.25, 6.0)
	await _frames(20)
	await _snap(dir, "q16_portal_cheburek")
	_look(Vector3(14.0, 0, 3.5), Vector3(19.0, 0, 2.0), 0.25, 6.0)
	await _frames(20)
	await _snap(dir, "q17_portal_laundry")
	# the concert in the GK with the neighbours in the crowd
	await _at_goto_map("garages")
	pos = CONCERT_FRONT + Vector3(0.6, 0, 0.4)
	await _frames(2)
	interact()
	await _frames(150)
	await _snap(dir, "q18_concert_neighbours")
	_finish_concert(true)
	# the city map and the journal
	taxi = true
	quest7 = 4
	open_map()
	hud.city_map.select("laundry")
	await _frames(3)
	await _snap(dir, "q19_city_map")
	close_list()
	open_journal()
	await _frames(2)
	await _snap(dir, "q20_journal")
	close_list()


func _shot_mob(dir: String, kind: String) -> void:
	var m = _find_mob(kind)
	if m == null:
		return
	for o in mobs:
		o.st = "idle"
	m.stun = 99.0
	_look(m.pos + Vector3(2.6, 0, -3.2), m.pos, 0.28, 7.6)
	facing = atan2(m.pos.x - pos.x, m.pos.z - pos.z)
	yaw = facing + PI + 0.4
	target = m
	await _frames(24)
	await _snap(dir, "q_mob_" + kind)
	m.stun = 0.0
	target = null


func _lg(lg: Array, line: String) -> void:
	lg.append(line)
	print("AUTOTEST_STEP ", line)


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
