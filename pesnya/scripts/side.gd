class_name SideRun
extends RefCounted
## 0.6: runtime of the side quests described in SideQ — progress, dialogs, markers, tracker and journal.

var g  # main game
var st := {}        # qid -> {"s": step index, "n": counter, "t": timer end (unix time), "done": bool}
var marks: Array = []   # loot-beam nodes over «find» spots on the current map
var wave_live := {}     # 0.7: qid -> mobs of the running wave («waves» steps)


func _init(game) -> void:
	g = game


# ================================================================== save
func reset() -> void:
	st = {}
	marks = []
	wave_live = {}


func to_save() -> Dictionary:
	return st.duplicate(true)


func load_from(d) -> void:
	st = {}
	if not (d is Dictionary):
		return
	for q in d:
		if SideQ.QUESTS.has(q) and d[q] is Dictionary:
			var e: Dictionary = d[q]
			st[q] = {"s": int(e.get("s", 0)), "n": int(e.get("n", 0)), "t": float(e.get("t", 0.0)), "done": bool(e.get("done", false))}


# ================================================================== queries
func is_active(q: String) -> bool:
	return st.has(q) and not st[q].done


func is_done(q: String) -> bool:
	return st.has(q) and st[q].done


func step(q: String) -> Dictionary:
	var steps: Array = SideQ.QUESTS[q].steps
	return steps[clampi(int(st[q].s), 0, steps.size() - 1)]


func req_ok(q: String) -> bool:
	var r: Array = SideQ.QUESTS[q].req
	return int(g.get(r[0])) >= int(r[1])


func prev_ok(q: String) -> bool:
	var p: String = SideQ.QUESTS[q].get("prev", "")
	return p == "" or is_done(p)


func available(q: String) -> bool:
	return not st.has(q) and req_ok(q) and prev_ok(q) and g.level >= int(SideQ.QUESTS[q].lvl)


## The quest of a neighbour that matters now: the first unfinished one of the chain (or the last, when all are done).
func cur_quest(id: String) -> String:
	var ch: Array = SideQ.chain(id)
	for q in ch:
		if not is_done(q):
			return q
	return ch[ch.size() - 1]


func has_talk_for(id: String) -> bool:
	for q in active_list():
		var s := step(q)
		if s.type == "talk" and s.npc == id:
			return true
	return false


func active_list() -> Array:
	var out := []
	for q in SideQ.ORDER:
		if is_active(q):
			out.append(q)
	return out


func done_count() -> int:
	var n := 0
	for q in st:
		if st[q].done:
			n += 1
	return n


func npc_name(id: String) -> String:
	if SideQ.NPCS.has(id):
		return SideQ.NPCS[id].name
	return g.npc_title(id)


func _has_items(s: Dictionary) -> bool:
	for id in s.items:
		if g.count_item(id) < int(s.items[id]):
			return false
	return true


func _items_line(s: Dictionary) -> String:
	var p := []
	for id in s.items:
		p.append("%s %d/%d" % [GameData.ITEMS[id].name.to_lower(), mini(g.count_item(id), int(s.items[id])), int(s.items[id])])
	return "у тебя: " + ", ".join(p)


func _res_have(s: Dictionary) -> int:
	if s.res == "food":
		return g.food
	return int(g.res[s.res])


func _res_name(s: Dictionary) -> String:
	return "шаурма" if s.res == "food" else GameData.RES_NAMES[s.res].to_lower()


## Items still needed by accepted quests (Lyuba will not buy them as junk).
func reserved() -> Dictionary:
	var out := {}
	for q in active_list():
		var steps: Array = SideQ.QUESTS[q].steps
		for i in range(int(st[q].s), steps.size()):
			var s: Dictionary = steps[i]
			if s.type == "give_items":
				for id in s.items:
					out[id] = int(out.get(id, 0)) + int(s.items[id])
	return out


