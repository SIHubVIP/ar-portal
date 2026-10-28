extends Node3D
## Личная база — отдельная инстанс-сцена вне карты Рубина (ТЗ, раздел 15):
## большое хранилище, верстак, стенд трофеев и безопасная точка восстановления.

const EXIT_POS := Vector3(0, 0, 6)

var player: Player
var camera: IsoCamera
var hud: Hud
var _interactables: Array = []


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.07)
	env.ambient_light_color = Color(0.6, 0.55, 0.5)
	env.ambient_light_energy = 0.6
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 4.5, 0)
	lamp.omni_range = 16.0
	lamp.light_energy = 2.0
	lamp.light_color = Color(1, 0.85, 0.65)
	lamp.shadow_enabled = true
	add_child(lamp)
	Kit.box(self, Vector3(0.4, 0.2, 0.4), Vector3(0, 4.6, 0), Color(1, 0.9, 0.6), 4.0)
	# гараж №13 изнутри
	Kit.solid_box(self, Vector3(16, 1, 16), Vector3(0, -0.5, 0), Color(0.35, 0.33, 0.32))
	Kit.solid_box(self, Vector3(16, 5, 0.5), Vector3(0, 2.5, -8), Color(0.45, 0.42, 0.4))
	Kit.solid_box(self, Vector3(0.5, 5, 16), Vector3(-8, 2.5, 0), Color(0.42, 0.4, 0.38))
	Kit.solid_box(self, Vector3(0.5, 5, 16), Vector3(8, 2.5, 0), Color(0.42, 0.4, 0.38), 0.0, true)
	Kit.solid_box(self, Vector3(16, 5, 0.5), Vector3(0, 2.5, 8.2), Color(0.42, 0.4, 0.38), 0.0, true)
	Kit.label(self, "ГАРАЖ №13 · ЛИЧНАЯ БАЗА", Vector3(0, 3.6, -7.7), 60, Color(1, 0.8, 0.3), false)
	# хранилище
	Kit.solid_box(self, Vector3(3, 1.4, 1.2), Vector3(-5, 0.7, -6), Color(0.5, 0.35, 0.2))
	Kit.label(self, "Сундук", Vector3(-5, 2.2, -6), 40, Color(1, 0.9, 0.6))
	_interactables.append({"pos": Vector3(-5, 0, -4.5), "label": "Сундук", "cb": func(): hud.open_storage()})
	# верстак
	Kit.solid_box(self, Vector3(3, 1.0, 1.2), Vector3(5, 0.5, -6), Color(0.35, 0.3, 0.28))
	Kit.label(self, "Верстак (скоро)", Vector3(5, 2.0, -6), 40, Color(0.8, 0.9, 1))
	_interactables.append({"pos": Vector3(5, 0, -4.5), "label": "Верстак", "cb": func():
		hud.show_toast("Крафт откроется вместе с рецептами квестов NPC.")})
	# стенд трофеев: пока пустые постаменты под 15 боссов
	for i in 5:
		Kit.cylinder(self, 0.4, 1.0, Vector3(-6.5, 0.5, -2 + i * 1.6), Color(0.3, 0.3, 0.35))
	Kit.label(self, "Трофеи: 0 / 15", Vector3(-6.5, 2.2, 1), 36, Color(0.9, 0.9, 0.9))
	# выход
	Kit.box(self, Vector3(3, 0.05, 2), EXIT_POS + Vector3(0, 0.03, 0), Color(0.3, 1, 0.5, 0.5), 1.0)
	Kit.label(self, "Выход в Рубин", EXIT_POS + Vector3(0, 2, 0), 44, Color(0.6, 1, 0.7))
	_interactables.append({"pos": EXIT_POS, "label": "Выйти", "cb": WorldRouter.leave_base})

	player = Player.new()
	player.position = Vector3(0, 0, 3)
	add_child(player)
	camera = IsoCamera.new()
	camera.target = player
	camera.distance = 13.0
	add_child(camera)
	camera.make_current()
	hud = Hud.new()
	add_child(hud)
	hud.set_player(player)
	hud.controls.attack.connect(player.basic_attack)
	hud.controls.dodge.connect(player.dodge)
	hud.controls.ability.connect(player.use_ability)
	hud.controls.interact.connect(_on_interact)
	hud.pause_action.connect(_on_pause_action)
	hud.controls.camera_rotate.connect(camera.rotate_by)
	hud.controls.camera_zoom.connect(camera.zoom_by)
	hud.controls.camera_tilt.connect(camera.tilt_by)
	hud.inventory.closed.connect(func(): SaveService.save_game())
	GameState.heal(GameState.max_hp)
	hud.show_toast("База: здесь безопасно, здоровье восстановлено")
	if OS.get_cmdline_user_args().has("--open=storage"):
		GameState.add_item("ITEM_P1_SCRAP", 2)
		GameState.add_item("ITEM_P2_BEER")
		GameState.storage["ITEM_P2_PIPE"] = 1
		hud.open_storage.call_deferred()
	if OS.get_cmdline_user_args().has("--autotest"):
		_autotest.call_deferred()


func _physics_process(_delta: float) -> void:
	var it := _nearest()
	hud.controls.interact_label = it.get("label", "")


func _nearest() -> Dictionary:
	for it in _interactables:
		if player.global_position.distance_to(it.pos) <= 2.5:
			return it
	return {}


func _on_interact() -> void:
	var it := _nearest()
	if not it.is_empty():
		it.cb.call()


func _stash() -> void:
	var moved := GameState.stash_backpack()
	SaveService.save_game()
	hud.show_toast("В хранилище перенесено: %d" % moved if moved > 0 else "Ранец пуст (квестовые вещи остаются при себе)")


func _on_pause_action(action: String) -> void:
	match action:
		"save":
			hud.show_toast("Сохранено" if SaveService.save_game() else "Не удалось сохранить")
		"base":
			hud.toggle_pause()
			hud.show_toast("Вы уже на базе")
		"zoom_in":
			camera.zoom_by(-3.0)
		"zoom_out":
			camera.zoom_by(3.0)
		"title":
			SaveService.save_game()
			get_tree().paused = false
			WorldRouter.go_to_title()


func _autotest() -> void:
	for i in 10:
		await get_tree().physics_frame
	_stash()
	print("AUTOTEST база: хранилище %s" % str(GameState.storage))
	SaveService.save_game()
	WorldRouter.leave_base()
