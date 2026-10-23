class_name GameData
## All tunable numbers and texts of «Песня» in one place.

const SAVE_PATH := "user://pesnya_save.json"
const SAVE_VERSION := 9

const ITEMS := {
	"seeds": {"name": "Семки", "rarity": 0, "slot": "", "power": 0, "desc": "Голубиная валюта. Баба Зина говорит, полезные."},
	"feather": {"name": "Пёрышко", "rarity": 0, "slot": "", "power": 0, "desc": "Мягкое. Можно щекотать врагов (нельзя)."},
	"crumbs": {"name": "Крошки батона", "rarity": 0, "slot": "", "power": 0, "desc": "Остатки голубиной роскоши."},
	"bolt": {"name": "Гайка от самоката", "rarity": 0, "slot": "", "power": 0, "desc": "Самокат без неё скрипит. Теперь скрипишь ты."},
	"dust": {"name": "Мешочек пыли", "rarity": 0, "slot": "", "power": 0, "desc": "Пылесос копил его годами."},
	"cap": {"name": "Кепка вымогателя", "rarity": 1, "slot": "head", "power": 4, "desc": "Восьмиклинка. +4 к силе и к понтам."},
	"chain": {"name": "Цепочка голубя", "rarity": 1, "slot": "neck", "power": 4, "desc": "Тонкая, но своя."},
	"sneaker": {"name": "Кроссовок-беглец", "rarity": 1, "slot": "feet", "power": 5, "desc": "Второй где-то во дворе."},
	"bell": {"name": "Звонок самоката", "rarity": 1, "slot": "neck", "power": 6, "desc": "Дзынь! Враги оборачиваются."},
	"filter": {"name": "Фильтр-нагрудник", "rarity": 1, "slot": "body", "power": 7, "desc": "Защищает от пыли и критики."},
	"mic": {"name": "Микрофон «Голубиный»", "rarity": 2, "slot": "weapon", "power": 12, "desc": "Воркует в бит. +12 к силе."},
	"turbo": {"name": "Турбо-кеды", "rarity": 2, "slot": "feet", "power": 11, "desc": "Сняты с самого быстрого самоката двора."},
	"hose": {"name": "Шланг-скакалка", "rarity": 2, "slot": "weapon", "power": 14, "desc": "Им можно и прыгать, и бить в такт."},
	"luck": {"name": "Перо удачи", "rarity": 2, "slot": "neck", "power": 10, "desc": "То самое перо, о котором шепчет весь двор."},
	"pakhan_cap": {"name": "Кепка Пахана", "rarity": 3, "slot": "head", "power": 25, "lvl": 5, "desc": "Легендарная. Голуби кланяются при виде."},
	# 0.3 — стройка Глушилки
	"lens": {"name": "Линза Тишинки", "rarity": 0, "slot": "", "power": 0, "desc": "В неё видно только тишину."},
	"foam": {"name": "Кусок поролона", "rarity": 0, "slot": "", "power": 0, "desc": "Им обита вся Глушилка. Мягко и скучно."},
	"helmet": {"name": "Каска прораба", "rarity": 1, "slot": "head", "power": 8, "desc": "Оранжевая. Защищает от кирпичей и плохих рифм."},
	"core": {"name": "Ядро Тишинки", "rarity": 1, "slot": "neck", "power": 9, "desc": "Гудит, если рядом кто-то не попадает в бит."},
	"rebar": {"name": "Арматура-метроном", "rarity": 2, "slot": "weapon", "power": 18, "desc": "Отбивает ритм сама. +18 к силе."},
	"vest": {"name": "Жилет сигнальный", "rarity": 2, "slot": "body", "power": 15, "desc": "Светится в темноте и на танцполе."},
	"megaphone": {"name": "Рупор Шумодава", "rarity": 3, "slot": "weapon", "power": 34, "lvl": 8, "desc": "Легендарный. Шептать в него запрещено."},
	# 0.4 — серверная Кощея
	"ears": {"name": "Уши робо-зайца", "rarity": 0, "slot": "", "power": 0, "desc": "Ловят Wi-Fi и сплетни."},
	"chip": {"name": "Микросхема тишины", "rarity": 0, "slot": "", "power": 0, "desc": "Отвечает за «ш-ш-ш». Больше не отвечает."},
	"duck": {"name": "Резиновая уточка", "rarity": 1, "slot": "neck", "power": 12, "desc": "Пищит в бит. ПИИ-ИК! Лучший отладчик."},
	"headset": {"name": "Корона-гарнитура", "rarity": 2, "slot": "head", "power": 22, "desc": "Серебряная. Звонки Кощею больше не приходят."},
	"turtleneck": {"name": "Водолазка технодиректора", "rarity": 2, "slot": "body", "power": 24, "desc": "Чёрная. Носишь — и хочется всё оптимизировать."},
	"gusli": {"name": "Гусли Кощея", "rarity": 3, "slot": "weapon", "power": 46, "lvl": 10, "desc": "Отобрал у соседа 500 лет назад. Теперь они звучат у тебя."},
	"flash": {"name": "Флешка «ПЕСНЯ_ФИНАЛ»", "rarity": 3, "slot": "neck", "power": 30, "lvl": 9, "desc": "Перепрошитое бессмертие. Внутри — только музыка."},
	# 0.5 — набережная и Змей Горыныч
	"gull_feather": {"name": "Перо чайки", "rarity": 0, "slot": "", "power": 0, "desc": "Пахнет рыбой и наглостью."},
	"cassette": {"name": "Кассета с джинглом", "rarity": 0, "slot": "", "power": 0, "desc": "Одна и та же песня. Тридцать раз подряд."},
	"keychain": {"name": "Колонка-брелок", "rarity": 1, "slot": "neck", "power": 14, "desc": "Маленькая, но басит."},
	"captain": {"name": "Фуражка капитана", "rarity": 2, "slot": "head", "power": 27, "desc": "Чайка носила её с гордостью. Теперь ты."},
	"phones": {"name": "Наушники Горыныча", "rarity": 3, "slot": "head", "power": 36, "lvl": 10, "desc": "Тройные. В каждом ухе — своя песня."},
	"jacket": {"name": "Чешуйчатая косуха", "rarity": 3, "slot": "body", "power": 40, "lvl": 10, "desc": "Сброшена Горынычем после линьки. Огнеупорная, стильная."},
	"golden_mic": {"name": "Микрофон «Золотой бит»", "rarity": 3, "slot": "weapon", "power": 54, "lvl": 10, "desc": "Награда двора. В него попадают даже те, кто не попадает в долю."},
	# 0.6 — награды новых соседей (уникальные: Люба их не скупает)
	"boots_pavlin": {"name": "Бутсы Павлина Футболиста", "rarity": 2, "slot": "feet", "power": 12, "lvl": 3, "stats": {"luck": 3}, "unique": true,
		"desc": "Для газона, но по асфальту тоже. Шипы не царапают даже паркет."},
	"apron": {"name": "Фартук чистюли", "rarity": 2, "slot": "body", "power": 13, "lvl": 4, "stats": {"hp": 4}, "unique": true,
		"desc": "Белоснежный. Грязь к нему не липнет — стесняется."},
	"goggles": {"name": "Лётные очки Шустрого Пилота", "rarity": 2, "slot": "head", "power": 15, "lvl": 5, "stats": {"speed": 3}, "unique": true,
		"desc": "С ними бит видно заранее. И кашу на взлёте."},
	"gamepad": {"name": "Геймпад-брелок Кента Организатора", "rarity": 2, "slot": "neck", "power": 16, "lvl": 6, "stats": {"rhythm": 3}, "unique": true,
		"desc": "Кнопки нажимаются в такт. Кент Организатор проверял — десять из десяти."},
	"climb_shoes": {"name": "Кеды скалолаза", "rarity": 2, "slot": "feet", "power": 18, "lvl": 7, "stats": {"speed": 4}, "unique": true,
		"desc": "Липкие подошвы. По стенам — почти. По лужам — точно."},
	"beret": {"name": "Берет Товарища Клюквы", "rarity": 2, "slot": "head", "power": 24, "lvl": 9, "stats": {"hp": 5}, "unique": true,
		"desc": "Клюквенного цвета. Носить с честью, снимать — с разрешения."},
	"comb": {"name": "Каменный гребень", "rarity": 2, "slot": "weapon", "power": 26, "lvl": 9, "stats": {"rhythm": 4}, "unique": true,
		"desc": "Гребень Щебня Не Атлета. Им и бороду, и врагов — строго в ритм."},
	"phone": {"name": "Смартфон Мистера Малого", "rarity": 2, "slot": "neck", "power": 26, "lvl": 11, "stats": {"vibe": 5}, "unique": true,
		"desc": "Трещина на экране — это не баг, это стиль. Вайб на максималках."},
	"ladle": {"name": "Половник Меткого Змея", "rarity": 3, "slot": "weapon", "power": 50, "lvl": 12, "stats": {"luck": 5}, "unique": true,
		"desc": "Мешает уху и бьёт в бит. Ссссильная вещь."},
	"mill_cap": {"name": "Картуз Молодого Мельника", "rarity": 2, "slot": "head", "power": 30, "lvl": 12, "stats": {"luck": 4}, "unique": true,
		"desc": "Пахнет хлебом и квасом. Голуби снимают кепки при встрече."},
	"compass": {"name": "Компас Мыслителя Зари", "rarity": 3, "slot": "neck", "power": 34, "lvl": 13, "stats": {"speed": 4}, "unique": true,
		"desc": "Показывает не на север, а туда, где интересно."},
	"lantern": {"name": "Свет Ярика-Фонарика", "rarity": 3, "slot": "weapon", "power": 58, "lvl": 14, "stats": {"rhythm": 4, "vibe": 6}, "unique": true,
		"desc": "Тёплая искра Жар-птицы. Мигает точно в бит."},
	# 0.7 — парк «Заря»
	"grass": {"name": "Клок газона", "rarity": 0, "slot": "", "power": 0, "desc": "Подстрижен смайликом. Павлин Футболист бы заплакал."},
	"wrapper": {"name": "Фантик", "rarity": 0, "slot": "", "power": 0, "desc": "Шуршит сам по себе. Пакет-призрак ушёл не до конца."},
	"spring": {"name": "Пружинка робо-утки", "rarity": 0, "slot": "", "power": 0, "desc": "Делает «кря» упругим."},
	"pixel": {"name": "Битый пиксель", "rarity": 0, "slot": "", "power": 0, "desc": "Остался от кружочка загрузки. Всё ещё грузится."},
	"panama": {"name": "Панама садовника", "rarity": 1, "slot": "head", "power": 30, "lvl": 14, "desc": "От солнца, от дождя и от газонокосилок."},
	"pruner": {"name": "Секатор «Ровный газон»", "rarity": 2, "slot": "weapon", "power": 60, "lvl": 16, "desc": "Стрижёт строго в бит. Павлин Футболист одобряет."},
	"bag_cape": {"name": "Дождевик из пакета", "rarity": 1, "slot": "body", "power": 30, "lvl": 14, "desc": "Шуршит при ходьбе. Зато сухо."},
	"rustle_hoodie": {"name": "Худи «Шшш»", "rarity": 2, "slot": "body", "power": 46, "lvl": 16, "desc": "Тихое снаружи, громкое внутри."},
	"quack_whistle": {"name": "Свисток-кряква", "rarity": 1, "slot": "neck", "power": 28, "lvl": 15, "desc": "Свистит, как утка. Утки в шоке."},
	"flippers": {"name": "Ласты робо-утки", "rarity": 2, "slot": "feet", "power": 44, "lvl": 16, "desc": "Хлоп-хлоп в такт. По асфальту — тоже."},
	"spinner": {"name": "Спиннер загрузки", "rarity": 1, "slot": "neck", "power": 30, "lvl": 15, "desc": "Крутится вечно. Как обновление."},
	"visor99": {"name": "Козырёк «99%»", "rarity": 2, "slot": "head", "power": 48, "lvl": 17, "desc": "Показывает, что почти готово. Всегда."},
	"wheel_mic": {"name": "Микрофон «Спица»", "rarity": 3, "slot": "weapon", "power": 78, "lvl": 18, "desc": "Спица Колеса Обновлений. Звенит в бит, как велосипедный звонок."},
	"cabin_helmet": {"name": "Шлем «Кабинка»", "rarity": 3, "slot": "head", "power": 62, "lvl": 18, "desc": "С окошками. Обзор — как с самого верха колеса."},
	"dawn_bomber": {"name": "Бомбер «Заря»", "rarity": 3, "slot": "body", "power": 66, "lvl": 18, "desc": "Розовый, как рассвет без подписки."},
	# 0.7 — награды соседей (уникальные)
	"boomerang": {"name": "Мяч-бумеранг", "rarity": 2, "slot": "weapon", "power": 64, "lvl": 16, "stats": {"vibe": 5}, "unique": true,
		"desc": "Пнёшь — вернётся. Как слава Павлина Футболиста."},
	"spray_gloves": {"name": "Перчатки-брызгалки", "rarity": 2, "slot": "weapon", "power": 62, "lvl": 15, "stats": {"rhythm": 4}, "unique": true,
		"desc": "Брызгают точно в такт. Чисто и ритмично."},
	"pilot_scarf": {"name": "Шарф Шустрого Пилота", "rarity": 2, "slot": "neck", "power": 46, "lvl": 17, "stats": {"speed": 5}, "unique": true,
		"desc": "Тот самый, что улетел. Вернулся сам — он верный."},
	"grapple": {"name": "Верёвка-кошка", "rarity": 2, "slot": "neck", "power": 48, "lvl": 18, "stats": {"speed": 6}, "unique": true,
		"desc": "С ней Джек Скалолаз повесил флаг на самую верхнюю кабинку. Страховка прилагается."},
	"rhythm_medal": {"name": "Медаль «За ритм»", "rarity": 2, "slot": "neck", "power": 46, "lvl": 17, "stats": {"rhythm": 5, "hp": 3}, "unique": true,
		"desc": "Вручена Товарищем Клюквой. Неофициально, но от души."},
	"ring_lamp": {"name": "Кольцевая лампа", "rarity": 2, "slot": "neck", "power": 44, "lvl": 16, "stats": {"vibe": 6}, "unique": true,
		"desc": "Со стрима Мистера Малого. Светит так, что Горыныч улыбнулся. Трижды."},
	# 0.7 — лавка Сингл Принца (за золотые синглы)
	"prince_jacket": {"name": "Пиджак Сингл Принца", "rarity": 3, "slot": "body", "power": 64, "lvl": 16, "stats": {"vibe": 6, "luck": 4}, "unique": true,
		"desc": "Фиолетовый бархат, золотые погоны. «Это не скидка — это ремикс цены»."},
	"single_shades": {"name": "Очки «Сингл»", "rarity": 3, "slot": "head", "power": 58, "lvl": 15, "stats": {"rhythm": 6}, "unique": true,
		"desc": "Тёмные в любое время суток. Бит сквозь них видно лучше."},
	"plunger": {"name": "Вантуз Вентилёва", "rarity": 3, "slot": "weapon", "power": 76, "lvl": 17, "stats": {"luck": 4}, "unique": true,
		"desc": "Удар в бит оглушает врага на 0,8 с. «Чпок — и тишина»."},
	"crown_tilt": {"name": "Корона набок", "rarity": 3, "slot": "head", "power": 66, "lvl": 18, "stats": {"luck": 8}, "unique": true,
		"desc": "Маленькая, золотая, всегда чуть набекрень. Как у Сингл Принца."},
	"earbud": {"name": "Один наушник", "rarity": 3, "slot": "neck", "power": 54, "lvl": 16, "stats": {"rhythm": 4, "vibe": 4}, "unique": true,
		"desc": "Второй — у Сингл Принца. Сингл же."},
	# 0.8 — Чебуречная «Сочная»
	"whisker": {"name": "Усик таракана", "rarity": 0, "slot": "", "power": 0, "desc": "Ловит сплетни и запах чебуреков."},
	"fly_wing": {"name": "Крылышко мухи", "rarity": 0, "slot": "", "power": 0, "desc": "Жужжит, даже когда муха улетела."},
	"crust": {"name": "Корочка чебурека", "rarity": 0, "slot": "", "power": 0, "desc": "Хрустит в бит. Почти съедобная."},
	"suction": {"name": "Присоска", "rarity": 0, "slot": "", "power": 0, "desc": "Присасывается ко всему, кроме удачи."},
	"dumpling": {"name": "Пельмешек", "rarity": 0, "slot": "", "power": 0, "desc": "Маленький, тёплый, обиженный. Не ешь — он разговаривает."},
	"ninja_band": {"name": "Повязка ниндзя", "rarity": 1, "slot": "head", "power": 32, "lvl": 15, "desc": "Таракан носил её с честью. Усы в комплект не входят."},
	"nunchaku": {"name": "Нунчаки из сосисок", "rarity": 2, "slot": "weapon", "power": 66, "lvl": 17, "desc": "Бьют в бит и пахнут обедом."},
	"bill": {"name": "Счёт за чебуреки", "rarity": 1, "slot": "neck", "power": 30, "lvl": 15, "desc": "Муха-коллектор выставила. Платить не обязательно."},
	"facet_shades": {"name": "Очки «Фасетка»", "rarity": 2, "slot": "head", "power": 50, "lvl": 17, "desc": "Видно всё и сразу. Особенно бит."},
	"oily_apron": {"name": "Фартук в масле", "rarity": 1, "slot": "body", "power": 32, "lvl": 15, "desc": "Брызги горячего сока ему не страшны."},
	"skewer": {"name": "Шампур-рапира", "rarity": 2, "slot": "weapon", "power": 68, "lvl": 18, "desc": "Колет точно в такт. Дзынь — шашлык!"},
	"plumber_boots": {"name": "Сапоги сантехника", "rarity": 1, "slot": "feet", "power": 30, "lvl": 16, "desc": "Не промокают даже в санузле, который не работает с 2009 года."},
	"hose_sax": {"name": "Шланг-саксофон", "rarity": 2, "slot": "weapon", "power": 68, "lvl": 18, "desc": "Из санузла. Звучит как джаз и немного как трубы."},
	"rolling_pin": {"name": "Скалка Вечности", "rarity": 3, "slot": "weapon", "power": 84, "lvl": 18, "desc": "Раскатывает тесто и врагов. Тесто — бесконечно, враги — нет."},
	"chef_hat": {"name": "Колпак «Сочный»", "rarity": 3, "slot": "head", "power": 66, "lvl": 18, "desc": "Высокий, как стопка чебуреков. Тётя Сочня одобряет."},
	"dough_apron": {"name": "Фартук «Тесто Вечности»", "rarity": 3, "slot": "body", "power": 70, "lvl": 18, "desc": "Мука не пачкает, тесто не липнет. Вечный."},
	# 0.8 — Прачечная «Ромашка»
	"lone_sock": {"name": "Одинокий носок", "rarity": 0, "slot": "", "power": 0, "desc": "Пары нет. Зато есть характер."},
	"button": {"name": "Пуговица из барабана", "rarity": 0, "slot": "", "power": 0, "desc": "Стиралка не отдавала её годами."},
	"scale_bit": {"name": "Накипь утюга", "rarity": 0, "slot": "", "power": 0, "desc": "Белая, твёрдая и обиженная."},
	"foam_drop": {"name": "Капля пены", "rarity": 0, "slot": "", "power": 0, "desc": "Пахнет ромашкой. Скользкая."},
	"striped_socks": {"name": "Носки в полоску", "rarity": 1, "slot": "feet", "power": 32, "lvl": 16, "desc": "Нашли пару! Носки счастливы — и ты быстрее."},
	"sock_scarf": {"name": "Шарф из носков", "rarity": 2, "slot": "neck", "power": 50, "lvl": 18, "desc": "Сто одиноких носков наконец вместе."},
	"drum_hat": {"name": "Шапка-барабан", "rarity": 1, "slot": "head", "power": 34, "lvl": 17, "desc": "Крутится, если сильно задуматься."},
	"spin_robe": {"name": "Халат «Отжим»", "rarity": 2, "slot": "body", "power": 54, "lvl": 18, "desc": "Махровый, после центрифуги. Мягкий до головокружения."},
	"iron_vest": {"name": "Жилет «Отглажено»", "rarity": 1, "slot": "body", "power": 34, "lvl": 17, "desc": "Стрелки на нём острее твоих рифм."},
	"iron_knuckle": {"name": "Утюг-кастет", "rarity": 2, "slot": "weapon", "power": 70, "lvl": 19, "desc": "Гладит врагов с паром. Режим «лён»."},
	"bubble_neck": {"name": "Пузырь-кулон", "rarity": 1, "slot": "neck", "power": 32, "lvl": 17, "desc": "Не лопается. Проверено каскадёрами."},
	"foam_sneakers": {"name": "Кеды на пене", "rarity": 2, "slot": "feet", "power": 52, "lvl": 19, "desc": "Скользишь, как по ромашковому полу. Быстро и чисто."},
	"drumsticks": {"name": "Палочки «Судьба»", "rarity": 3, "slot": "weapon", "power": 90, "lvl": 20, "desc": "Отбивают бит так, что стиралки встают в очередь."},
	"porthole_helmet": {"name": "Шлем-иллюминатор", "rarity": 3, "slot": "head", "power": 70, "lvl": 20, "desc": "Смотришь на мир, как бельё из барабана: всё крутится, но чисто."},
	"fluffy_robe": {"name": "Пушистый халат", "rarity": 3, "slot": "body", "power": 74, "lvl": 20, "desc": "После «деликатной стирки». Мягкий и непобедимый."},
	# 0.8 — награды заданий и спецматериалы (уникальные)
	"wrench": {"name": "Разводной ключ «Сантехник»", "rarity": 2, "slot": "weapon", "power": 66, "lvl": 15, "stats": {"luck": 5}, "unique": true,
		"desc": "Вентилёв чинил им санузел неделю. Теперь он чинит врагов."},
	"warehouse_key": {"name": "Ключ от склада №0", "rarity": 3, "slot": "", "power": 0, "unique": true,
		"desc": "Микрочип из пельменя: «Склад №0. Рынок. Тьма». Откроет подпольный склад на Рынке электроники."},
	"clapper": {"name": "Хлопушка режиссёра", "rarity": 2, "slot": "weapon", "power": 70, "lvl": 17, "stats": {"rhythm": 5}, "unique": true,
		"desc": "Хлоп — и дубль! Враги путают, где кадр, а где бит."},
	"detective_glasses": {"name": "Очки «Детектив»", "rarity": 2, "slot": "head", "power": 52, "lvl": 18, "stats": {"luck": 6}, "unique": true,
		"desc": "Как у бабы Зины в сериале. Видно, кто не доел."},
	"dough_mat": {"name": "Тесто вечности", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал. Не кончается. Пригодится изобретателям на Помойке."},
	"drum_mat": {"name": "Барабан стиралки", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал. Крутится сам. Пригодится изобретателям на Помойке."},
	# 0.9 «Своё дело» — спецматериалы (падают в ремиксах боссов и за задания)
	"feather_mat": {"name": "Перо Пахана", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Голубиный рэп». Пахан роняет его, когда уходит в отрыв."},
	"concrete_mat": {"name": "Бетон сцены", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Бетонный бас». Шумодав был сценой — бетон помнит музыку."},
	"chip_mat": {"name": "Чип бессмертия", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Бессмертие 1.1». Внутри — чужая подписка. Кеша её обнулит."},
	"scale_mat": {"name": "Чешуя Горыныча", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Три куплета». Тёплая, с запахом рекламы."},
	"spoke_mat": {"name": "Спица колеса", "rarity": 2, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Бесконечная загрузка». Крутится, даже когда не надо."},
	"atom_mat": {"name": "Гаечный ключ «Атом»", "rarity": 3, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Спецматериал из ремикса «Генеральная уборка». Откручивает всё, даже плохое настроение."},
	"light_mat": {"name": "Светочастицы", "rarity": 3, "slot": "", "power": 0, "unique": true, "mat": true,
		"desc": "Рассвет, соскобленный с неба. Их прячут на подпольном складе Рынка электроники (0.10)."},
	# 0.9 — Помойка: хлам и вещи мобов
	"rat_tail": {"name": "Хвост-брелок", "rarity": 0, "slot": "", "power": 0, "desc": "Крыса-коллектор носила на нём ключи от чужих кошельков."},
	"frost_cube": {"name": "Кубик инея", "rarity": 0, "slot": "", "power": 0, "desc": "Не тает. Холодильник был очень обижен."},
	"coil": {"name": "Матрасная пружина", "rarity": 0, "slot": "", "power": 0, "desc": "Прыгает сама. Кеша говорит, это «энергия сна»."},
	"collector_cap": {"name": "Кепка коллектора", "rarity": 1, "slot": "head", "power": 34, "lvl": 17, "desc": "На ней написано «ВЕРНИ ДОЛГ». Долг вернули — кепка твоя."},
	"coin_sack": {"name": "Мешок с медью", "rarity": 2, "slot": "weapon", "power": 70, "lvl": 19, "desc": "Звенит в бит. Крысы смотрят с уважением."},
	"fridge_door": {"name": "Дверца-щит", "rarity": 1, "slot": "body", "power": 36, "lvl": 19, "desc": "С магнитиками. Холодильник больше не кусается — отдал дверцу."},
	"ice_shades": {"name": "Очки «Иней»", "rarity": 2, "slot": "head", "power": 54, "lvl": 20, "desc": "Всё видно, всё прохладно. Бит — в особенности."},
	"bounce_slippers": {"name": "Тапки-пружинки", "rarity": 1, "slot": "feet", "power": 34, "lvl": 18, "desc": "Шаг — и ты уже на полметра дальше."},
	"pillow_neck": {"name": "Подушка-воротник", "rarity": 2, "slot": "neck", "power": 52, "lvl": 20, "desc": "Мягко держит голову. Даже под ударом."},
	"junk_crown": {"name": "Корона Короля Хлама", "rarity": 3, "slot": "head", "power": 74, "lvl": 22, "desc": "Из крышек, ложек и гордости. Король был не прав, корона — ни при чём."},
	"press_gauntlets": {"name": "Перчатки-пресс", "rarity": 3, "slot": "weapon", "power": 96, "lvl": 22, "desc": "Утрамбовывают врагов в аккуратный кубик."},
	"tarp_cape": {"name": "Мантия из брезента", "rarity": 3, "slot": "body", "power": 78, "lvl": 22, "desc": "Королевская, непромокаемая, с запахом приключений."},
	# 0.9 — поделки Кеши и Деда (крафт из хлама)
	"pot_helmet": {"name": "Шлем-кастрюля", "rarity": 2, "slot": "head", "power": 56, "lvl": 19, "stats": {"rhythm": 4},
		"desc": "Дед Утиль: «Звенит, если ударить в бит. Значит, правильная»."},
	"wire_scarf": {"name": "Шарф из проводов", "rarity": 2, "slot": "neck", "power": 54, "lvl": 19, "stats": {"luck": 5},
		"desc": "Кеша сплёл. Ловит удачу и немного вай-фай."},
	"mattress_coat": {"name": "Пальто-матрас", "rarity": 2, "slot": "body", "power": 58, "lvl": 20, "stats": {"hp": 6},
		"desc": "Тёплое, мягкое, удар держит. Спать в нём тоже можно."},
	"spring_sneakers": {"name": "Кеды на пружинах", "rarity": 2, "slot": "feet", "power": 56, "lvl": 20, "stats": {"speed": 5},
		"desc": "Подпрыгивают на каждом шаге. Догоняют даже крысу."},
	"basin_guitar": {"name": "Гитара из тазика", "rarity": 2, "slot": "weapon", "power": 76, "lvl": 21, "stats": {"vibe": 5},
		"desc": "Три струны, один тазик, ноль сомнений. Звучит как свалка — в хорошем смысле."},
	"inventor_crown": {"name": "Корона изобретателя", "rarity": 3, "slot": "head", "power": 78, "lvl": 22, "stats": {"luck": 6, "rhythm": 6}, "unique": true,
		"desc": "Из гаечного ключа «Атом» и чипа бессмертия. Дед Утиль: «Носи — и думай»."},
	# 0.9 — награды заданий соседей
	"propeller_cap": {"name": "Пропеллер-кепка", "rarity": 2, "slot": "head", "power": 56, "lvl": 18, "stats": {"speed": 5}, "unique": true,
		"desc": "Шустрый Пилот проверил: крутится. Взлететь не даёт, но очень хочется."},
	"hoop_neck": {"name": "Обруч от бочки", "rarity": 2, "slot": "neck", "power": 54, "lvl": 19, "stats": {"rhythm": 5}, "unique": true,
		"desc": "Молодой Мельник: «Квас без обруча — просто вода с мечтой»."},
	"joystick": {"name": "Джойстик «Кент»", "rarity": 2, "slot": "weapon", "power": 76, "lvl": 20, "stats": {"vibe": 5}, "unique": true,
		"desc": "Кент Организатор собрал приставку, а джойстик отдал тебе. Комбо — как в игре."},
}

const SELL_PRICE := [5, 20, 60, 0]

const MOBS := {
	"pigeon": {"name": "Голубь-вымогатель", "hp": [70.0, 32.0], "dmg": [5.0, 3.0], "xp": [24, 9], "scale": 0.72, "height": 3.0, "radius": 1.1,
		"speed": 4.4, "aggro": 7.0, "leash": 15.0, "atk": 1.5,
		"loot": [[0.05, "mic"], [0.22, "cap|chain|sneaker"], [0.7, "seeds|feather|crumbs"]], "res": []},
	"scooter": {"name": "Самокат-беглец", "hp": [45.0, 18.0], "dmg": [7.0, 3.0], "xp": [22, 8], "scale": 1.0, "height": 1.7, "radius": 0.6,
		"speed": 3.4, "aggro": 9.0, "leash": 18.0, "atk": 2.4,
		"loot": [[0.05, "turbo"], [0.2, "bell|sneaker"], [0.6, "bolt"]], "res": [[0.75, "wires", 1, 2]]},
	"vacuum": {"name": "Злой пылесос", "hp": [130.0, 40.0], "dmg": [7.0, 3.0], "xp": [36, 12], "scale": 1.0, "height": 1.6, "radius": 0.85,
		"speed": 2.3, "aggro": 6.5, "leash": 14.0, "atk": 1.8,
		"loot": [[0.06, "hose"], [0.22, "filter"], [0.6, "dust"]], "res": [[0.5, "cement", 1, 2], [0.6, "brick", 2, 3]]},
	"pakhan": {"name": "Голубиный Пахан", "hp": [1500.0, 0.0], "dmg": [26.0, 0.0], "xp": [420, 0], "scale": 1.25, "height": 3.0, "radius": 1.1,
		"speed": 3.6, "aggro": 12.0, "leash": 22.0, "atk": 1.8, "loot": [], "res": [], "boss": true},
	"drone": {"name": "Тишинка", "hp": [55.0, 24.0], "dmg": [6.0, 2.6], "xp": [30, 10], "scale": 1.0, "height": 2.7, "radius": 0.6,
		"speed": 3.4, "aggro": 10.0, "leash": 17.0, "atk": 2.6,
		"loot": [[0.04, "rebar|vest"], [0.18, "helmet|core"], [0.6, "lens|foam"]], "res": [[0.6, "wires", 1, 3], [0.3, "cement", 1, 2]]},
	"hare": {"name": "Робо-заяц", "hp": [95.0, 30.0], "dmg": [9.0, 3.2], "xp": [40, 12], "scale": 1.0, "height": 2.3, "radius": 0.6,
		"speed": 5.0, "aggro": 8.0, "leash": 16.0, "atk": 2.2,
		"loot": [[0.04, "headset|turtleneck"], [0.2, "duck|core"], [0.6, "ears|chip"]], "res": [[0.5, "wires", 2, 3]]},
	"safe_hare": {"name": "Заяц-сейф", "hp": [4000.0, 0.0], "dmg": [18.0, 0.0], "xp": [300, 0], "scale": 1.7, "height": 2.3, "radius": 0.7,
		"speed": 4.6, "aggro": 30.0, "leash": 60.0, "atk": 1.6, "loot": [], "res": [], "boss": true},
	"koschei": {"name": "Кощей Бессмертный", "hp": [11000.0, 0.0], "dmg": [30.0, 0.0], "xp": [900, 0], "scale": 1.0, "height": 3.0, "radius": 0.8,
		"speed": 3.0, "aggro": 30.0, "leash": 60.0, "atk": 1.8, "loot": [], "res": [], "boss": true},
	"gull": {"name": "Чайка-перекупщица", "hp": [110.0, 32.0], "dmg": [10.0, 3.4], "xp": [44, 13], "scale": 0.62, "height": 2.7, "radius": 0.9,
		"speed": 5.6, "aggro": 8.0, "leash": 16.0, "atk": 1.4,
		"loot": [[0.04, "captain"], [0.2, "keychain"], [0.6, "gull_feather|cassette"]], "res": [[0.4, "planks", 2, 4]]},
	"autoplay": {"name": "Колонка-автоплей", "hp": [180.0, 40.0], "dmg": [14.0, 3.0], "xp": [50, 14], "scale": 1.0, "height": 2.4, "radius": 0.8,
		"speed": 0.0, "aggro": 11.0, "leash": 99.0, "atk": 3.2,
		"loot": [[0.05, "captain"], [0.22, "keychain"], [0.6, "cassette"]], "res": [[0.6, "wires", 2, 4]]},
	"gorynych": {"name": "Змей Горыныч", "hp": [16000.0, 0.0], "dmg": [34.0, 0.0], "xp": [1000, 0], "scale": 1.0, "height": 6.4, "radius": 2.4,
		"speed": 2.4, "aggro": 16.0, "leash": 40.0, "atk": 2.2, "loot": [], "res": [], "boss": true},
	"shumodav": {"name": "Шумодав", "hp": [6500.0, 0.0], "dmg": [34.0, 0.0], "xp": [700, 0], "scale": 0.62, "height": 7.6, "radius": 2.6,
		"speed": 2.6, "aggro": 14.0, "leash": 30.0, "atk": 2.2, "loot": [], "res": [], "boss": true},
	# 0.7 — парк «Заря»
	"mower": {"name": "Газонокосилка-бунтарь", "hp": [150.0, 36.0], "dmg": [10.0, 3.3], "xp": [52, 14], "scale": 1.0, "height": 1.8, "radius": 0.8,
		"speed": 3.2, "aggro": 9.0, "leash": 18.0, "atk": 2.6,
		"loot": [[0.04, "pruner"], [0.18, "panama"], [0.6, "grass"]], "res": [[0.5, "planks", 2, 3], [0.3, "wires", 1, 2]]},
	"bag": {"name": "Пакет-призрак", "hp": [100.0, 28.0], "dmg": [9.0, 3.1], "xp": [48, 14], "scale": 1.0, "height": 2.4, "radius": 0.6,
		"speed": 4.4, "aggro": 9.5, "leash": 18.0, "atk": 1.9,
		"loot": [[0.04, "rustle_hoodie"], [0.18, "bag_cape"], [0.6, "wrapper"]], "res": [[0.4, "planks", 1, 3]]},
	"duck": {"name": "Робо-утка", "hp": [130.0, 32.0], "dmg": [10.0, 3.4], "xp": [54, 15], "scale": 1.0, "height": 1.9, "radius": 0.7,
		"speed": 2.8, "aggro": 11.0, "leash": 17.0, "atk": 2.8,
		"loot": [[0.04, "flippers"], [0.18, "quack_whistle"], [0.6, "spring"]], "res": [[0.5, "wires", 2, 3]]},
	"loader": {"name": "Кружочек загрузки", "hp": [90.0, 26.0], "dmg": [12.0, 3.6], "xp": [56, 15], "scale": 1.0, "height": 2.0, "radius": 0.6,
		"speed": 5.4, "aggro": 10.0, "leash": 18.0, "atk": 1.8,
		"loot": [[0.04, "visor99"], [0.18, "spinner"], [0.6, "pixel"]], "res": [[0.5, "wires", 1, 3], [0.3, "cement", 1, 2]]},
	"wheel": {"name": "Колесо Обновлений", "hp": [32000.0, 0.0], "dmg": [36.0, 0.0], "xp": [1400, 0], "scale": 1.0, "height": 10.0, "radius": 2.8,
		"speed": 0.0, "aggro": 20.0, "leash": 99.0, "atk": 2.4, "loot": [], "res": [], "boss": true},
	# 0.8 — Чебуречная «Сочная»
	"roach": {"name": "Таракан-ниндзя", "hp": [110.0, 30.0], "dmg": [10.0, 3.3], "xp": [52, 14], "scale": 1.0, "height": 1.3, "radius": 0.6,
		"speed": 5.6, "aggro": 9.0, "leash": 17.0, "atk": 1.7,
		"loot": [[0.04, "nunchaku"], [0.18, "ninja_band"], [0.6, "whisker"]], "res": [[0.4, "planks", 1, 2]]},
	"fly": {"name": "Муха-коллектор", "hp": [80.0, 24.0], "dmg": [9.0, 3.0], "xp": [50, 14], "scale": 1.0, "height": 2.6, "radius": 0.5,
		"speed": 4.8, "aggro": 10.0, "leash": 18.0, "atk": 1.3,
		"loot": [[0.04, "facet_shades"], [0.18, "bill"], [0.6, "fly_wing"]], "res": [[0.4, "wires", 1, 2]]},
	"cheb": {"name": "Чебурек-брызгун", "hp": [170.0, 40.0], "dmg": [11.0, 3.5], "xp": [58, 15], "scale": 1.0, "height": 1.6, "radius": 0.8,
		"speed": 2.4, "aggro": 9.0, "leash": 16.0, "atk": 3.0,
		"loot": [[0.04, "skewer"], [0.18, "oily_apron"], [0.6, "crust"]], "res": [[0.5, "planks", 2, 3]]},
	"plunger_mob": {"name": "Вантуз-прыгун", "hp": [120.0, 32.0], "dmg": [11.0, 3.4], "xp": [56, 15], "scale": 1.0, "height": 1.6, "radius": 0.55,
		"speed": 3.8, "aggro": 9.0, "leash": 16.0, "atk": 2.4,
		"loot": [[0.04, "hose_sax"], [0.18, "plumber_boots"], [0.6, "suction"]], "res": [[0.5, "wires", 1, 3]]},
	"pelmeshek": {"name": "Пельмешек", "hp": [40.0, 12.0], "dmg": [6.0, 2.0], "xp": [12, 3], "scale": 1.0, "height": 0.9, "radius": 0.45,
		"speed": 4.4, "aggro": 16.0, "leash": 40.0, "atk": 1.4, "loot": [[0.5, "dumpling"]], "res": []},
	"dough": {"name": "Тесто Вечности", "hp": [26000.0, 0.0], "dmg": [34.0, 0.0], "xp": [1300, 0], "scale": 1.0, "height": 4.6, "radius": 2.3,
		"speed": 1.6, "aggro": 18.0, "leash": 40.0, "atk": 2.3, "loot": [], "res": [], "boss": true},
	# 0.8 — Прачечная «Ромашка»
	"sock": {"name": "Носок-одиночка", "hp": [100.0, 28.0], "dmg": [10.0, 3.3], "xp": [54, 15], "scale": 1.0, "height": 1.7, "radius": 0.5,
		"speed": 4.6, "aggro": 9.5, "leash": 17.0, "atk": 1.7,
		"loot": [[0.04, "sock_scarf"], [0.18, "striped_socks"], [0.6, "lone_sock"]], "res": [[0.4, "planks", 1, 2]]},
	"washer": {"name": "Стиралка-центрифуга", "hp": [220.0, 46.0], "dmg": [12.0, 3.6], "xp": [64, 16], "scale": 1.0, "height": 2.0, "radius": 0.95,
		"speed": 2.0, "aggro": 8.0, "leash": 14.0, "atk": 2.8,
		"loot": [[0.04, "spin_robe"], [0.18, "drum_hat"], [0.6, "button"]], "res": [[0.5, "wires", 2, 3], [0.3, "cement", 1, 2]]},
	"iron": {"name": "Утюг-гладиатор", "hp": [150.0, 36.0], "dmg": [13.0, 3.8], "xp": [62, 16], "scale": 1.0, "height": 1.5, "radius": 0.7,
		"speed": 3.2, "aggro": 9.0, "leash": 18.0, "atk": 2.6,
		"loot": [[0.04, "iron_knuckle"], [0.18, "iron_vest"], [0.6, "scale_bit"]], "res": [[0.5, "brick", 2, 3]]},
	"bubble": {"name": "Пена-пузырь", "hp": [70.0, 22.0], "dmg": [8.0, 2.8], "xp": [46, 13], "scale": 1.0, "height": 2.2, "radius": 0.6,
		"speed": 3.0, "aggro": 9.0, "leash": 16.0, "atk": 2.0,
		"loot": [[0.04, "foam_sneakers"], [0.18, "bubble_neck"], [0.6, "foam_drop"]], "res": [[0.3, "cement", 1, 2]]},
	"drum": {"name": "Барабан Судьбы", "hp": [30000.0, 0.0], "dmg": [36.0, 0.0], "xp": [1500, 0], "scale": 1.0, "height": 6.4, "radius": 2.7,
		"speed": 0.0, "aggro": 20.0, "leash": 99.0, "atk": 2.4, "loot": [], "res": [], "boss": true},
	# 0.9 — Помойка
	"rat": {"name": "Крыса-коллектор", "hp": [120.0, 30.0], "dmg": [11.0, 3.5], "xp": [58, 16], "scale": 1.0, "height": 1.2, "radius": 0.55,
		"speed": 5.4, "aggro": 10.0, "leash": 20.0, "atk": 1.6,
		"loot": [[0.04, "coin_sack"], [0.18, "collector_cap"], [0.6, "rat_tail"]], "res": [[0.5, "wires", 1, 3]]},
	"fridge": {"name": "Холодильник-кусака", "hp": [260.0, 50.0], "dmg": [14.0, 4.0], "xp": [70, 18], "scale": 1.0, "height": 2.4, "radius": 0.9,
		"speed": 1.8, "aggro": 8.0, "leash": 14.0, "atk": 2.6,
		"loot": [[0.04, "ice_shades"], [0.18, "fridge_door"], [0.6, "frost_cube"]], "res": [[0.5, "wires", 2, 3], [0.4, "brick", 2, 3]]},
	"mattress": {"name": "Матрас-пружина", "hp": [180.0, 40.0], "dmg": [13.0, 3.8], "xp": [64, 17], "scale": 1.0, "height": 2.2, "radius": 0.8,
		"speed": 2.6, "aggro": 9.0, "leash": 16.0, "atk": 2.8,
		"loot": [[0.04, "pillow_neck"], [0.18, "bounce_slippers"], [0.6, "coil"]], "res": [[0.5, "planks", 2, 3]]},
	"king": {"name": "Король Хлама", "hp": [36000.0, 0.0], "dmg": [38.0, 0.0], "xp": [1700, 0], "scale": 1.0, "height": 5.6, "radius": 2.6,
		"speed": 1.2, "aggro": 22.0, "leash": 99.0, "atk": 2.6, "loot": [], "res": [], "boss": true},
}

const RES_NAMES := {"brick": "Кирпич", "cement": "Цемент", "planks": "Доски", "wires": "Провода"}
const RES_ORDER := ["brick", "cement", "planks", "wires"]

# Buildings at the base. cost[level-1] = [coins, {res}]; effect[level-1] = value
const BUILDINGS := {
	"grill": {"name": "Мангал", "desc": "Жарит шаурму сам. Шаурма лечит 40% здоровья (кнопка еды в бою).",
		"cost": [[60, {"planks": 6, "brick": 4}], [200, {"planks": 12, "brick": 10, "wires": 2}], [500, {"planks": 20, "brick": 20, "cement": 6, "wires": 6}],
			[1200, {"planks": 24, "brick": 24, "cement": 10, "wires": 10}], [2400, {"planks": 30, "brick": 30, "cement": 14, "wires": 14}]],
		"period": [600, 420, 300, 180, 120], "cap": [5, 5, 5, 8, 10], "fx": "шаурма раз в %d мин"},
	"garden": {"name": "Огород", "desc": "Растит урожай, Люба покупает его за монеты.",
		"cost": [[50, {"planks": 8}], [180, {"planks": 14, "wires": 4}], [450, {"planks": 20, "cement": 8, "wires": 8}],
			[1100, {"planks": 26, "cement": 10, "wires": 10}], [2200, {"planks": 32, "cement": 14, "wires": 14}]],
		"period": [600, 600, 600, 600, 600], "coins": [25, 50, 90, 180, 260], "cap": [6, 6, 6, 6, 6], "fx": "+%d монет раз в 10 мин"},
	"gym": {"name": "Гаражный спортзал", "desc": "Качалка из покрышек и гантелей. Больше здоровья.",
		"cost": [[80, {"brick": 6, "wires": 2}], [250, {"brick": 14, "cement": 4, "wires": 4}], [600, {"brick": 24, "cement": 10, "wires": 8}],
			[1300, {"brick": 30, "cement": 14, "wires": 10}], [2500, {"brick": 36, "cement": 18, "wires": 14}]],
		"value": [0.08, 0.16, 0.25, 0.35, 0.45], "fx": "+%d%% к здоровью"},
	"stage": {"name": "Сцена", "desc": "Репетиции на публику. Вайб копится быстрее — ХИТ! чаще.",
		"cost": [[100, {"planks": 10, "wires": 4}], [300, {"planks": 16, "wires": 10}], [700, {"planks": 24, "cement": 6, "wires": 16}],
			[1400, {"planks": 30, "cement": 10, "wires": 20}], [2700, {"planks": 36, "cement": 14, "wires": 26}]],
		"value": [0.2, 0.4, 0.6, 0.8, 1.0], "fx": "+%d%% к вайбу"},
	"studio": {"name": "Студия", "desc": "Звукозапись в гараже. Твои удары звучат мощнее.",
		"cost": [[150, {"brick": 8, "cement": 4, "wires": 6}], [400, {"brick": 16, "cement": 8, "wires": 12}], [900, {"brick": 26, "cement": 14, "wires": 20}],
			[1600, {"brick": 30, "cement": 18, "wires": 24}], [3000, {"brick": 36, "cement": 22, "wires": 30}]],
		"value": [0.05, 0.1, 0.15, 0.2, 0.26], "fx": "+%d%% к урону"},
	"solar": {"name": "Солнечные панели", "desc": "Питают Васю. Он возвращается быстрее.",
		"cost": [[120, {"wires": 8, "brick": 4}], [300, {"wires": 14, "cement": 4}], [650, {"wires": 22, "cement": 10}],
			[1200, {"wires": 28, "cement": 12, "brick": 8}], [2400, {"wires": 34, "cement": 16, "brick": 12}]],
		"value": [0.15, 0.3, 0.45, 0.6, 0.75], "fx": "Вася быстрее на %d%%"},
}
const BUILD_ORDER := ["grill", "garden", "gym", "stage", "studio", "solar"]

# Robot errands: seconds, coin cost, reward
const ERRANDS := {
	"ezhik": {"name": "Гипермаркет «Ёжик»", "time": 180, "cost": 40, "res": {"planks": 6, "wires": 3}, "food": 1,
		"note": "Доски, провода и шаурма навынос"},
	"stroy": {"name": "Стройрынок", "time": 480, "cost": 100, "res": {"brick": 10, "cement": 5, "planks": 4}, "food": 0,
		"note": "Кирпич, цемент, доски"},
	"dump": {"name": "Свалка (бесплатно)", "time": 720, "cost": 0, "res": {"brick": 4, "planks": 4, "wires": 5}, "food": 0,
		"note": "Всего понемногу + шанс редкой вещи"},
}
const ERRAND_ORDER := ["ezhik", "stroy", "dump"]

const SHOP := [
	["food", "Шаурма", 30, 1, "Лечит 40% здоровья. Фирменная, с хрустом."],
	["planks", "Доски ×5", 60, 5, "Для мангала, огорода, сцены"],
	["brick", "Кирпич ×5", 70, 5, "Для спортзала и студии"],
	["wires", "Провода ×3", 60, 3, "Для студии и панелей"],
	["cement", "Цемент ×3", 70, 3, "Для улучшений"],
]

const DAILIES := [
	["pigeon", "Разогнать голубей", 8, 60, {"planks": 4}],
	["scooter", "Поймать самокаты", 3, 70, {"wires": 3}],
	["vacuum", "Выключить пылесосы", 2, 80, {"cement": 2, "brick": 4}],
]

# Map names (loading screen, minimap)
const MAP_NAMES := {"yard": "двор «Берёзки»", "garages": "ГК «Песня»", "stroyka": "стройку Глушилки", "server": "серверную Кощея",
	"embankment": "набережную и Калинов мост", "park": "парк «Заря»", "cheburek": "Чебуречную «Сочная»", "laundry": "Прачечную «Ромашка»",
	"dump": "Помойку"}
const MAPS := ["yard", "garages", "stroyka", "server", "embankment", "park", "cheburek", "laundry", "dump"]

# Quest 3 «Флешка Кощея»
const Q3_DRONES := 8
const MOUNT_SPEED := 11.0

# Quest 4 «Перепрошивка»
const Q4_HARES := 6
const RAP_LOCK := 4
const RAP_LINES := ["Тишина — не продукт,", "бит — не по подписке,", "открывай, железный друг,", "я пришёл без записки!"]

# 0.5: concert in ГК «Песня» and quest 5 «Бэкап Горыныча»
const Q5_SPEAKERS := 6
# note pattern in beats from the start (halves are off-beats); 48 beats ≈ 30 s at 96 BPM
const CONCERT_NOTES := [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10.5, 11, 12, 13, 14, 15, 16, 16.5, 17, 18, 19, 20, 21, 22, 22.5, 23,
	24, 25, 26, 27, 28, 28.5, 29, 29.5, 30, 32, 33, 34, 34.5, 35, 36, 37, 38, 38.5, 39, 40, 41, 42, 43, 44, 44.5, 45, 46, 47]
const CONCERT_LINES := ["Это песня, песня, песня во дворе,", "от балкона до гаража — в одной игре!", "Если стало тихо — не беда, не грусти:",
	"хлопни раз, хлопни два — и бит запусти!"]


# ================================================================== 0.6: levels 1–70 and item stats
const MAX_LEVEL := 70
const STAT_NAMES := {"rhythm": "Ритм", "luck": "Удача", "hp": "Стойкость", "speed": "Скорость", "vibe": "Вайб"}
const STAT_ORDER := ["rhythm", "luck", "hp", "speed", "vibe"]
const SLOT_STAT := {"head": "rhythm", "neck": "luck", "body": "hp", "feet": "speed", "weapon": "vibe"}
const SLOT_STAT_VAL := [0, 4, 7, 11]
const SLOT_NAMES := {"head": "голова", "neck": "шея", "body": "тело", "feet": "ноги", "weapon": "в руках"}


## Experience needed to go from level l to l + 1: gentle up to 10, then a steep curve.
static func xp_for_level(l: int) -> int:
	var base := 80 + l * 60
	if l < 10:
		return base
	return int(base + 22.0 * pow(float(l - 9), 2.2))


## Required level of a piece of equipment (explicit "lvl" or derived from its power, 1–10 for the old items).
static func item_level(it: Dictionary) -> int:
	if it.has("lvl"):
		return int(it.lvl)
	return clampi(int(it.power) / 5 + 1, 1, 10)


## Secondary stats: one by slot and rarity + the item's own bonus.
static func item_stats(it: Dictionary) -> Dictionary:
	var out := {}
	if str(it.slot) == "":
		return out
	var main: String = SLOT_STAT[it.slot]
	var v: int = SLOT_STAT_VAL[clampi(int(it.rarity), 0, 3)]
	if v > 0:
		out[main] = v
	var extra: Dictionary = it.get("stats", {})
	for k in extra:
		out[k] = int(out.get(k, 0)) + int(extra[k])
	return out


static func stats_text(st: Dictionary) -> String:
	var p := []
	for k in STAT_ORDER:
		if int(st.get(k, 0)) > 0:
			p.append("%s +%d" % [STAT_NAMES[k], int(st[k])])
	return " · ".join(p)


# ================================================================== 0.7: boss remixes, golden singles, Сингл Принц, the city map
## Boss remixes: re-fight a defeated boss at its arena (the «РЕМИКС» console). Loot (golden singles) once a day per boss.
const REMIX := {
	"pakhan": {"title": "Голубиный рэп", "map": "yard", "pos": Vector3(0, 0, -24), "lvl": 7, "need": ["quest", 5], "console": Vector3(-8.5, 0, -26.8), "rot": 0.0,
		"twist": "Зовёт голубей трижды за бой и кидается перьями-сюрикенами", "where": "двор, у гаражей", "items": ["pakhan_cap", "mic"]},
	"shumodav": {"title": "Бетонный бас", "map": "stroyka", "pos": Vector3(-18.5, 0, 0), "lvl": 10, "need": ["quest3", 6], "console": Vector3(-12.0, 0, 6.5), "rot": PI,
		"twist": "Шёпот тишины теперь идёт с басовыми волнами — перепрыгивай рывком", "where": "стройка, площадка у Глушилки", "npc": "shumodav",
		"items": ["megaphone", "vest", "rebar"]},
	"koschei": {"title": "Бессмертие 1.1", "map": "server", "pos": Vector3(-20, 0, 0), "lvl": 12, "need": ["quest4", 8], "console": Vector3(-6.5, 0, -4.6), "rot": 0.0,
		"twist": "Две подписки сразу: рэп-баттл до 5 ударов в бит", "where": "серверная, у железного дуба", "items": ["gusli", "headset", "turtleneck"]},
	"gorynych": {"title": "Три куплета", "map": "embankment", "pos": Vector3(-23, 0, -1.5), "lvl": 12, "need": ["quest5", 7], "console": Vector3(-27.5, 0, 2.8), "rot": PI,
		"twist": "Рекламные паузы без перерыва — все три головы поют до конца", "where": "набережная, у Калинова моста", "npc": "gorynych",
		"items": ["phones", "jacket"]},
	"wheel": {"title": "Бесконечная загрузка", "map": "park", "pos": Vector3(22, 0, 13), "lvl": 18, "need": ["quest6", 6], "console": Vector3(14.6, 0, 18.4), "rot": PI * 0.75,
		"twist": "Кружочки загрузки без конца и кольцо жёлтых кругов", "where": "парк «Заря», у колеса", "items": ["wheel_mic", "cabin_helmet", "dawn_bomber"]},
	"dough": {"title": "Тесто 2.0", "map": "cheburek", "pos": Vector3(-22, 0, -12), "lvl": 18, "need": ["quest7", 3], "console": Vector3(-16.6, 0, -3.0), "rot": PI / 2,
		"twist": "Делится вдвое чаще, а лепёшки из теста падают рядами", "where": "Чебуречная, двор за кухней", "items": ["rolling_pin", "chef_hat", "dough_apron"]},
	"drum": {"title": "Отжим 1400", "map": "laundry", "pos": Vector3(0, 0, -15), "lvl": 20, "need": ["quest7", 5], "console": Vector3(8.8, 0, -8.0), "rot": -PI / 2,
		"twist": "Центрифуга крутит быстрее, носки летят в два ряда", "where": "Прачечная, зал премьеры", "items": ["drumsticks", "porthole_helmet", "fluffy_robe"]},
	"king": {"title": "Генеральная уборка", "map": "dump", "pos": Vector3(14, 0, -12), "lvl": 22, "need": ["quest8", 3], "console": Vector3(3.6, 0, -3.2), "rot": PI * 0.75,
		"twist": "Пресс-атаки с трёх сторон сразу и мусорный залп рядами", "where": "Помойка, площадка пресса", "items": ["junk_crown", "press_gauntlets", "tarp_cape"]},
}
## 0.9: every remix win drops the boss's special material (not limited by the day): [Демо, Сингл, Альбом, Платина]
const REMIX_MAT := {"pakhan": "feather_mat", "shumodav": "concrete_mat", "koschei": "chip_mat", "gorynych": "scale_mat", "wheel": "spoke_mat",
	"dough": "dough_mat", "drum": "drum_mat", "king": "atom_mat"}
const REMIX_MAT_N := [1, 1, 2, 3]
const REMIX_ORDER := ["pakhan", "shumodav", "koschei", "gorynych", "wheel", "dough", "drum", "king"]
## [name, hp ×, damage ×, level +, golden singles]
const REMIX_DIFF := [["Демо", 1.0, 1.0, 0, 1], ["Сингл", 1.45, 1.2, 1, 2], ["Альбом", 2.0, 1.45, 2, 3], ["Платина", 2.8, 1.75, 3, 5]]
const REMIX_HP := {"pakhan": 0.7, "shumodav": 0.9, "koschei": 1.0, "gorynych": 1.1, "wheel": 1.15, "dough": 1.1, "drum": 1.2, "king": 1.25}

## Сингл Принц appears for 3 minutes; random visits every 30–40 minutes of play (after the first meeting)
const PRINCE_TIME := 180.0
const PRINCE_EVERY := [1800.0, 2400.0]
const PRINCE_SHOP := {
	"metronome": {"name": "Метроном Сингл Принца", "price": 4, "kind": "buff", "desc": "10 минут окно бита шире на 30 мс. «Это не чит — это ремикс времени»."},
	"pass": {"name": "Пропуск в ремикс", "price": 2, "kind": "pass", "desc": "+1 бой с добычей, если сегодня с этого босса ты её уже забрал."},
	"royal_food": {"name": "Шаурма «Королевская» ×3", "price": 1, "kind": "food", "desc": "Лечит как обычная, но ешь её как принц."},
	"prince_jacket": {"price": 12, "kind": "item"},
	"single_shades": {"price": 10, "kind": "item"},
	"plunger": {"price": 16, "kind": "item"},
	"crown_tilt": {"price": 15, "kind": "item"},
	"earbud": {"price": 9, "kind": "item"},
}
const METRONOME_SECS := 600.0
const METRONOME_WIN := 0.03

## Aerotaxi of Шустрый Пилот «Ложка» (side quest «Воздушный патруль»): 0.8 — from 170 coins, the farther the dearer
const TAXI_BASE := 170
const TAXI_STEP := 10


static func taxi_price(from_map: String, to_map: String) -> int:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	for pl in CITY_PLACES:
		if pl.get("map", "") == from_map:
			a = pl.p
		if pl.get("map", "") == to_map:
			b = pl.p
	var d := a.distance_to(b)
	return TAXI_BASE + TAXI_STEP * int(round(maxf(0.0, d - 0.12) * 45.0))

## The city map of Рубин (screen coordinates 0..1 inside the map area)
const CITY_DISTRICTS := [
	["Над городом и за порталом", Rect2(0.01, 0.0, 0.98, 0.11)],
	["Новостройки", Rect2(0.01, 0.14, 0.25, 0.37)],
	["Центр «Берёзки»", Rect2(0.28, 0.14, 0.34, 0.37)],
	["Промзона", Rect2(0.64, 0.14, 0.35, 0.37)],
	["Окраина «Частный сектор»", Rect2(0.01, 0.54, 0.25, 0.28)],
	["Река", Rect2(0.28, 0.54, 0.71, 0.28)],
	["За городом и под землёй", Rect2(0.01, 0.85, 0.98, 0.14)],
]
const CITY_PLACES := [
	{"id": "yard", "name": "Двор «Берёзки»", "p": Vector2(0.40, 0.36), "map": "yard"},
	{"id": "garages", "name": "ГК «Песня»", "p": Vector2(0.53, 0.23), "map": "garages"},
	{"id": "stroyka", "name": "Стройка Глушилки", "p": Vector2(0.73, 0.25), "map": "stroyka", "up": true},
	{"id": "server", "name": "Серверная Кощея", "p": Vector2(0.73, 0.43), "map": "server"},
	{"id": "embankment", "name": "Набережная", "p": Vector2(0.42, 0.62), "map": "embankment", "up": true},
	{"id": "park", "name": "Парк «Заря»", "p": Vector2(0.42, 0.76), "map": "park"},
	{"id": "cheb", "name": "Чебуречная", "p": Vector2(0.31, 0.24), "map": "cheburek"},
	{"id": "laundry", "name": "Прачечная", "p": Vector2(0.53, 0.44), "map": "laundry"},
	{"id": "tower", "name": "Телебашня", "p": Vector2(0.59, 0.37), "ver": "1.0", "about": "Финал Части 2: здесь споёт Жар-птица"},
	{"id": "dump", "name": "Помойка", "p": Vector2(0.87, 0.22), "map": "dump"},
	{"id": "market", "name": "Рынок электроники", "p": Vector2(0.89, 0.34), "ver": "0.10", "about": "Подпольный склад светочастиц"},
	{"id": "taxi", "name": "Таксопарк", "p": Vector2(0.88, 0.46), "ver": "1.1", "about": "Внедорожник «Носорог» у вокзала"},
	{"id": "parkour", "name": "Паркур Парк", "p": Vector2(0.07, 0.24), "ver": "0.11", "about": "Ищем профи, чтобы расписать детсад"},
	{"id": "kinder", "name": "Детсад «Бабочка»", "p": Vector2(0.18, 0.35), "ver": "0.11", "about": "Плюшевый мишка Потапыч и детская Олимпиада"},
	{"id": "police", "name": "Полиция", "p": Vector2(0.08, 0.46), "ver": "1.4", "about": "Иностранец-халявщик Мистер Завтра"},
	{"id": "airsales", "name": "«Золотой воздух»", "p": Vector2(0.07, 0.62), "ver": "1.2", "about": "Золотые банки с воздухом прошлого"},
	{"id": "major", "name": "Участок Мажора", "p": Vector2(0.19, 0.69), "ver": "1.3", "about": "«Здоровая медицина» Мажора-Альфонса"},
	{"id": "sanat", "name": "Санаторий", "p": Vector2(0.08, 0.77), "ver": "1.5", "about": "Поддельные часы «Секундомер-Люкс»"},
	{"id": "politics", "name": "Парк Политиков", "p": Vector2(0.72, 0.72), "ver": "1.7", "about": "Парковка машины времени и полёт в космос"},
	{"id": "airfield", "name": "Аэродром «Турник»", "p": Vector2(0.12, 0.92), "ver": "1.6", "about": "Прыжки с парашютом на краю Рубина"},
	{"id": "metro", "name": "Метро-2", "p": Vector2(0.52, 0.92), "ver": "1.1", "about": "Станция в каждом районе"},
	{"id": "cloud", "name": "Облако №9", "p": Vector2(0.30, 0.055), "ver": "1.8", "about": "Дом Бога Здорово — он уже спускается к людям"},
	{"id": "orbit", "name": "Орбита", "p": Vector2(0.62, 0.055), "ver": "1.8", "about": "«Вечные часы» Кощея"},
	{"id": "portal", "name": "Тридевятое царство", "p": Vector2(0.88, 0.055), "ver": "1.9", "about": "Лукоморье и Кощеево царство"},
]
const CITY_LINKS := [["yard", "garages"], ["garages", "stroyka"], ["stroyka", "server"], ["yard", "embankment"], ["embankment", "park"],
	["yard", "cheb"], ["yard", "laundry"], ["stroyka", "dump"]]
const CITY_INFO := {
	"yard": ["Голуби, самокаты, пылесосы · ур. 2–6", "Баба Зина, Люба, Дядя Миша, Павлин Футболист, Невысокий Лис", "Здесь всё начинается"],
	"garages": ["Твой бокс №40, постройки и Вася · концерт", "Петрович, Шустрый Пилот, Кент Организатор, Джек Скалолаз", "Двор → арка «ГК Песня» у гаражей"],
	"stroyka": ["Тишинки и самокаты · ур. 6–8", "Товарищ Клюква, Щебень Не Атлет, Шумодав", "ГК → западные ворота (путёвка Петровича)"],
	"server": ["Робо-зайцы · ур. 9–10", "Мистер Малой", "Стройка → лифт-Шумодав на крышу Глушилки"],
	"embankment": ["Колонки-автоплеи и чайки · ур. 9–10", "Меткий Змей, Молодой Мельник, Мыслитель Зари, Ярик-Фонарик, Змей Горыныч", "Двор → южная калитка"],
	"park": ["Газонокосилки, пакеты, робо-утки, кружочки · ур. 14–18", "Охранник Подписочкин · Колесо Обновлений", "Набережная → Калинов мост"],
	"cheburek": ["Тараканы-ниндзя, мухи, чебуреки, вантузы · ур. 14–18", "Тётя Сочня, Пельмень Недоеденный, сантехник Вентилёв", "Двор → западная калитка (трамвай)"],
	"laundry": ["Носки, стиралки, утюги, пена · ур. 16–20", "Тамара Ресепшн, режиссёр Дубль Дублевич", "Двор → восточная калитка"],
	"dump": ["Крысы, холодильники, матрасы, пакеты · ур. 17–22", "Дед Утиль, Кеша Вторсырьё, Вася-3000 · Король Хлама", "Стройка → южные ворота «Свалка»"],
}


# ================================================================== 0.8 «Мыльная опера»
## Music: loops at the same tempo; they change by themselves (each map has its theme, then the playlist goes on)
const TRACKS := [["music_run", "Двор качает"], ["music_funk", "Гаражный фанк"], ["music_river", "Набережная"], ["music_disco", "Чебурек-диско"],
	["music_soap", "Мыльная опера"], ["music_dawn", "Рассвет"], ["music_wind", "Ветер без пароля"]]
const MAP_TRACK := {"yard": "music_run", "garages": "music_funk", "stroyka": "music_funk", "server": "music_dawn", "embankment": "music_river",
	"park": "music_dawn", "cheburek": "music_disco", "laundry": "music_soap", "dump": "music_wind"}

## Благословения Бога Здорово: the first «Здорово!» of the day at a bench gives one of them for the day
const BLESSINGS := {
	"cheer": ["Бодрость", "+10% к скорости"],
	"appetite": ["Аппетит", "шаурма лечит 60% вместо 40%"],
	"ear": ["Слух", "окно бита шире на 20 мс"],
	"luck": ["Удача", "+10 к Удаче"],
	"xp": ["Опыт", "+15% опыта"],
	"kind": ["Добрый день", "мобы реже нападают первыми"],
}
const BLESSING_ORDER := ["cheer", "appetite", "ear", "luck", "xp", "kind"]
## Дары: Благодать → вечные бонусы. [name, effect, max level, base cost, cost step]
const GIFTS := {
	"hp": ["Крепкое здоровье", "+2% здоровья", 5, 20, 15],
	"luck": ["Везение", "+2 к Удаче", 5, 20, 15],
	"beat": ["Чуткий слух", "окно бита +10 мс", 3, 30, 20],
	"qxp": ["Мудрость", "+5% опыта за задания", 4, 25, 15],
}
const GIFT_ORDER := ["hp", "luck", "beat", "qxp"]
const GREET_GOAL := 10       # «Скажи «здорово»»: greet 10 residents a day
const GREET_MAX := 20        # Благодать for greetings, a day
const KIT_HEAL := 0.5        # «Отличная аптечка»
const KIT_CD := 20.0

## Rhythm mini-games of the quests (notes in beats; halves are off-beats)
const RHYTHM := {
	"tickle": {"say": "Щекочи пёрышком строго в бит. Не в бит — это уже не щекотка, а приставание.", "title": "ЩЕКОТКА В БИТ", "meter": "Пельменю щекотно", "notes": [0, 1, 2, 3, 4, 4.5, 5, 6, 7, 8, 9, 10, 10.5, 11, 12, 13, 14, 14.5, 15, 16, 17, 18, 18.5, 19, 20, 22],
		"lines": ["Хи!", "Ха-ха! Не туда!", "Хи-хи-хи!", "Ладно-ладно, открываюсь!"]},
	"audition": {"say": "Пробы! Встаёшь в кадр и двигаешься в бит. Камера любит ритм. Я тоже. Мотор!", "title": "ПРОБЫ · ДУБЛЬ 1", "meter": "Режиссёр доволен", "notes": [0, 1, 2, 2.5, 3, 4, 5, 6, 6.5, 7, 8, 9, 10, 11, 12, 12.5, 13, 14, 15, 16, 17, 18, 18.5, 19, 20, 21, 22],
		"lines": ["Мотор!", "Камера! Свет!", "Хорошо… ещё!", "Снято! Почти."]},
	"stream": {"say": "Эфир! Жми в бит — зрители остаются. Промахнёшься — уходят смотреть котиков.", "title": "ЭФИР «ОТЖИМ»", "meter": "Зрители в эфире", "notes": [0, 0.5, 1, 2, 3, 3.5, 4, 5, 6, 7, 7.5, 8, 9, 10, 10.5, 11, 12, 13, 14, 14.5, 15, 16, 17, 18, 19, 19.5, 20, 21, 22, 23],
		"lines": ["Всем привет, это «Отжим»!", "Лайк, если пахнет ромашкой!", "Баба Зина в кадре!", "Не переключайтесь!"]},
	"console": {"say": "Приставка собрана! Проверяем: жми в бит — если не зависнет, значит, работает. Если зависнет — значит, тоже работает, но медленно.",
		"title": "ТЕСТ ПРИСТАВКИ", "meter": "Приставка работает", "notes": [0, 1, 1.5, 2, 3, 4, 5, 5.5, 6, 7, 8, 9, 10, 10.5, 11, 12, 13, 13.5, 14, 15, 16, 17, 18, 18.5, 19, 20, 21, 22],
		"lines": ["Загрузка… 99%…", "Уровень 1: двор!", "Комбо! Ещё комбо!", "Новый рекорд Кента!"]},
}

## Скамейки Здорово (one per place; the server room has none — «там тишина»)
const BENCHES := {"yard": [Vector3(-6.9, 0, -8.0), PI / 2, true], "garages": [Vector3(25.5, 0, 5.4), PI, false], "stroyka": [Vector3(24.5, 0, 9.0), PI, false],
	"embankment": [Vector3(22.0, 0, 5.2), 0.0, true], "park": [Vector3(-5.2, 0, -17.0), PI / 2, false], "cheburek": [Vector3(-5.0, 0, 13.4), PI, false],
	"laundry": [Vector3(-16.0, 0, 8.5), 0.0, false], "dump": [Vector3(-16.0, 0, 7.4), 0.0, false]}


# ================================================================== 0.9 «Своё дело»
## Идеи изобретателей: улучшения построек до 4–5 уровня. Купить идею — монеты; построить — спецматериалы + обычная цена уровня.
## "soon": материал появится в следующем обновлении (идею видно, но строить пока нельзя).
const IDEAS := {
	"grill4": {"name": "Мангал-реактор", "b": "grill", "lvl": 4, "price": 900, "mats": {"scale_mat": 3, "dough_mat": 2},
		"desc": "Шаурма раз в 3 минуты, лечит 50%, запас 8", "by": "Кеша"},
	"grill5": {"name": "Мангал «Жар-птица»", "b": "grill", "lvl": 5, "price": 2200, "mats": {"feather_mat": 3, "scale_mat": 2, "atom_mat": 1},
		"desc": "Шаурма раз в 2 минуты, лечит 60%, запас 10", "by": "Дед Утиль"},
	"garden4": {"name": "Гидропоника из стиралки", "b": "garden", "lvl": 4, "price": 1000, "mats": {"drum_mat": 1, "atom_mat": 1},
		"desc": "Урожай вдвое больше: 180 монет раз в 10 минут", "by": "Кеша"},
	"garden5": {"name": "Теплица на тесте вечности", "b": "garden", "lvl": 5, "price": 2400, "mats": {"dough_mat": 2, "spoke_mat": 2},
		"desc": "260 монет и шаурма с каждого урожая", "by": "Дед Утиль"},
	"gym4": {"name": "Качалка из бетона сцены", "b": "gym", "lvl": 4, "price": 1000, "mats": {"concrete_mat": 4},
		"desc": "+35% к здоровью", "by": "Дед Утиль"},
	"gym5": {"name": "Качалка-центрифуга", "b": "gym", "lvl": 5, "price": 2400, "mats": {"drum_mat": 2, "concrete_mat": 2, "atom_mat": 1},
		"desc": "+45% к здоровью", "by": "Кеша"},
	"stage4": {"name": "Сцена с пиротехникой", "b": "stage", "lvl": 4, "price": 1100, "mats": {"feather_mat": 3, "spoke_mat": 1},
		"desc": "+80% к вайбу, концерт в ГК даёт вдвое больше монет", "by": "Кеша"},
	"stage5": {"name": "Сцена «Колесо обозрения»", "b": "stage", "lvl": 5, "price": 2600, "mats": {"spoke_mat": 3, "chip_mat": 1},
		"desc": "+100% к вайбу, концерт втрое щедрее", "by": "Дед Утиль"},
	"studio4": {"name": "Студия «Золотой сингл»", "b": "studio", "lvl": 4, "price": 1200, "mats": {"chip_mat": 2}, "singles": 1,
		"desc": "+20% к урону", "by": "Кеша"},
	"studio5": {"name": "Студия «Бессмертный хит»", "b": "studio", "lvl": 5, "price": 2800, "mats": {"chip_mat": 2, "scale_mat": 2, "atom_mat": 1},
		"desc": "+26% к урону", "by": "Дед Утиль"},
	"solar4": {"name": "Ветряк без пароля", "b": "solar", "lvl": 4, "price": 900, "mats": {"spoke_mat": 2, "atom_mat": 1},
		"desc": "Вася быстрее на 60%: ветер дует без пароля", "by": "Кеша"},
	"solar5": {"name": "Панели на светочастицах", "b": "solar", "lvl": 5, "price": 2400, "mats": {"light_mat": 8}, "soon": "0.10",
		"desc": "Вася быстрее на 75%: светит и ночью", "by": "Дед Утиль"},
}
const IDEA_ORDER := ["grill4", "grill5", "garden4", "garden5", "gym4", "gym5", "stage4", "stage5", "studio4", "studio5", "solar4", "solar5"]
## Where the special materials come from (shown in the workshop)
const MAT_SOURCE := {"feather_mat": "ремикс Пахана (двор)", "concrete_mat": "ремикс Шумодава (стройка)", "chip_mat": "ремикс Кощея (серверная)",
	"scale_mat": "ремикс Горыныча (набережная)", "spoke_mat": "ремикс Колеса (парк)", "dough_mat": "ремикс Теста (Чебуречная)",
	"drum_mat": "ремикс Барабана (Прачечная)", "atom_mat": "ремикс Короля Хлама (Помойка)", "light_mat": "Рынок электроники (0.10)"}
const MAT_ORDER := ["feather_mat", "concrete_mat", "chip_mat", "scale_mat", "spoke_mat", "dough_mat", "drum_mat", "atom_mat", "light_mat"]
## Поделки: вещи из хлама. "after" — когда рецепт открывается (quest8)
const CRAFTS := {
	"pot_helmet": {"items": {"crust": 3, "scale_bit": 2, "wrapper": 2}, "coins": 300},
	"wire_scarf": {"items": {"fly_wing": 3, "button": 3, "coil": 2}, "coins": 300},
	"mattress_coat": {"items": {"foam_drop": 3, "lone_sock": 3, "frost_cube": 2}, "coins": 350},
	"spring_sneakers": {"items": {"coil": 3, "spring": 3, "grass": 2}, "coins": 350},
	"basin_guitar": {"items": {"whisker": 3, "pixel": 2, "rat_tail": 3}, "coins": 400},
	"inventor_crown": {"items": {"atom_mat": 2, "chip_mat": 1, "scale_mat": 1}, "coins": 1500, "after": 5},
}
const CRAFT_ORDER := ["pot_helmet", "wire_scarf", "mattress_coat", "spring_sneakers", "basin_guitar", "inventor_crown"]
## Мастерская в боксе №13 (финал «Своего дела»)
const WORKSHOP_COST := [600, {"planks": 16, "brick": 12, "wires": 10}, {"atom_mat": 1}]
const BOX13 := Vector3(-20.4, 0, 6.6)
