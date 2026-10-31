class_name QuestLog
extends PanelContainer
## Журнал заданий: вкладки «Сюжет», «Поручения», «Выполнено». Слева список карточек,
## справа подробности выбранного. Закрытые задания не показываются (без спойлеров):
## внизу только счётчик «впереди ещё N». У активного задания видны пройденные шаги
## и текущий; будущие шаги скрыты.

signal closed

const STATE_CHIP := {"AVAILABLE": ["можно взять", Color(0.4, 0.85, 1)], "ACTIVE": ["в работе", Color(1, 0.8, 0.25)],
		"OBJECTIVE_DONE": ["сдать", Color(0.4, 1, 0.5)], "TURN_IN_READY": ["сдать", Color(0.4, 1, 0.5)],
		"COMPLETED": ["выполнено", Color(0.6, 0.6, 0.6)], "FAILED_RECOVERABLE": ["провалено, можно повторить", Color(1, 0.4, 0.35)]}
## Районы, которые уже есть в сборке.
const PLAYABLE := ["DIST_POGULYAY"]

var _tab := "main"
var _selected := ""
var _tabs: HBoxContainer
var _list: VBoxContainer
var _detail: VBoxContainer
var _footer: Label
var _title_font: Font


func _ready() -> void:
	visible = false
	_title_font = load("res://assets/fonts/RussoOne-Regular.ttf")
	var sb := UiSkin.panel(16)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_tabs)
	var close := UiSkin.icon_button("close", 54, Color(0, 0, 0, 0))
	close.pressed.connect(close_panel)
	head.add_child(close)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	v.add_child(body)
	var ls := ScrollContainer.new()
	ls.custom_minimum_size.x = 420
	ls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(ls)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	ls.add_child(_list)
	var ds := ScrollContainer.new()
	ds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ds.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(ds)
	_detail = VBoxContainer.new()
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.add_theme_constant_override("separation", 8)
	ds.add_child(_detail)
	_footer = _lbl(v, "", 16, Color(0.6, 0.58, 0.55))


func open() -> void:
	visible = true
	if _selected == "" or not _visible_quest(GameData.quest(_selected)):
		var act := QuestService.active_quests()
		_selected = act[0].id if not act.is_empty() else ""
	_render()


func close_panel() -> void:
	if visible:
		visible = false
		closed.emit()


## Поручение «можно взять» видно, только когда герой о нём услышал (флаг offered:<ID>
## ставит тот, кто его даёт), оно по силам и таких не больше RUMORS. Остальное —
## «впереди», чтобы список не превращался в простыню и не спойлерил.
const RUMORS := 4
const LEVEL_SLACK := 3


static func _visible_quest(q: Dictionary) -> bool:
	return not q.is_empty() and _shown(q)


static func _shown(q: Dictionary) -> bool:
	var s := QuestService.state_of(q.id)
	if s == QuestService.LOCKED:
		return false
	if s != QuestService.AVAILABLE or q.kind == "main":
		return true
	return GameState.has_flag("offered:" + q.id) and PLAYABLE.has(q.district_id) \
			and int(q.min_level) <= GameState.level + LEVEL_SLACK


func _quests_for(tab: String) -> Array:
	var out := GameData.quests.filter(func(q):
		if not _shown(q):
			return false
		var s := QuestService.state_of(q.id)
		if tab == "done":
			return s == QuestService.COMPLETED
		if s == QuestService.COMPLETED:
			return false
		return (q.kind == "main") == (tab == "main"))
	if tab == "side":
		var active := out.filter(func(q): return QuestService.state_of(q.id) != QuestService.AVAILABLE)
		var rumors := out.filter(func(q): return QuestService.state_of(q.id) == QuestService.AVAILABLE)
		rumors.sort_custom(func(a, b): return int(a.min_level) < int(b.min_level))
		out = active + rumors.slice(0, RUMORS)
	return out


func _render() -> void:
	for c in _tabs.get_children():
		c.queue_free()
	for t in [["main", "Сюжет"], ["side", "Поручения"], ["done", "Выполнено"]]:
		var n: int = _quests_for(t[0]).size()
		var b := _btn(_tabs, "  %s  %s" % [t[1], "(%d)" % n if n > 0 else ""], func():
			_tab = t[0]
			var list := _quests_for(_tab)
			_selected = list[0].id if not list.is_empty() else ""
			_render(), 22)
		UiSkin.style_tab(b, _tab == t[0])
	for c in _list.get_children():
		c.queue_free()
	var quests := _quests_for(_tab)
	if quests.is_empty():
		_lbl(_list, {"main": "Сюжет пока молчит.", "side": "Поручений пока нет. Люди Погуляя присматриваются к тебе.",
				"done": "Ещё ничего не сделано. Как и всегда в Рубине."}[_tab], 18, Color(0.7, 0.68, 0.62)) \
				.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for q in quests:
		_list.add_child(_card(q))
	var shown := 0
	for t in ["main", "side", "done"]:
		shown += _quests_for(t).size()
	var locked := GameData.quests.size() - shown
	_footer.text = "Впереди ещё %d заданий. Они откроются по ходу истории — без спойлеров." % locked
	for c in _detail.get_children():
		c.queue_free()
	var sel := GameData.quest(_selected)
	if _visible_quest(sel):
		_render_detail(sel)


