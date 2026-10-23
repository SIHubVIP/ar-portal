class_name U09
extends RefCounted
## 0.9 «Своё дело»: the story (quest8), the Помойка, the inventors' idea shop and crafting, the levels 4–5 of the buildings,
## special materials from boss remixes, the workshop in box №13 with a house-warming party, the mount skin «Тележка из «Ёжика»»,
## the neighbours as guests at the dump, and the AI of the rats, fridges, mattresses and the boss Король Хлама.

var g   # main game

var ideas: Array = []        # owned ideas (IDEAS keys)
var shop_open := false       # the idea shop opens after «Вася, кто это?»
var cart_skin := false       # «Тележка из «Ёжика»» owned
var mount_skin := "izba"     # "izba" or "cart"

# guests: [id, map, pos, rot, condition, lines]
const GUESTS := [
	["shcheben", "dump", Vector3(-16.4, 0, -6.6), -0.6, "q8", ["Холодильник… подниму… это… тренировка… на выносливость… и на холод.",
		"Кеша сказал… матрас — лучший батут… для отдыха… после тренировки."]],
	["jack", "dump", Vector3(-2.0, 2.3, -14.6), 0.0, "q8", ["Гора Хлама — шесть метров! Флаг поставил. Страховка — из старых шлангов!",
		"Сверху видно Рынок электроники. Там темно. Даже днём."]],
	["maloy", "dump", Vector3(-5.8, 0, 6.0), 2.6, "q8", ["Стрим «Свалка-ASMR»: хруст пакетов, гул холодильников, ветер без пароля. Пятьдесят два подписчика!",
		"Кеша сделал мне кольцевую лампу из крышки от кастрюли. Это контент."]],
	["pilot", "dump", Vector3(-21.6, 0, 11.4), 2.2, "q8", ["Списанный кукурузник… Брат по небу. Я заберу у него пропеллер — с уважением.",
		"Аэротакси «Ложка» долетает и до Помойки. От 170 монет: чем дальше, тем дороже."]],
	["melnik", "dump", Vector3(-20.8, 0, -14.6), 2.4, "q8", ["Где-то здесь лежит дубовая бочка. Я чую хлеб. И крыс.",
		"Квас — тоже изобретение. Древнее, но рабочее. Дед Утиль согласен."]],
	["kent", "dump", Vector3(7.6, 0, 4.6), -2.0, "q8", ["Свалка — это лобби. Каждый хлам ждёт своего матча.",
		"Приставку из хлама? Это не приставка. Это легенда."]],
	["yarik", "dump", Vector3(-11.0, 0, -0.4), 0.4, "q8", ["Я свечу в лаборатории. Дед говорит, я — самая экономная лампочка.",
		"Склад №0 — там темно? Я свечусь на три процента. Этого хватит!"]],
	["lyuba", "dump", Vector3(-4.4, 0, 2.6), -0.8, "vasya", ["Шаурма на свалке — это пикник! Кеша съел четыре.",
		"Дед Утиль сделал мне ветряк для соуса. Теперь соус «с ветерком»."]],
	["zari", "dump", Vector3(-16.6, 0, 3.4), PI / 2, "idea", ["Ветер без пароля работает. Я проверил — шесть веков.",
		"Свалка — это память города. Тут лежит всё, что Рубин забыл."]],
	["petrovich", "dump", Vector3(2.8, 0, 14.2), -2.6, "q8_3", ["Вот она, Помойка. Я тут в молодости нашёл баян. До сих пор играет.",
		"Король Хлама уехал — по уставу, задним ходом."]],
	["kesha", "garages", Vector3(-19.0, 0, 4.4), PI, "workshop", ["Мастерская «Идея» открыта! Идеи — на любую постройку. Почти даром. Почти.",
		"Ветряк на крыше гаража ловит ветер без пароля. И немного вай-фая соседей."]],
	["ded", "garages", Vector3(-21.8, 0, 4.4), PI, "workshop", ["Своё дело — это когда утром хочется в мастерскую.",
		"Спецматериалы — в ремиксах боссов. Каждый босс оставляет что-то хорошее. Даже Кощей."]],
]

var party: Array = []        # neighbours dancing at the house-warming of the workshop
var lane: Node3D = null      # the King's charge telegraph
var ws_anchor: Node3D = null


func _init(game) -> void:
	g = game


# ================================================================== save
func reset() -> void:
	g.quest8 = 0
	ideas = []
	shop_open = false
	cart_skin = false
	mount_skin = "izba"


func to_save() -> Dictionary:
	return {"quest8": g.quest8, "ideas": ideas, "shop": shop_open, "cart": cart_skin, "skin": mount_skin}


func load_from(d: Dictionary) -> void:
	reset()
	g.quest8 = clampi(int(d.get("quest8", 0)), 0, 6)
	for k in d.get("ideas", []):
		if GameData.IDEAS.has(str(k)) and not (str(k) in ideas):
			ideas.append(str(k))
	shop_open = bool(d.get("shop", false))
	cart_skin = bool(d.get("cart", false))
	mount_skin = str(d.get("skin", "izba"))
	if not cart_skin:
		mount_skin = "izba"


func workshop_open() -> bool:
	return g.quest8 >= 5


func max_level() -> int:
	return 5 if workshop_open() else 3


func mat_count(id: String) -> int:
	return g.count_item(id)


func mats_text(m: Dictionary) -> String:
	var p := []
	for k in m:
		p.append("%s %d/%d" % [GameData.ITEMS[k].name, mini(mat_count(k), int(m[k])), int(m[k])])
	return ", ".join(p)


func has_mats(m: Dictionary) -> bool:
	for k in m:
		if mat_count(k) < int(m[k]):
			return false
	return true


func pay_mats(m: Dictionary) -> void:
	for k in m:
		_remove_unique(k, int(m[k]))


## remove_items skips equipped gear; materials are never equipped, so this is the same but explicit
func _remove_unique(id: String, n: int) -> void:
	for it in g.inventory.duplicate():
		if n <= 0:
			break
		if it.id == id and not g.equipped.values().has(it):
			g.inventory.erase(it)
			n -= 1


