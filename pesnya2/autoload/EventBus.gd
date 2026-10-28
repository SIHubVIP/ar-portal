extends Node
## Шина событий. Модель только испускает сигналы, UI и мир на них подписываются.

signal resources_changed(babki: int, reputation: int, kukukha: int)
signal xp_changed(xp: int, level: int, xp_into_level: int, xp_for_next: int)
signal level_up(level: int)
signal quest_state_changed(quest_id: String, state: String)
signal quest_stage_changed(quest_id: String, stage_index: int)
signal flag_set(flag: String)
signal item_added(item_id: String, count: int)
signal player_hp_changed(hp: float, max_hp: float)
signal ability_cast(ability_id: String, cooldown: float)
signal toast(text: String)
