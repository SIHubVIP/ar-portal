class_name DelovoySites
extends RefCounted
## Площадки района «Деловой» по пакету «Рубин» (0.14, D-056). Объёмы и места — из
## data/pogulyay_layout.json → sites (id "dl_*"), облик и вывески — по брифу и артам
## docs/source/rubin_delovoy:
##   dl_mfc    — B2 «Последний талон»: администрация, площадь с очередью и боковым обходом,
##               тарелка, застрявшая в бюрократии, архив и копицентр;
##   dl_credit — A3 «Кредит доверчивым»: кооператив, ломбард, склад изъятого, машины
##               с блокираторами, изъятая тарелка и аукционные ограждения;
##   dl_yard   — B1 «Двор свидетелей»: дома с аркой, бельё, ковры, грядки, качели,
##               бабушка держит разведывательный зонд;
##   dl_school, dl_zags, dl_archive — конторы с площадью, очередью и маленькой тарелкой;
##   dl_station — станция «Тихая доставка» с трубами; dl_passage — пассаж «Труд без оплаты»;
##   dl_greenhouses — теплицы «Рассада будущего».
## Общие приёмы — у DistrictSites (_hall, _sign, _person, _alien, _lantern…).

const GREY := Color(0.62, 0.64, 0.66)
const YELLOW := Color(0.95, 0.78, 0.12)
const GRANNY := {"skirt": true, "style": "curlers", "hair": Color(0.85, 0.85, 0.85), "top": Color(0.55, 0.3, 0.45)}


