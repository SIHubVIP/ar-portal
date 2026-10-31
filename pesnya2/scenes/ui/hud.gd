class_name Hud
extends CanvasLayer
## Интерфейс поверх мира: ресурсы, задание, диалоги, выбор, пауза с журналом.
## Наблюдает EventBus и не меняет экономику напрямую.

signal pause_action(action: String)
## Маршрутка с карты (0.22): мир сам решает, хватает ли денег, и везёт.
signal travel(plan: Vector2, title: String)

var controls: TouchControls
var _hp_bar: ProgressBar
var _xp_bar: ProgressBar
var _level: Label
var _hp_text: Label
var _res_babki: Label
var _res_rep: Label
var _res_kuk: Label
var _tracker: PanelContainer
var _tr_head: Label
var _tr_title: Label
var _tr_goal: Label
var _tr_detail: Label
var _banner: VBoxContainer
var _banner_title: Label
var _banner_sub: Label
var pointer: ObjectivePointer
var minimap: MiniMap
var world_map: WorldMap
var quest_log: QuestLog
var _objective_detail := ""
var _toast: Label
var _toast_box: CenterContainer
var _toast_tween: Tween
var dialog: DialogView
var inventory: InventoryPanel
var _pause: PanelContainer
var _death: PanelContainer
var boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_phase: Label
var _combo_box: VBoxContainer
var _combo_big: Label
var _combo_sub: Label
var _combo_tween: Tween


## Корень интерфейса: на телефоне отступает от выреза камеры и системных полос (0.23).
var _root: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.theme = UiSkin.theme()     # CanvasLayer не передаёт тему окна дальше — ставим здесь
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root = root
	_fit_safe_area()
	get_viewport().size_changed.connect(_fit_safe_area)

	pointer = ObjectivePointer.new()
	root.add_child(pointer)
	controls = TouchControls.new()
	root.add_child(controls)

	var top := VBoxContainer.new()
	top.position = Vector2(16, 12)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("separation", 8)
	root.add_child(top)
	_build_plate(top)
	_build_tracker(top)

	# справа сверху — круглые кнопки со значками и подписью (0.20), левее мини-карты
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	root.add_child(btns)
	_place(btns, Vector2(1, 0), Vector2(-470, 10), Vector2(-236, 100))
	btns.alignment = BoxContainer.ALIGNMENT_END
	_icon_button(btns, "quests", "Задания", open_quests)
	_icon_button(btns, "bag", "Сумка", func(): open_inventory("bags"))
	_icon_button(btns, "menu", "Меню", toggle_pause)
	# мини-карта в правом верхнем углу, как на ориентире; нажатие — большая карта
	minimap = MiniMap.new()
	root.add_child(minimap)
	_place(minimap, Vector2(1, 0), Vector2(-226, 8), Vector2(-18, 216))
	minimap.opened.connect(open_map)
	minimap.visible = false

	_banner = VBoxContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_banner)
	_place(_banner, Vector2(0.5, 0), Vector2(-450, 150), Vector2(450, 260))
	_banner_title = _label(_banner, "", 34)
	_banner_title.add_theme_font_override("font", UiSkin.title_font())
	_banner_title.add_theme_color_override("font_color", UiSkin.GOLD)
	_banner_title.add_theme_constant_override("outline_size", 10)
	_banner_sub = _label(_banner, "", 22)
	for l in [_banner_title, _banner_sub]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.modulate.a = 0.0

	# тост — плашка по ширине текста по центру сверху (0.20)
	_toast_box = CenterContainer.new()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)
	_place(_toast_box, Vector2(0.5, 0), Vector2(-420, 112), Vector2(420, 112))
	_toast = _label(_toast_box, "", 22)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var ts := UiSkin.card(UiSkin.GREEN, 0.92, 10)
	ts.content_margin_right = 18
	_toast.add_theme_stylebox_override("normal", ts)
	_toast_box.modulate.a = 0.0

	_build_boss(root)
	_build_combo(root)
	_build_pause(root)
	inventory = InventoryPanel.new()
	root.add_child(inventory)
	_place(inventory, Vector2(0.5, 0.5), Vector2(-600, -300), Vector2(600, 300))
	inventory.set_toast(show_toast)
	inventory.closed.connect(func(): _set_controls(true))
	quest_log = QuestLog.new()
	root.add_child(quest_log)
	_place(quest_log, Vector2(0.5, 0.5), Vector2(-600, -340), Vector2(600, 340))
	quest_log.closed.connect(func(): _set_controls(true))
	world_map = WorldMap.new()
	root.add_child(world_map)
	_place(world_map, Vector2(0.5, 0.5), Vector2(-620, -350), Vector2(620, 350))
	world_map.closed.connect(func(): _set_controls(true))
	world_map.travel_requested.connect(func(plan: Vector2, title: String) -> void: travel.emit(plan, title))
	dialog = DialogView.new()
	root.add_child(dialog)
	dialog.closed.connect(func(): _set_controls(true))
	_build_death(root)

	EventBus.resources_changed.connect(func(_b, _r, _k): _refresh_resources())
	EventBus.xp_changed.connect(_on_xp)
	EventBus.player_hp_changed.connect(_on_hp)
	EventBus.quest_stage_changed.connect(func(q, _s):
		refresh_quest()
		var st := QuestService.current_stage(q)
		if not st.is_empty():
			show_banner("Задание обновлено", st.text))
	EventBus.quest_state_changed.connect(func(q, s):
		refresh_quest()
		if s == QuestService.COMPLETED:
			show_banner("Задание выполнено", "«%s»" % GameData.quest(q).title))
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
	p.combo.connect(_on_combo)
	p.perfect_dodge.connect(func() -> void:
		_pop_combo("ЛОВКО!", "следующий удар ×2", UiSkin.BLUE))
	pointer.player = p
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