# ================================================================== the story «Своё дело» (quest8)
## 0 — not started, 1 — go to the dump, 2 — the dump chain, 3 — tell Петрович, 4 — build the workshop, 5 — the house-warming, 6 — done
func main_lines() -> Array:
	match g.quest8:
		0:
			return ["Часть 2 · «Своё дело»", "Мыслитель Зари знает, что дальше", "Набережная, у западной скамейки"]
		1:
			return ["Своё дело", "Иди на Помойку", "Стройка Глушилки → южные ворота «Городская свалка»"]
		2:
			return ["Своё дело", "Помойка: " + _chain_line(["vasya_who", "idea_q", "fridge", "utilization"]), "Вася-3000, Кеша Вторсырьё и Дед Утиль"]
		3:
			return ["Своё дело", "Расскажи Петровичу про Короля Хлама", "ГК «Песня», у правления"]
		4:
			return ["Своё дело", "Построй мастерскую в боксе №13", "ГК, северный ряд у западных ворот"]
		5:
			return ["Своё дело", "Новоселье! Поговори с Кешей у мастерской", "Бокс №13 в ГК"]
	return ["Часть 2 · «Своё дело» пройдено", "Постройки до 5 уровня — по идеям мастерской «Идея»", "Продолжение — Рынок электроники (0.10)"]


func _chain_line(ids: Array) -> String:
	for q in ids:
		if not g.side.is_done(q):
			var qd: Dictionary = SideQ.QUESTS[q]
			if g.side.is_active(q):
				return "«%s» — %s" % [qd.title, g.side._short(q)]
			return "«%s» — %s" % [qd.title, g.side.npc_name(qd.npc)]
	return "всё сделано"


func zari_marker() -> String:
	if g.quest7 >= 7 and g.quest8 == 0:
		return "!"
	return ""


func zari_talk() -> bool:
	if g.quest7 < 7:
		return false
	var close := func(): g.close_dialog()
	if g.quest8 == 0:
		g.open_dialog("Мыслитель Зари", "Полтора миллиона, говорит Кощей. Пусть. Деньги — это не главное. Главное — идеи. На Помойке живут два изобретателя: Дед Утиль и Кеша Вторсырьё. Они из хлама делают будущее. Подними с ними свои постройки — и район станет сильнее, чем Кощеева касса.", [
			["Как туда попасть?", func():
				g.hud.show_dialog("Мыслитель Зари", "Вася-3000 знает дорогу — он ездит туда по поручению «Свалка». Иди через стройку Глушилки: у южных ворот подняли шлагбаум. И не обижай холодильники. Они кусаются, когда их не любят.", [
					["На Помойку! (задание «Своё дело»)", func():
						g.quest8 = 1
						g.hud.toast("Новое задание: «Своё дело» — Помойка за стройкой Глушилки", Hud.GOLD)
						g.play_sfx("bank")
						g.save_game()
						close.call()]])]])
		return true
	if g.quest8 >= 1 and g.quest8 <= 5:
		var t: String = ["", "Стройка Глушилки, южные ворота. Там табличка «Городская свалка». Не перепутаешь — пахнет приключениями.",
			"Дед Утиль — мудрец. Кеша — гений. Вместе они — стартап. Помоги им.",
			"Король Хлама уехал? Тогда Петровичу нужно знать: изобретателям нужна мастерская.",
			"Бокс №13 никто не брал — несчастливый. А для изобретателей — самый счастливый.",
			"Новоселье! Без меня не начинайте. Хотя нет, начинайте: я медленно хожу, шестьсот лет всё-таки."][g.quest8]
		g.open_dialog("Мыслитель Зари", t, [["Понял!", close]])
		return true
	return false


func petrovich_marker() -> String:
	return "!" if g.quest8 == 3 else ""


func petrovich_talk() -> bool:
	var close := func(): g.close_dialog()
	match g.quest8:
		3:
			g.open_dialog("Петрович", "Слышал, слышал! Король Хлама уехал задним ходом — весь кооператив гудел. Изобретатели, говоришь? По уставу можно, если с идеями. Идеи есть? Взносы — идеями!", [
				["А мастерская?", func():
					g.hud.show_dialog("Петрович", "Бокс №13 пустует: несчастливый, никто не берёт. Отдаю под мастерскую. Северный ряд, у западных ворот. Построишь — будет у изобретателей своё дело, а у тебя — постройки, каких во всём Рубине нет.", [
						["Построю! (бокс №13)", func():
							g.quest8 = 4
							g.hud.toast("«Своё дело»: построй мастерскую в боксе №13", Hud.GOLD)
							g.play_sfx("bank")
							g.save_game()
							close.call()]])]])
			return true
		4:
			var c: Array = GameData.WORKSHOP_COST
			var parts := []
			for r in GameData.RES_ORDER:
				if c[1].has(r):
					parts.append("%s — %d" % [GameData.RES_NAMES[r].to_lower(), int(c[1][r])])
			g.open_dialog("Петрович", "Бокс №13 — северный ряд, у западных ворот. Нужно: %d монет, %s и гаечный ключ «Атом». Ключ у тебя от Деда, я знаю — он всем рассказал." % [int(c[0]), ", ".join(parts)], [["Иду строить", close]])
			return true
		5:
			g.open_dialog("Петрович", "Мастерская стоит — Кеша уже чинит мне калькулятор. Иди к ним, там новоселье! Все соседи пришли. Я тоже приду — после заседания правления.", [["Бегу!", close]])
			return true
	return false


func map_open() -> bool:
	return g.quest8 >= 1


## Unlocks from quest rewards (SideRun.complete → main.unlock → here).
func unlock(kind: String) -> void:
	match kind:
		"ideas":
			shop_open = true
			g.hud.toast("Лавка идей открыта: стол Кеши на Помойке", Hud.GOLD)
		"idea_grill4":
			_give_idea("grill4")
		"idea_solar4":
			_give_idea("solar4")
		"q8_dump":
			cart_skin = true
			if g.quest8 <= 2:
				g.quest8 = 3
			g.hud.toast("Скин «Тележка из «Ёжика»»: сменить — в лавке идей (Избушка-Бас должна быть твоей)", Color("d8a8ff"))
			g.hud.toast("«Своё дело»: расскажи Петровичу (ГК «Песня»)", Hud.GOLD)


func _give_idea(id: String) -> void:
	if not (id in ideas):
		ideas.append(id)
	var idd: Dictionary = GameData.IDEAS[id]
	g.hud.toast("Идея «%s»: %s ур. %d — строить в мастерской после «Своего дела»" % [idd.name, GameData.BUILDINGS[idd.b].name, int(idd.lvl)], Color("ffe8a0"))


