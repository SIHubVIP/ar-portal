class_name U08
extends RefCounted
## 0.8 «Мыльная опера»: the story «Мыльная опера» (quest7), the Чебуречная and the Прачечная, the medics of «Отлично-03»,
## Бог Здорово (benches, blessings, Благодать, Дары, «Второе дыхание»), the neighbours as guests all over the story,
## the AI of the new mobs and the bosses Тесто Вечности and Барабан Судьбы.

var g   # main game

# guests: the neighbours (and old friends) come to the new places as the story goes on
# [id, map, pos, rot, condition, lines]
const GUESTS := [
	["pavlin", "park", Vector3(-19.0, 0, -1.5), 0.8, "dawn", ["Поляна снова зелёная! Газонокосилки теперь стригут ровно — я им дал тактику.",
		"Здесь мой второй газон. Первый — во дворе. Разрываюсь, как мяч между воротами."]],
	["jack", "park", Vector3(15.5, 0, 9.6), -1.2, "dawn", ["Видишь флаг на колесе? Это наш двор. Со страховкой!", "С колеса видно телебашню. Там что-то мигает. Кощеево."]],
	["klyukva", "park", Vector3(4.6, 0, 15.6), PI, "dawn", ["Пост у летней сцены. Охраняю рассвет: три процента, зато наши!", "Отставить тишину в парке!"]],
	["yarik", "park", Vector3(-4.6, 0, 16.6), 0.5, "dawn", ["Рассвет на три процента. А я свечусь на три процента ярче!", "Здесь пела Жар-птица. Я чувствую: внутри что-то тёплое."]],
	["chef", "cheburek", Vector3(-10.6, 0, -3.4), 0.7, "q7", ["Сссудить кулинарные дуэли — моё призвание. Есть — тоже призвание.", "Чебурек — это шаурма, которая решила быть круглой."]],
	["lis", "cheburek", Vector3(12.0, 0, 1.2), -1.6, "q7", ["Санузел? Я туда не пойду. Я туда даже смотреть не буду.", "Санинспекция снаружи — это тоже санинспекция."]],
	["pilot", "cheburek", Vector3(8.4, 0, 3.0), -2.6, "q7", ["Чебурек — топливо, белок — крылья. Взлёт через пять минут.",
		"Аэротакси «Ложка» летает и от Чебуречной. От 170 монет: чем дальше, тем дороже — топливо нынче чебуречное."]],
	["maloy", "cheburek", Vector3(10.6, 0, -3.4), -2.2, "q7", ["Стрим «Чебуречная ASMR»: хруст в бит. Сорок три подписчика!", "Пельмень — лучший гость стрима. Он разговаривает!"]],
	["gorynych", "cheburek", Vector3(-23.0, 0, 15.0), 0.7, "q7", ["Средняя голова: «Чебурек». Левая: «Два чебурека». Правая: «Я на диете… три чебурека».",
		"Три головы — три чебурека. Это не жадность, это арифметика."]],
	["lyuba", "cheburek", Vector3(-3.4, 0, -2.8), 0.3, "duel", ["Тётя Сочня — женщина с характером. Я тоже. Поэтому и дружим.", "Мой соус — к её чебурекам. Фьюжн!"]],
	["osob", "cheburek", Vector3(10.6, 0, 11.4), 2.4, "q7", ["Пульс в бит — значит, живой. Не в бит — значит, танцевать не умеешь. Тоже лечим!",
		"Скорая «Отлично-03» на месте. Диагноз району — отлично!"]],
	["lis", "laundry", Vector3(-8.6, 0, 3.6), 0.9, "laundry", ["Прачечная «Ромашка» — я о ней мечтал! Ряды стиралок, строгий ресепшен — красота.",
		"Мыльная опера — это когда мыло главное."]],
	["zina", "laundry", Vector3(21.6, 0, -15.8), 0.2, "laundry", ["Я сорок лет детективы смотрела. Я готова!", "В кадре я бабушка-детектив. В жизни — тоже, между прочим."]],
	["maloy", "laundry", Vector3(10.6, 0, -11.6), 0.6, "laundry", ["Стрим со съёмок «Отжима»! Сорок пять подписчиков. Это кино!", "Если в кадре пена — это не баг, это атмосфера."]],
	["kent", "laundry", Vector3(-8.8, 0, 10.4), 1.6, "laundry", ["Очередь к Тамаре — как лобби в игре. Жду матч.", "Мой талончик — №37. Это мой ранг."]],
]

var bench_node := {}
var god := {}            # the face in the sky: {"node", "t", "life"}
var premiere: Array = []  # neighbours in the premiere seats (dancing decor)
var greet_flash := 0.0


func _init(game) -> void:
	g = game


# ================================================================== save
func reset() -> void:
	g.quest7 = 0
	g.kits = 0
	g.grace = 0
	g.gifts = {"hp": 0, "luck": 0, "beat": 0, "qxp": 0}
	g.blessing = {"day": "", "kind": ""}
	g.medics = false
	g.fusion = false
	g.wind_day = ""


func to_save() -> Dictionary:
	return {"quest7": g.quest7, "kits": g.kits, "grace": g.grace, "gifts": g.gifts, "blessing": g.blessing, "medics": g.medics, "fusion": g.fusion,
		"wind_day": g.wind_day}


func load_from(d: Dictionary) -> void:
	reset()
	g.quest7 = int(d.get("quest7", 0))
	g.kits = int(d.get("kits", 0))
	g.grace = int(d.get("grace", 0))
	var gf = d.get("gifts", {})
	if gf is Dictionary:
		for k in g.gifts:
			g.gifts[k] = clampi(int(gf.get(k, 0)), 0, int(GameData.GIFTS[k][2]))
	var bl = d.get("blessing", {})
	if bl is Dictionary:
		g.blessing = {"day": str(bl.get("day", "")), "kind": str(bl.get("kind", ""))}
	g.medics = bool(d.get("medics", false))
	g.fusion = bool(d.get("fusion", false))
	g.wind_day = str(d.get("wind_day", ""))


# ================================================================== small helpers for the main game
func today() -> String:
	return Time.get_date_string_from_system()


func blessed(kind: String) -> bool:
	return g.blessing.kind == kind and g.blessing.day == today()


func god_open() -> bool:
	return g.quest7 >= 6


func luck_bonus() -> int:
	return int(g.gifts.luck) * 2 + (10 if blessed("luck") else 0)


func beat_bonus() -> float:
	return int(g.gifts.beat) * 0.01 + (0.02 if blessed("ear") else 0.0)


func hp_mult() -> float:
	return 1.0 + int(g.gifts.hp) * 0.02


func speed_mult() -> float:
	return (1.1 if blessed("cheer") else 1.0) * (0.55 if g.slow_t > 0.0 else 1.0) * (1.1 if g.fusion_t > 0.0 else 1.0)


func xp_mult() -> float:
	return 1.15 if blessed("xp") else 1.0


func quest_xp(v: int) -> int:
	return int(round(v * (1.0 + int(g.gifts.qxp) * 0.05)))


func aggro_mult() -> float:
	return 0.7 if blessed("kind") else 1.0


func food_heal() -> float:
	return (0.6 if blessed("appetite") else 0.4) + g.u09.food_bonus()


func neighbours_count() -> int:
	var n := 0
	for id in SideQ.NPCS:
		if SideQ.NPCS[id].get("neighbour", false):
			n += 1
	return n