func _card(q: Dictionary) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 76)
	var state := QuestService.state_of(q.id)
	var chip: Array = STATE_CHIP.get(state, ["", Color.WHITE])
	for st in ["normal", "hover", "pressed"]:
		var sb := UiSkin.card(chip[1] if q.id == _selected else chip[1].darkened(0.45), 1.0)
		sb.bg_color = UiSkin.INK_LIGHT.lightened(0.08) if q.id == _selected else UiSkin.INK_LIGHT.darkened(0.15)
		if st == "hover":
			sb.bg_color = sb.bg_color.lightened(0.06)
		if q.id == _selected:
			sb.border_color = chip[1]
			sb.set_border_width_all(3)
			sb.border_width_left = 8
		b.add_theme_stylebox_override(st, sb)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16
	v.offset_top = 8
	v.add_theme_constant_override("separation", 2)
	b.add_child(v)
	var t := _lbl(v, q.title, 20, Color(1, 0.93, 0.8))
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.custom_minimum_size.x = 380
	_lbl(v, "%s · %s" % [q.district, chip[0]], 15, chip[1])
	for l in v.get_children():
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pressed.connect(func():
		_selected = q.id
		_render())
	return b


func _render_detail(q: Dictionary) -> void:
	var state := QuestService.state_of(q.id)
	var r: Dictionary = QuestService.records.get(q.id, {})
	var title := _lbl(_detail, q.title, 30, UiSkin.GOLD)
	title.add_theme_font_override("font", _title_font)
	title.add_theme_color_override("font_outline_color", UiSkin.OUTLINE)
	title.add_theme_constant_override("outline_size", 8)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var meta: PackedStringArray = ["Акт %d" % q.act if q.kind == "main" else ("Поручение" if q.kind == "npc" else "Своё дело"),
			q.location, "рекомендуемый уровень %d" % q.min_level]
	_lbl(_detail, " · ".join(meta), 16, Color(0.6, 0.85, 1)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not PLAYABLE.has(q.district_id) and state != QuestService.COMPLETED:
		_lbl(_detail, "Район «%s» откроется в следующей сборке." % q.district, 16, Color(1, 0.6, 0.4))
	_section("Что случилось")
	_para(q.setup)
	_section("Что делать")
	var current := int(r.get("stage", 0))
	for i in q.stages.size():
		var st: Dictionary = q.stages[i]
		var done: bool = state == QuestService.COMPLETED or (state != QuestService.AVAILABLE and i < current)
		var now: bool = state != QuestService.COMPLETED and state != QuestService.AVAILABLE and i == current
		if done:
			_lbl(_detail, "✓  %s" % _stage_text(st), 18, Color(0.55, 0.78, 0.5)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		elif now:
			# текущий шаг — на жёлтой карточке, чтобы глаз сразу находил, что делать
			var now_l := _lbl(_detail, "●  %s" % _stage_text(st), 20, UiSkin.GOLD)
			now_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			now_l.add_theme_stylebox_override("normal", UiSkin.card(UiSkin.GOLD, 0.9, 8))
		else:
			_lbl(_detail, "○  …", 18, Color(0.45, 0.43, 0.4))
	if state == QuestService.AVAILABLE:
		_lbl(_detail, "Задание ещё не взято. Найди, кто его даёт: %s." % q.giver, 17, Color(0.4, 0.85, 1)) \
				.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if state == QuestService.COMPLETED and String(r.get("choice", "")) != "":
		var c: Dictionary = q.choices[r.choice]
		_section("Твой выбор")
		_para("%s → %s." % [c.text, c.result])
		_section("А потом выяснилось")
		_para(q.twist)
	var rw: Dictionary = q.reward
	_section("Награда")
	# награда значками, как валюты в HUD (0.20)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_detail.add_child(row)
	_lbl(row, "%d опыта" % rw.xp, 20, UiSkin.BLUE)
	for it in [["coin", "%d" % rw.babki], ["rep", "%+d" % rw.reputation]]:
		var ic := TextureRect.new()
		ic.texture = UiSkin.icon(it[0])
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.custom_minimum_size = Vector2(30, 30)
		row.add_child(ic)
		_lbl(row, it[1], 20, UiSkin.GOLD)


static func _stage_text(st: Dictionary) -> String:
	var t: String = st.text
	# хвосты карточек «, 3/3 (70% за победу)» — служебные, игроку они ни к чему (0.21)
	var re := RegEx.create_from_string(",? \\d+/\\d+ \\(\\d+%( за победу)?\\)")
	t = re.sub(t, "", true)
	if t.begins_with("Решение: "):
		return "Принять решение. От него зависит, кто тебе потом поможет"
	return t


func _section(text: String) -> void:
	var l := _lbl(_detail, text.to_upper(), 15, Color(1, 0.75, 0.45))
	l.add_theme_constant_override("line_spacing", 0)


func _para(text: String) -> void:
	_lbl(_detail, text, 18, Color(0.92, 0.9, 0.85)).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _lbl(parent: Node, text: String, fs: int, color := Color(0.95, 0.93, 0.88)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _btn(parent: Node, text: String, cb: Callable, fs := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.custom_minimum_size.y = 48
	b.pressed.connect(cb)
	parent.add_child(b)
	return b