# ================================================================== maps: the dump gate, guests, the workshop, the party
func on_enter_map(id: String) -> void:
	party = []
	_clear_lane()
	ws_anchor = null
	if id == "stroyka":
		if map_open():
			g.world.portals.append({"pos": Vector3(22.0, 0, 16.4), "r": 1.3, "to": "dump", "spawn": "from_stroyka", "label": "Помойка"})
			Chars.ring(g.world.root, Vector3(22.0, 0.05, 16.4), 1.2, Color("c8e86a"), 0.08, 3.0)
		else:
			var bar := Node3D.new()
			bar.position = Vector3(22.0, 1.0, 18.0)
			g.world.root.add_child(bar)
			for k in range(6):
				Kit.part(bar, Kit.BOX, Kit.mat(Color("e8323c") if k % 2 == 0 else Color("f4f4f4"), 0.6), Vector3(0.8, 0.14, 0.14), Vector3(-2.0 + k * 0.8, 0, 0))
			Chars.label(g.world.root, "ЗАКРЫТО", 60, Color("ffffff"), Vector3(22.0, 1.5, 17.9), Vector3(0, PI, 0), 0.006, 6)
	if id == "dump" and g.quest8 == 1:
		g.quest8 = 2
		g.hud.big("ПОМОЙКА", "Вася-3000 ждёт у входа. А дальше — лагерь изобретателей", 4.0)
		g.play_sfx("bank")
		g.save_game()
	if id == "garages" and g.world.has("workshop_anchor"):
		ws_anchor = g.world.workshop_anchor
		_build_workshop_vis()
		if g.quest8 == 5:
			_party()
	_add_guests(id)


func _build_workshop_vis() -> void:
	if ws_anchor == null or not is_instance_valid(ws_anchor):
		return
	for c in ws_anchor.get_children():
		c.queue_free()
	var w := Mobs09.workshop(ws_anchor, Vector3.ZERO, workshop_open())
	Kit.bake_tree(w)


func _guest_ok(cond: String) -> bool:
	match cond:
		"q8":
			return g.quest8 >= 2
		"vasya":
			return g.side.is_done("vasya_who")
		"idea":
			return g.side.is_done("idea_q")
		"q8_3":
			return g.quest8 >= 3
		"workshop":
			return workshop_open()
	return true


func _add_guests(id: String) -> void:
	for e in GUESTS:
		if e[1] != id or not _guest_ok(str(e[4])):
			continue
		var gid: String = e[0]
		var dup := false
		for n in g.npcs:
			if n.id == gid:
				dup = true
		if dup:
			continue
		g._spawn_npc(gid, e[2], float(e[3]))
		var last: Dictionary = g.npcs[g.npcs.size() - 1]
		last["guest"] = e[5]


## The house-warming: the neighbours dance in front of box №13 (those who live in the GK stand at home anyway)
func _party() -> void:
	var k := 0
	var ids := []
	for id in SideQ.NPCS:
		if SideQ.NPCS[id].get("neighbour", false) and SideQ.NPCS[id].map != "garages":
			ids.append(id)
	for id in ids:
		var a := -1.2 + k * (2.4 / maxf(1.0, ids.size() - 1))
		var p := GameData.BOX13 + Vector3(sin(a) * 5.2, 0, -cos(a) * 5.2 - 0.8)
		var h := Npcs.build(id)
		g.world.root.add_child(h.root)
		h.root.position = p
		h.root.rotation.y = atan2(GameData.BOX13.x - p.x, GameData.BOX13.z - p.z) + PI
		h.root.scale *= 0.9
		Kit.bake_tree(h.root)
		party.append({"node": h.root, "arms": h.get("arms", []), "base": p, "ph": randf()})
		k += 1
	# garlands over the box
	var cols := [Kit.GOLD, Color("ff5d7a"), Kit.TEAL]
	for i in range(14):
		var t := i / 13.0
		var gp := GameData.BOX13 + Vector3(-4.0 + t * 8.0, 3.4 - sin(t * PI) * 0.5, -1.6)
		var b := Kit.part(g.world.root, Kit.SPH, Kit.neon(cols[i % 3], 4.0), Vector3.ONE * 0.16, gp)
		party.append({"node": b, "arms": [], "base": gp, "ph": 0.0, "bulb": true})


# ================================================================== interactions: the idea shop, the workshop
func interactables() -> Array:
	var out := []
	if g.map_id == "dump" and shop_open:
		out.append({"label": "Лавка идей", "kind": "ideas", "id": "dump", "pos": Dump.IDEA_TABLE + Vector3(0, 0, 1.3), "r": 2.4})
	if g.map_id == "garages" and g.quest8 >= 4:
		out.append({"label": "Мастерская", "kind": "ideas" if workshop_open() else "workshop", "id": "box13", "pos": GameData.BOX13 + Vector3(0, 0, -1.4), "r": 2.4})
	return out


func labels() -> Array:
	var out := []
	if g.map_id == "dump" and shop_open:
		out.append([Dump.IDEA_TABLE + Vector3(0, 2.9, 0), "Лавка идей · Кеша и Дед", 16, Color("ffe8a0")])
	if g.map_id == "garages":
		if g.quest8 == 4:
			out.append([GameData.BOX13 + Vector3(0, 3.4, -0.6), "Бокс №13 · построй мастерскую", 17, Hud.GOLD])
		elif workshop_open():
			out.append([GameData.BOX13 + Vector3(0, 3.4, -0.6), "Мастерская «Идея» · идеи и поделки", 16, Color("ffe8a0")])
	return out


func interact(e: Dictionary) -> void:
	match e.kind:
		"ideas":
			g.open_list("ideas", e.id)
		"workshop":
			g.open_list("workshop13")


func list_workshop13() -> void:
	var c: Array = GameData.WORKSHOP_COST
	var cost := [int(c[0]), c[1]]
	var ok: bool = g._affordable(cost) and has_mats(c[2])
	var rows := [{"text": "Мастерская «Идея» в боксе №13", "sub": "Бокс несчастливый — никто не брал. Для изобретателей — самый счастливый. Здесь откроется лавка идей, поделки и улучшения построек до 5 уровня.",
		"color": Hud.GOLD},
		{"text": "Построить мастерскую", "sub": "Нужно: %s · %s" % [g._cost_text(cost), mats_text(c[2])], "btn": "Построить", "enabled": ok, "cb": func(): _build_workshop()}]
	g.hud.show_list("Бокс №13 · ГК «Песня»", "Монеты: %d · %s" % [g.coins, g.res_line()], rows)