# ================================================================== the story «Мыльная опера» (quest7)
## quest7: 0 — not started (after the park), 1 — go to the Чебуречная, 2 — the Чебуречная chain, 3 — go to the Прачечная,
## 4 — the Прачечная chain, 5 — sit on a Скамейка Здорово, 6 — bring the box office to Мыслитель Зари, 7 — done
func main_lines() -> Array:
	match g.quest7:
		0:
			return ["Часть 2 · «Мыльная опера»", "Мыслитель Зари на набережной знает, как выкупить парк", "Он у западной скамейки"]
		1:
			return ["Мыльная опера", "Иди в Чебуречную «Сочная»", "Двор → западная калитка (трамвай)"]
		2:
			return ["Мыльная опера", "Чебуречная: " + _chain_line(["who_left", "toilet", "duel", "inside", "dough_q"]), "Задания тёти Сочни, Пельменя и Вентилёва"]
		3:
			return ["Мыльная опера", "Иди в Прачечную «Ромашка»", "Двор → восточная калитка"]
		4:
			return ["Мыльная опера", "Прачечная: " + _chain_line(["ticket", "stunt", "star", "forget"]), "Задания Тамары и режиссёра Дубля Дублевича"]
		5:
			return ["Мыльная опера", "Посиди на Скамейке Здорово", "Во дворе у бабы Зины — скамейка с золотой аркой"]
		6:
			return ["Мыльная опера", "Отнеси кассу Мыслителю Зари", "Набережная, у западной скамейки"]
	return ["Часть 2 · акт 2 пройден", "Касса выкупа растёт · продолжение в 0.9", "Скамейки Здорово, медики и ремиксы — уже с тобой"]


func _chain_line(ids: Array) -> String:
	for q in ids:
		if not g.side.is_done(q):
			var qd: Dictionary = SideQ.QUESTS[q]
			if g.side.is_active(q):
				return "«%s» — %s" % [qd.title, g.side._short(q)]
			return "«%s» — %s" % [qd.title, g.side.npc_name(qd.npc)]
	return "всё сделано"


func zari_marker() -> String:
	if g.quest6 >= 7 and g.quest7 == 0:
		return "!"
	if g.quest7 == 6:
		return "?"
	return ""


## Мыслитель Зари starts and ends «Мыльная опера». Returns true when he spoke about it.
func zari_talk() -> bool:
	var close := func(): g.close_dialog()
	if g.quest6 >= 7 and g.quest7 == 0:
		g.open_dialog("Мыслитель Зари", "Миллион за парк… Кощей думает, что район не умеет складываться. Умеет! Начнём с Чебуречной «Сочная»: тётя Сочня жарит лучшие чебуреки района и отдаст выручку на выкуп. Только у неё беда — третий день на тарелке лежит недоеденный пельмень. И разговаривает.", [
			["Пельмень разговаривает?!", func():
				g.hud.show_dialog("Мыслитель Зари", "Шестьсот лет живу — разговаривающих пельменей не встречал. Хотя нет, встречал. Тоже у Кощея. Иди через западную калитку двора, к трамваю. А потом — Прачечная: там сериал снимают, премьера пойдёт на выкуп.", [
					["Иду в Чебуречную! (задание «Мыльная опера»)", func():
						g.quest7 = 1
						g.hud.toast("Новое задание: «Мыльная опера» — Чебуречная «Сочная»", Hud.GOLD)
						g.play_sfx("bank")
						g.save_game()
						close.call()]])]])
		return true
	if g.quest7 >= 1 and g.quest7 <= 5:
		var t: String = ["", "Чебуречная — через западную калитку двора, где трамвай. Пельмень ждёт. Он вообще терпеливый.",
			"Тётя Сочня, Пельмень, Вентилёв… Чебуречная — это целая сказка. С соусом.",
			"Прачечная «Ромашка» — через восточную калитку двора. Там снимают сериал. Мыльная опера — опера, где мыло главное.",
			"Премьера — это касса. Касса — это парк. Не дай Кощею её отстирать.",
			"Бог Здорово сказал «Здорово!» всему району? Посиди на скамейке с золотой аркой — он любит, когда отдыхают."][g.quest7]
		g.open_dialog("Мыслитель Зари", t, [["Понял!", close]])
		return true
	if g.quest7 == 6:
		g.open_dialog("Мыслитель Зари", "Касса! Чебуречная, Прачечная, премьера… и каждый сосед добавил от себя. Смотри, сколько набралось.", [
			["Показать кассу выкупа", func(): _box_office()]])
		return true
	return false


func _box_office() -> void:
	var lines := ["Тётя Сочня — выручка дня: 31 000", "Премьера «Отжима» — сбор: 154 000", "Павлин Футболист — призовые за «Матч века»: 4 000",
		"Невысокий Лис — гонорар консультанта по чистоте: 2 500", "Шустрый Пилот — аэротакси «Ложка», неделя полётов: 7 000",
		"Кент Организатор — турнир в гараже: 5 000", "Джек Скалолаз — «копилка со страховкой»: 900", "Товарищ Клюква — премия «За ритм»: 3 000",
		"Щебень Не Атлет — «камни для альпийской горки»: 1 200", "Мистер Малой — донаты стрима: 48", "Меткий Змей — уха по-фьюжн: 6 000",
		"Молодой Мельник — квас на премьере: 8 000", "Ярик-Фонарик — подсветка зала: бесплатно (от души)", "Мыслитель Зари — «то, что лежало там, где никто не искал»: 21 000"]
	g.hud.show_dialog("Касса выкупа парка «Заря»", "\n".join(lines) + "\n\nИтого: 244 648 из 1 000 000. Почти четверть!", [
		["Это же почти четверть! (+1500 монет, +3000 опыта)", func(): _finish_q7()]])


func _finish_q7() -> void:
	if g.quest7 != 6:
		return
	g.quest7 = 7
	g.coins += 1500
	g.gain_xp(3000)
	g.hud.big("АКТ 2 ЧАСТИ 2 ПРОЙДЕН!", "«Мыльная опера» — касса выкупа: почти четверть миллиона", 5.0)
	g._notes_fx(g.pos + Vector3(0, 2, 0), Kit.GOLD)
	g.play_sfx("bank")
	g.save_game()
	g.open_dialog("Кощей (по громкоговорителю)", "Алло, район. Опять Кощей. Двести сорок четыре тысячи? Мило. Цена выросла: инфляция бессмертия, налог на рассвет и… короче, теперь полтора миллиона. И да, пельмень был мой. Доем при случае.", [
		["Полтора?!", func():
			g.hud.show_dialog("Мыслитель Зари", "Пусть растёт. Мы растём быстрее. Следующий шаг — Помойка: там живут два изобретателя, у них идеи дороже денег. А Пельмень пусть сидит у кассы — он теперь свидетель обвинения.", [
				["Дальше — Помойка! (продолжение — в 0.9)", func(): g.close_dialog()]])]])