func step_text(q: String) -> String:
	var s := step(q)
	var n := int(st[q].n)
	match s.type:
		"kill", "collect":
			return s.text % [n, int(s.n)]
		"timer":
			var left: float = float(st[q].t) - g.now()
			return s.text % g._mmss(left) if left > 0.0 else "Готово! Загляни к хозяину"
		"waves":
			return s.text % [mini(int(st[q].n) + 1, int(s.n)), int(s.n)]
		"give_items":
			return "%s (%s)" % [s.text, _items_line(s)]
		"give_res":
			return "%s (у тебя: %d)" % [s.text, _res_have(s)]
	return s.text


static func _cut(t: String, n := 46) -> String:
	return t if t.length() <= n else t.substr(0, n - 1) + "…"


# ================================================================== tracker, markers, journal
## One or two compact tracker lines (they start with «● » — the HUD draws them in teal).
func tracker_lines() -> Array:
	var out := []
	for q in active_list():
		if out.size() >= 2:
			break
		out.append(_cut("● %s: %s" % [SideQ.QUESTS[q].title, _short(q)]))
	return out


func _short(q: String) -> String:
	var s := step(q)
	match s.type:
		"kill", "collect":
			return "%s %d/%d" % [_verb(s), int(st[q].n), int(s.n)]
		"timer":
			var left: float = float(st[q].t) - g.now()
			return ("ждать %s" % g._mmss(left)) if left > 0.0 else "забери у хозяина"
		"give_items":
			return "%s %s" % ["отдать" if _has_items(s) else "собрать", _items_short(s)]
		"give_res":
			return "%s: %d/%d" % [_res_name(s), mini(_res_have(s), int(s.n)), int(s.n)]
		"combo":
			return "комбо ×%d" % int(s.n)
		"waves":
			return "оборона: волна %d/%d" % [mini(int(st[q].n) + 1, int(s.n)), int(s.n)]
		"talk":
			return "поговорить: " + npc_name(s.npc)
		"find":
			var lb := str(s.label)
			return "найти: " + lb.left(1).to_lower() + lb.substr(1)   # keep names capitalised: «кепка Джека Скалолаза»
		"return":
			return "вернуться: " + npc_name(s.npc)
	return s.text


func _verb(s: Dictionary) -> String:
	if s.type == "collect":
		return str(s.drop).to_lower()
	return GameData.MOBS[s.mob].name.to_lower()


func _items_short(s: Dictionary) -> String:
	var p := []
	for id in s.items:
		p.append("%s %d/%d" % [GameData.ITEMS[id].name.to_lower(), mini(g.count_item(id), int(s.items[id])), int(s.items[id])])
	return ", ".join(p)


func marker(id: String) -> String:
	for q in active_list():
		var s := step(q)
		if s.type == "talk" and s.npc == id:
			return "?"
	if SideQ.NPCS.has(id):
		var q: String = cur_quest(id)
		if available(q):
			return "!"
		if is_active(q):
			var s2 := step(q)
			if s2.type == "return":
				return "?"
			if s2.type == "give_items" and _has_items(s2):
				return "?"
			if s2.type == "give_res" and _res_have(s2) >= int(s2.n):
				return "?"
	return ""