func _build_workshop() -> void:
	var c: Array = GameData.WORKSHOP_COST
	var cost := [int(c[0]), c[1]]
	if g.quest8 != 4 or not g._affordable(cost) or not has_mats(c[2]):
		return
	g.coins -= int(c[0])
	for r in c[1]:
		g.res[r] -= int(c[1][r])
	pay_mats(c[2])
	g.quest8 = 5
	g.close_list()
	_build_workshop_vis()
	_add_guests("garages")
	_party()
	g._burst(GameData.BOX13 + Vector3(0, 1.4, -0.6), [Color("ffe8a0"), Color("ff5d7a"), Kit.TEAL, Color.WHITE], 50)
	g._ring_fx(GameData.BOX13 + Vector3(0, 0.1, -1.0), Kit.GOLD, 4.0, 0.7)
	g.hud.big("МАСТЕРСКАЯ «ИДЕЯ» ОТКРЫТА!", "Новоселье! Поговори с Кешей — соседи уже танцуют", 4.5)
	g.play_sfx("smash", 1.2, -4.0)
	g.play_sfx("bank")
	g.save_game()


## Кеша at the house-warming ends «Своё дело». Returns true when he spoke about it.
func kesha_talk() -> bool:
	if g.quest8 != 5 or g.map_id != "garages":
		return false
	var close := func(): g.close_dialog()
	g.open_dialog("Кеша Вторсырьё", "Новоселье! Дед, смотри: свет, верстак, ветряк на крыше. Своё дело! Теперь любую твою постройку можно поднять до пятого уровня — по нашим идеям.", [
		["А из чего строить?", func():
			g.hud.show_dialog("Дед Утиль", "Из спецматериалов, внучок. Каждый босс в ремиксе оставляет свой: перо Пахана, бетон Шумодава, чип Кощея, чешую Горыныча, спицу колеса, тесто, барабан стиралки и наш ключ «Атом». Пульт «РЕМИКС» — у каждой арены.", [
				["Понял! А дальше?", func():
					g.hud.show_dialog("Кеша Вторсырьё", "А дальше — вот. Помнишь ключ из пельменя? «Склад №0. Рынок. Тьма». Я его просканировал. Там не просто склад — там светочастицы. Рассвет, соскобленный с неба!", [
						["Светочастицы?!", func():
							g.hud.show_dialog("Кощей (по громкоговорителю)", "Алло, кооператив. Мастерская? Мило. Мой склад вы не найдёте: там темно, а фонарики я скупил. Все. Кроме одного…", [
								["Кроме одного?", func():
									g.hud.show_dialog("Ярик-Фонарик", "Кроме меня! Я свечусь на три процента. Этого хватит! Я теперь знаю, кто я: я — фонарик для рассвета.", [
										["На Рынок электроники! (+2000 монет, +4000 опыта, +3 сингла)", func():
											_finish_q8()
											close.call()]])]])]])]])]])
	return true


func _finish_q8() -> void:
	if g.quest8 != 5:
		return
	g.quest8 = 6
	g.coins += 2000
	g.singles += 3
	g.gain_xp(4000)
	g.hud.big("«СВОЁ ДЕЛО» ПРОЙДЕНО!", "Мастерская «Идея» работает · следующий шаг — Рынок электроники (0.10)", 5.0)
	g._notes_fx(g.pos + Vector3(0, 2, 0), Kit.GOLD)
	g.play_sfx("bank")
	g.save_game()


# ================================================================== the idea shop, crafting, the mount skin
func list_ideas(where: String) -> void:
	var rows := []
	var have := []
	for k in GameData.MAT_ORDER:
		var n := mat_count(k)
		if n > 0:
			have.append("%s ×%d" % [GameData.ITEMS[k].name, n])
	rows.append({"text": "Спецматериалы: " + (", ".join(have) if have.size() > 0 else "пока нет"),
		"sub": "Падают в ремиксах боссов — пульт «РЕМИКС» у каждой арены (Демо и Сингл — по 1, Альбом — 2, Платина — 3).", "color": Color("d8a8ff")})
	if not workshop_open():
		rows.append({"text": "Строить по идеям — после новоселья мастерской", "sub": "Задание «Своё дело»: мастерская в боксе №13 (ГК). Идеи можно купить уже сейчас.", "color": Hud.CREAM})
	for id in GameData.IDEA_ORDER:
		var idd: Dictionary = GameData.IDEAS[id]
		var bname: String = GameData.BUILDINGS[idd.b].name
		var owned: bool = id in ideas
		var src := []
		for k in idd.mats:
			src.append("%s ×%d (%s)" % [GameData.ITEMS[k].name, int(idd.mats[k]), GameData.MAT_SOURCE[k]])
		if idd.has("singles"):
			src.append("золотой сингл ×%d" % int(idd.singles))
		var sub: String = "%s · %s\nДля стройки: %s + обычная цена уровня" % [idd.desc, idd.by, ", ".join(src)]
		var row := {"text": "«%s» — %s, ур. %d" % [idd.name, bname, int(idd.lvl)], "sub": sub, "color": Color("fff0c0")}
		if idd.has("soon"):
			row["btn"] = "В %s" % idd.soon
			row["enabled"] = false
			row["cb"] = func(): pass
			row["color"] = Color(0.7, 0.75, 0.82)
		elif owned:
			row["btn"] = "Твоя"
			row["enabled"] = false
			row["cb"] = func(): pass
			row["color"] = Hud.GREEN
		else:
			var key: String = id
			row["btn"] = "%d монет" % int(idd.price)
			row["enabled"] = g.coins >= int(idd.price)
			row["cb"] = func(): _buy_idea(key)
		rows.append(row)
	rows.append({"text": "Поделки из хлама", "sub": "Кеша и Дед делают вещи из того, что ты собрал. Такое у Любы не купишь.", "color": Hud.GOLD})
	for id in GameData.CRAFT_ORDER:
		var cr: Dictionary = GameData.CRAFTS[id]
		var it: Dictionary = GameData.ITEMS[id]
		var locked: bool = int(cr.get("after", 0)) > g.quest8
		var parts := []
		for k in cr.items:
			parts.append("%s %d/%d" % [GameData.ITEMS[k].name.to_lower() if not GameData.ITEMS[k].get("mat", false) else GameData.ITEMS[k].name, mini(g.count_item(k), int(cr.items[k])), int(cr.items[k])])
		var st := GameData.stats_text(GameData.item_stats(it))
		var ok: bool = not locked and g.coins >= int(cr.coins)
		for k in cr.items:
			if g.count_item(k) < int(cr.items[k]):
				ok = false
		var key2: String = id
		rows.append({"text": "%s · %s · ур. %d" % [it.name, Hud.RARITY_NAME[it.rarity], GameData.item_level(it)],
			"sub": "%s · +%d силы%s\nНужно: %s, %d монет%s" % [GameData.SLOT_NAMES.get(it.slot, ""), int(it.power), (" · " + st) if st != "" else "", ", ".join(parts), int(cr.coins),
				"\nОткроется после «Своего дела»" if locked else ""],
			"btn": "Сделать", "enabled": ok, "cb": func(): _craft(key2), "color": Hud.RARITY[it.rarity]})
	if cart_skin:
		rows.append({"text": "Скин Избушки-Бас: %s" % ("«Тележка из «Ёжика»»" if mount_skin == "cart" else "Избушка-Бас"),
			"sub": "Кеша поставил на тележку пропеллер. Скорость та же, стиль — другой.", "btn": "Сменить", "enabled": true, "cb": func(): _toggle_skin(),
			"color": Color("d8a8ff")})
	var title := "ЛАВКА ИДЕЙ · ПОМОЙКА" if where == "dump" else "МАСТЕРСКАЯ «ИДЕЯ» · БОКС №13"
	g.hud.show_list(title, "Монеты: %d · синглы: %d · %s" % [g.coins, g.singles, g.res_line()], rows)