## Unlocks from quest rewards (SideRun.complete → main.unlock → here).
func unlock(kind: String) -> void:
	match kind:
		"fusion":
			g.fusion = true
			g.hud.toast("Рецепт «Чебурек-фьюжн»: шаурма теперь ещё и разгоняет (+10% к скорости на 20 с)", Hud.GOLD)
		"medics":
			g.medics = true
			g.kits += 3
			g.hud.toast("Медпункт «Отлично-03» открыт: возрождение у скорой · «Отличные аптечки» ×3", Hud.GOLD)
		"q7_cheb":
			if g.quest7 <= 2:
				g.quest7 = 3
				g.get_tree().create_timer(4.2).timeout.connect(func():
					if g.is_playing():
						g.open_dialog("Тётя Сочня", "Ну, раз тесто побеждено — вся выручка недели на выкуп парка! А ещё говорят, в Прачечной «Ромашка» сериал снимают. Премьера будет платная — тоже на парк. Беги туда: через восточную калитку двора.", [
							["В Прачечную! («Мыльная опера»)", func(): g.close_dialog()]]))
				g.hud.toast("«Мыльная опера»: открыта Прачечная «Ромашка» — восточная калитка двора", Hud.GOLD)
		"q7_laundry":
			if g.quest7 <= 4:
				g.quest7 = 5
				g.get_tree().create_timer(3.0).timeout.connect(func(): god_event())


## Бог Здорово appears in the sky over the Прачечная after the premiere.
func god_event() -> void:
	if not g.world.has("root") or not g.is_playing():
		g.get_tree().create_timer(2.0).timeout.connect(func(): god_event())
		return
	show_god(g.pos + Vector3(0, 0, -6), 14.0)
	g.play_sfx("bank", 0.8)
	g.open_dialog("Бог Здорово", "ЗДОРОВО, РОДНОЙ! Здорово сняли! Я даже всплакнул — дождиком над всем районом. Я Бог Здорово: здоровья, приветствий и хорошего настроения. Моя сила растёт, когда люди здороваются и живут здорово.", [
		["Здорово! А что мне делать?", func():
			g.hud.show_dialog("Бог Здорово", "Отдыхать, родной! По району стоят мои Скамейки Здорово — с золотой аркой. Посиди на любой: подлечу, сохраню, а первое «Здорово!» за день — благословение на весь день. Начни с той, что во дворе у бабы Зины.", [
				["Посижу! («Мыльная опера»)", func():
					g.hud.toast("«Мыльная опера»: посиди на Скамейке Здорово", Hud.GOLD)
					g.close_dialog()]])]])


func show_god(at: Vector3, life: float) -> void:
	if not god.is_empty() and is_instance_valid(god.node):
		god.node.queue_free()
	var f := Mobs08.god_face()
	g.world.root.add_child(f.root)
	var dir := Vector3(sin(g.yaw), 0, cos(g.yaw))
	f.root.position = Vector3(g.pos.x, 0, g.pos.z) - dir * 30.0 + Vector3(0, 17.0, 0)
	f.root.rotation.y = g.yaw
	f.root.scale = Vector3.ONE * 0.1
	Kit.bake_tree(f.root)
	god = {"node": f.root, "halo": f.halo, "t": 0.0, "life": life}


# ================================================================== the maps: portals, the ambulance, benches, guests, the premiere
func on_enter_map(id: String) -> void:
	bench_node = {}
	premiere = []
	god = {}
	if id == "yard":
		var cg := World.gate("cheb")
		var lg := World.gate("laundry")
		if map_open_cheb():
			g.world.portals.append({"pos": cg, "r": 1.3, "to": "cheburek", "spawn": "from_yard", "label": "Чебуречная «Сочная» (трамвай)"})
			Chars.ring(g.world.root, cg + Vector3(0, 0.05, 0), 1.2, Color("ffb05a"), 0.08, 3.0)
			Chars.label(g.world.root, "ЧЕБУРЕЧНАЯ «СОЧНАЯ» ←", 70, Color(3.0, 2.2, 1.0), cg + Vector3(-1.0, 2.4, 0), Vector3(0, PI / 2, 0), 0.0075, 8)
		if map_open_laundry():
			g.world.portals.append({"pos": lg, "r": 1.3, "to": "laundry", "spawn": "from_yard", "label": "Прачечная «Ромашка»"})
			Chars.ring(g.world.root, lg + Vector3(0, 0.05, 0), 1.2, Color("8ad8ff"), 0.08, 3.0)
			Chars.label(g.world.root, "→ ПРАЧЕЧНАЯ «РОМАШКА»", 70, Color(2.4, 3.0, 3.6), lg + Vector3(1.0, 2.4, 0), Vector3(0, -PI / 2, 0), 0.0075, 8)
		g.world.spawns["from_cheburek"] = [cg + Vector3(2.4, 0, 0), PI / 2]
		g.world.spawns["from_laundry"] = [lg + Vector3(-2.4, 0, 0), -PI / 2]
		if g.side.is_done("toilet"):
			Mobs08.ambulance(g.world.root, Vector3(-14.4, 0, 6.8), PI)
			g.world.rects.append(Rect2(-15.6, 4.0, 2.4, 5.8))
	if id == "cheburek":
		Mobs08.ambulance(g.world.root, Vector3(13.2, 0, 13.8), PI / 2)
		g.world.rects.append(Rect2(10.4, 12.7, 5.6, 2.2))
		if g.quest7 == 1:
			g.quest7 = 2
			g.hud.big("ЧЕБУРЕЧНАЯ «СОЧНАЯ»", "Тётя Сочня за стойкой. Пельмень — на третьем столике. Он смотрит", 4.0)
			g.play_sfx("bank")
			g.save_game()
	if id == "laundry":
		if g.quest7 == 3:
			g.quest7 = 4
			g.hud.big("ПРАЧЕЧНАЯ «РОМАШКА»", "Сначала — к Тамаре на ресепшен. Без талончика никуда", 4.0)
			g.play_sfx("bank")
			g.save_game()
		if premiere_seated():
			_premiere_audience()
	_add_bench(id)
	_add_guests(id)


func map_open_cheb() -> bool:
	return g.quest7 >= 1


func map_open_laundry() -> bool:
	return g.quest7 >= 3


func npc_shown(id: String) -> bool:
	var sn: Dictionary = SideQ.NPCS[id]
	if sn.has("show"):
		for q in sn.show:
			if not g.side.is_done(q):
				return false
	return true


func npc_place(id: String) -> Array:
	var sn: Dictionary = SideQ.NPCS[id]
	if sn.has("moved") and g.side.is_done(str(sn.moved[0])):
		return [sn.moved[1], float(sn.moved[2])]
	return [sn.pos, float(sn.rot)]


func _guest_ok(cond: String) -> bool:
	match cond:
		"dawn":
			return g.quest6 >= 6
		"q7":
			return g.quest7 >= 1
		"duel":
			return g.side.is_done("duel") or g.side.is_active("duel")
		"laundry":
			return g.quest7 >= 3
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


## A guest has nothing about quests to say: one of his lines for this place.
func guest_line(n: Dictionary) -> void:
	var lines: Array = n.guest
	g.open_dialog(n.name, str(lines[randi() % lines.size()]), [["Здорово!", func(): g.close_dialog()]])


## Tamara has let the twelve neighbours in by their tickets (the first step of «Отстирать забвение»).
func premiere_seated() -> bool:
	if g.side.is_done("forget"):
		return true
	return g.side.is_active("forget") and int(g.side.st["forget"].s) >= 1