## Безопасная зона экрана телефона: часы, вырез камеры и полоса жестов не ложатся на кнопки.
func _fit_safe_area() -> void:
	if _root == null or not OS.has_feature("mobile"):
		return
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	if screen.x <= 0.0 or safe.size.x <= 0.0:
		return
	var k := get_viewport().get_visible_rect().size / screen
	_root.offset_left = safe.position.x * k.x
	_root.offset_top = safe.position.y * k.y
	_root.offset_right = -(screen.x - safe.end.x) * k.x
	_root.offset_bottom = -(screen.y - safe.end.y) * k.y


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
	l.add_theme_color_override("font_outline_color", UiSkin.OUTLINE)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _bar(parent: Node, color: Color, min_size: Vector2) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = min_size
	b.show_percentage = false
	var boxes := UiSkin.bar_boxes(color)
	b.add_theme_stylebox_override("fill", boxes[0])
	b.add_theme_stylebox_override("background", boxes[1])
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b


func _panel(parent: Node) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiSkin.panel(22))
	p.visible = false
	parent.add_child(p)
	return p


func _button(parent: Node, text: String, cb: Callable, fs := 24) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size.y = 60
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


## Круглая кнопка-значок с подписью под ней.
func _icon_button(parent: Node, icon: String, caption: String, cb: Callable) -> Button:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	parent.add_child(v)
	var b := UiSkin.icon_button(icon, 66)
	b.pressed.connect(cb)
	v.add_child(b)
	var l := _label(v, caption, 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return b


## Плашка героя: значок уровня, сердце и полоса здоровья с цифрами, опыт, три валюты значками.
func _build_plate(parent: Node) -> void:
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiSkin.card(Color(0, 0, 0, 0), 0.82, 8)
	sb.content_margin_left = 10
	sb.content_margin_right = 14
	plate.add_theme_stylebox_override("panel", sb)
	parent.add_child(plate)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	plate.add_child(row)
	# значок уровня — жёлтая монета с цифрой
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(66, 66)
	var bb := UiSkin.button_box(UiSkin.GOLD, "normal", 33)
	bb.set_content_margin_all(0)
	badge.add_theme_stylebox_override("panel", bb)
	row.add_child(badge)
	var bv := VBoxContainer.new()
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_theme_constant_override("separation", -6)
	badge.add_child(bv)
	var cap := _label(bv, "УР", 13)
	cap.add_theme_color_override("font_color", UiSkin.BROWN)
	cap.add_theme_constant_override("outline_size", 0)
	_level = _label(bv, "1", 30)
	_level.add_theme_font_override("font", UiSkin.title_font())
	_level.add_theme_color_override("font_color", UiSkin.BROWN)
	_level.add_theme_constant_override("outline_size", 0)
	for l in [cap, _level]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	row.add_child(col)
	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	col.add_child(hp_row)
	_icon(hp_row, "heart", 30)
	_hp_bar = _bar(hp_row, Color(0.93, 0.27, 0.3), Vector2(250, 26))
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_text = _label(_hp_bar, "", 16)
	_hp_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_text.add_theme_constant_override("outline_size", 5)
	_xp_bar = _bar(col, UiSkin.BLUE, Vector2(286, 9))
	var res := HBoxContainer.new()
	res.add_theme_constant_override("separation", 6)
	col.add_child(res)
	_res_babki = _chip(res, "coin")
	_res_rep = _chip(res, "rep")
	_res_kuk = _chip(res, "kukukha")


func _icon(parent: Node, name: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = UiSkin.icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t


func _chip(parent: Node, icon: String) -> Label:
	_icon(parent, icon, 26)
	var l := _label(parent, "0", 19)
	l.custom_minimum_size.x = 52
	return l


# ---------- ресурсы ----------

func _refresh_resources() -> void:
	_res_babki.text = str(GameState.babki)
	_res_rep.text = str(GameState.reputation)
	_res_kuk.text = str(GameState.kukukha)


func _on_hp(hp: float, max_hp: float) -> void:
	_hp_bar.max_value = max_hp
	_hp_bar.value = hp
	_hp_text.text = "%d / %d" % [ceili(hp), roundi(max_hp)]


func _on_xp(_xp: int, level: int, into: int, need: int) -> void:
	_level.text = str(level)
	_xp_bar.max_value = need
	_xp_bar.value = into


func _build_tracker(parent: Node) -> void:
	_tracker = PanelContainer.new()
	var sb := UiSkin.card(UiSkin.GOLD, 0.82, 8)
	sb.content_margin_left = 16
	sb.content_margin_right = 14
	_tracker.add_theme_stylebox_override("panel", sb)
	_tracker.custom_minimum_size.x = 330     # 0.23: уже и мельче — меньше закрывает двор
	_tracker.gui_input.connect(func(e: InputEvent):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			open_quests())
	parent.add_child(_tracker)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	_tracker.add_child(v)
	_tr_head = _label(v, "", 12)
	_tr_head.add_theme_color_override("font_color", UiSkin.GOLD)
	_tr_title = _label(v, "", 16)
	_tr_title.add_theme_font_override("font", UiSkin.title_font())
	_tr_goal = _label(v, "", 16)
	_tr_goal.add_theme_color_override("font_color", Color(1, 0.92, 0.55))
	_tr_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tr_goal.custom_minimum_size.x = 300
	_tr_detail = _label(v, "", 14)
	_tr_detail.add_theme_color_override("font_color", Color(0.75, 0.9, 1))


## Трекер показывает одно отслеживаемое задание: что это и что делать прямо сейчас.
func refresh_quest() -> void:
	var act := QuestService.active_quests()
	if act.is_empty():
		var next := GameData.quests.filter(func(q): return QuestService.state_of(q.id) == QuestService.AVAILABLE)
		_tracker.visible = not next.is_empty()
		if _tracker.visible:
			_tr_head.text = "НОВОЕ ЗАДАНИЕ"
			_tr_title.text = next[0].title
			_tr_goal.text = "Где: %s" % next[0].location
			_tr_detail.text = _objective_detail if _objective_detail != "" else "Нажми, чтобы открыть журнал"
		return
	_tracker.visible = true
	var q: Dictionary = QuestService.tracked_quest()
	var st := QuestService.current_stage(q.id)
	var state := QuestService.state_of(q.id)
	_tr_head.text = "%s · %s" % ["СЮЖЕТ" if q.kind == "main" else "ПОРУЧЕНИЕ", String(q.district).to_upper()]
	_tr_title.text = q.title
	if state == QuestService.TURN_IN_READY:
		_tr_goal.text = "● Сдать задание"
	elif st.is_empty():
		_tr_goal.text = "● %s" % state
	else:
		_tr_goal.text = "● %s" % QuestLog._stage_text(st)
	var r: Dictionary = QuestService.records[q.id]
	var detail := _objective_detail
	if not st.is_empty() and int(st.target) > 1:
		detail = "%d из %d" % [r.progress, st.target]
	_tr_detail.text = detail
	_tr_detail.visible = detail != ""


## Цель в мире: стрелка на экране и подпись. detail — строка прогресса в трекере.
func set_objective(pos: Vector3, label := "", detail := "") -> void:
	pointer.target = pos
	minimap.objective = pos
	world_map.objective = pos
	pointer.label = label
	if detail != _objective_detail:
		_objective_detail = detail
		refresh_quest()


func show_banner(title: String, sub: String) -> void:
	_banner_title.text = title
	_banner_sub.text = sub
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.5)


func show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_box.scale = Vector2(0.9, 0.9)
	_toast_box.pivot_offset = Vector2(_toast_box.size.x / 2, 0)
	_toast_tween = _toast_box.create_tween()
	_toast_tween.tween_property(_toast_box, "modulate:a", 1.0, 0.15)
	_toast_tween.parallel().tween_property(_toast_box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast_box, "modulate:a", 0.0, 0.4)


# ---------- серия ударов (0.20) ----------

## Счётчик серии над кнопкой удара: «×3 РАЗМАХ!», гаснет сам.
func _build_combo(root: Control) -> void:
	_combo_box = VBoxContainer.new()
	_combo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_box.add_theme_constant_override("separation", -8)
	root.add_child(_combo_box)
	_place(_combo_box, Vector2(1, 1), Vector2(-300, -420), Vector2(-40, -300))
	_combo_big = _label(_combo_box, "", 52)
	_combo_big.add_theme_font_override("font", UiSkin.title_font())
	_combo_big.add_theme_constant_override("outline_size", 12)
	_combo_sub = _label(_combo_box, "", 20)
	for l in [_combo_big, _combo_sub]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_box.modulate.a = 0.0


func _on_combo(n: int) -> void:
	if n < 2:
		return
	var sweep := n % 3 == 0
	_pop_combo("×%d" % n, "РАЗМАХ!" if sweep else "серия", UiSkin.RED if sweep else UiSkin.GOLD)


func _pop_combo(big: String, sub: String, color: Color) -> void:
	_combo_big.text = big
	_combo_sub.text = sub
	_combo_big.add_theme_color_override("font_color", color)
	if _combo_tween:
		_combo_tween.kill()
	_combo_box.pivot_offset = _combo_box.size / 2.0
	_combo_box.scale = Vector2(1.35, 1.35)
	_combo_box.modulate.a = 1.0
	_combo_tween = _combo_box.create_tween()
	_combo_tween.tween_property(_combo_box, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	_combo_tween.tween_interval(0.9)
	_combo_tween.tween_property(_combo_box, "modulate:a", 0.0, 0.35)


# ---------- босс (0.16) ----------

## Полоса босса внизу между джойстиком и кнопками способностей: видна всё время боя.
func _build_boss(root: Control) -> void:
	boss_box = VBoxContainer.new()
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.add_theme_constant_override("separation", 2)
	root.add_child(boss_box)
	_place(boss_box, Vector2(0.5, 1), Vector2(-360, -118), Vector2(170, -36))
	_boss_name = _label(boss_box, "", 26)
	_boss_name.add_theme_font_override("font", UiSkin.title_font())
	_boss_name.add_theme_color_override("font_color", Color(1, 0.55, 0.75))
	_boss_bar = _bar(boss_box, Color(0.9, 0.2, 0.45), Vector2(530, 20))
	_boss_bar.max_value = 1.0
	_boss_bar.step = 0.001
	_boss_phase = _label(boss_box, "", 18)
	for l in [_boss_name, _boss_phase]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.visible = false


func show_boss(title: String) -> void:
	_boss_name.text = title
	_boss_bar.value = 1.0
	_boss_phase.text = ""
	boss_box.visible = true


func set_boss(ratio: float, phase_text: String) -> void:
	_boss_bar.value = ratio
	_boss_phase.text = phase_text


func hide_boss() -> void:
	boss_box.visible = false


# ---------- диалог и выбор ----------

func is_busy() -> bool:
	return dialog.visible or inventory.visible or quest_log.visible or world_map.visible or _pause.visible \
			or _death.visible


## lines: [{speaker, text}]; on_done вызывается и при пропуске (с теми же последствиями).
func play_dialog(lines: Array, on_done := Callable()) -> void:
	_set_controls(false)
	dialog.play_lines(lines, on_done)


## Разговор по графу data/dialogues.json. on_event получает сюжетные события (choose_A, bribe, ...).
func run_dialogue(id: String, on_event := Callable(), on_done := Callable()) -> void:
	GameState.set_flag("talked:%s" % id)
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


## Вопрос от говорящего с вариантами: [{text, tone, cb}] (поручения жителей, 0.21).
func ask_from(speaker: String, text: String, options: Array) -> void:
	_set_controls(false)
	dialog.ask(speaker, text, options)


func _finish_dialog() -> void:
	dialog.skip()


func open_inventory(tab := "gear") -> void:
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
	_place(_pause, Vector2(0.5, 0.5), Vector2(-200, -290), Vector2(200, 290))
	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	_pause.add_child(menu)
	var ttl := UiSkin.title(menu, "Пауза", 34)
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(menu, "Продолжить", toggle_pause)
	_button(menu, "Задания", func():
		toggle_pause()
		open_quests())
	_button(menu, "Сумка", func():
		toggle_pause()
		open_inventory("hero"))
	_button(menu, "На базу", func(): pause_action.emit("base"))
	_button(menu, "Сохранить", func(): pause_action.emit("save"))
	_button(menu, "В главное меню", func(): pause_action.emit("title"))


func toggle_pause() -> void:
	if dialog.visible or inventory.visible or quest_log.visible:
		return
	_pause.visible = not _pause.visible
	_set_controls(not _pause.visible)


## Карты: мир отдаёт живые точки (map_points), геометрия квартала снимается с коллизий один раз.
func setup_map(world: Node, cam: IsoCamera, p: Node3D) -> void:
	minimap.camera = cam
	minimap.player = p
	minimap.source = world
	minimap.visible = true
	world_map.player = p
	world_map.source = world
	var shapes := MapCanvas.collect(world)
	minimap.set_shapes(shapes)
	world_map.shapes = shapes


func open_map() -> void:
	if is_busy():
		return
	_set_controls(false)
	world_map.open()


func open_quests() -> void:
	if is_busy():
		return
	_set_controls(false)
	quest_log.open()


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