func _buy_idea(id: String) -> void:
	var idd: Dictionary = GameData.IDEAS[id]
	if id in ideas or idd.has("soon") or g.coins < int(idd.price):
		return
	g.coins -= int(idd.price)
	ideas.append(id)
	g.hud.toast("Идея «%s» — твоя!" % idd.name, Color("ffe8a0"))
	g.play_sfx("bank", 1.2)
	g.save_game()
	g._refresh_list()


func _craft(id: String) -> void:
	var cr: Dictionary = GameData.CRAFTS[id]
	if int(cr.get("after", 0)) > g.quest8 or g.coins < int(cr.coins):
		return
	for k in cr.items:
		if g.count_item(k) < int(cr.items[k]):
			return
	g.coins -= int(cr.coins)
	for k in cr.items:
		_remove_unique(k, int(cr.items[k]))
	g.add_item(id)
	g._burst(g.pos + Vector3(0, 1.4, 0), [Color("ffe8a0"), Color.WHITE], 20)
	g.play_sfx("smash", 1.4, -6.0)
	g.save_game()
	g._refresh_list()


func _toggle_skin() -> void:
	mount_skin = "izba" if mount_skin == "cart" else "cart"
	if g.mounted and not g.mount_vis.is_empty():
		if is_instance_valid(g.mount_vis.root):
			g.mount_vis.root.queue_free()
		g.mount_vis = {}
		g._create_mount_vis()
	g.hud.toast("Скин: %s" % ("«Тележка из «Ёжика»»" if mount_skin == "cart" else "Избушка-Бас"), Color("d8a8ff"))
	g.save_game()
	g._refresh_list()


# ================================================================== levels 4–5 of the buildings (used by main._list_slot / _build)
func idea_for(id: String, lv: int) -> String:
	return "%s%d" % [id, lv]


## Rows for a slot at level 3+ (the next level needs an idea and special materials)
func slot_rows(id: String, lv: int) -> Array:
	var rows := []
	if lv >= 5:
		rows.append({"text": "Максимальный уровень", "sub": "Изобретатели довольны: «Дальше — только своё дело»", "color": Hud.GREEN})
		return rows
	var key := idea_for(id, lv + 1)
	var idd: Dictionary = GameData.IDEAS[key]
	if not workshop_open():
		rows.append({"text": "Уровни 4–5 — по идеям изобретателей", "sub": "Дед Утиль и Кеша на Помойке (0.9): задание «Своё дело» и мастерская в боксе №13", "color": Hud.CREAM})
	elif idd.has("soon"):
		rows.append({"text": "«%s» → ур. %d" % [idd.name, lv + 1], "sub": "Материал (%s) появится в обновлении %s" % [mats_text(idd.mats), idd.soon], "color": Color(0.7, 0.75, 0.82)})
	elif not (key in ideas):
		rows.append({"text": "Нужна идея «%s» → ур. %d" % [idd.name, lv + 1], "sub": "%s · купи в мастерской «Идея» (бокс №13) или в лавке на Помойке" % idd.desc, "color": Hud.CREAM})
	else:
		var cost: Array = GameData.BUILDINGS[id].cost[lv]
		var need := "%s · %s" % [g._cost_text(cost), mats_text(idd.mats)]
		if idd.has("singles"):
			need += ", золотой сингл %d/%d" % [mini(g.singles, int(idd.singles)), int(idd.singles)]
		rows.append({"text": "«%s» → ур. %d: %s" % [idd.name, lv + 1, g._effect_text(id, lv + 1)], "sub": "Нужно: " + need, "btn": "Улучшить",
			"enabled": can_upgrade(id, lv), "cb": func(): g._build(id)})
	return rows


func can_upgrade(id: String, lv: int) -> bool:
	if lv < 3:
		return true
	if lv >= 5 or not workshop_open():
		return false
	var key := idea_for(id, lv + 1)
	var idd: Dictionary = GameData.IDEAS[key]
	if idd.has("soon") or not (key in ideas):
		return false
	if g.singles < int(idd.get("singles", 0)):
		return false
	return has_mats(idd.mats) and g._affordable(GameData.BUILDINGS[id].cost[lv])


func pay_upgrade(id: String, lv: int) -> void:
	if lv < 3:
		return
	var idd: Dictionary = GameData.IDEAS[idea_for(id, lv + 1)]
	pay_mats(idd.mats)
	g.singles -= int(idd.get("singles", 0))


func cap(id: String) -> int:
	var lv: int = g.buildings[id]
	var c = GameData.BUILDINGS[id].cap
	return int(c[clampi(lv - 1, 0, c.size() - 1)])


## Shawarma heals 40% → 50% with the Мангал-реактор, 60% with «Жар-птица»
func food_bonus() -> float:
	var lv: int = g.buildings.grill
	return 0.2 if lv >= 5 else (0.1 if lv >= 4 else 0.0)


func concert_mult() -> int:
	var lv: int = g.buildings.stage
	return 3 if lv >= 5 else (2 if lv >= 4 else 1)


# ================================================================== remix special materials
func remix_mats(b: String, diff: int, at: Vector3) -> String:
	if not GameData.REMIX_MAT.has(b):
		return ""
	var id: String = GameData.REMIX_MAT[b]
	var n: int = GameData.REMIX_MAT_N[clampi(diff, 0, 3)]
	for k in range(n):
		g.inventory.append(_item(id))
	g._burst(at + Vector3(0, 2.0, 0), [Color("d8a8ff"), Color.WHITE], 16)
	return "%s ×%d" % [GameData.ITEMS[id].name, n]


func _item(id: String) -> Dictionary:
	var it: Dictionary = GameData.ITEMS[id].duplicate()
	it["id"] = id
	return it