func _premiere_audience() -> void:
	var k := 0
	for id in SideQ.NPCS:
		if not SideQ.NPCS[id].get("neighbour", false) or k >= Laundry.SEATS.size():
			continue
		var h := Npcs.build(id)
		g.world.root.add_child(h.root)
		var p: Vector3 = Laundry.SEATS[k] + Vector3(0, 0.2, 0)
		h.root.position = p
		h.root.rotation.y = PI
		h.root.scale *= 0.85
		Kit.bake_tree(h.root)
		premiere.append({"node": h.root, "body": h.body, "arms": h.get("arms", []), "base": p, "ph": randf()})
		k += 1


func _add_bench(id: String) -> void:
	if not GameData.BENCHES.has(id):
		return
	var b: Array = GameData.BENCHES[id]
	var made := Mobs08.bench(g.world.root, b[0], float(b[1]), not bool(b[2]))
	Kit.bake_tree(made.node)
	if not bool(b[2]):
		var bp: Vector3 = b[0]
		g.world.rects.append(Rect2(bp.x - 1.15, bp.z - 0.35, 2.3, 0.7))
	bench_node = {"node": made.node, "glow": made.glow, "pos": b[0], "rot": float(b[1])}
	made.node.visible = god_open() or g.quest7 >= 5


func bench_front() -> Vector3:
	var rot: float = bench_node.rot
	return bench_node.pos + Vector3(sin(rot), 0, cos(rot)) * 1.2


# ================================================================== Скамейки Здорово: rest, blessing, Дары
func interactables() -> Array:
	var out := []
	if not bench_node.is_empty() and (god_open() or g.quest7 >= 5):
		out.append({"label": "Скамейка", "kind": "bench", "id": "bench", "pos": bench_front(), "r": 2.6})
	return out


func labels() -> Array:
	var out := []
	if not bench_node.is_empty() and (god_open() or g.quest7 >= 5):
		var t := "Скамейка Здорово"
		if g.blessing.day != today():
			t += " · «Здорово!» ждёт"
		out.append([bench_node.pos + Vector3(0, 3.2, 0), t, 16, Color("ffe08a")])
	return out


func bench() -> void:
	if g.quest7 == 5:
		g.quest7 = 6
		g.hud.big("СКАМЕЙКА ЗДОРОВО", "Бог Здорово доволен: отдыхать — тоже подвиг. Отнеси кассу Мыслителю Зари", 4.0)
		g.play_sfx("bank")
		g.save_game()
	g.hp = g.hp_max
	g.heal_left = 0.0
	g.silence_t = 0.0
	g.slow_t = 0.0
	g.save_game()
	g.open_list("bench")


func bench_list() -> void:
	var rows := []
	var fresh: bool = g.blessing.day != today()
	if fresh:
		rows.append({"text": "Сказать «Здорово!»", "sub": "Первое «Здорово!» за день — благословение Бога Здорово на весь день", "btn": "Здорово!", "enabled": true,
			"cb": func(): _bless(), "color": Hud.GOLD})
	else:
		var bd: Array = GameData.BLESSINGS[g.blessing.kind]
		rows.append({"text": "Благословение дня: %s" % bd[0], "sub": "%s · до конца дня. Завтра — новое «Здорово!»" % bd[1], "color": Hud.GOLD})
	rows.append({"text": "Благодать: %d" % g.grace, "sub": "Растёт от добрых дел: задания соседей +10, «здорово» жителям +1 (до %d в день), «Скажи «здорово»» +15" % GameData.GREET_MAX,
		"color": Color("ffe08a")})
	for k in GameData.GIFT_ORDER:
		var gd: Array = GameData.GIFTS[k]
		var lv := int(g.gifts[k])
		var maxed := lv >= int(gd[2])
		var cost := int(gd[3]) + int(gd[4]) * lv
		var key: String = k
		rows.append({"text": "Дар «%s» · %d/%d" % [gd[0], lv, int(gd[2])], "sub": "%s за уровень%s" % [gd[1], "" if maxed else " · цена: %d Благодати" % cost],
			"btn": "Готово" if maxed else "Взять", "enabled": not maxed and g.grace >= cost, "cb": func(): _gift(key), "color": Color("fff0c0")})
	rows.append({"text": "Посидеть", "sub": "Здоровье восстановлено, игра сохранена. «Лучшее лекарство — выспаться, поесть супа и сказать соседу «здорово»».",
		"color": Hud.CREAM})
	g.hud.show_list("СКАМЕЙКА ЗДОРОВО", "Бог Здорово ничего не продаёт: всё — за доброту и отдых", rows)


func _bless() -> void:
	var k: String = GameData.BLESSING_ORDER[randi() % GameData.BLESSING_ORDER.size()]
	g.blessing = {"day": today(), "kind": k}
	var bd: Array = GameData.BLESSINGS[k]
	g._recalc_power()
	g._recalc_stats()
	g.close_list()
	show_god(g.pos, 6.0)
	g.hud.big("ЗДОРОВО, РОДНОЙ!", "Благословение дня: %s — %s" % [bd[0], bd[1]], 4.0)
	g._notes_fx(g.pos + Vector3(0, 2, 0), Color("ffd23a"))
	g.play_sfx("bank", 1.1)
	g.save_game()


func _gift(k: String) -> void:
	var gd: Array = GameData.GIFTS[k]
	var lv := int(g.gifts[k])
	var cost := int(gd[3]) + int(gd[4]) * lv
	if lv >= int(gd[2]) or g.grace < cost:
		return
	g.grace -= cost
	g.gifts[k] = lv + 1
	g._recalc_power()
	g._recalc_stats()
	g.hud.toast("Дар «%s» · уровень %d" % [gd[0], lv + 1], Color("ffe08a"))
	g.play_sfx("pickup", 1.2)
	g.save_game()
	g._refresh_list()


## Every NPC the hero speaks to gets a «здорово» (once a day each) — after Бог Здорово appeared.
func greet(id: String) -> void:
	if not god_open():
		return
	var gl: Array = g.daily.get("greet", [])
	if id in gl:
		return
	gl.append(id)
	g.daily["greet"] = gl
	if gl.size() <= GameData.GREET_MAX:
		g.grace += 1
	if gl.size() == GameData.GREET_GOAL:
		g.grace += 15
		g.hud.big("«СКАЖИ «ЗДОРОВО»» — ВЫПОЛНЕНО!", "%d жителей сказали «здорово» в ответ · +15 Благодати" % GameData.GREET_GOAL, 3.0)
		g.play_sfx("bank", 1.2)
	elif gl.size() < GameData.GREET_GOAL:
		g.hud.toast("«Здорово!» · %d / %d · Благодать +1" % [gl.size(), GameData.GREET_GOAL], Color("ffe08a"))


## One compact tracker line: today's blessing, «Скажи «здорово»», the medics' kits.
func status_line() -> String:
	var p := []
	if g.blessing.day == today() and GameData.BLESSINGS.has(g.blessing.kind):
		p.append("Благословение «%s»" % GameData.BLESSINGS[g.blessing.kind][0])
	if god_open():
		var n: int = g.daily.get("greet", []).size()
		if n < GameData.GREET_GOAL:
			p.append("«здорово» %d/%d" % [n, GameData.GREET_GOAL])
	if g.kits > 0:
		p.append("аптечки ×%d" % g.kits)
	return " · ".join(p)


func side_quest_done() -> void:
	if god_open():
		g.grace += 10