static func build(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	match String(site.id):
		"dl_mfc":
			_mfc(root, site, batch)
		"dl_credit":
			_credit(root, site, batch)
		"dl_yard":
			_yard(root, site, batch)
		"dl_school":
			_office(root, site, batch, "DL_A1", "ШКОЛА ПОКОРНОСТИ", "ПРИЁМ В ПЕРВЫЙ КЛАСС\nИ В РАБСТВО — ОДНОЙ ЗАЯВКОЙ",
					Color(0.85, 0.72, 0.5))
		"dl_zags":
			_office(root, site, batch, "DL_A2", "ЗАГС «СЧАСТЬЕ ПО ЗАПИСИ»", "РАСПИСЫВАЕМ С ПРИШЕЛЬЦАМИ\nПО ЧЕТВЕРГАМ",
					Color(0.9, 0.78, 0.8))
		"dl_archive":
			_office(root, site, batch, "DL_B3", "АРХИВ ЖИВЫХ", "СПРАВКА О ТОМ, ЧТО ВЫ ЖИВЫ —\nЧЕРЕЗ 30 РАБОЧИХ ДНЕЙ",
					Color(0.72, 0.74, 0.7))
		"dl_station":
			_station(root, site, batch)
		"dl_passage":
			_passage(root, site, batch)
		"dl_greenhouses":
			_greenhouses(root, site, batch)


# ---------- B2 «Последний талон» ----------

static func _mfc(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4500
	var pav := DistrictSites._r(DistrictSites._o(site, "DL_B2_courtyard_paving"))
	DistrictSites._paving(batch, pav)
	DistrictSites._paving(batch, DistrictSites._r(DistrictSites._o(site, "DL_B2_mfc_plaza")), 0.045)
	# плитка «ёлочкой» не нужна: тёмные швы сеткой 15 м, как на арте
	var gx := pav.position.x + 10.0
	while gx < pav.end.x - 5.0:
		DistrictSites._b(batch, DistrictSites._w(gx, pav.get_center().y, 0.058), Vector3(0.6, 0.03, pav.size.y - 4.0), Color(0.36, 0.35, 0.34), 0.0, "paint")
		gx += 15.0
	DistrictSites._tree_row(batch, site, "DL_B2_town_tree_trunk")
	# администрация: серый модернизм, лента окон, козырёк на столбах, флагштоки
	var adm := DistrictSites._r(DistrictSites._o(site, "DL_B2_mfc_office"))
	var ac := DistrictSites._hall(root, adm, 12.0, false, GREY, Color(0.3, 0.31, 0.33), true)
	var front := ac + Vector3(0, 0, adm.size.y / 2.0)
	DistrictSites._b(batch, front + Vector3(0, 4.2, 3.0), Vector3(36, 0.4, 6.0), Color(0.5, 0.52, 0.55))
	for k in 6:
		DistrictSites._b(batch, front + Vector3(-15 + k * 6.0, 2.0, 5.6), Vector3(0.5, 4.0, 0.5), Color(0.72, 0.72, 0.7))
	for k in 3:
		DistrictSites._b(batch, front + Vector3(0, 0.15 + k * 0.3, 7.2 - k * 0.7), Vector3(38, 0.3, 1.4 + k * 0.7), Color(0.58, 0.57, 0.55))
	Props.collider(root, Vector3(38, 1.0, 3), front + Vector3(0, 0.5, 7.2))
	for k in 3:
		var fp := front + Vector3(-6 + k * 6.0, 0, 11.0)
		DistrictSites._b(batch, fp + Vector3(0, 5.0, 0), Vector3(0.14, 10.0, 0.14), Color(0.7, 0.7, 0.72))
		DistrictSites._b(batch, fp + Vector3(0.9, 9.2, 0), Vector3(1.8, 1.1, 0.04), [Color(0.95, 0.95, 0.95), Color(0.2, 0.35, 0.75),
				Color(0.4, 0.85, 0.5)][k])
	DistrictSites._sign(batch, root, "ПОСЛЕДНИЙ ТАЛОН", "letters", Color(1.0, 0.85, 0.5), front + Vector3(0, 13.6, 0.2), 0.0, 1.3)
	DistrictSites._sign(batch, root, "ЗАХВАТ ПЛАНЕТЫ — В ОКНО 7", "neon", Color(0.3, 1.0, 0.6), front + Vector3(0, 6.6, 0.15), 0.0, 0.6,
			{"flicker": true})
	DistrictSites._sign(batch, root, "ОБЕД ДО КОНЦА\nВТОРЖЕНИЯ", "board", Color(0.1, 0.1, 0.1), front + Vector3(5, 1.9, 0.12), 0.0, 0.3,
			{"bg": Color(0.95, 0.95, 0.92), "lamp": true})
	DistrictSites._sign(batch, root, "ОКНО 7", "lightbox", Color(0.8, 0.1, 0.1), front + Vector3(-5, 2.8, 0.12), 0.0, 0.4,
			{"bg": Color(1.0, 0.96, 0.85)})
	DistrictSites._sign(batch, root, "СОГЛАСОВАНИЕ\nКОНЦА СВЕТА\nВ ПОРЯДКЕ\nОЧЕРЕДИ", "poster", Color(0.12, 0.12, 0.14),
			front + Vector3(-27, 6.0, 0.1), 0.0, 0.7, {"bg": Color(0.93, 0.9, 0.84), "font": "block", "tilt": 0.0})
	DistrictSites._sign(batch, root, "НЕ ЗАНИМАТЬ\nДЛЯ ЗАХВАТЧИКОВ\nОТДЕЛЬНОЕ ОКНО", "poster", Color(0.7, 0.12, 0.1),
			front + Vector3(27, 6.0, 0.1), 0.0, 0.6, {"bg": Color(0.95, 0.93, 0.88), "font": "block", "tilt": 0.0})
	_mfc_ufo(root, site, batch)
	# очередь змейкой: стойки с лентой, люди и пришельцы; западный край — свободный обход
	var rows := DistrictSites._all(site, "DL_B2_mfc_queue")
	for i in rows.size():
		var r := DistrictSites._r(rows[i])
		var x := r.position.x
		while x <= r.end.x:
			DistrictSites._b(batch, DistrictSites._w(x, r.position.y, 0.5), Vector3(0.1, 1.0, 0.1), Color(0.75, 0.72, 0.6))
			DistrictSites._b(batch, DistrictSites._w(x, r.position.y, 1.0), Vector3(0.22, 0.12, 0.22), Color(0.85, 0.75, 0.3))
			x += 4.0
		DistrictSites._b(batch, DistrictSites._w(r.get_center().x, r.position.y, 0.85), Vector3(r.size.x, 0.05, 0.05), Color(0.2, 0.35, 0.8))
	for k in 22:
		var row := k / 4
		var t := float(k % 4)
		var x2 := 4458.0 + t * 10.0 + rng.randf_range(-1.5, 1.5) if row % 2 == 0 else 4492.0 - t * 10.0
		var p := DistrictSites._w(x2, 1495.0 + row * 6.0)
		var yaw := -PI / 2.0 if row % 2 == 0 else PI / 2.0
		if k % 4 == 1:
			DistrictSites._alien(root, p, yaw, rng, k == 13)
		else:
			DistrictSites._person(root, p, yaw, rng)
	# боковой обход: зелёная полоса и стрелки по западному краю площади
	var by := DistrictSites._r(DistrictSites._o(site, "DL_B2_mfc_plaza"))
	DistrictSites._b(batch, DistrictSites._w(by.position.x - 3.0, by.get_center().y, 0.06), Vector3(3.0, 0.02, by.size.y), Color(0.25, 0.55, 0.3), 0.0, "paint")
	for k in 4:
		DistrictSites._b(batch, DistrictSites._w(by.position.x - 3.0, by.position.y + 8.0 + k * 14.0, 0.07), Vector3(0.8, 0.02, 2.4),
				Color(0.95, 0.95, 0.9), 0.0, "paint")
	DistrictSites._sign(batch, root, "ОБХОД ОЧЕРЕДИ —\nТОЛЬКО ДЛЯ СВОИХ", "board", Color(0.1, 0.1, 0.1),
			DistrictSites._w(by.position.x - 3.0, by.end.y + 2.0, 1.5), 0.0, 0.26, {"bg": Color(0.9, 0.95, 0.88)})
	# терминал талонов: светится экран, перед ним пришелец с бумажкой
	var term := DistrictSites._w(4452, 1548)
	DistrictSites._b(batch, term + Vector3(0, 0.9, 0), Vector3(0.9, 1.8, 0.6), Color(0.85, 0.82, 0.75))
	DistrictSites._b(batch, term + Vector3(0, 1.35, 0.31), Vector3(0.6, 0.45, 0.02), Color(0.4, 0.8, 1.0, 0.0), 0.0, "glow")
	Props.collider(root, Vector3(0.9, 1.8, 0.6), term + Vector3(0, 0.9, 0))
	DistrictSites._sign(batch, root, "ТАЛОН № 0000001\nВЫДАН ВЧЕРА", "board", Color(0.1, 0.1, 0.1), term + Vector3(0, 2.2, 0.32), 0.0, 0.16,
			{"bg": Color(1, 1, 1), "far": DistrictDressing.SIGN_FAR_M})
	DistrictSites._alien(root, term + Vector3(0, 0, 1.6), PI, rng)
	# пропускной ряд турникетов
	for o in DistrictSites._all(site, "DL_B2_ticket_barrier"):
		var r2 := DistrictSites._r(o)
		var c2 := DistrictSites.sw(r2.get_center())
		DistrictSites._b(batch, c2 + Vector3(0, 0.55, 0), Vector3(0.4, 1.1, r2.size.y), Color(0.55, 0.57, 0.6))
		DistrictSites._b(batch, c2 + Vector3(0, 1.0, 0), Vector3(0.1, 0.1, r2.size.y), Color(1.0, 0.25, 0.2, 0.2), 0.0, "glow")
	# архив (восток) и копицентр (запад)
	var arch := DistrictSites._r(DistrictSites._o(site, "DL_B2_archive"))
	var arc := DistrictSites._hall(root, arch, 12.0, true, Color(0.52, 0.3, 0.24))
	DistrictSites._sign(batch, root, "АРХИВ\nСОГЛАСОВАНИЙ", "board", Color(0.95, 0.9, 0.8), arc + Vector3(-arch.size.x / 2.0 - 0.05, 4.0, 12), -90.0,
			0.5, {"bg": Color(0.2, 0.25, 0.35), "lamp": true})
	var copy := DistrictSites._r(DistrictSites._o(site, "DL_B2_copyshop"))
	var cc := DistrictSites._hall(root, copy, 5.0, false, Color(0.3, 0.5, 0.46), Color(0.25, 0.25, 0.27), true)
	DistrictSites._sign(batch, root, "КОПИЦЕНТР\nТРИ ПОДПИСИ — ОДНА ЦЕНА", "lightbox", Color(0.2, 0.5, 0.9), cc + Vector3(copy.size.x / 2.0 + 0.05, 3.8, 0),
			90.0, 0.36, {"bg": Color(0.92, 0.95, 1.0)})
	# «вторая очередь» — к копицентру: три человека с папками
	for k in 3:
		DistrictSites._person(root, cc + Vector3(copy.size.x / 2.0 + 2.0 + k * 1.1, 0, 6.0 + k * 0.4), -PI / 2.0, rng)
	for k in 6:
		DistrictSites._lantern(batch, DistrictSites._w(4420 + k * 32, 1590))
	for k in 3:
		DistrictSites._lantern(batch, DistrictSites._w(4440 + k * 60, 1486))
	# лавки вдоль аллеи, на одной спит контролёр
	for k in 4:
		batch.model("bench", DistrictSites._w(4420 + k * 50, 1586), 0.0)
	DistrictSites._person(root, DistrictSites._w(4470, 1586.6), PI, rng, {"top": Color(0.95, 0.55, 0.1)})


## Тарелка застряла между крылом администрации и лесами: нос в стене, корма на опорах,
## по борту — бумажки с печатями и лента «НЕ ЗАНИМАТЬ».
static func _mfc_ufo(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var u := DistrictSites._r(DistrictSites._o(site, "DL_B2_mfc_ufo"))
	var ufo := Node3D.new()
	ufo.name = "StuckUfo"
	ufo.position = DistrictSites.sw(u.get_center(), 10.5)
	ufo.rotation_degrees = Vector3(-22, -30, 12)
	root.add_child(ufo)
	Kit.cylinder(ufo, 15.0, 2.2, Vector3.ZERO, Color(0.42, 0.44, 0.5), 0.0, 12.5)
	Kit.cylinder(ufo, 7.0, 1.8, Vector3(0, -1.9, 0), Color(0.26, 0.27, 0.31), 0.0, 11.5)
	Kit.cylinder(ufo, 9.0, 0.4, Vector3(0, 1.3, 0), Color(0.5, 0.52, 0.58), 0.0, 8.5)
	Kit.sphere(ufo, 5.6, Vector3(0, 2.2, 0), Color(0.55, 0.95, 0.75, 0.85), 0.7)
	var ux := ufo.transform
	for i in 16:
		var a := TAU * i / 16.0
		batch.add("glow", ux * Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(cos(a) * 14.4, 0.2, sin(a) * 14.4)),
				Color(1.0, 0.35, 0.25) if i % 4 == 0 else Color(0.3, 1.0, 0.75))
	# бумажки с печатями по борту
	for i in 10:
		var a := TAU * i / 10.0 + 0.2
		batch.add("site", ux * Transform3D(Basis(Vector3.UP, -a) * Basis.from_scale(Vector3(0.05, 0.8, 0.6)),
				Vector3(cos(a) * 13.7, 0.9, sin(a) * 13.7)), Color(0.96, 0.95, 0.9))
	var beacon := Kit.sphere(ufo, 0.5, Vector3(0, 8.0, 0), Color(1.0, 0.75, 0.2), 5.0)
	beacon.create_tween().set_loops().tween_property(beacon, "scale", Vector3.ONE * 0.2, 0.8).from(Vector3.ONE)
	# опоры лесов и полосатая лента
	for k in 4:
		var leg := ufo.position + Vector3(-8 + k * 5.0, -5.5, 8 - k * 1.5)
		DistrictSites._b(batch, leg, Vector3(0.25, 11.0, 0.25), YELLOW)
		DistrictSites._b(batch, leg + Vector3(0, -1.0 + k * 0.8, 0), Vector3(5.0, 0.15, 0.15), YELLOW, 0.4)
	var base := DistrictSites.sw(u.get_center()) + Vector3(-4, 0, 18)
	for k in 6:
		DistrictSites._b(batch, base + Vector3(-10 + k * 4.0, 0.5, 0), Vector3(0.12, 1.0, 0.12), Color(0.8, 0.2, 0.15))
	DistrictSites._b(batch, base + Vector3(0, 0.9, 0), Vector3(20, 0.12, 0.03), Color(0.95, 0.85, 0.2))
	DistrictSites._sign(batch, root, "ОБЪЕКТ НА СОГЛАСОВАНИИ\nНЕ ВЗЛЕТАТЬ", "board", Color(0.1, 0.1, 0.1), base + Vector3(0, 1.6, 0.05), 0.0, 0.28,
			{"bg": Color(0.98, 0.9, 0.3)})
	var smoke := Kit.particles(ufo, Vector3(9, 1.0, -6), Color(0.3, 0.3, 0.32, 0.45), 16, 5.0, Vector3(0, 1.8, 0), 0.3, 3.5,
			Vector3(1, 0.2, 1))
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# ---------- A3 «Кредит доверчивым» ----------

static func _credit(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5500
	var yard := DistrictSites._r(DistrictSites._o(site, "DL_A3_courtyard"))
	DistrictSites._paving(batch, yard)
	DistrictSites._tree_row(batch, site, "DL_A3_edge_tree_trunk")
	# кооператив: кремовый корпус, золотые буквы, табло курса
	var off := DistrictSites._r(DistrictSites._o(site, "DL_A3_credit_office"))
	var oc := DistrictSites._hall(root, off, 12.0, false, Color(0.86, 0.82, 0.7), Color(0.3, 0.3, 0.32), true)
	var front := oc + Vector3(0, 0, off.size.y / 2.0)
	DistrictSites._b(batch, front + Vector3(0, 3.8, 1.8), Vector3(20, 0.3, 3.6), Color(0.6, 0.12, 0.1))
	DistrictSites._sign(batch, root, "КРЕДИТ ДОВЕРЧИВЫМ", "letters", Color(1.0, 0.82, 0.3), front + Vector3(0, 13.4, 0.2), 0.0, 1.3)
	DistrictSites._sign(batch, root, "ВАША ДУША\nУЖЕ В ЗАЛОГЕ", "lightbox", Color(0.6, 0.1, 0.1), front + Vector3(-22, 6.5, 0.1), 0.0, 0.6,
			{"bg": Color(1.0, 0.95, 0.85)})
	DistrictSites._sign(batch, root, "СУДНЫЙ ДЕНЬ —\nПО ГРАФИКУ ПЛАТЕЖЕЙ", "lightbox", Color(0.1, 0.15, 0.35), front + Vector3(22, 6.5, 0.1), 0.0, 0.5,
			{"bg": Color(0.95, 0.96, 1.0)})
	DistrictSites._sign(batch, root, "СТАВКА: ВСЁ\nСРОК: НАВСЕГДА", "neon", Color(1.0, 0.3, 0.2), front + Vector3(0, 6.0, 0.15), 0.0, 0.42,
			{"flicker": true})
	# ломбард (запад) и склад изъятого (восток)
	var paw := DistrictSites._r(DistrictSites._o(site, "DL_A3_pawnshop"))
	var pc := DistrictSites._hall(root, paw, 6.0, false, Color(0.28, 0.48, 0.44), Color(0.22, 0.22, 0.24), true)
	DistrictSites._sign(batch, root, "ЛОМБАРД\nПРИМЕМ ВСЁ, ДАЖЕ ВАС", "lightbox", Color(0.95, 0.8, 0.2), pc + Vector3(paw.size.x / 2.0 + 0.05, 4.6, 0),
			90.0, 0.42, {"bg": Color(0.15, 0.15, 0.18)})
	for k in 3:
		DistrictSites._b(batch, pc + Vector3(paw.size.x / 2.0 + 0.06, 1.6, -18 + k * 18.0), Vector3(0.08, 2.2, 4.0), Color(0.95, 0.8, 0.45, 0.0),
				0.0, "glow")
	var wh := DistrictSites._r(DistrictSites._o(site, "DL_A3_seized_property_warehouse"))
	var wc := DistrictSites._hall(root, wh, 8.0, true, Color(0.55, 0.32, 0.24))
	for k in 2:
		DistrictSites._b(batch, wc + Vector3(-wh.size.x / 2.0 - 0.06, 2.4, -14 + k * 28.0), Vector3(0.12, 4.8, 6.0), Color(0.35, 0.4, 0.42))
	DistrictSites._sign(batch, root, "СКЛАД ИЗЪЯТОГО\nВЫДАЧА — НИКОГДА", "board", Color(0.95, 0.9, 0.8), wc + Vector3(-wh.size.x / 2.0 - 0.1, 6.2, 0),
			-90.0, 0.5, {"bg": Color(0.22, 0.2, 0.18), "lamp": true})
	# залоговая стоянка: асфальт, разметка мест, очередь должников у двери
	var cols := [Color(0.75, 0.2, 0.15), Color(0.2, 0.32, 0.55), Color(0.85, 0.85, 0.82), Color(0.3, 0.45, 0.3), Color(0.15, 0.15, 0.17)]
	batch.box("pocket", DistrictSites._w(5492, 532, 0.05), Vector3(140, 0.04, 62))
	# места по 6 м: машины стоят цепочкой вдоль ряда, между изъятыми — обычные, ещё не изъятые
	for k in 22:
		for y: float in [515.0, 549.0]:
			DistrictSites._b(batch, DistrictSites._w(5430.0 + k * 6.0, y, 0.075), Vector3(0.15, 0.02, 3.0), Color(0.92, 0.9, 0.82), 0.0, "paint")
	for k in 21:
		if k % 4 == 2 or rng.randf() < 0.35:
			continue
		for y: float in [515.0, 549.0]:
			if k > 17 and y > 530.0:
				continue          # у изъятой тарелки — пусто
			var free := CarKit.make(root, cols[(k + int(y)) % cols.size()].darkened(0.1), false, (k + 1) % 3)
			free.position = DistrictSites._w(5433.0 + k * 6.0, y)
			free.rotation.y = PI / 2.0
			Props.collider(root, Vector3(CarKit.LENGTH, 1.5, CarKit.WIDTH), free.position + Vector3(0, 0.75, 0))
	for k in 6:
		DistrictSites._person(root, front + Vector3(2.0, 0, 4.0 + k * 1.3), PI, rng)
	# изъятое у склада: холодильники, телевизоры, диван, коробки и шины
	var heap := wc + Vector3(-wh.size.x / 2.0 - 4.0, 0, 0)
	for k in 6:
		DistrictSites._b(batch, heap + Vector3(rng.randf_range(-0.6, 0.6), 0.9, -22.0 + k * 1.2), Vector3(0.8, 1.8, 0.75),
				Color(0.92, 0.92, 0.9))
	for k in 5:
		DistrictSites._b(batch, heap + Vector3(-1.4, 0.35 + (k % 2) * 0.6, -12.0 + k * 0.9), Vector3(0.8, 0.55, 0.5), Color(0.12, 0.12, 0.14))
	DistrictSites._b(batch, heap + Vector3(-0.5, 0.45, 8.0), Vector3(1.0, 0.9, 2.4), Color(0.45, 0.25, 0.4))
	Props.collider(root, Vector3(2.5, 1.8, 9), heap + Vector3(0, 0.9, -19))
	for k in 3:
		batch.model("boxes", heap + Vector3(-1.0, 0, 14.0 + k * 3.0), rng.randf() * TAU)
		batch.model("tires", heap + Vector3(-2.0, 0, 2.0 + k * 2.5), rng.randf() * TAU)
	DistrictSites._sign(batch, root, "ХОЛОДИЛЬНИК «ЗИЛ»\nИЗЪЯТ ЗА ЛАЙК", "board", Color(0.1, 0.1, 0.1), heap + Vector3(1.0, 1.6, -18), 90.0, 0.18,
			{"bg": Color(1, 1, 0.92), "far": DistrictDressing.SIGN_FAR_M})
	# решётчатый забор по южной стороне двора, проход у въездной вывески
	for seg: Vector2 in [Vector2(5400, 5482), Vector2(5502, 5600)]:
		var mid := DistrictSites._w((seg.x + seg.y) / 2.0, 594.0)
		var len := seg.y - seg.x
		DistrictSites._b(batch, mid + Vector3(0, 1.8, 0), Vector3(len, 0.08, 0.08), Color(0.3, 0.31, 0.33))
		DistrictSites._b(batch, mid + Vector3(0, 0.3, 0), Vector3(len, 0.08, 0.08), Color(0.3, 0.31, 0.33))
		var x := seg.x
		while x <= seg.y:
			DistrictSites._b(batch, DistrictSites._w(x, 594.0, 1.0), Vector3(0.06, 2.0, 0.06), Color(0.3, 0.31, 0.33))
			x += 0.5
		Props.collider(root, Vector3(len, 2.0, 0.3), mid + Vector3(0, 1.0, 0))
	# машины с жёлтыми блокираторами, на лобовом — розовая квитанция
	var cars := DistrictSites._all(site, "DL_A3_seized_car")
	for i in cars.size():
		var r := DistrictSites._r(cars[i])
		var c := DistrictSites.sw(r.get_center())
		var mi := CarKit.make(root, cols[i % cols.size()], false, i % 3)
		mi.position = c
		mi.rotation.y = PI / 2.0 if i % 2 == 0 else -PI / 2.0
		Props.collider(root, Vector3(CarKit.LENGTH, 1.5, CarKit.WIDTH), c + Vector3(0, 0.75, 0))
		DistrictSites._b(batch, c + Vector3(0, 1.43, 0), Vector3(0.3, 0.02, 0.25), Color(1.0, 0.55, 0.7))
	for o in DistrictSites._all(site, "DL_A3_wheel_clamp"):
		var c3 := DistrictSites.sw(DistrictSites._r(o).get_center())
		DistrictSites._b(batch, c3 + Vector3(0, 0.35, 0), Vector3(0.55, 0.6, 0.18), YELLOW)
		DistrictSites._b(batch, c3 + Vector3(0, 0.35, 0.12), Vector3(0.2, 0.2, 0.1), Color(0.2, 0.2, 0.2))
	# изъятая тарелка: на колодках, на цепях, с бирками и пломбой «ИЗЪЯТО»
	var t := DistrictSites._r(DistrictSites._o(site, "DL_A3_seized_alien_transport"))
	var tc := DistrictSites.sw(t.get_center())
	batch.add("tank", Transform3D(Basis().scaled(Vector3(17, 1.6, 17)), tc + Vector3(0, 2.0, 0)), Color(0.55, 0.58, 0.64))
	batch.add("tank", Transform3D(Basis().scaled(Vector3(9, 1.0, 9)), tc + Vector3(0, 1.0, 0)), Color(0.3, 0.32, 0.36))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(6, 3.6, 6)), tc + Vector3(0, 3.2, 0)), Color(0.55, 0.85, 1.0))
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		DistrictSites._b(batch, tc + Vector3(cos(a) * 5.0, 0.35, sin(a) * 5.0), Vector3(1.2, 0.7, 1.2), Color(0.35, 0.25, 0.18))      # колодки
		var anchor := tc + Vector3(cos(a) * 10.5, 0.2, sin(a) * 10.5)
		DistrictSites._b(batch, anchor, Vector3(0.6, 0.4, 0.6), Color(0.3, 0.3, 0.32))
		var top := tc + Vector3(cos(a) * 8.0, 2.4, sin(a) * 8.0)
		var d := top - anchor
		batch.add("site", Transform3D(Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.95 else Vector3.RIGHT)
				* Basis.from_scale(Vector3(0.12, 0.12, d.length())), anchor + d / 2.0), Color(0.25, 0.25, 0.27))
	for i in 12:
		var a2 := TAU * i / 12.0
		DistrictSites._b(batch, tc + Vector3(cos(a2) * 8.4, 2.1, sin(a2) * 8.4), Vector3(0.45, 0.25, 0.45), Color(0.3, 1.0, 0.8, 0.3), 0.0, "glow")
	Props.collider(root, Vector3(16, 3.4, 16), tc + Vector3(0, 1.7, 0))
	DistrictSites._sign(batch, root, "ИЗЪЯТО", "poster", Color(0.8, 0.1, 0.1), tc + Vector3(0, 2.6, 8.7), 0.0, 0.7,
			{"bg": Color(0.98, 0.96, 0.9), "font": "block", "tilt": 0.0})
	DistrictSites._sign(batch, root, "ЛОТ № 1. ТАРЕЛКА\nБ/У, ОДИН ВЛАДЕЛЕЦ,\nНЕ БИТА, НЕ ВЗЛЕТАЛА", "board", Color(0.1, 0.1, 0.1),
			tc + Vector3(-9.5, 1.4, 6), 0.0, 0.22, {"bg": Color(1, 1, 0.95), "far": DistrictDressing.SIGN_FAR_M})
	DistrictSites._alien(root, tc + Vector3(-11, 0, 3), PI / 2.0, rng)
	# аукционные ограждения, молоток на кафедре, оценщик с планшетом
	for o in DistrictSites._all(site, "DL_A3_auction_rail"):
		var r4 := DistrictSites._r(o)
		var c4 := DistrictSites.sw(r4.get_center())
		DistrictSites._b(batch, c4 + Vector3(0, 1.0, 0), Vector3(r4.size.x, 0.08, 0.08), Color(0.7, 0.7, 0.72))
		DistrictSites._b(batch, c4 + Vector3(0, 0.5, 0), Vector3(r4.size.x, 0.06, 0.06), Color(0.7, 0.7, 0.72))
		var x := r4.position.x
		while x <= r4.end.x + 0.01:
			DistrictSites._b(batch, DistrictSites._w(x, r4.position.y, 0.55), Vector3(0.08, 1.1, 0.08), Color(0.6, 0.6, 0.62))
			x += 3.0
	var lect := DistrictSites._w(5496, 572)
	DistrictSites._b(batch, lect + Vector3(0, 0.6, 0), Vector3(1.0, 1.2, 0.6), Color(0.45, 0.28, 0.16))
	Props.collider(root, Vector3(1.0, 1.2, 0.6), lect + Vector3(0, 0.6, 0))
	DistrictSites._person(root, lect + Vector3(0, 0, -1.0), 0.0, rng, {"top": Color(0.95, 0.55, 0.1)})
	for k in 7:
		DistrictSites._person(root, DistrictSites._w(5440 + k * 13.0, 585.0 + rng.randf_range(-1.5, 1.5)), PI, rng)
	# въездная вывеска на двух столбах
	var es := DistrictSites._r(DistrictSites._o(site, "DL_A3_entry_sign"))
	var ec := DistrictSites.sw(es.get_center())
	for sx: float in [-1.0, 1.0]:
		DistrictSites._b(batch, ec + Vector3(sx * 7.6, 2.5, 0), Vector3(0.3, 5.0, 0.3), Color(0.25, 0.25, 0.27))
		Props.collider(root, Vector3(0.4, 5.0, 0.4), ec + Vector3(sx * 7.6, 2.5, 0))
	DistrictSites._sign(batch, root, "КООПЕРАТИВ «КРЕДИТ ДОВЕРЧИВЫМ»\nЗАЛОГОВЫЙ ДВОР", "board", Color(1.0, 0.85, 0.4), ec + Vector3(0, 5.0, 0.3), 0.0,
			0.5, {"bg": Color(0.55, 0.1, 0.08), "lamp": true})
	for k in 4:
		DistrictSites._lantern(batch, DistrictSites._w(5420 + k * 50, 598))