# ================================================================== per-frame
func update(dt: float) -> void:
	var t: float = g.time
	if g.world.has("rotor") and is_instance_valid(g.world.rotor):
		g.world.rotor.rotation.z += dt * 3.2
	if g.world.has("flame") and is_instance_valid(g.world.flame):
		g.world.flame.scale = Vector3(1.0, 1.0 + sin(t * 9.0) * 0.12 + sin(t * 23.0) * 0.06, 1.0)
	if party.size() > 0:
		var bob := maxf(0.0, 0.12 - minf(g.beat_phase(), 1.0 - g.beat_phase()) * 0.45)
		for n in party:
			if not is_instance_valid(n.node):
				continue
			if n.has("bulb"):
				n.node.visible = int(t * 3.0 + n.base.x) % 3 != 0
				continue
			n.node.position = n.base + Vector3(0, bob * 0.9, 0)
			for a in n.arms:
				a.rotation.x = -2.6 if bob > 0.05 else -0.3


# ================================================================== the mount skin
func create_cart() -> Dictionary:
	var c := Mobs09.ride_cart()
	g.world.root.add_child(c.root)
	Kit.bake_tree(c.root)
	c.root.position = g.pos
	c["phase"] = 0.0
	c["cart"] = true
	return c


func animate_cart(dt: float, spd: float, beat_bob: float) -> void:
	var c: Dictionary = g.mount_vis
	c.phase += dt * 10.0 * spd
	c.root.position = g.pos + Vector3(0, beat_bob * 0.6, 0)
	c.root.rotation.y = g.facing
	c.root.rotation.z = sin(c.phase * 0.5) * 0.03 * minf(1.0, spd)
	for w in c.wheels:
		w.rotation.x += dt * 14.0 * spd
	c.prop.rotation.z += dt * (6.0 + 30.0 * spd)
	g.hero.root.position = g.pos + Vector3(0, float(c.floor) + beat_bob * 0.6, 0.0)
	g.hero.legs[0].rotation.x = 0.1
	g.hero.legs[1].rotation.x = -0.1
	g.hero.arms[0].rotation.x = -1.2
	g.hero.arms[1].rotation.x = -1.2
	g.hero.body.position.y = 0.0
	g.hero.body.rotation.x = 0.12


# ================================================================== the new mobs
const MOB_KINDS := ["rat", "fridge", "mattress", "king"]


func model(kind: String) -> Dictionary:
	match kind:
		"rat": return Mobs09.rat()
		"fridge": return Mobs09.fridge()
		"mattress": return Mobs09.mattress()
		"king": return Mobs09.king()
	return Mobs09.rat()


func setup_mob(m: Dictionary) -> void:
	m["loot_coins"] = 0
	m["flee_t"] = 0.0
	match m.kind:
		"king":
			m.special = 4.0
			m.whisper_t = 3.0
			m.fly_t = 0.0
			m.pull_cd = 7.0
			m["press_rows"] = 0
			m["hit_done"] = false
		"fridge":
			m.special = 3.0


func chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	var reach: float = m.radius + 0.9
	var dir := to_p.normalized() if dp > 0.01 else Vector3.FORWARD
	match m.kind:
		"rat":
			if m.flee_t > 0.0:
				# runs away with the coins; catch it — they come back twice
				m.flee_t -= dt
				var away := -dir
				m.yaw = lerp_angle(m.yaw, atan2(away.x, away.z), minf(1.0, dt * 10))
				spd = 7.2
				m.pos += away * spd * dt
				return spd
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 10))
			if dp > reach:
				spd = m.speed
				m.pos += dir * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				g.hurt_player(m.dmg * randf_range(0.9, 1.1), m.pos)
				var take := mini(g.coins, 6 + int(m.lvl) / 2)
				if take > 0:
					g.coins -= take
					m.loot_coins = int(m.loot_coins) + take
					g.hud.float_text(g.pos + Vector3(0, 3.1, 0), "Коллектор: -%d монет! Догони!" % take, Color("ffd27a"), 20, 40)
				m.flee_t = 3.2
		"fridge":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 3))
			m.special -= dt
			if m.charge_t > 0.0:
				# the frost breath: a cone in front — slows and nibbles
				m.charge_t -= dt
				m.extra.frost.visible = true
				var fwd := Vector3(sin(m.yaw), 0, cos(m.yaw))
				if dp < 5.2 and fwd.dot(dir) > 0.55:
					g.slow_t = maxf(g.slow_t, 1.6)
					m.whisper_t -= dt
					if m.whisper_t <= 0.0:
						m.whisper_t = 0.45
						g.hurt_player(m.dmg * 0.35, m.pos)
				if m.charge_t <= 0.0:
					m.extra.frost.visible = false
				return 0.0
			if m.special <= 0.0 and dp < 5.0:
				m.special = 5.5
				m.charge_t = 1.4
				m.whisper_t = 0.2
				m.flap = 1.4
				g.hud.float_text(m.pos + Vector3(0, 2.8, 0), "ХОЛОДОК!", Color("bfe8ff"), 24, 40)
				g.play_sfx("near", 0.5, -6.0)
			elif dp > reach:
				spd = m.speed
				m.pos += dir * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				m.flap = 0.4
				g.hurt_player(m.dmg * randf_range(0.9, 1.15), m.pos)
				g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "КУСЬ!", Color("e8f8ff"), 22, 40)
		"mattress":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 7.5 * dt
				if m.charge_t <= 0.0:
					g._ring_fx(m.pos + Vector3(0, 0.1, 0), Color("8ad8ff"), 2.6, 0.35)
					var hd := Vector2(g.pos.x - m.pos.x, g.pos.z - m.pos.z)
					if hd.length() < 2.4:
						g.hurt_player(m.dmg * randf_range(0.95, 1.2), m.pos)
						g.pull_v = Vector3(hd.x, 0, hd.y).normalized() * 6.0
						g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "БОИНГ!", Color("8ad8ff"), 24, 40)
				return 7.5
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 5))
			if m.atk_cd <= 0.0 and dp < 8.0:
				m.atk_cd = m.atk
				m.charge_dir = dir
				m.charge_t = clampf(dp / 7.5, 0.3, 0.85)
				g.play_sfx("jump", 0.7, -6.0)
			elif dp > 3.0:
				spd = m.speed * 0.7
				m.pos += dir * spd * dt
		"king":
			return _king_chase(m, dt, to_p, dp)
	return spd