# ================================================================== medics, kits, «Второе дыхание»
## Called from main._die: true when Бог Здорово catches the hero (once a day).
func second_wind() -> bool:
	if not god_open() or g.wind_day == today():
		return false
	g.wind_day = today()
	g.hp = g.hp_max * 0.5
	g.invuln = 2.0
	show_god(g.pos, 4.0)
	g.hud.big("НЕ СЕГОДНЯ, РОДНОЙ!", "Бог Здорово поймал тебя: «Второе дыхание» — раз в день", 3.0)
	g.play_sfx("bank", 0.9)
	return true


func dead_text() -> String:
	if g.medics:
		return "Скорая «Отлично-03» уже едет. Диагноз — отлично, лечение — ещё отличнее!"
	return "Баба Зина уже несёт валерьянку. Возвращаемся через пару секунд."


func on_respawn() -> void:
	if g.medics:
		if g.map_id == "yard":
			g.pos = Vector3(-11.6, 0, 7.0)
		g.hp = g.hp_max * 0.85
		g.hud.toast("Ты приходишь в себя у скорой «Отлично-03»: «Отлично подлечен!»", Color("ff9ad0"))


func update_kits(dt: float) -> void:
	g.kit_cd = maxf(0.0, g.kit_cd - dt)
	if g.kits > 0 and g.kit_cd <= 0.0 and g.is_playing() and g.hp < g.hp_max * 0.25 and g.hp > 0.0:
		g.kits -= 1
		g.kit_cd = GameData.KIT_CD
		g.heal_left += g.hp_max * GameData.KIT_HEAL
		g.silence_t = 0.0
		g.slow_t = 0.0
		g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "Отличная аптечка! Диагноз — отлично", Color("ff9ad0"), 22, 40)
		g.play_sfx("pickup", 1.3)


# ================================================================== rhythm steps of the quests
func start_quest_rhythm(q: String, game: String) -> void:
	var r: Dictionary = GameData.RHYTHM[game]
	g.close_dialog()
	g.start_rhythm({"kind": game, "title": r.title, "notes": r.notes, "lines": r.lines, "meter": r.meter, "big": r.title,
		"on_end": func(stars: int):
			if stars >= 1:
				g.hud.big("ПОЛУЧИЛОСЬ!", "%s · %s" % [r.title, ["", "неплохо", "хорошо", "идеально"][mini(stars, 3)]], 2.5)
				g.side.rhythm_done(q)
			elif stars == 0:
				g.hud.toast("Не попал в ритм — поговори ещё раз и попробуй снова", Hud.CREAM)})


# ================================================================== per-frame
func update(dt: float) -> void:
	update_kits(dt)
	greet_flash = maxf(0.0, greet_flash - dt)
	if not god.is_empty() and is_instance_valid(god.node):
		god.t += dt
		var k: float = god.t / god.life
		var sc := 3.4 * minf(1.0, god.t * 0.8) * (1.0 - maxf(0.0, (k - 0.85) / 0.15))
		god.node.scale = Vector3.ONE * maxf(0.05, sc)
		god.node.position.y = 17.0 + sin(god.t * 1.3) * 0.6
		god.halo.rotation.z += dt * 0.4
		if god.t >= god.life:
			god.node.queue_free()
			god = {}
	if not bench_node.is_empty() and is_instance_valid(bench_node.glow):
		bench_node.glow.visible = g.blessing.day != today() and (god_open() or g.quest7 >= 5)
	if g.map_id == "laundry" and premiere.is_empty() and g.world.has("root") and premiere_seated():
		_premiere_audience()
	if premiere.size() > 0:
		var bob := maxf(0.0, 0.12 - minf(g.beat_phase(), 1.0 - g.beat_phase()) * 0.45)
		for n in premiere:
			if is_instance_valid(n.node):
				n.node.position = n.base + Vector3(0, bob * 0.8, 0)
				for a in n.arms:
					a.rotation.x = -2.5 if bob > 0.05 else -0.4


# ================================================================== the new mobs
const MOB_KINDS := ["roach", "fly", "cheb", "plunger_mob", "pelmeshek", "sock", "washer", "iron", "bubble", "dough", "drum"]


func model(kind: String, at: Vector3) -> Dictionary:
	match kind:
		"roach": return Mobs08.roach()
		"fly": return Mobs08.fly()
		"cheb": return Mobs08.cheb()
		"plunger_mob": return Mobs08.plunger()
		"pelmeshek": return Mobs08.pelmeshek()
		"sock": return Mobs08.sock(int(absf(at.x * 3.0 + at.z)))
		"washer": return Mobs08.washer()
		"iron": return Mobs08.iron()
		"bubble": return Mobs08.bubble()
		"dough": return Mobs08.dough()
		"drum": return Mobs08.drum()
	return Mobs08.pelmeshek()


func setup_mob(m: Dictionary) -> void:
	match m.kind:
		"drum":
			m.yaw = 0.0
			m.fly_t = 20.0
			m.pull_cd = 6.0
			m.special = 3.5
			m.whisper_t = 9.0
		"dough":
			m.special = 6.0
			m.pull_cd = 9.0
			m.whisper_t = 12.0
		"fly":
			m.alt = 0.0


func chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var spd := 0.0
	var reach: float = m.radius + 0.9
	var dir := to_p.normalized() if dp > 0.01 else Vector3.FORWARD
	match m.kind:
		"roach":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 11.0 * dt
				if dp < reach + 0.2:
					g.hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
					m.charge_t = 0.0
					g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "Кья!", Color("ffb07a"), 22, 40)
				return 11.0
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 9))
			if dp < 5.0:
				# ninja circling: strafe around the hero, then dash in
				var side := Vector3(dir.z, 0, -dir.x) * float(m.strafe)
				spd = m.speed * 0.8
				m.pos += (side * 0.9 + dir * 0.15).normalized() * spd * dt
				if m.atk_cd <= 0.0:
					m.atk_cd = m.atk
					m.charge_dir = dir
					m.charge_t = 0.35
					if randf() < 0.4:
						m.strafe = -float(m.strafe)
			else:
				spd = m.speed
				m.pos += dir * spd * dt
		"fly":
			# hovers around the hero; dives on the beat; a hit «collects a debt» — a few coins
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 9.0 * dt
				m.alt = lerpf(m.alt, -1.0, minf(1.0, dt * 8.0))
				if dp < reach:
					g.hurt_player(m.dmg * randf_range(0.9, 1.15), m.pos)
					var take := mini(g.coins, 3 + int(m.lvl) / 4)
					if take > 0:
						g.coins -= take
						g.hud.float_text(g.pos + Vector3(0, 3.1, 0), "Долг по чебурекам! -%d монет" % take, Color("ffd27a"), 20, 40)
					m.charge_t = 0.0
				return 9.0
			m.alt = lerpf(m.alt, 0.0, minf(1.0, dt * 3.0))
			var ang := atan2(-to_p.x, -to_p.z) + dt * 1.4 * float(m.strafe)
			var want: Vector3 = g.pos + Vector3(sin(ang), 0, cos(ang)) * 4.0
			var wd: Vector3 = want - m.pos
			wd.y = 0
			if wd.length() > 0.2:
				spd = minf(m.speed, wd.length() * 3.0)
				m.pos += wd.normalized() * spd * dt
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
			var ph: float = g.beat_phase()
			if m.atk_cd <= 0.0 and dp < 7.0 and (ph < 0.12 or ph > 0.92):
				m.atk_cd = m.atk * 2.0
				m.charge_dir = dir
				m.charge_t = 0.5
				g.play_sfx("near", 1.8, -10.0)
		"cheb":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 5))
			m.special -= dt
			if m.special <= 0.0 and dp < 7.0:
				m.special = 4.0
				m.flap = 0.5
				g._add_trap(g.pos, 1.9, 1.1, m.dmg * 1.3)
				g.hud.float_text(m.pos + Vector3(0, 2.0, 0), "ПШШ! Горячий сок!", Color("ffcc33"), 22, 40)
				g.play_sfx("near", 0.7, -6.0)
			elif dp > reach:
				spd = m.speed
				m.pos += dir * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				m.flap = 0.3
				g.hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
		"plunger_mob":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 8.0 * dt
				if m.charge_t <= 0.0:
					g._ring_fx(m.pos + Vector3(0, 0.1, 0), Color("ff5d7a"), 2.0, 0.3)
					if Vector2(g.pos.x - m.pos.x, g.pos.z - m.pos.z).length() < 1.8:
						g.hurt_player(m.dmg * randf_range(0.9, 1.15), m.pos)
						g.slow_t = 1.6
						g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "ЧПОК! Присосался", Color("ff9ab0"), 22, 40)
				return 8.0
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
			if m.atk_cd <= 0.0 and dp < 8.0:
				m.atk_cd = m.atk
				m.charge_dir = dir
				m.charge_t = 0.5 * minf(1.0, dp / 4.0) + 0.15
				g.play_sfx("jump", 0.8, -6.0)
			elif dp > 3.0:
				spd = m.speed * 0.6
				m.pos += dir * spd * dt
		"pelmeshek", "sock":
			var sp: float = m.speed * (1.5 if int(m.phase) == 9 else 1.0)
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 8))
			if dp > reach:
				spd = sp
				m.pos += dir * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				m.flap = 0.3
				g.hurt_player(m.dmg * randf_range(0.85, 1.15) * (1.3 if int(m.phase) == 9 else 1.0), m.pos)
		"washer":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 4))
			m.pull_cd -= dt
			if m.charge_t > 0.0:
				# the centrifuge: the hero is spun around the machine
				m.charge_t -= dt
				var away := Vector3(g.pos.x - m.pos.x, 0, g.pos.z - m.pos.z)
				var tang := Vector3(-away.z, 0, away.x).normalized()
				g.pull_v = tang * 9.0 - away.normalized() * 2.0
				m.whisper_t -= dt
				if m.whisper_t <= 0.0:
					m.whisper_t = 0.5
					g.hurt_player(m.dmg * 0.35, m.pos)
				return 0.0
			if m.pull_cd <= 0.0 and dp < 4.5:
				m.pull_cd = 7.0
				m.charge_t = 1.6
				m.whisper_t = 0.3
				m.flap = 1.6
				g.hud.float_text(m.pos + Vector3(0, 2.6, 0), "ЦЕНТРИФУГА!", Color("8ad8ff"), 26, 40)
				g.play_sfx("near", 0.6, -2.0)
			elif dp > reach:
				spd = m.speed
				m.pos += dir * spd * dt
			elif m.atk_cd <= 0.0:
				m.atk_cd = m.atk
				g.hurt_player(m.dmg * randf_range(0.85, 1.15), m.pos)
		"iron":
			if m.charge_t > 0.0:
				m.charge_t -= dt
				m.pos += m.charge_dir * 10.5 * dt
				if dp < reach + 0.3:
					g.hurt_player(m.dmg * randf_range(0.9, 1.2), m.pos)
					g.pull_v = m.charge_dir * 8.0
					m.charge_t = 0.0
					m.atk_cd = m.atk
					g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "Отглажено!", Color("8ad8ff"), 22, 40)
				return 10.5
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 6))
			if m.atk_cd <= 0.0 and dp < 8.5:
				m.charge_dir = dir
				m.charge_t = 0.8
				m.flap = 0.8
				g.hud.float_text(m.pos + Vector3(0, 2.0, 0), "ПШШ-Ш!", Color("e8eeff"), 20, 30)
				g.play_sfx("dash", 1.1, -6.0)
			elif dp > 3.5:
				spd = m.speed
				m.pos += dir * spd * dt
		"bubble":
			m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 4))
			if dp > reach - 0.2:
				var sway := Vector3(dir.z, 0, -dir.x) * sin(g.time * 1.8 + m.home.x) * 0.6
				spd = m.speed
				m.pos += (dir + sway).normalized() * spd * dt
			elif m.atk_cd <= 0.0:
				# pops on contact: foam in the face, the hero slides
				g.hurt_player(m.dmg * 1.4, m.pos)
				g.pull_v = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * 7.0
				g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "ПЛЮХ! Скользко!", Color("ff9ad0"), 22, 40)
				g._burst(m.pos + Vector3(0, 1.2, 0), [Color.WHITE, Color("ff9ad0"), Color("8ad8ff")], 18)
				g.damage_mob(m, m.hp + 1.0, false)
		"dough":
			return _dough_chase(m, dt, to_p, dp)
		"drum":
			return _drum_chase(m, dt, to_p, dp)
	return spd


