class_name Hud
extends CanvasLayer
## Интерфейс поверх мира: ресурсы, задание, диалоги, выбор, пауза с журналом.
## Наблюдает EventBus и не меняет экономику напрямую.

signal pause_action(action: String)

var controls: TouchControls
var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _level: Label
var _resources: Label
var _quest: Label
var _toast: Label
var dialog: DialogView
var inventory: InventoryPanel
var _pause: PanelContainer
var _journal: Label
var _death: PanelContainer


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	controls = TouchControls.new()
	root.add_child(controls)

	var top := VBoxContainer.new()
	top.position = Vector2(20, 16)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)
	var row := HBoxContainer.new()
	top.add_child(row)
	_level = _label(row, "Ур. 1", 22)
	_hp_bar = _bar(row, Color(0.85, 0.2, 0.2), Vector2(240, 22))
	_xp_bar = _bar(top, Color(0.95, 0.75, 0.2), Vector2(310, 8))
	_resources = _label(top, "", 20)
	_quest = _label(top, "", 19)
	_quest.custom_minimum_size.x = 430
	_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quest.add_theme_color_override("font_color", Color(1, 0.95, 0.8))

	var pause_btn := Button.new()
	pause_btn.text = "  ☰  "
	pause_btn.add_theme_font_size_override("font_size", 30)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(toggle_pause)
	root.add_child(pause_btn)
	_place(pause_btn, Vector2(1, 0), Vector2(-110, 14), Vector2(-20, 74))
	var bag_btn := Button.new()
	bag_btn.text = " Сумка "
	bag_btn.add_theme_font_size_override("font_size", 24)
	bag_btn.focus_mode = Control.FOCUS_NONE
	bag_btn.pressed.connect(func(): open_inventory("bags"))
	root.add_child(bag_btn)
	_place(bag_btn, Vector2(1, 0), Vector2(-250, 14), Vector2(-120, 74))

	_toast = _label(root, "", 24)
	_place(_toast, Vector2(0.5, 0), Vector2(-400, 90), Vector2(400, 160))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.modulate.a = 0.0

	_build_pause(root)
	inventory = InventoryPanel.new()
	root.add_child(inventory)
	_place(inventory, Vector2(0.5, 0.5), Vector2(-600, -340), Vector2(600, 340))
	inventory.set_toast(show_toast)
	inventory.closed.connect(func(): _set_controls(true))
	dialog = DialogView.new()
	root.add_child(dialog)
	dialog.closed.connect(func(): _set_controls(true))
	_build_death(root)

	EventBus.resources_changed.connect(func(_b, _r, _k): _refresh_resources())
	EventBus.xp_changed.connect(_on_xp)
	EventBus.player_hp_changed.connect(_on_hp)
	EventBus.quest_stage_changed.connect(func(_q, _s): refresh_quest())
	EventBus.quest_state_changed.connect(func(_q, _s): refresh_quest())
	EventBus.toast.connect(show_toast)
	EventBus.level_up.connect(_on_level_up)
	EventBus.item_added.connect(func(id, n): show_toast("+ %s%s" % [GameData.item_name(id), " ×%d" % n if n > 1 else ""]))
	_refresh_resources()
	_on_hp(GameState.hp, GameState.max_hp)
	_on_xp(GameState.xp, GameState.level, GameState.xp - GameState.total_xp_for(GameState.level),
			GameState.xp_to_next(GameState.level))
	refresh_quest()


func set_player(p: Player) -> void:
	controls.player = p
	inventory.player = p
	var names := PackedStringArray()
	for a in p.book.abilities:
		names.append(_wrap(a.name))
	controls.ability_names = names


## Делит название на две строки так, чтобы самая длинная была как можно короче.
static func _wrap(name: String) -> String:
	var words := name.split(" ")
	if words.size() <= 1:
		return name
	var best := name
	var best_len := name.length()
	for i in range(1, words.size()):
		var a := " ".join(words.slice(0, i))
		var b := " ".join(words.slice(i))
		if maxi(a.length(), b.length()) < best_len:
			best_len = maxi(a.length(), b.length())
			best = a + "\n" + b
	return best