func animate(m: Dictionary, dt: float, spd: float) -> void:
	var t: float = g.time
	match m.kind:
		"rat":
			var k := minf(1.0, spd / 3.0)
			for i in range(m.wheels.size()):
				m.wheels[i].rotation.x = sin(t * 26.0 + i * 1.6) * 0.6 * k
			m.body.position.y = absf(sin(t * 22.0)) * 0.05 * k
			m.wings[0].rotation.y = sin(t * 8.0 + m.home.x) * 0.4
			m.head.rotation.x = sin(t * 5.0) * 0.08
		"fridge":
			var open := 0.0
			if m.charge_t > 0.0:
				open = 0.9
			elif m.flap > 0.0:
				open = 0.7 * sin(m.flap / 0.4 * PI)
			m.head.rotation.y = -open
			m.body.rotation.z = sin(t * 6.0 + m.home.x) * 0.05 * minf(1.0, spd)
			m.body.position.y = absf(sin(t * 6.0)) * 0.06 * minf(1.0, spd)
		"mattress":
			var hop := 0.0
			if m.charge_t > 0.0:
				hop = 1.6 * sin(clampf(m.charge_t / 0.85, 0.0, 1.0) * PI)
			else:
				hop = absf(sin(t * 5.0 + m.home.z)) * 0.15
			m.body.position.y = hop
			var squash := 0.7 if hop < 0.08 and m.charge_t <= 0.0 else 1.25
			for s in m.wheels:
				s.scale = Vector3(1.0, squash, 1.0)
			m.body.rotation.x = -0.15 if m.charge_t > 0.0 else 0.0
		"king":
			var drive: bool = m.charge_t > 0.0
			for w in m.wheels:
				w.rotation.x += dt * (12.0 if drive else spd * 2.0)
			var alarm: bool = m.loading > 0.0 or drive
			for i in range(m.extra.beacons.size()):
				m.extra.beacons[i].visible = (not alarm) or int(t * 8.0 + i) % 2 == 0
			m.extra.press.rotation.x = lerpf(m.extra.press.rotation.x, -0.9 if m.shield else 0.0, minf(1.0, dt * 4.0))
			for f in m.wings:
				f.rotation.x = -0.9 if m.flap > 0.0 else sin(t * 2.0) * 0.08
			m.extra.crown.position.y = 1.5 + absf(sin(t * PI / g.beat_len)) * 0.12
			m.extra.smoke.scale = Vector3.ONE * (0.7 + fposmod(t * 1.5, 1.0) * (1.2 if drive else 0.6))
			m.body.position.y = (sin(t * 40.0) * 0.05) if m.loading > 0.0 else 0.0


func dead_anim(m: Dictionary, dt: float) -> bool:
	if m.kind != "king":
		return false
	# the King drives away backwards, beeping
	var back := Vector3(-sin(m.yaw), 0, -cos(m.yaw))
	if m.dead_t < 3.0:
		m.pos += back * 3.0 * dt
		m.node.position = m.pos
		for w in m.wheels:
			w.rotation.x -= dt * 8.0
		for b in m.extra.beacons:
			b.visible = int(g.time * 8.0) % 2 == 0
	else:
		m.node.visible = false
	g._remix_after(m)
	return true


func on_kill(m: Dictionary) -> void:
	if m.kind == "rat" and int(m.get("loot_coins", 0)) > 0:
		var back: int = int(m.loot_coins) * 2
		g.coins += back
		g.hud.float_text(m.pos + Vector3(0, 2.2, 0), "Возврат с процентами! +%d" % back, Hud.GOLD, 24, 40)
		m.loot_coins = 0
	if m.kind == "king":
		_clear_lane()
		for o in g.mobs:
			if o.alive and o.temp and o.kind in ["rat", "bag"]:
				o.alive = false
				o.node.visible = false
		if int(m.remix) == 0:
			g.hud.float_text(m.pos + Vector3(0, 6.5, 0), "Би-би-би… Задний ход… Корона — ваша…", Color("c8f0d0"), 24, 30)
			g.hud.big("КОРОЛЬ ХЛАМА УЕХАЛ ЗАДНИМ ХОДОМ!", "Утилизация отменяется! Вернись к Деду Утилю", 4.5)
			g.save_game()


func loot(m: Dictionary) -> Array:
	if m.kind != "king":
		return []
	g.coins += 1000
	var d := ["press_gauntlets"]
	if randf() < 0.6:
		d.append(["junk_crown", "tarp_cape"][randi() % 2])
	return d


func on_damage(m: Dictionary, dmg: float, _crit: bool) -> float:
	if m.kind == "king" and m.shield:
		if randf() < 0.3:
			g.hud.float_text(m.pos + Vector3(0, 6.2, 0), "УТРАМБОВКА! урон -92%", Color("c8d0e8"), 20, 40)
		return dmg * 0.08
	return dmg


## «Кеша взламывает пресс»: combo ×8 on the beat breaks the King's compactor shield.
func beat(ok: bool) -> void:
	for m in g.mobs:
		if m.alive and m.kind == "king" and m.shield and m.pos.distance_to(g.pos) < 28.0:
			if ok:
				if g.combo >= 8:
					m.shield = false
					m.stun = 4.0
					m.fly_t = 16.0
					g.hud.big("ВЗЛОМАНО!", "Кеша отключил пресс — Король завис на 4 секунды. Бей!", 2.5)
					g._ring_fx(m.pos + Vector3(0, 0.3, 0), Kit.TEAL, 6.0, 0.5)
					g.play_sfx("smash", 1.2, -2.0)
				else:
					g.hud.float_text(g.pos + Vector3(0, 3.4, 0), "Взлом: %d/8" % g.combo, Kit.TEAL, 22, 40)
			else:
				g.hud.float_text(m.pos + Vector3(0, 6.2, 0), "Сбой взлома! Комбо заново", Color("9ad8ff"), 20, 40)


func cam_extra(m: Dictionary) -> float:
	return 5.0 if m.kind == "king" else 0.0