func animate(m: Dictionary, dt: float, spd: float) -> void:
	var t: float = g.time
	match m.kind:
		"roach":
			var k := minf(1.0, spd / 3.0)
			for i in range(m.wheels.size()):
				m.wheels[i].rotation.x = sin(t * 24.0 + i * 1.7) * 0.5 * k
			m.body.position.y = absf(sin(t * 20.0)) * 0.05 * k
			m.head.rotation.x = -0.2 if m.charge_t > 0.0 else sin(t * 3.0 + m.home.x) * 0.1
		"fly":
			m.body.position.y = 1.8 + sin(t * 3.0 + m.home.x) * 0.2
			for i in range(m.wings.size()):
				m.wings[i].rotation.z = sin(t * 60.0) * 0.5 * (1.0 if i == 0 else -1.0)
			m.body.rotation.x = 0.4 if m.charge_t > 0.0 else 0.1
		"cheb":
			var bob := maxf(0.0, 0.1 - minf(g.beat_phase(), 1.0 - g.beat_phase()) * 0.4)
			m.body.position.y = bob
			m.body.rotation.z = sin(t * 7.0 + m.home.x) * 0.06 * minf(1.0, spd)
			for i in range(m.wings.size()):
				var s: MeshInstance3D = m.wings[i]
				s.position.y = 1.25 + i * 0.25 + fposmod(t * 0.6 + i * 0.33, 1.0) * 0.6
				s.scale = Vector3.ONE * (0.32 - i * 0.06) * (1.6 if m.flap > 0.0 else 1.0)
		"plunger_mob":
			var hop := 0.0
			if m.charge_t > 0.0:
				hop = 1.1 * sin(clampf(m.charge_t / 0.65, 0.0, 1.0) * PI)
			else:
				hop = absf(sin(t * 6.0 + m.home.z)) * 0.12
			m.body.position.y = hop
			m.body.scale = Vector3(1.0 + (0.15 if hop < 0.05 else 0.0), 1.0 - (0.12 if hop < 0.05 else 0.0), 1.0 + (0.15 if hop < 0.05 else 0.0))
		"pelmeshek":
			m.body.position.y = absf(sin(t * 12.0 + m.home.x)) * 0.12 * minf(1.0, spd / 2.0)
			m.body.rotation.z = sin(t * 10.0) * 0.12 * minf(1.0, spd / 2.0)
		"sock":
			m.body.rotation.z = sin(t * 8.0 + m.home.x) * 0.15 * minf(1.0, spd / 2.0) + (sin(t * 30.0) * 0.08 if int(m.phase) == 9 else 0.0)
			m.body.position.y = absf(sin(t * 8.0 + m.home.x)) * 0.12 * minf(1.0, spd / 2.0)
		"washer":
			m.wheels[0].rotation.z -= dt * (20.0 if m.charge_t > 0.0 else 3.0)
			m.body.position.y = sin(t * 40.0) * (0.03 if m.charge_t > 0.0 else 0.005)
			m.body.rotation.y = sin(t * 30.0) * 0.04 if m.charge_t > 0.0 else 0.0
		"iron":
			m.body.rotation.x = -0.15 if m.charge_t > 0.0 else 0.0
			for i in range(m.wings.size()):
				var v: MeshInstance3D = m.wings[i]
				v.visible = m.charge_t > 0.0 or fposmod(t + i * 0.5, 1.5) < 0.4
				v.scale = Vector3.ONE * 0.24 * (1.0 + fposmod(t * 2.0 + i, 1.0))
		"bubble":
			m.body.position.y = 1.2 + sin(t * 2.0 + m.home.x) * 0.25
			m.body.rotation.y += dt * 0.6
			var sq := 1.0 + sin(t * 4.0 + m.home.z) * 0.05
			m.body.scale = Vector3(sq, 1.0 / sq, sq)
		"dough":
			var grow := 1.0 + (0.25 if m.phase >= 2 else 0.0)
			var breathe := 1.0 + sin(t * 2.2) * 0.04 + (0.1 if m.flap > 0.0 else 0.0)
			m.body.scale = Vector3(grow * breathe, grow / breathe, grow * breathe)
			for i in range(m.wings.size()):
				var a: Node3D = m.wings[i]
				a.rotation.x = (-1.4 if m.flap > 0.0 else sin(t * 1.6 + i) * 0.25)
			m.extra.mouth.scale = Vector3(1.0, 2.2 if m.flap > 0.0 else 1.0, 1.0)
		"drum":
			var rate := 2.0
			if m.shield:
				rate = 14.0
			if m.stun > 0.0:
				rate = 0.0
			m.wheels[0].rotation.z -= dt * rate
			m.body.position.y = sin(t * 45.0) * (0.06 if m.shield else 0.01)
			m.body.rotation.y = sin(t * 30.0) * (0.03 if m.shield else 0.0)


## Returns true when the death of a new boss was animated here.
func dead_anim(m: Dictionary, dt: float) -> bool:
	match m.kind:
		"dough":
			m.node.scale = Vector3(1.0 + m.dead_t * 0.3, maxf(0.15, 1.0 - m.dead_t * 0.4), 1.0 + m.dead_t * 0.3)
			g._remix_after(m)
			return true
		"drum":
			m.wheels[0].rotation.z -= dt * maxf(0.0, 3.0 - m.dead_t)
			g._remix_after(m)
			return true
	return false


## Pair rage of the socks; the dough leaves its pelmeshki behind.
func on_kill(m: Dictionary) -> void:
	if m.kind == "sock":
		for o in g.mobs:
			if o.alive and o.kind == "sock" and int(o.phase) != 9 and o.pos.distance_to(m.pos) < 8.0:
				o.phase = 9
				o.st = "chase"
				g.hud.float_text(o.pos + Vector3(0, 2.4, 0), "Где моя пара?!", Color("ff9ab0"), 22, 40)
				break
	if m.kind in ["dough", "drum"] and int(m.remix) == 0:
		var line := "Шлёп… Шлёп… Тишина в трубах." if m.kind == "dough" else "Программа «Забвение» отменена. Режим: деликатная стирка."
		g.hud.float_text(m.pos + Vector3(0, m.height + 1.0, 0), line, Color("c8f0d0"), 24, 30)
		g.hud.big("ТЕСТО ВЕЧНОСТИ ОСЕЛО!" if m.kind == "dough" else "БАРАБАН СУДЬБЫ ОСТАНОВЛЕН!", "Вернись к Вентилёву" if m.kind == "dough" else "Зал аплодирует! Вернись к режиссёру", 4.5)
		for o in g.mobs:
			if o.alive and o.temp and o.kind in ["pelmeshek", "sock"]:
				o.alive = false
				o.node.visible = false
		g.save_game()


func loot(m: Dictionary) -> Array:
	match m.kind:
		"dough":
			g.coins += 800
			var d := ["rolling_pin"]
			if randf() < 0.6:
				d.append(["chef_hat", "dough_apron"][randi() % 2])
			return d
		"drum":
			g.coins += 900
			var d2 := ["drumsticks"]
			if randf() < 0.6:
				d2.append(["porthole_helmet", "fluffy_robe"][randi() % 2])
			return d2
	return []


## A hit on a 0.8 boss: the dough splits when you miss the beat; the drum in «ОТЖИМ» takes −92%.
func on_damage(m: Dictionary, dmg: float, crit: bool) -> float:
	if m.kind == "dough" and not crit and m.alive:
		var chance := 0.7 if int(m.remix) > 0 else 0.35
		var live := 0
		for o in g.mobs:
			if o.alive and o.kind == "pelmeshek":
				live += 1
		if randf() < chance and live < (10 if int(m.remix) > 0 else 6):
			var a := randf() * TAU
			var p: Dictionary = g._spawn_mob("pelmeshek", m.pos + Vector3(sin(a) * 3.0, 0, cos(a) * 3.0), maxi(12, int(m.lvl) - 4))
			p.temp = true
			p.st = "chase"
			if randf() < 0.4:
				g.hud.float_text(m.pos + Vector3(0, m.height + 0.6, 0), "Не в бит — тесто делится!", Color("ffe0a0"), 20, 40)
	if m.kind == "drum" and m.shield:
		if randf() < 0.3:
			g.hud.float_text(m.pos + Vector3(0, 7.0, 0), "ОТЖИМ! урон -92%", Color("c8d0e8"), 20, 40)
		return dmg * 0.08
	return dmg


## The beat breaks the drum's «ОТЖИМ»: 4 hits on the beat in a row → «деликатная стирка».
func beat(ok: bool) -> void:
	for m in g.mobs:
		if m.alive and m.kind == "drum" and m.shield and m.pos.distance_to(g.pos) < 26.0:
			if ok:
				m.rap = int(m.rap) + 1
				g.hud.float_text(g.pos + Vector3(0, 3.4, 0), ["Деликатно!", "Шерсть!", "Ручная стирка!", "30 градусов!"][randi() % 4], Kit.GOLD, 22, 40)
				if int(m.rap) >= 4:
					m.shield = false
					m.rap = 0
					m.fly_t = 18.0
					m.stun = 3.0
					g.hud.big("ДЕЛИКАТНАЯ СТИРКА!", "Барабан замер на 3 секунды — бей!", 2.5)
					g._ring_fx(m.pos + Vector3(0, 0.3, 0), Kit.GOLD, 6.0, 0.5)
					g.play_sfx("smash", 1.2, -2.0)
			elif int(m.rap) > 0:
				m.rap = 0
				g.hud.float_text(m.pos + Vector3(0, 7.0, 0), "Сбой! Программа «Отжим» заново", Color("9ad8ff"), 20, 40)