func _place(c: Control, anchor: Vector2, top_left: Vector2, bottom_right: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = top_left.x
	c.offset_top = top_left.y
	c.offset_right = bottom_right.x
	c.offset_bottom = bottom_right.y


func _label(parent: Node, text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _bar(parent: Node, color: Color, min_size: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = min_size
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(4)
	b.add_theme_stylebox_override("fill", fill)
	b.add_theme_stylebox_override("background", bg)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


func _panel(parent: Node) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.09, 0.92)
	sb.border_color = Color(0.95, 0.75, 0.2)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	p.add_theme_stylebox_override("panel", sb)
	p.visible = false
	parent.add_child(p)
	return p


func _button(parent: Node, text: String, cb: Callable, fs := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size.y = 56
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


# ---------- ресурсы ----------

func _refresh_resources() -> void:
	_resources.text = "Бабки %d   Репутация %d   Кукуха %d" % [GameState.babki, GameState.reputation, GameState.kukukha]


func _on_hp(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp


func _on_xp(_xp: int, level: int, into: int, need: int) -> void:
	_level.text = "Ур. %d  " % level
	_xp_bar.max_value = need
	_xp_bar.value = into


func refresh_quest() -> void:
	var lines: PackedStringArray = []
	for q in QuestService.active_quests():
		var st := QuestService.current_stage(q.id)
		var state := QuestService.state_of(q.id)
		var line := "◆ %s\n   " % q.title
		if state == QuestService.TURN_IN_READY:
			line += "Сдать задание"
		elif st.is_empty():
			line += state
		else:
			line += st.text
			var r: Dictionary = QuestService.records[q.id]
			if int(st.target) > 1:
				line += " (%d/%d)" % [r.progress, st.target]
		lines.append(line)
	_quest.text = "\n".join(lines)


func show_toast(text: String) -> void:
	_toast.text = text
	var tw := _toast.create_tween()
	tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.6)
	tw.tween_property(_toast, "modulate:a", 0.0, 0.4)


# ---------- диалог и выбор ----------

func is_busy() -> bool:
	return dialog.visible or inventory.visible or _pause.visible or _death.visible


## lines: [{speaker, text}]; on_done вызывается и при пропуске (с теми же последствиями).
func play_dialog(lines: Array, on_done := Callable()) -> void:
	_set_controls(false)
	dialog.play_lines(lines, on_done)


## Разговор по графу data/dialogues.json. on_event получает сюжетные события (choose_A, bribe, ...).
func run_dialogue(id: String, on_event := Callable(), on_done := Callable()) -> void:
	_set_controls(false)
	dialog.run(id, on_event, on_done)


## options: [{key, key_label, text, hint, tone?}]. Выбор не совершается без нажатия игрока.
func ask_choice(title: String, options: Array, on_pick: Callable) -> void:
	_set_controls(false)
	var tones := ["green", "purple", "cyan", "orange"]
	var i := 0
	var opts: Array = []
	for o in options:
		opts.append({"text": "%s — %s" % [o.key_label, o.text], "tone": o.get("tone", tones[i % 4]),
				"cb": func(): on_pick.call(o.key)})
		i += 1
	dialog.ask("journal", title, opts)


func _finish_dialog() -> void:
	dialog.skip()


func open_inventory(tab := "hero") -> void:
	if is_busy():
		return
	_set_controls(false)
	inventory.open(tab)


func open_storage() -> void:
	if is_busy():
		return
	_set_controls(false)
	inventory.open_storage()


func _on_level_up(l: int) -> void:
	var text := "Новый уровень: %d" % l
	if controls.player:
		for i in controls.player.book.abilities.size():
			if AbilityBook.unlock_level(i) == l:
				var a: Dictionary = controls.player.book.abilities[i]
				text += "\nОткрыта способность «%s»! %s" % [a.name, AbilityBook.describe(a, l).text]
	show_toast(text)


# ---------- пауза и журнал ----------

func _build_pause(root: Control) -> void:
	_pause = _panel(root)
	_place(_pause, Vector2(0.5, 0.5), Vector2(-460, -300), Vector2(460, 300))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	_pause.add_child(h)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size.x = 280
	menu.add_theme_constant_override("separation", 10)
	h.add_child(menu)
	_label(menu, "Пауза", 30)
	_button(menu, "Продолжить", toggle_pause)
	_button(menu, "На базу", func(): pause_action.emit("base"))
	_button(menu, "Сохранить", func(): pause_action.emit("save"))
	_button(menu, "Приблизить", func(): pause_action.emit("zoom_in"))
	_button(menu, "Отдалить", func(): pause_action.emit("zoom_out"))
	_button(menu, "В главное меню", func(): pause_action.emit("title"))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 520)
	h.add_child(scroll)
	_journal = _label(scroll, "", 19)
	_journal.custom_minimum_size.x = 540
	_journal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func toggle_pause() -> void:
	if dialog.visible or inventory.visible:
		return
	_pause.visible = not _pause.visible
	_set_controls(not _pause.visible)
	if _pause.visible:
		_journal.text = _journal_text()


func _journal_text() -> String:
	var out: PackedStringArray = ["ЖУРНАЛ"]
	for q in GameData.quests:
		var s := QuestService.state_of(q.id)
		if s == QuestService.LOCKED:
			continue
		var mark: String = {"AVAILABLE": "○", "COMPLETED": "✓"}.get(s, "◆")
		out.append("%s %s «%s» — %s, %s (рек. ур. %d)" % [mark, q.id, q.title, q.district, q.location, q.min_level])
		if s == QuestService.COMPLETED and QuestService.records[q.id].choice != "":
			var c: Dictionary = q.choices[QuestService.records[q.id].choice]
			out.append("    Выбор: %s → %s" % [c.text, c.result])
			out.append("    %s" % q.twist)
		elif s == QuestService.AVAILABLE:
			out.append("    %s" % q.setup)
	out.append("")
	out.append("СУМКИ")
	out.append("Карманы: %s" % _bag(GameState.pockets))
	out.append("Ранец: %s" % _bag(GameState.backpack))
	out.append("Хранилище базы: %s" % _bag(GameState.storage))
	return "\n".join(out)


func _bag(d: Dictionary) -> String:
	if d.is_empty():
		return "пусто"
	var parts: PackedStringArray = []
	for id in d:
		parts.append("%s ×%d" % [GameData.item_name(id), d[id]])
	return ", ".join(parts)


# ---------- смерть ----------

func _build_death(root: Control) -> void:
	_death = _panel(root)
	_place(_death, Vector2(0.5, 0.5), Vector2(-300, -110), Vector2(300, 110))
	var v := VBoxContainer.new()
	_death.add_child(v)
	_label(v, "Герой отключился.\nОчередь за спасением подождёт.", 26)
	_button(v, "Очнуться у контрольной точки", func():
		_death.visible = false
		_set_controls(true)
		pause_action.emit("respawn"))


func show_death() -> void:
	_death.visible = true
	_set_controls(false)


## Пока открыт диалог, выбор, пауза или экран поражения, мир стоит на паузе.
func _set_controls(enabled: bool) -> void:
	get_tree().paused = not enabled
	controls.visible = enabled
	if controls.player:
		controls.player.controls_enabled = enabled
		controls.player.move_input = Vector2.ZERO