func journal_rows() -> Array:
	var rows := []
	var main: Array = g.main_quest_lines()
	if main.size() > 1:
		var sub := " · ".join(main.slice(1))
		rows.append({"text": "Сюжет: " + main[0], "sub": sub, "color": Hud.GOLD})
	for q in active_list():
		var qd: Dictionary = SideQ.QUESTS[q]
		var s := step(q)
		var hint: String = ("\nПодсказка: " + s.hint) if s.has("hint") else ""
		rows.append({"text": "%s — %s" % [qd.title, npc_name(qd.npc)], "sub": "Сейчас: %s%s\n«%s»" % [step_text(q), hint, qd.offer], "color": Hud.TEAL})
	var later := 0
	for q in SideQ.ORDER:
		if st.has(q):
			continue
		var qd2: Dictionary = SideQ.QUESTS[q]
		var where: String = GameData.MAP_NAMES.get(SideQ.NPCS[qd2.npc].map, "")
		if available(q):
			rows.append({"text": "Доступно: «%s»" % qd2.title, "sub": "%s ждёт тебя: %s · жёлтый «!» над головой" % [npc_name(qd2.npc), where], "color": Hud.CREAM})
		elif req_ok(q) and prev_ok(q):
			rows.append({"text": "Скоро: «%s» (нужен уровень %d)" % [qd2.title, int(qd2.lvl)], "sub": "%s · %s · опыт дают мобы и задания" % [npc_name(qd2.npc), where], "color": Color(0.7, 0.75, 0.82)})
		else:
			later += 1
	for q in SideQ.ORDER:
		if is_done(q):
			var qd3: Dictionary = SideQ.QUESTS[q]
			rows.append({"text": "Выполнено: «%s»" % qd3.title, "sub": "%s: «%s»" % [npc_name(qd3.npc), qd3.after[0]], "color": Hud.GREEN})
	if later > 0:
		rows.append({"text": "Ещё %d %s ждут своего часа" % [later, "соседей" if later >= 5 else "соседа"], "sub": "Проходи сюжет — откроются новые места и новые знакомые", "color": Color(0.6, 0.65, 0.72)})
	return rows


# ================================================================== progress
func accept(q: String) -> void:
	st[q] = {"s": 0, "n": 0, "t": 0.0, "done": false}
	var s := step(q)
	if s.type == "timer":
		st[q].t = g.now() + float(s.secs)
	g.hud.toast("Новое задание: «%s»" % SideQ.QUESTS[q].title, Hud.GOLD)
	g.play_sfx("bank")
	refresh_marks()
	g.save_game()


func _advance(q: String) -> void:
	st[q].s = int(st[q].s) + 1
	st[q].n = 0
	var s := step(q)
	if s.type == "timer":
		st[q].t = g.now() + float(s.secs)
	g.hud.toast("«%s»: %s" % [SideQ.QUESTS[q].title, _short(q)], Hud.GOLD)
	g.play_sfx("bank", 1.2, -4.0)
	refresh_marks()
	g.save_game()


func complete(q: String) -> void:
	var qd: Dictionary = SideQ.QUESTS[q]
	var rw: Dictionary = qd.reward
	st[q].done = true
	if rw.has("unlock"):
		g.unlock(str(rw.unlock))
	g.coins += int(rw.get("coins", 0))
	g.food += int(rw.get("food", 0))
	if rw.has("item"):
		g.add_item(rw.item)
	g.gain_xp(int(rw.get("xp", 0)))
	g.hud.big("ЗАДАНИЕ ВЫПОЛНЕНО!", "«%s» · +%d монет · +%d опыта" % [qd.title, int(rw.get("coins", 0)), int(rw.get("xp", 0))], 4.0)
	g.play_sfx("bank")
	refresh_marks()
	g.save_game()


func on_kill(m: Dictionary) -> void:
	if m.temp:
		return
	for q in active_list():
		var s := step(q)
		if s.type == "kill" and s.mob == m.kind:
			st[q].n = int(st[q].n) + 1
			if int(st[q].n) >= int(s.n):
				_advance(q)
			else:
				g.hud.float_text(m.pos + Vector3(0, m.height + 1.2, 0), "«%s» %d/%d" % [SideQ.QUESTS[q].title, int(st[q].n), int(s.n)], Hud.TEAL, 18, 40)
		elif s.type == "collect" and s.mob == m.kind and (randf() < float(s.chance) or g.autotest):
			st[q].n = int(st[q].n) + 1
			g.hud.float_text(m.pos + Vector3(0, m.height + 1.2, 0), "+%s %d/%d" % [s.drop, int(st[q].n), int(s.n)], Hud.GOLD, 22, 40)
			if int(st[q].n) >= int(s.n):
				_advance(q)