func cam_extra(m: Dictionary) -> float:
	match m.kind:
		"dough":
			return 3.5
		"drum":
			return 4.5
	return 0.0


# ------------------------------------------------------------------ Тесто Вечности
func _dough_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var f: float = m.hp / m.hp_max
	var rm := int(m.remix) > 0
	if m.phase == 0 and f < 0.6:
		m.phase = 1
		g.hud.big("ТЕСТО ПОДНИМАЕТСЯ!", "Шлёп-волны — перепрыгивай рывком", 3.0)
	if m.phase == 1 and f < 0.4:
		m.phase = 2
		for k in range(4):
			var a := k * TAU / 4.0
			var p: Dictionary = g._spawn_mob("pelmeshek", m.pos + Vector3(sin(a) * 4.0, 0, cos(a) * 4.0), maxi(12, int(m.lvl) - 3))
			p.temp = true
			p.st = "chase"
		g.hud.toast("Тесто: «Пельмешки, на выход!»", Color("ffe0a0"))
	m.yaw = lerp_angle(m.yaw, atan2(to_p.x, to_p.z), minf(1.0, dt * 2.0))
	var spd := 0.0
	if dp > m.radius + 1.2:
		spd = m.speed * (1.35 if m.phase >= 2 else 1.0)
		m.pos += to_p.normalized() * spd * dt
	elif m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.5
		g.hurt_player(m.dmg * randf_range(0.9, 1.1), m.pos)
		g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "ШЛЁП!", Color("ffe0a0"), 26, 40)
		g.play_sfx("smash", 0.6, -4.0)
	m.special -= dt
	if m.special <= 0.0 and dp < 24.0:
		m.special = 4.2 if rm else 5.5
		m.flap = 0.6
		var n := 5 if rm else 3
		for k in range(n):
			var off := Vector3.ZERO if k == 0 else Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5))
			g._add_trap(g.pos + off, 2.0, 1.4, m.dmg * 1.25)
		g.hud.float_text(m.pos + Vector3(0, m.height + 0.6, 0), "ЛЕПЁШКИ!", Color("ffe0a0"), 26, 40)
	if m.phase >= 1:
		m.pull_cd -= dt
		if m.pull_cd <= 0.0 and dp < 24.0:
			m.pull_cd = 6.0 if rm else 7.5
			m.flap = 0.5
			g._add_wave(m.pos, 18.0, 7.5, m.dmg * 0.9, Color("ffe0a0"))
			g.hud.float_text(m.pos + Vector3(0, m.height + 1.0, 0), "ШЛЁП-ВОЛНА!", Color("ffe0a0"), 28, 40)
	return spd


# ------------------------------------------------------------------ Барабан Судьбы
func _drum_chase(m: Dictionary, dt: float, to_p: Vector3, dp: float) -> float:
	var f: float = m.hp / m.hp_max
	var rm := int(m.remix) > 0
	if m.phase == 0 and f < 0.7:
		m.phase = 1
		_drum_socks(m, 2)
	elif m.phase == 1 and f < 0.5:
		m.phase = 2
		_drum_spin(m)
	elif m.phase == 2 and f < 0.35:
		m.phase = 3
		_drum_socks(m, 4)
	if m.shield:
		m.shield_t -= dt
		m.hp = minf(m.hp_max, m.hp + m.hp_max * 0.01 * dt)
		# the centrifuge pulls everybody around the arena
		var away := Vector3(g.pos.x - m.pos.x, 0, g.pos.z - m.pos.z)
		if away.length() < 14.0 and g.invuln <= 0.0:
			var tang := Vector3(-away.z, 0, away.x).normalized()
			g.pull_v = g.pull_v.lerp(tang * (6.5 if rm else 4.5) - away.normalized() * 0.8, minf(1.0, dt * 3.0))
		if m.shield_t <= 0.0:
			m.shield = false
			m.fly_t = 18.0
			g.hud.toast("Отжим закончился — Барабан подлечился", Color("9ad8ff"))
	elif m.phase >= 2:
		m.fly_t -= dt
		if m.fly_t <= 0.0:
			_drum_spin(m)
	m.special -= dt
	if m.special <= 0.0 and dp < 26.0:
		m.special = 2.8 if rm else 3.6
		m.flap = 0.4
		var rows := 2 if rm else 1
		for r in range(rows):
			for k in range(3):
				var a := atan2(to_p.x, to_p.z) + (k - 1) * 0.28 + r * 0.14
				var n := Mobs08.sock_shot()
				g.fx_root.add_child(n)
				var from: Vector3 = m.pos + Vector3(0, 2.6, 0) + Vector3(sin(a), 0, cos(a)) * 2.4
				n.position = from
				g.mob_shots.append({"node": n, "dir": Vector3(sin(a), -0.08, cos(a)).normalized(), "life": 4.0, "dmg": m.dmg * 0.8, "kind": "sock"})
		g.hud.float_text(m.pos + Vector3(0, 7.2, 0), "НОСКИ!", Color("ff9ab0"), 26, 40)
	m.pull_cd -= dt
	if m.pull_cd <= 0.0 and dp < 26.0:
		m.pull_cd = 7.0 if rm else 8.5
		g._add_wave(m.pos, 22.0, 8.0, m.dmg * 0.9, Color("8ad8ff"))
		g.hud.float_text(m.pos + Vector3(0, 7.6, 0), "ПОЛОСКАНИЕ!", Color("8ad8ff"), 28, 40)
	if dp < m.radius + 1.8 and m.atk_cd <= 0.0:
		m.atk_cd = m.atk
		m.flap = 0.4
		g.hurt_player(m.dmg * randf_range(0.9, 1.1), m.pos)
		g.hud.float_text(g.pos + Vector3(0, 2.8, 0), "Дверцей — ХЛОП!", Color("ff9ad0"), 22, 40)
	return 0.0


func _drum_spin(m: Dictionary) -> void:
	m.shield = true
	m.shield_t = 9.0
	m.rap = 0
	g.hud.big("ПРОГРАММА «ОТЖИМ 1400»!", "Центрифуга крутит арену · 4 удара в бит подряд — «деликатная стирка»", 3.5)
	g.play_sfx("laser", 0.5)


func _drum_socks(m: Dictionary, n: int) -> void:
	for k in range(n):
		var a := PI + (k - (n - 1) * 0.5) * 0.6
		var s2: Dictionary = g._spawn_mob("sock", m.pos + Vector3(sin(a) * 5.0, 0, cos(a) * 5.0), maxi(15, int(m.lvl) - 2))
		s2.st = "chase"
		s2.temp = true
	g.hud.toast("Барабан: «Носки без пары — на выход!»", Color("ff9ab0"))


## A sock or a juice blob hits the hero.
func shot_hit(b: Dictionary) -> void:
	if b.kind == "sock":
		g.pull_v = Vector3(b.dir.x, 0, b.dir.z).normalized() * 6.0
		g.hud.float_text(g.pos + Vector3(0, 2.9, 0), "Носком в лицо!", Color("ff9ab0"), 22, 40)