# ------------------------------------------------------------------ Король Хлама
func _king_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var f: float = m.hp / m.hp_max
	var rm := int(m.remix) > 0
	var home: Vector3 = m.home
	if m.phase == 0 and f < 0.7:
		m.phase = 1
		_summon(m, 2, 1)
	if m.phase == 1 and f < 0.5:
		m.phase = 2
		_press(m)
	if m.phase == 2 and f < 0.3:
		m.phase = 3
		_summon(m, 3, 1)
	var spd := 0.0
	# the press «Утрамбовка»: the shield is up, the hero is dragged towards the back of the truck
	if m.shield:
		m.shield_t -= dt
		m.hp = minf(m.hp_max, m.hp + m.hp_max * 0.006 * dt)
		var back: Vector3 = m.pos - Vector3(sin(m.yaw), 0, cos(m.yaw)) * 4.6
		var to_back := Vector3(back.x - g.pos.x, 0, back.z - g.pos.z)
		if to_back.length() > 1.5 and to_back.length() < 16.0 and g.invuln <= 0.0:
			g.pull_v = g.pull_v.lerp(to_back.normalized() * (4.6 if rm else 3.4), minf(1.0, dt * 3.0))
		if to_back.length() < 2.2:
			m.whisper_t = minf(m.whisper_t, 0.6)
		if m.shield_t <= 0.0:
			m.shield = false
			m.fly_t = 16.0
			g.hud.toast("Утрамбовка кончилась — Король подлечился", Color("9ad8ff"))
	elif m.phase >= 2:
		m.fly_t -= dt
		if m.fly_t <= 0.0:
			_press(m)
	if m.loading > 0.0:
		# aiming: the lane is on the ground, beep-beep
		m.loading -= dt
		m.yaw = lerp_angle(m.yaw, atan2(m.charge_dir.x, m.charge_dir.z), minf(1.0, dt * 8.0))
		if m.loading <= 0.0:
			m.charge_t = 2.2
			m.hit_done = false
			g.play_sfx("dash", 0.6, -2.0)
		return 0.0
	if m.charge_t > 0.0:
		m.charge_t -= dt
		var sp := 17.0 if rm else 15.0
		m.pos += m.charge_dir * sp * dt
		var dh := Vector2(g.pos.x - m.pos.x, g.pos.z - m.pos.z)
		if not m.hit_done and dh.length() < m.radius + 1.0:
			m.hit_done = true
			g.hurt_player(m.dmg * 1.5, m.pos)
			var side := Vector3(m.charge_dir.z, 0, -m.charge_dir.x)
			if side.dot(Vector3(dh.x, 0, dh.y)) < 0.0:
				side = -side
			g.pull_v = (m.charge_dir * 0.6 + side).normalized() * 11.0
			g.hud.float_text(g.pos + Vector3(0, 2.9, 0), "БИБИ-БАМ!", Color("ffb07a"), 26, 40)
		var out: Vector3 = m.pos - home
		out.y = 0
		if out.length() > Dump.ARENA_R - 1.6 or m.charge_t <= 0.0:
			m.charge_t = 0.0
			_clear_lane()
			if out.length() > Dump.ARENA_R - 1.6:
				m.pos = home + out.normalized() * (Dump.ARENA_R - 1.6)
				m.stun = 2.6
				g.hud.float_text(m.pos + Vector3(0, 6.0, 0), "ВРЕЗАЛСЯ В ГОРУ ХЛАМА!", Color("ffd8a0"), 26, 40)
				g._ring_fx(m.pos + Vector3(0, 0.2, 0), Color("ffd8a0"), 4.0, 0.4)
				g.play_sfx("smash", 0.5, -2.0)
		return sp
	# between moves: turn to the hero, roll closer, bite with the forks
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 1.6))
	if dp > 7.0 and m.pos.distance_to(home) < Dump.ARENA_R - 3.0:
		spd = m.speed
		m.pos += to_p.normalized() * spd * dt
	if dp < m.radius + 1.6 and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.5
		g.hurt_player(m.dmg * randf_range(0.9, 1.1), m.pos)
		g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "Хрусть вилами!", Color("ffb07a"), 22, 40)
	m.whisper_t -= dt
	if m.whisper_t <= 0.0 and dp < 26.0:
		m.whisper_t = 3.4 if rm else 4.6
		var n := 5 if rm else 3
		for k in range(n):
			var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-4.0, 4.0), 0, randf_range(-4.0, 4.0))
			g._add_trap(g.pos + off, 1.7, 1.3, m.dmg * 1.1)
		g.hud.float_text(m.pos + Vector3(0, 6.0, 0), "МУСОРНЫЙ ЗАЛП!", Color("ffd8a0"), 26, 40)
	if not m.shield:
		m.special -= dt
		if m.special <= 0.0 and dp < 30.0:
			m.special = 4.6 if rm else 6.0
			if rm:
				m.press_rows = int(m.press_rows) + 1
			if rm and int(m.press_rows) % 2 == 0:
				_press_rows(m)
			else:
				var d := Vector3(g.pos.x - m.pos.x, 0, g.pos.z - m.pos.z)
				m.charge_dir = d.normalized() if d.length() > 0.1 else Vector3(sin(m.yaw), 0, cos(m.yaw))
				m.loading = 1.0 if rm else 1.25
				_make_lane(m)
				g.hud.float_text(m.pos + Vector3(0, 6.2, 0), "БИП-БИП! ПОЕХАЛИ!", Color("ff8a6a"), 26, 40)
	return spd


func _press(m: Dictionary) -> void:
	m.shield = true
	m.shield_t = 9.0
	g.hud.big("«УТРАМБОВКА»!", "Пресс тянет к себе · комбо ×8 в бит — Кеша взломает пресс", 3.5)
	g.play_sfx("laser", 0.5)


func _summon(m: Dictionary, rats: int, bags: int) -> void:
	for k in range(rats + bags):
		var a := k * TAU / float(rats + bags) + 0.4
		var p: Vector3 = m.home + Vector3(sin(a) * 7.0, 0, cos(a) * 7.0)
		var s: Dictionary = g._spawn_mob("rat" if k < rats else "bag", p, maxi(17, int(m.lvl) - 3))
		s.st = "chase"
		s.temp = true
	g.hud.toast("Король Хлама: «Коллекторы, на выход!»", Color("ffd8a0"))


## Remix «Генеральная уборка»: press walls from three sides — three rows of red circles converge on the hero
func _press_rows(m: Dictionary) -> void:
	var base_a := randf() * TAU
	for r in range(3):
		var a := base_a + r * TAU / 3.0
		var d := Vector3(sin(a), 0, cos(a))
		for k in range(4):
			g._add_trap(g.pos + d * (7.5 - k * 2.0), 1.5, 0.9 + k * 0.25, m.dmg * 1.0)
	g.hud.float_text(m.pos + Vector3(0, 6.4, 0), "ПРЕСС С ТРЁХ СТОРОН!", Color("ff8a6a"), 26, 40)


func _make_lane(m: Dictionary) -> void:
	_clear_lane()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.25, 0.2, 0.38)
	lane = Node3D.new()
	g.fx_root.add_child(lane)
	var length := Dump.ARENA_R * 2.0
	Kit.part(lane, Kit.BOX, mat, Vector3(m.radius * 2.0, 0.02, length), Vector3(0, 0.08, length / 2.0))
	lane.position = m.pos
	lane.rotation.y = atan2(m.charge_dir.x, m.charge_dir.z)


func _clear_lane() -> void:
	if lane != null and is_instance_valid(lane):
		lane.queue_free()
	lane = null