func on_combo(c: int) -> void:
	for q in active_list():
		var s := step(q)
		if s.type == "combo" and c >= int(s.n):
			g.hud.big("СКИЛЛ-ЧЕК ПРОЙДЕН!", "Комбо ×%d · «%s»" % [c, SideQ.QUESTS[q].title], 2.5)
			_advance(q)


func update(_dt: float) -> void:
	for q in active_list():
		var s := step(q)
		if s.type == "timer" and g.now() >= float(st[q].t):
			_advance(q)
		elif s.type == "waves":
			_update_waves(q, s)


## 0.7 «waves»: when the hero comes to the spot, a wave of temporary mobs attacks; a cleared wave counts.
func _update_waves(q: String, s: Dictionary) -> void:
	if g.map_id != s.map or not g.is_playing():
		wave_live.erase(q)
		return
	var live: Array = wave_live.get(q, [])
	if live.size() > 0:
		for m in live:
			if m.alive:
				return
		wave_live.erase(q)
		st[q].n = int(st[q].n) + 1
		if int(st[q].n) >= int(s.n):
			g.hud.big("УЧЕНИЯ: ВСЕ ВОЛНЫ ОТБИТЫ!", "«%s»" % SideQ.QUESTS[q].title, 2.5)
			_advance(q)
		else:
			g.hud.big("ВОЛНА %d/%d ОТБИТА!" % [int(st[q].n), int(s.n)], "Следующая — через пару секунд", 2.0)
			refresh_marks()
			g.save_game()
		return
	var p: Vector3 = s.pos
	if Vector2(g.pos.x - p.x, g.pos.z - p.z).length() > 12.0:
		return
	var out := []
	for k in range(int(s.per)):
		var a := TAU * k / float(s.per) + int(st[q].n) * 0.7
		var m: Dictionary = g._spawn_mob(str(s.mob), p + Vector3(cos(a) * 7.0, 0, sin(a) * 7.0), int(s.lvl) + int(st[q].n) / 2)
		m.temp = true
		m.st = "chase"
		m.name = str(s.get("name", m.name))
		out.append(m)
	wave_live[q] = out
	refresh_marks()
	g.hud.big("ВОЛНА %d/%d!" % [int(st[q].n) + 1, int(s.n)], "%s атакуют сцену!" % str(s.get("name", "Враги")), 2.0)
	g.play_sfx("laser", 0.7, -4.0)


func wave_spots() -> Array:
	var out := []
	for q in active_list():
		var s := step(q)
		if s.type == "waves" and s.map == g.map_id and not wave_live.has(q):
			out.append({"q": q, "pos": s.pos})
	return out