# ---------- B1 «Двор свидетелей» ----------

static func _yard(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3500
	var yard := DistrictSites._r(DistrictSites._o(site, "DL_B1_courtyard"))
	batch.box("path", DistrictSites.sw(yard.get_center(), 0.03), Vector3(yard.size.x, 0.03, yard.size.y), 0.0,
			Color(0.82, 0.8, 0.76))
	# газоны по сторонам центрального прохода: проход свободен
	for x0: float in [3412.0, 3512.0]:
		batch.box("lawn", DistrictSites._w(x0 + 37.0, 1510.0, 0.05), Vector3(74, 0.04, 164), 0.0, Color(1.3, 1.5, 0.85))
	DistrictDressing._playground(batch, DistrictSites._w(3428, 1500), 0.0, rng)
	# машины жильцов вдоль западного дома, мордой к стене
	for k in 9:
		var car := CarKit.make(root, [Color(0.85, 0.85, 0.82), Color(0.55, 0.15, 0.12), Color(0.2, 0.3, 0.45)][k % 3], false, k % 3)
		car.position = DistrictSites._w(3405.5, 1446.0 + k * 9.0)
		car.rotation.y = -PI / 2.0
		Props.collider(root, Vector3(CarKit.LENGTH, 1.5, CarKit.WIDTH), car.position + Vector3(0, 0.75, 0))
	# стол доминошников
	var dom := DistrictSites._w(3560, 1585)
	DistrictSites._b(batch, dom + Vector3(0, 0.75, 0), Vector3(1.6, 0.08, 1.0), Color(0.4, 0.55, 0.35))
	DistrictSites._b(batch, dom + Vector3(0, 0.37, 0), Vector3(0.15, 0.75, 0.15), Color(0.3, 0.3, 0.32))
	for k in 4:
		DistrictSites._person(root, dom + Vector3(-0.5 + (k % 2) * 1.0, 0, -1.0 if k < 2 else 1.0), 0.0 if k < 2 else PI, rng,
				{"skirt": false})
	DistrictSites._tree_row(batch, site, "DL_B1_yard_tree_trunk")
	DistrictSites._tree_row(batch, site, "DL_B1_edge_tree_trunk")
	# жилые дома: северные с аркой между ними, западный кирпичный
	for name in ["DL_B1_north_block_w", "DL_B1_north_block_e", "DL_B1_west_block"]:
		var o := DistrictSites._o(site, name)
		_house(root, DistrictSites._r(o), o.mat == "brick", batch, rng)
	_arch(root, site, batch)
	var ws := DistrictSites._r(DistrictSites._o(site, "DL_B1_east_workshop"))
	var wc := DistrictSites._hall(root, ws, 5.0, false, Color(0.3, 0.5, 0.46), Color(0.24, 0.24, 0.26), true)
	DistrictSites._sign(batch, root, "МАСТЕРСКАЯ\nЧИНИМ ЗОНДЫ И ЗАМКИ", "board", Color(0.95, 0.9, 0.8), wc + Vector3(-ws.size.x / 2.0 - 0.1, 3.6, 0),
			-90.0, 0.36, {"bg": Color(0.22, 0.2, 0.18), "lamp": true})
	# лавки с бабушками-свидетельницами
	var benches := DistrictSites._all(site, "DL_B1_bench")
	for i in benches.size():
		var c := DistrictSites.sw(DistrictSites._r(benches[i]).get_center())
		batch.model("bench", c, 0.0)
		if i % 2 == 0:
			DistrictSites._person(root, c + Vector3(-0.5, 0, 0.3), PI, rng, GRANNY)
	DistrictSites._sign(batch, root, "ПОНЯТЫХ\nНЕ ЗАНИМАТЬ", "board", Color(0.1, 0.1, 0.1),
			DistrictSites.sw(DistrictSites._r(benches[2]).get_center()) + Vector3(0, 1.6, -0.4), 0.0, 0.2,
			{"bg": Color(0.95, 0.95, 0.9), "far": DistrictDressing.SIGN_FAR_M})
	# бельё и ковры на верёвках
	for o in DistrictSites._all(site, "DL_B1_laundry_post"):
		var c := DistrictSites.sw(DistrictSites._r(o).get_center())
		DistrictSites._b(batch, c + Vector3(0, 1.5, 0), Vector3(0.1, 3.0, 0.1), Color(0.35, 0.36, 0.38))
	for o in DistrictSites._all(site, "DL_B1_clothesline"):
		var r := DistrictSites._r(o)
		var c := DistrictSites.sw(r.get_center(), 3.0)
		DistrictSites._b(batch, c, Vector3(r.size.x, 0.02, 0.02), Color(0.85, 0.85, 0.82))
		for k in 7:
			batch.add("cloth", Transform3D(Basis().scaled(Vector3(0.7, 0.85, 0.03)), c + Vector3(-9.0 + k * 1.3, -0.45, 0)),
					[Color(0.9, 0.3, 0.3), Color(0.95, 0.95, 0.9), Color(0.35, 0.5, 0.85), Color(0.95, 0.8, 0.3)][(k + int(r.position.x)) % 4])
	for o in DistrictSites._all(site, "DL_B1_hanging_rug"):
		var r := DistrictSites._r(o)
		var c := DistrictSites.sw(r.get_center(), 2.1)
		DistrictSites._b(batch, c, Vector3(r.size.x, 1.8, 0.05), Color(0.62, 0.12, 0.12))
		DistrictSites._b(batch, c + Vector3(0, 0, 0.03), Vector3(r.size.x - 0.6, 1.2, 0.02), Color(0.85, 0.65, 0.25))
		DistrictSites._b(batch, c + Vector3(0, 0, 0.045), Vector3(1.0, 0.6, 0.02), Color(0.15, 0.25, 0.5))
	# одного ковра нет: пустые прищепки и записка
	DistrictSites._sign(batch, root, "КТО ВЗЯЛ КОВЁР —\nВЕРНИ, ВСЁ ВИДЕЛИ", "board", Color(0.1, 0.1, 0.1), DistrictSites._w(3518, 1514.8, 2.4), 0.0, 0.2,
			{"bg": Color(1, 1, 0.92), "far": DistrictDressing.SIGN_FAR_M})
	# приподнятые грядки
	for o in DistrictSites._all(site, "DL_B1_raised_garden"):
		var r := DistrictSites._r(o)
		var c := DistrictSites.sw(r.get_center())
		DistrictSites._b(batch, c + Vector3(0, 0.25, 0), Vector3(r.size.x, 0.5, r.size.y), Color(0.45, 0.35, 0.25))
		DistrictDressing._garden(batch, c + Vector3(0, 0.5, 0), r.size - Vector2(1, 1), rng)
		Props.collider(root, Vector3(r.size.x, 0.5, r.size.y), c + Vector3(0, 0.25, 0))
	# качели
	for name in ["DL_B1_swing_l", "DL_B1_swing_r"]:
		DistrictSites._b(batch, DistrictSites.sw(DistrictSites._r(DistrictSites._o(site, name)).get_center(), 1.5), Vector3(0.15, 3.0, 0.15), Color(0.8, 0.3, 0.2))
	var top := DistrictSites._r(DistrictSites._o(site, "DL_B1_swing_top"))
	var sc := DistrictSites.sw(top.get_center(), 3.1)
	DistrictSites._b(batch, sc, Vector3(top.size.x, 0.15, 0.15), Color(0.8, 0.3, 0.2))
	for sx: float in [-1.4, 1.4]:
		DistrictSites._b(batch, sc + Vector3(sx, -1.25, 0), Vector3(0.6, 0.08, 0.35), Color(0.3, 0.5, 0.75))
		DistrictSites._b(batch, sc + Vector3(sx, -0.6, 0), Vector3(0.03, 1.2, 0.03), Color(0.4, 0.4, 0.42))
	# бабушка держит зонд за антенну: зонд рвётся вверх, бабушка — ни в какую
	var pr := DistrictSites.sw(DistrictSites._r(DistrictSites._o(site, "DL_B1_confiscated_alien_probe")).get_center())
	var probe := Node3D.new()
	probe.name = "ProbeHeld"
	probe.position = pr + Vector3(0, 2.4, 0)
	root.add_child(probe)
	Kit.sphere(probe, 0.9, Vector3.ZERO, Color(0.55, 0.58, 0.65))
	Kit.sphere(probe, 0.35, Vector3(0, 0, 0.75), Color(0.3, 1.0, 0.6), 4.0)
	Kit.cylinder(probe, 1.3, 0.12, Vector3(0, -0.1, 0), Color(0.35, 0.37, 0.42), 0.0, 1.3)
	for i in 3:
		var a := TAU * i / 3.0
		Kit.box(probe, Vector3(0.08, 1.0, 0.08), Vector3(cos(a) * 0.7, -0.9, sin(a) * 0.7), Color(0.3, 0.3, 0.33))
	probe.create_tween().set_loops().tween_property(probe, "position:y", pr.y + 2.9, 0.7).from(pr.y + 2.3) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	DistrictSites._b(batch, pr + Vector3(0.35, 1.4, 0), Vector3(0.03, 1.6, 0.03), Color(0.2, 0.2, 0.22))      # верёвка-поводок
	DistrictSites._person(root, pr + Vector3(0.4, 0, 0.4), PI * 0.8, rng, GRANNY)
	var bench := pr + Vector3(-3.5, 0, 2.5)
	batch.model("bench", bench, 0.6)
	DistrictSites._sign(batch, root, "ВЕРНИ ЛАВКУ —\nОТПУЩУ", "board", Color(0.1, 0.1, 0.1), pr + Vector3(1.6, 1.3, 0.8), -30.0, 0.18,
			{"bg": Color(0.98, 0.95, 0.85), "far": DistrictDressing.SIGN_FAR_M})
	for k in 4:
		DistrictSites._lantern(batch, DistrictSites._w(3420 + k * 54, 1596))


## Жилой дом участка: BuildingKit.house по размеру схемы, высота — 5 этажей.
static func _house(root: Node3D, r: Rect2, brick: bool, batch: DistrictDressing.Batch, rng: RandomNumberGenerator) -> void:
	var at := DistrictSites.sw(r.get_center())
	var built := BuildingKit.house(r.size.x, r.size.y, 5, at, brick, rng)
	var height := 5 * BuildingKit.FLOOR_M + 0.4
	var body := Props.collider(root, Vector3(r.size.x, height, r.size.y), at + Vector3(0, height / 2.0, 0), true)
	var mi := MeshInstance3D.new()
	mi.mesh = built.mesh
	mi.position = Vector3(0, -height / 2.0, 0)
	body.add_child(mi)
	for e: Vector3 in built.entrances:
		batch.lamps.append(e + Vector3(0, 2.4, 0))
		batch.add("spill", Transform3D(Basis().scaled(Vector3(3.6, 1.0, 3.6)), e + Vector3(0, 0.07, 0)), Color(0.8, 0.62, 0.4))


## Арка в северном доме: кирпичные пилоны, над проходом 4 × 5 м — дом до крыши.
static func _arch(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var brick := Color(0.55, 0.32, 0.25)
	for name in ["DL_B1_arch_l", "DL_B1_arch_r"]:
		DistrictSites._hall(root, DistrictSites._r(DistrictSites._o(site, name)), 15.4, true, brick)
	var l := DistrictSites._r(DistrictSites._o(site, "DL_B1_arch_lintel"))
	var c := DistrictSites.sw(l.get_center())
	DistrictSites._b(batch, c + Vector3(0, 10.2, 0), Vector3(l.size.x, 10.4, l.size.y), brick)
	Props.collider(root, Vector3(l.size.x, 10.4, l.size.y), c + Vector3(0, 10.2, 0), true)
	DistrictSites._b(batch, c + Vector3(0, 4.9, l.size.y / 2.0 + 0.05), Vector3(l.size.x + 0.6, 0.4, 0.1), Color(0.75, 0.72, 0.65))
	DistrictSites._b(batch, c + Vector3(0, 4.4, 0), Vector3(0.3, 0.2, 0.3), Color(1.0, 0.8, 0.5, 0.0), 0.0, "glow")
	batch.lamps.append(c + Vector3(0, 4.3, 0))
	DistrictSites._sign(batch, root, "ДВОР СВИДЕТЕЛЕЙ", "letters", Color(1.0, 0.85, 0.5), c + Vector3(0, 6.2, l.size.y / 2.0 + 0.2), 0.0, 0.55)
	DistrictSites._sign(batch, root, "КОНЕЦ СВЕТА —\nПОСЛЕ ТИХОГО ЧАСА", "board", Color(0.1, 0.1, 0.1), c + Vector3(7.5, 2.4, l.size.y / 2.0 + 0.08),
			0.0, 0.3, {"bg": Color(0.95, 0.95, 0.9), "lamp": true})


# ---------- конторы A1, A2, B3 ----------

static func _office(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch, p: String, title: String, poster: String,
		wall: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(p)
	var r := DistrictSites._r(DistrictSites._o(site, p + "_office"))
	var c := DistrictSites._hall(root, r, 12.0, false, wall, Color(0.3, 0.31, 0.33), true)
	DistrictSites._paving(batch, DistrictSites._r(DistrictSites._o(site, p + "_plaza")))
	var front := c + Vector3(0, 0, r.size.y / 2.0)
	DistrictSites._sign(batch, root, title, "letters", Color(1.0, 0.85, 0.5), front + Vector3(0, 13.4, 0.2), 0.0, 1.1)
	DistrictSites._sign(batch, root, poster, "lightbox", Color(0.12, 0.15, 0.3), front + Vector3(-20, 6.5, 0.1), 0.0, 0.45,
			{"bg": Color(0.95, 0.96, 1.0)})
	var u := DistrictSites._r(DistrictSites._o(site, p + "_ufo"))
	var uc := DistrictSites.sw(u.get_center(), 13.8)
	batch.add("tank", Transform3D(Basis().scaled(Vector3(22, 1.6, 22)), uc), Color(0.6, 0.62, 0.68))
	batch.add("crown", Transform3D(Basis().scaled(Vector3(8, 4.5, 8)), uc + Vector3(0, 1.3, 0)), Color(0.5, 0.85, 1.0))
	for i in 10:
		var a := TAU * i / 10.0
		DistrictSites._b(batch, uc + Vector3(cos(a) * 10.6, 0, sin(a) * 10.6), Vector3(0.7, 0.35, 0.7), Color(0.3, 1.0, 0.8), 0.0, "glow")
	for o in DistrictSites._all(site, p + "_queue"):
		var q := DistrictSites._r(o)
		DistrictSites._b(batch, DistrictSites._w(q.get_center().x, q.position.y, 0.85), Vector3(q.size.x, 0.05, 0.05), Color(0.75, 0.1, 0.1))
	var x0 := r.position.x - 9.0
	for k in 10:
		var pos := DistrictSites._w(x0 + (k % 5) * 9.0, r.end.y + 25.0 + (k / 5) * 12.0)
		if k == 3:
			DistrictSites._alien(root, pos, -PI / 2.0, rng)
		else:
			DistrictSites._person(root, pos, -PI / 2.0, rng)
	for k in 3:
		DistrictSites._lantern(batch, front + Vector3(-24 + k * 24, 0, 12))


# ---------- C1, C2, C3 ----------

static func _station(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var r := DistrictSites._r(DistrictSites._o(site, "DL_C1_boiler"))
	var c := DistrictSites._hall(root, r, 15.0, true, Color(0.55, 0.31, 0.23))
	DistrictSites._sign(batch, root, "СТАНЦИЯ «ТИХАЯ ДОСТАВКА»\nПОСЫЛКИ ИЗ КОСМОСА — БЕЗ ВСКРЫТИЯ (ПОЧТИ)", "board", Color(0.95, 0.9, 0.8),
			c + Vector3(0, 7.5, r.size.y / 2.0 + 0.1), 0.0, 0.5, {"bg": Color(0.2, 0.22, 0.25), "lamp": true})
	for name in ["DL_C1_chimney", "DL_C1_chimney2"]:
		var o := DistrictSites._o(site, name)
		var foot := DistrictSites.sw(DistrictSites._r(o).get_center())
		var h := float(o.z[1])
		var bands := int(h / 5.0)
		for i in bands:
			batch.add("tank", Transform3D(Basis().scaled(Vector3(4.2 - i * 0.1, h / bands, 4.2 - i * 0.1)),
					foot + Vector3(0, (i + 0.5) * h / bands, 0)), DistrictSites.RED if i % 2 == 1 and i > bands - 4 else Color(0.6, 0.34, 0.26))
		Props.collider(root, Vector3(4.2, h, 4.2), foot + Vector3(0, h / 2.0, 0))
		var smoke := Kit.particles(root, foot + Vector3(0, h + 1.0, 0), Color(0.85, 0.82, 0.78, 0.35), 12, 7.0, Vector3(0.6, 2.0, 0.2),
				0.15, 4.0)
		smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rng := RandomNumberGenerator.new()
	rng.seed = 3480
	for k in 4:
		batch.model("boxes", c + Vector3(-24 + k * 12.0, 0, r.size.y / 2.0 + 6.0), rng.randf() * TAU)
	DistrictSites._person(root, c + Vector3(6, 0, r.size.y / 2.0 + 5.0), PI, rng, {"top": Color(0.95, 0.55, 0.1)})


static func _passage(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4480
	var hall := DistrictSites._r(DistrictSites._o(site, "DL_C2_hall"))
	var hc := DistrictSites._hall(root, hall, 9.0, true, Color(0.6, 0.36, 0.26), Color(0.3, 0.3, 0.32), true)
	DistrictSites._sign(batch, root, "ПАССАЖ «ТРУД БЕЗ ОПЛАТЫ»\nБИРЖА ТРУДА · 2 ЭТАЖ", "lightbox", Color(0.6, 0.12, 0.1),
			hc + Vector3(0, 7.2, hall.size.y / 2.0 + 0.1), 0.0, 0.5, {"bg": Color(1.0, 0.95, 0.85)})
	var st := DistrictSites._r(DistrictSites._o(site, "DL_C2_store"))
	var sc := DistrictSites._hall(root, st, 6.0, false, Color(0.82, 0.8, 0.72), Color(0.3, 0.3, 0.32), true)
	DistrictSites._sign(batch, root, "ВАКАНСИИ:\nСОГЛАСНЫЙ — 1 ШТ.", "board", Color(0.1, 0.1, 0.1), sc + Vector3(-st.size.x / 2.0 - 0.1, 3.6, 0), -90.0,
			0.36, {"bg": Color(0.95, 0.95, 0.9), "lamp": true})
	var wares := [Color(0.9, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.4, 0.7, 0.4), Color(0.4, 0.5, 0.9)]
	for o in DistrictSites._all(site, "DL_C2_stall_"):
		var r := DistrictSites._r(o)
		var c := DistrictSites.sw(r.get_center())
		var col := Color(0.28, 0.5, 0.45) if o.mat == "teal" else Color(0.68, 0.18, 0.14)
		DistrictSites._b(batch, c + Vector3(0, 1.2, 0), Vector3(r.size.x, 2.4, r.size.y), col)
		DistrictSites._b(batch, c + Vector3(0, 2.55, 0.4), Vector3(r.size.x + 0.4, 0.15, r.size.y + 0.8), col.darkened(0.25))
		DistrictSites._b(batch, c + Vector3(r.size.x / 2.0 + 0.4, 0.85, 0), Vector3(0.8, 0.1, r.size.y - 1.0), wares[rng.randi() % 4])
		Props.collider(root, Vector3(r.size.x, 2.4, r.size.y), c + Vector3(0, 1.2, 0))
		if rng.randf() < 0.5:
			DistrictSites._person(root, c + Vector3(r.size.x / 2.0 + 1.4, 0, 0), -PI / 2.0, rng)
	for name in ["DL_C2_gate_l", "DL_C2_gate_r"]:
		var g := DistrictSites.sw(DistrictSites._r(DistrictSites._o(site, name)).get_center())
		DistrictSites._b(batch, g + Vector3(0, 3.0, 0), Vector3(0.5, 6.0, 0.5), Color(0.3, 0.3, 0.32))
		Props.collider(root, Vector3(0.6, 6.0, 0.6), g + Vector3(0, 3.0, 0))
	var sg := DistrictSites._r(DistrictSites._o(site, "DL_C2_sign"))
	DistrictSites._sign(batch, root, "ТРУД БЕЗ ОПЛАТЫ", "board", Color(1.0, 0.9, 0.6), DistrictSites.sw(sg.get_center(), 6.2) + Vector3(0, 0, 0.3), 0.0,
			0.8, {"bg": Color(0.55, 0.1, 0.08), "lamp": true})


static func _greenhouses(root: Node3D, site: Dictionary, batch: DistrictDressing.Batch) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5480
	var first := Vector3.ZERO
	for i in 4:
		var r := DistrictSites._r(DistrictSites._o(site, "DL_C3%d" % i))
		var c := DistrictSites.sw(r.get_center())
		if i == 0:
			first = c
		batch.box("greenhouse", c + Vector3(0, 2.0, 0), Vector3(r.size.x, 4.0, r.size.y))
		var z := -r.size.y / 2.0
		while z <= r.size.y / 2.0:
			DistrictSites._b(batch, c + Vector3(0, 4.05, z), Vector3(r.size.x + 0.1, 0.12, 0.12), Color(0.85, 0.87, 0.85))
			z += 5.0
		DistrictSites._b(batch, c + Vector3(0, 4.2, 0), Vector3(0.15, 0.2, r.size.y), Color(0.85, 0.87, 0.85))
		DistrictDressing._garden(batch, c, r.size - Vector2(2, 2), rng)
		Props.collider(root, Vector3(r.size.x, 4.0, r.size.y), c + Vector3(0, 2.0, 0))
	DistrictSites._sign(batch, root, "РАССАДА БУДУЩЕГО\nВЫРАСТИМ, ЧТО ПРИКАЖУТ", "board", Color(0.95, 0.9, 0.8), first + Vector3(-7.5, 2.6, 26), 0.0,
			0.36, {"bg": Color(0.2, 0.35, 0.2), "lamp": true})
	DistrictSites._person(root, first + Vector3(-8, 0, 20), PI / 2.0, rng, GRANNY)