# ================================================================== dialogs
## Returns true when this NPC had something to say about side quests.
func talk(id: String) -> bool:
	var close := func(): g.close_dialog()
	for q in active_list():
		var s := step(q)
		if s.type == "talk" and s.npc == id:
			var title: String = SideQ.QUESTS[q].title
			g.open_dialog(npc_name(id), s.say, [["Спасибо! («%s»)" % title, func(): _advance(q); close.call()]])
			return true
	if not SideQ.NPCS.has(id):
		return false
	var q2: String = cur_quest(id)
	var qd: Dictionary = SideQ.QUESTS[q2]
	var nm: String = SideQ.NPCS[id].name
	if is_done(q2):
		var a: Array = qd.after
		g.open_dialog(nm, a[randi() % a.size()], [["До встречи!", close]])
	elif not st.has(q2):
		if not req_ok(q2) or not prev_ok(q2):
			g.open_dialog(nm, qd.lock, [["Понял", close]])
		elif g.level < int(qd.lvl):
			g.open_dialog(nm, "%s\n\n(Задание с %d уровня. У тебя %d — опыт дают мобы и другие задания.)" % [qd.offer, int(qd.lvl), g.level],
				[["Подкачаюсь и вернусь", close]])
		else:
			g.open_dialog(nm, qd.offer, [[qd.accept, func(): accept(q2); close.call()], ["Позже", close]])
	else:
		var s2 := step(q2)
		var hint: String = ("\nПодсказка: " + s2.hint) if s2.has("hint") else ""
		match s2.type:
			"return":
				var rw: Dictionary = qd.reward
				var item_name: String = GameData.ITEMS[rw.item].name if rw.has("item") else ""
				g.open_dialog(nm, qd.done, [["Спасибо! (+%d монет, %s)" % [int(rw.get("coins", 0)), item_name], func(): complete(q2); close.call()]])
			"give_items":
				if _has_items(s2):
					g.open_dialog(nm, "%s\n\n%s" % [qd.progress, s2.text], [["Отдать", func():
						for it_id in s2.items:
							g.remove_items(it_id, int(s2.items[it_id]))
						_advance(q2)
						talk(id)]])
				else:
					g.open_dialog(nm, "%s\n\nСейчас: %s%s" % [qd.progress, step_text(q2), hint], [["Пойду искать", close]])
			"give_res":
				if _res_have(s2) >= int(s2.n):
					g.open_dialog(nm, "%s\n\n%s" % [qd.progress, s2.text], [["Отдать (%s ×%d)" % [_res_name(s2), int(s2.n)], func():
						if s2.res == "food":
							g.food -= int(s2.n)
						else:
							g.res[s2.res] = int(g.res[s2.res]) - int(s2.n)
						_advance(q2)
						talk(id)]])
				else:
					g.open_dialog(nm, "%s\n\nСейчас: %s%s" % [qd.progress, step_text(q2), hint], [["Добуду", close]])
			_:
				g.open_dialog(nm, "%s\n\nСейчас: %s%s" % [qd.progress, step_text(q2), hint], [["Иду!", close]])
	return true


# ================================================================== «find» spots
func find_spots() -> Array:
	var out := []
	for q in active_list():
		var s := step(q)
		if s.type == "find" and s.map == g.map_id:
			out.append({"q": q, "pos": s.pos, "label": s.label})
	return out


func interactables() -> Array:
	var out := []
	for f in find_spots():
		out.append({"label": "Осмотреть", "kind": "side_find", "id": f.q, "pos": f.pos, "r": 2.6})
	return out


func inspect(q: String) -> void:
	var s := step(q)
	g.open_dialog(str(s.label), s.say, [["Забрать!", func(): _advance(q); g.close_dialog()]])


func refresh_marks() -> void:
	for n in marks:
		if is_instance_valid(n):
			n.queue_free()
	marks = []
	if not g.world.has("root"):
		return
	for f in find_spots():
		var n := Node3D.new()
		g.world.root.add_child(n)
		n.position = f.pos
		Chars.loot_beam(n, Vector3.ZERO, Hud.GOLD, 5.0)
		Kit.part(n, Kit.SPH, Kit.neon(Hud.GOLD, 2.4), Vector3.ONE * 0.36, Vector3(0, 0.5, 0))
		marks.append(n)
	for w in wave_spots():
		var n2 := Node3D.new()
		g.world.root.add_child(n2)
		n2.position = w.pos
		Chars.ring(n2, Vector3(0, 0.05, 0), 3.0, Color("ff5d7a"), 0.12, 3.0)
		Chars.loot_beam(n2, Vector3.ZERO, Color("ff5d7a"), 6.0)
		marks.append(n2)


func world_labels() -> Array:
	var out := []
	for f in find_spots():
		out.append([f.pos + Vector3(0, 2.4, 0), "%s · осмотреть" % f.label, 17, Hud.GOLD])
	for w in wave_spots():
		out.append([w.pos + Vector3(0, 3.0, 0), "Учения: подойди — начнётся оборона", 17, Color("ff9ab0")])
	return out
