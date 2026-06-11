extends Node2D

enum UIState {
	TITLE,
	CHARACTER_SELECT,
	WEAPON_SELECT,
	DANGER_SELECT,
	COMBAT,
	WAVE_COMPLETE,
	CRATE_REWARD,
	LEVEL_UP,
	SHOP,
	PAUSE,
	SETTINGS,
	RESULT,
}

const PlayerDataScript = preload("res://src/core/player_data.gd")
const EffectEntryScript = preload("res://src/core/effect_entry.gd")
const FormulasScript = preload("res://src/core/formulas.gd")
const WeaponStatsScript = preload("res://src/combat/weapon_stats.gd")
const WeaponAttackRuntimeScript = preload("res://src/combat/weapon_attack_runtime.gd")
const EnemyStatsScript = preload("res://src/combat/enemy_stats.gd")
const TargetingScript = preload("res://src/combat/targeting.gd")
const WaveSchedulerScript = preload("res://src/combat/wave_scheduler.gd")
const CombatRuntimeScript = preload("res://src/combat/combat_runtime.gd")
const EconomyCatalogScript = preload("res://src/economy/economy_catalog.gd")
const ShopStateScript = preload("res://src/economy/shop_state.gd")
const LevelUpPoolScript = preload("res://src/economy/level_up_pool.gd")
const RewardResolverScript = preload("res://src/economy/reward_resolver.gd")
const AssetManifestScript = preload("res://src/presentation/asset_manifest.gd")
const PresentationRulesScript = preload("res://src/presentation/presentation_rules.gd")
const AudioRulesScript = preload("res://src/presentation/audio_rules.gd")

const MENU_FONT_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/fonts/raw/Anybody-Medium.ttf"
const PLAYER_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/player/potato.png"
const MATERIAL_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/materials/material_0000.png"
const MATERIAL_UI_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/materials/material_ui.png"
const MATERIAL_BAG_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/materials/material_bag.png"
const SHOP_BACKGROUND_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/ui/menus/shop/shop_background.png"
const TITLE_BACKGROUND_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/ui/menus/title_screen/title_screen_background/splash_art_bg.png"
const TITLE_BROTATO_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/ui/menus/title_screen/title_screen_background/splash_art_brotato.png"
const TITLE_LOGO_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/ui/menus/title_screen/title_screen_background/ui_logo.png"
const UPGRADE_ICON_TEXTURE_PATH := "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/upgrade_icon.png"

const WEAPON_DATA_PATH := "res://data/m2/starter_weapons.json"
const ENEMY_DATA_PATH := "res://data/m2/area1_enemies.json"
const WAVE_DATA_PATH := "res://data/m2/area1_waves.json"
const CHARACTER_DATA_PATH := "res://data/m3/characters.json"
const ASSET_MANIFEST_PATH := "res://data/m5/asset_manifest.json"
const STARTER_WEAPON_IDS := ["weapon_pistol_1", "weapon_fist_1", "weapon_smg_1"]

# Doc 11 section 4 fixes combat HUD at a 24 px edge margin.
const HUD_MARGIN := 24
# Asset map 04 section 3 defines the runtime HUD material tint as #76FF76.
const MATERIAL_UI_COLOR := Color("76ff76")
# Asset map 05 section 7.2 uses black 78 percent buttons and black 90 percent panels.
const BUTTON_BG := Color(0, 0, 0, 0.784)
const PANEL_BG := Color(0, 0, 0, 0.902)
const PANEL_BORDER := Color(0, 0, 0, 1)
const SHOP_CARD_SIZE := Vector2(230, 260)
const SELECTION_CARD_SIZE := Vector2(260, 260)
const FLOATING_TEXT_LIFETIME := 0.85

const CHARACTER_OPTIONS := [
	{
		"id": "well_rounded",
		"name": "Well-Rounded",
		"subtitle": "+5 Max HP, +5 Speed",
		"icon": "res://devkit/brotato_original_devkit/asset_pack/assets/characters/well_rounded/well_rounded_icon.png",
		"stats": {"stat_max_hp": 5, "stat_speed": 5},
	},
	{
		"id": "ranger",
		"name": "Ranger",
		"subtitle": "+4 Ranged Damage, +20 Range",
		"icon": "res://devkit/brotato_original_devkit/asset_pack/assets/characters/ranger/ranger_icon.png",
		"stats": {"stat_ranged_damage": 4, "stat_range": 20},
	},
	{
		"id": "lucky",
		"name": "Lucky",
		"subtitle": "+25 Luck, +10 Harvesting",
		"icon": "res://devkit/brotato_original_devkit/asset_pack/assets/characters/lucky/lucky_icon.png",
		"stats": {"stat_luck": 25, "stat_harvesting": 10},
	},
]

const ITEM_ICON_BY_ID := {
	"item_coupon": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/coupon/coupon_icon.png",
	"item_fertilizer": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/fertilizer/fertilizer_icon.png",
	"item_recycling_machine": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/recycling_machine/recycling_machine_icon.png",
	"item_dangerous_bunny": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/dangerous_bunny/dangerous_bunny_icon.png",
	"item_crown": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/crown/crown_icon.png",
	"item_axolotl": "res://devkit/brotato_original_devkit/asset_pack/assets/item_icons/doc_moth/healBosster_flower_icon.png",
}

const UPGRADE_ICON_BY_KEY := {
	"stat_max_hp": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/health/health.png",
	"stat_percent_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/percent_damage/percent_dmg.png",
	"stat_melee_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/melee_damage/melee_dmg.png",
	"stat_ranged_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/ranged_damage/ranged_dmg.png",
	"stat_elemental_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/elemental_damage/elemental_dmg.png",
	"stat_attack_speed": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/attack_speed/attack_speed.png",
	"stat_crit_chance": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/crit_chance/crit_chance.png",
	"stat_range": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/range/range.png",
	"accuracy": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/accuracy/accuracy.png",
	"stat_armor": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/armor/flat_dmg_reduction.png",
	"stat_dodge": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/dodge/dodge.png",
	"stat_speed": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/speed/speed.png",
	"stat_hp_regeneration": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/health_regeneration/health_regen.png",
	"stat_lifesteal": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/lifesteal/lifesteal.png",
	"stat_harvesting": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/harvesting/harvesting.png",
	"stat_engineering": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/engineering/engineering.png",
	"stat_luck": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/luck/consumable_drop_chance.png",
	"weapon_slot": "res://devkit/brotato_original_devkit/asset_pack/assets/upgrade_icons/weapon_slot/weapon_slot.png",
}

const STAT_ICON_BY_KEY := {
	"stat_max_hp": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/max_hp.png",
	"stat_ranged_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/ranged_damage.png",
	"stat_melee_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/melee_damage.png",
	"stat_percent_damage": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/percent_damage.png",
	"stat_attack_speed": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/attack_speed.png",
	"stat_speed": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/speed.png",
	"stat_harvesting": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/harvesting.png",
	"stat_luck": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/luck.png",
	"stat_armor": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/armor.png",
	"stat_dodge": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/dodge.png",
	"stat_range": "res://devkit/brotato_original_devkit/asset_pack/assets/stat_icons/range.png",
}

const TIER_COLORS := [
	Color(0.88, 0.88, 0.82),
	Color(0.35, 0.58, 1.0),
	Color(0.78, 0.37, 1.0),
	Color(1.0, 0.32, 0.24),
]

var ui_state: UIState = UIState.TITLE
var previous_state: UIState = UIState.TITLE
var settings_return_state: UIState = UIState.TITLE
var settings_tab := "Gameplay"
var settings := {
	"damage_display": true,
	"optimize_end_waves": false,
	"retry_wave": true,
	"keep_lock": true,
	"pause_on_focus_lost": true,
	"manual_aim": false,
	"manual_aim_on_mouse_press": false,
	"movement_with_gamepad": true,
	"darken_screen": true,
}

var ui_layer: CanvasLayer
var screen_root: Control
var hud_root: Control
var floating_root: Control
var tooltip_panel: PanelContainer
var tooltip_label: Label
var hud_refs: Dictionary = {}
var floating_texts: Array = []
var bootstrapped := false
var texture_cache: Dictionary = {}
var player_texture: Texture2D
var material_texture: Texture2D
var material_ui_texture: Texture2D
var material_bag_texture: Texture2D
var shop_background_texture: Texture2D
var title_background_texture: Texture2D
var title_brotato_texture: Texture2D
var title_logo_texture: Texture2D
var upgrade_icon_texture: Texture2D
var menu_font: Font

var player_data: Variant
var formulas: Variant = FormulasScript.new()
var economy_catalog: Variant
var reward_resolver: Variant
var level_up_pool: Variant
var current_shop: Variant
var combat_runtime: Variant
var weapon_stats: Variant
var wave_scheduler: Variant
var asset_manifest: Variant
var audio_rules: Variant = AudioRulesScript.new()
var player_position := Vector2.ZERO
var enemies: Array = []
var materials: Array = []
var weapon_cooldown_ticks := 0.0
var weapon_attack_runtime: Variant = WeaponAttackRuntimeScript.new()
var weapon_attack_sequence: int = 0
var current_wave := 1
var current_danger := 0
var current_health_invuln := 0.0
var enemy_stats_by_id: Dictionary = {}
var enemy_textures: Dictionary = {}
var waves_by_number: Dictionary = {}
var starter_weapons: Array = []
var weapon_icon_by_id: Dictionary = {}
var common_wave_groups: Array = []
var weapon_texture: Texture2D
var performance_clears: int = 0
var world_visible := false
var selected_character_id := ""
var selected_weapon_id := "weapon_pistol"
var selected_weapon_row: Dictionary = {}
var pending_level_ups := 0
var pending_crates: Array = []
var current_level_options: Array = []
var last_level_option_ids: Array = []
var crate_reward_entry: Dictionary = {}
var last_wave_summary: Dictionary = {}
var run_result: Dictionary = {}
var player_visual: Dictionary = {}
var ground_theme: Dictionary = {}
var ground_texture: Texture2D
var ground_subtiles: Array = []
var material_textures: Array = []
var screen_shake := {"intensity": 0.0, "duration": 0.0}
var screen_shake_offset := Vector2.ZERO

func _ready() -> void:
	_bootstrap()

func _bootstrap() -> void:
	if bootstrapped:
		return
	bootstrapped = true
	Engine.physics_ticks_per_second = 60
	randomize()
	_load_m5_presentation()
	_load_bitmap_assets()
	economy_catalog = EconomyCatalogScript.from_m3_content()
	_load_m2_data()
	reward_resolver = RewardResolverScript.new()
	level_up_pool = LevelUpPoolScript.new()
	_create_ui_roots()
	_show_title_screen()

func _process(delta: float) -> void:
	_update_floating_texts(delta)
	_update_tooltip_position()
	if ui_state == UIState.COMBAT:
		_refresh_hud()

func _physics_process(delta: float) -> void:
	_update_presentation(delta)
	if ui_state != UIState.COMBAT:
		return
	if combat_runtime == null or combat_runtime.state != CombatRuntimeScript.STATE_RUNNING:
		queue_redraw()
		return
	combat_runtime.advance(delta)
	_update_player(delta)
	_update_enemies(delta)
	_update_contact_damage()
	if ui_state != UIState.COMBAT:
		queue_redraw()
		return
	_update_weapon(delta)
	_update_materials(delta)
	_update_wave(delta)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if ui_state == UIState.COMBAT and (event.is_action_released("ui_pause") or event.is_action_released("ui_cancel")):
		_show_pause_menu()
	elif ui_state == UIState.PAUSE and (event.is_action_released("ui_pause") or event.is_action_released("ui_cancel")):
		_resume_combat()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bool(settings.get("pause_on_focus_lost", true)) and ui_state == UIState.COMBAT:
		_show_pause_menu()

func _draw() -> void:
	if not world_visible:
		draw_rect(Rect2(Vector2.ZERO, _viewport_size()), Color(0.08, 0.09, 0.1), true)
		return
	var viewport_size: Vector2 = _viewport_size()
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.18, 0.31, 0.17), true)
	draw_set_transform(screen_shake_offset, 0.0, Vector2.ONE)
	_draw_ground(viewport_size)
	for material in materials:
		var material_data: Dictionary = material
		var material_pos: Vector2 = material_data["position"]
		var sprite_texture := _texture_for_material(material_data)
		var material_scale: float = float(material_data.get("scale", PresentationRulesScript.material_scale(int(material_data.get("value", 1)), int(material_data.get("boosted", 1)))))
		var material_size := Vector2(24, 24) * material_scale
		if sprite_texture != null:
			draw_texture_rect(sprite_texture, Rect2(material_pos - material_size * 0.5, material_size), false)
		else:
			draw_circle(material_pos, material_size.x * 0.35, Color(0.9, 0.8, 0.22), true)
	if wave_scheduler != null:
		for warning in wave_scheduler.warning_queue:
			var warning_data: Dictionary = warning
			var warning_pos: Vector2 = warning_data["position"]
			var pulse := 0.45 + 0.25 * sin(float(warning_data["remaining_ticks"]) * 0.45)
			draw_circle(warning_pos, 34.0, Color(1.0, 0.25, 0.12, pulse))
			draw_arc(warning_pos, 46.0, 0.0, TAU, 48, Color(1.0, 0.85, 0.25, 0.9), 3.0)
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_pos: Vector2 = enemy_data["position"]
		var texture := _texture_for_enemy(enemy_data)
		if texture != null:
			var enemy_rect := Rect2(enemy_pos - Vector2(32, 32), Vector2(64, 64))
			draw_texture_rect(texture, enemy_rect, false)
			if float(enemy_data.get("flash_seconds", 0.0)) > 0.0:
				draw_rect(enemy_rect.grow(-8.0), Color(1, 1, 1, 0.62), true)
		else:
			draw_circle(enemy_pos, 26.0, Color(0.8, 0.14, 0.12), true)
		var hp_ratio: float = clamp(float(enemy_data["hp"]) / float(enemy_data["max_hp"]), 0.0, 1.0)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48, 5)), Color.BLACK, true)
		draw_rect(Rect2(enemy_pos + Vector2(-24, -44), Vector2(48 * hp_ratio, 5)), Color(0.9, 0.14, 0.12), true)
	draw_ellipse(player_position + Vector2(0, 30), 84.0, 24.0, Color(0, 0, 0, 0.35), true)
	var player_tint := Color.WHITE
	if combat_runtime != null and combat_runtime.iframe_seconds_remaining > 0.0:
		player_tint = Color(1.0, 1.0, 1.0, 0.55 + 0.35 * sin(combat_runtime.iframe_seconds_remaining * 80.0))
	var player_size: Vector2 = _vec2(player_visual.get("body_draw_size", [96, 96]))
	if player_texture != null:
		draw_texture_rect(player_texture, Rect2(player_position - player_size * 0.5, player_size), false, player_tint)
	else:
		draw_circle(player_position, 30.0, Color(0.84, 0.66, 0.34, player_tint.a), true)
	if weapon_texture != null:
		var weapon_visual: Dictionary = asset_manifest.weapon_visual(weapon_stats.weapon_id) if asset_manifest != null and weapon_stats != null else {}
		var weapon_size: Vector2 = _vec2(weapon_visual.get("sprite_size", [88, 44])) * 0.64
		var weapon_origin: Vector2 = PresentationRulesScript.weapon_draw_origin(player_position, weapon_visual, player_visual, 0, 1)
		draw_texture_rect(weapon_texture, Rect2(weapon_origin - weapon_size * 0.5, weapon_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func start_new_run() -> void:
	_bootstrap()
	selected_character_id = ""
	selected_weapon_id = "weapon_pistol_1"
	selected_weapon_row = {}
	world_visible = false
	_show_character_select()

func choose_character(character_id: String) -> void:
	_bootstrap()
	selected_character_id = character_id
	_show_weapon_select()

func choose_weapon(weapon_id: String) -> void:
	_bootstrap()
	selected_weapon_id = weapon_id
	var resolved_weapon := _starter_weapon_entry_for_id(weapon_id)
	if not resolved_weapon.is_empty():
		selected_weapon_row = resolved_weapon
		selected_weapon_id = String(resolved_weapon.get("id", weapon_id))
	_show_danger_select()

func choose_danger(danger: int) -> void:
	_bootstrap()
	current_danger = clampi(danger, 0, 5)
	_begin_run()

func ui_state_name() -> String:
	_bootstrap()
	match ui_state:
		UIState.TITLE:
			return "title"
		UIState.CHARACTER_SELECT:
			return "character_select"
		UIState.WEAPON_SELECT:
			return "weapon_select"
		UIState.DANGER_SELECT:
			return "danger_select"
		UIState.COMBAT:
			return "combat"
		UIState.WAVE_COMPLETE:
			return "wave_complete"
		UIState.CRATE_REWARD:
			return "crate_reward"
		UIState.LEVEL_UP:
			return "level_up"
		UIState.SHOP:
			return "shop"
		UIState.PAUSE:
			return "pause"
		UIState.SETTINGS:
			return "settings"
		UIState.RESULT:
			return "result"
	return "unknown"

func floating_text_rule(kind: String) -> Dictionary:
	match kind:
		"enemy_damage":
			return {"color": Color.WHITE, "uses_damage_toggle": true, "always_display": false}
		"enemy_critical":
			return {"color": Color(1.0, 0.93, 0.2), "uses_damage_toggle": true, "always_display": false}
		"player_damage":
			return {"color": Color(1.0, 0.18, 0.16), "uses_damage_toggle": true, "always_display": true}
		"player_heal":
			return {"color": Color(0.35, 1.0, 0.38), "uses_damage_toggle": true, "always_display": true}
		"material":
			return {"color": MATERIAL_UI_COLOR, "uses_damage_toggle": false, "always_display": true}
		"level_up":
			return {"color": Color.WHITE, "uses_damage_toggle": false, "always_display": true}
	return {"color": Color.WHITE, "uses_damage_toggle": true, "always_display": false}

func force_wave_complete_for_smoke() -> void:
	if ui_state == UIState.COMBAT:
		_complete_wave(true)

func continue_wave_end() -> void:
	_open_next_reward_screen()

func accept_crate_reward() -> void:
	if ui_state != UIState.CRATE_REWARD:
		return
	if not crate_reward_entry.is_empty():
		_grant_item(crate_reward_entry)
		_spawn_floating_text("ITEM", player_position + Vector2(0, -80), "level_up", true)
	crate_reward_entry = {}
	if not pending_crates.is_empty():
		pending_crates.pop_front()
	_open_next_reward_screen()

func recycle_crate_reward() -> void:
	if ui_state != UIState.CRATE_REWARD:
		return
	var value := maxi(1, 5 + current_wave * 2)
	player_data.materials += value
	_spawn_floating_text("+%d" % value, player_position + Vector2(0, -80), "material", true)
	crate_reward_entry = {}
	if not pending_crates.is_empty():
		pending_crates.pop_front()
	_open_next_reward_screen()

func choose_level_option(index: int) -> void:
	if ui_state != UIState.LEVEL_UP or index < 0 or index >= current_level_options.size():
		return
	var option: Dictionary = current_level_options[index]
	level_up_pool.apply_option(player_data, option)
	last_level_option_ids.append(String(option.get("id", "")))
	pending_level_ups = maxi(0, pending_level_ups - 1)
	_spawn_floating_text("LEVEL UP", player_position + Vector2(0, -96), "level_up", true)
	if pending_level_ups > 0:
		_generate_level_options()
		_show_level_up_screen()
	else:
		_open_shop()

func reroll_level_options() -> void:
	if ui_state != UIState.LEVEL_UP:
		return
	var price: int = formulas.reroll_price(current_wave, 0, player_data.get_stat("reroll_price"), formulas.endless_factor(current_wave))
	if player_data.materials < price:
		_spawn_floating_text("NOT ENOUGH", player_position + Vector2(0, -80), "player_damage", true)
		return
	player_data.materials -= price
	_generate_level_options()
	_show_level_up_screen()

func buy_shop_slot(index: int) -> void:
	if ui_state != UIState.SHOP or current_shop == null:
		return
	var result: Dictionary = current_shop.buy_slot(index, player_data, economy_catalog)
	if bool(result.get("ok", false)):
		_refresh_active_weapon_stats()
		_spawn_floating_text("BUY", player_position + Vector2(0, -80), "material", true)
	else:
		_spawn_floating_text(String(result.get("reason", "NO")), player_position + Vector2(0, -80), "player_damage", true)
	_show_shop_screen()

func lock_shop_slot(index: int) -> void:
	if ui_state != UIState.SHOP or current_shop == null:
		return
	current_shop.toggle_lock(index, player_data)
	_show_shop_screen()

func ban_shop_slot(index: int) -> void:
	if ui_state != UIState.SHOP or current_shop == null:
		return
	current_shop.ban_slot(index)
	_show_shop_screen()

func reroll_shop() -> void:
	if ui_state != UIState.SHOP or current_shop == null:
		return
	var result: Dictionary = current_shop.reroll(player_data, economy_catalog)
	if not bool(result.get("ok", false)):
		_spawn_floating_text(String(result.get("reason", "NO")), player_position + Vector2(0, -80), "player_damage", true)
	_show_shop_screen()

func leave_shop() -> void:
	if ui_state != UIState.SHOP:
		return
	if current_wave >= _highest_wave_number():
		_show_result(true)
		return
	current_wave += 1
	_start_wave()

func _begin_run() -> void:
	player_data = PlayerDataScript.new()
	player_data.materials = 12
	player_data.add_permanent_stat("stat_ranged_damage", 4)
	player_data.add_permanent_stat("stat_attack_speed", 20)
	_apply_selected_character()
	if selected_weapon_row.is_empty():
		selected_weapon_row = _starter_weapon_entry_for_id(selected_weapon_id)
	if selected_weapon_row.is_empty() and not starter_weapons.is_empty():
		selected_weapon_row = starter_weapons[0].duplicate(true)
	if not selected_weapon_row.is_empty():
		selected_weapon_id = String(selected_weapon_row.get("id", selected_weapon_id))
		weapon_stats = WeaponStatsScript.from_dict(selected_weapon_row)
		weapon_texture = _safe_texture(weapon_stats.texture_path)
	_grant_starting_weapon()
	_refresh_active_weapon_stats()
	current_wave = 1
	performance_clears = 0
	combat_runtime = CombatRuntimeScript.new()
	combat_runtime.start_run(player_data, current_wave, _highest_wave_number(), current_danger)
	pending_level_ups = 0
	pending_crates.clear()
	last_level_option_ids.clear()
	player_position = _viewport_size() * 0.5
	player_data.current_health = player_data.get_max_health()
	_start_wave()

func _start_wave() -> void:
	world_visible = true
	enemies.clear()
	materials.clear()
	floating_texts.clear()
	weapon_cooldown_ticks = 0.0
	current_health_invuln = 0.0
	reward_resolver.apply_start_wave_interest(player_data, current_wave)
	if combat_runtime != null:
		combat_runtime.start_wave(current_wave)
	if waves_by_number.has(current_wave):
		wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number[current_wave], common_wave_groups)
	else:
		wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number[_highest_wave_number()], common_wave_groups)
	player_position = _viewport_size() * 0.5
	ui_state = UIState.COMBAT
	_clear_screen_ui()
	_show_combat_hud()
	queue_redraw()

func _complete_wave(success: bool) -> void:
	if ui_state != UIState.COMBAT:
		return
	var settlement: Dictionary = combat_runtime.settle_wave(enemies.size(), materials)
	var recovered_ground := int(settlement.get("recovered_materials", 0))
	var levels_from_harvest := int(settlement.get("harvest_levels", 0))
	enemies.clear()
	materials.clear()
	if levels_from_harvest <= 0:
		var needed: int = ceili(formulas.next_level_xp_needed(player_data.level, player_data.get_stat("next_level_xp_needed")) - player_data.current_xp)
		if needed > 0:
			levels_from_harvest += player_data.gain_xp(needed)
	pending_level_ups += maxi(1, levels_from_harvest)
	# Crate drops are represented by the fixture catalog until the full drop runtime is merged.
	pending_crates.append(economy_catalog.get_entry("consumable_item_box"))
	last_wave_summary = {
		"success": success,
		"ground_materials": recovered_ground,
		"harvest_value": int(settlement.get("harvest", 0)),
		"harvest_growth": int(settlement.get("harvesting_growth", 0)),
		"levels": levels_from_harvest,
		"crates": pending_crates.size(),
	}
	ui_state = UIState.WAVE_COMPLETE
	_show_wave_complete_screen()
	queue_redraw()

func _open_next_reward_screen() -> void:
	if not pending_crates.is_empty():
		_prepare_crate_reward()
		_show_crate_reward_screen()
	elif pending_level_ups > 0:
		_generate_level_options()
		_show_level_up_screen()
	else:
		_open_shop()

func _prepare_crate_reward() -> void:
	var wanted_tier := clampi(current_wave / 2, 0, 3)
	crate_reward_entry = economy_catalog.pick("item", wanted_tier, player_data)
	if crate_reward_entry.is_empty():
		crate_reward_entry = economy_catalog.pick("item", 0, player_data)

func _open_shop() -> void:
	if current_wave >= _highest_wave_number():
		_show_result(true)
		return
	current_shop = ShopStateScript.open(player_data, economy_catalog, current_wave, bool(settings.get("keep_lock", true)))
	_show_shop_screen()

func _show_title_screen() -> void:
	ui_state = UIState.TITLE
	world_visible = false
	_clear_screen_ui()
	_clear_hud_refs()
	var root := _screen_container("TitleScreen")
	_add_title_background(root)
	var margin := _margin_container(root, 52)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(row)
	var menu := VBoxContainer.new()
	menu.custom_minimum_size = Vector2(360, 0)
	menu.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(menu)
	var logo := TextureRect.new()
	logo.texture = title_logo_texture
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(320, 160)
	menu.add_child(logo)
	menu.add_child(_make_button("NEW RUN", Callable(self, "start_new_run"), "Doc 11 section 2.3: title menu entry starts the pre-run flow."))
	menu.add_child(_make_button("SETTINGS", Callable(self, "_show_settings_from_title"), "Settings are shared by title and pause menus per doc 11 section 11."))
	menu.add_child(_make_button("RESULTS", Callable(self, "_show_result_preview"), "Preview the result screen data contract from doc 11 section 9."))
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)

func _show_character_select() -> void:
	ui_state = UIState.CHARACTER_SELECT
	world_visible = false
	_clear_screen_ui()
	var root := _menu_background("CharacterSelect")
	_add_screen_title(root, "CHARACTER", "Doc 11 section 3.2 selection grid; fixture subset until static content import lands.")
	var grid := _centered_grid(root, 3)
	for character in CHARACTER_OPTIONS:
		var data: Dictionary = character
		grid.add_child(_make_selection_card(
			String(data["name"]),
			String(data["subtitle"]),
			String(data["icon"]),
			0,
			Callable(self, "choose_character").bind(String(data["id"])),
			"Character stats apply to PlayerData before combat."
		))
	_add_back_button(root, Callable(self, "_show_title_screen"))

func _show_weapon_select() -> void:
	ui_state = UIState.WEAPON_SELECT
	world_visible = false
	_clear_screen_ui()
	var root := _menu_background("WeaponSelect")
	_add_screen_title(root, "WEAPON", "Doc 11 section 3.3 weapon choice; rows come from data/m2/starter_weapons.json.")
	var grid := _centered_grid(root, 3)
	for weapon in starter_weapons:
		var data: Dictionary = weapon
		var subtitle := "%s  Damage %s  Cooldown %s" % [
			String(data.get("type", "weapon")).capitalize(),
			str(data.get("damage", 0)),
			str(data.get("cooldown", 0)),
		]
		grid.add_child(_make_selection_card(
			String(data.get("name", data.get("id", ""))),
			subtitle,
			String(data.get("icon", "")),
			int(data.get("tier", 0)),
			Callable(self, "choose_weapon").bind(String(data.get("id", ""))),
			"Combat uses WeaponStats from the selected row."
		))
	_add_back_button(root, Callable(self, "_show_character_select"))

func _show_danger_select() -> void:
	ui_state = UIState.DANGER_SELECT
	world_visible = false
	_clear_screen_ui()
	var root := _menu_background("DangerSelect")
	_add_screen_title(root, "DANGER", "Doc 11 section 3.4 records the chosen danger before entering combat.")
	var grid := _centered_grid(root, 6)
	for danger in range(0, 6):
		var button := _make_button(
			"DANGER %d" % danger,
			Callable(self, "choose_danger").bind(danger),
			"Enemy stat multiplier: %.0f%%" % (formulas.danger_enemy_stat_multiplier(danger) * 100.0),
			Vector2(150, 110)
		)
		grid.add_child(button)
	_add_back_button(root, Callable(self, "_show_weapon_select"))

func _show_combat_hud() -> void:
	_clear_screen_ui()
	_clear_hud_refs()
	var root := _full_rect_control("CombatHud")
	hud_root.add_child(root)
	var top_left := PanelContainer.new()
	top_left.position = Vector2(HUD_MARGIN, HUD_MARGIN)
	top_left.custom_minimum_size = Vector2(310, 152)
	top_left.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 5, 8))
	root.add_child(top_left)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 6)
	top_left.add_child(left_box)
	hud_refs["hp_label"] = _make_label("", 22)
	left_box.add_child(hud_refs["hp_label"])
	var hp_bar := ProgressBar.new()
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(270, 18)
	left_box.add_child(hp_bar)
	hud_refs["hp_bar"] = hp_bar
	hud_refs["xp_label"] = _make_label("", 20)
	left_box.add_child(hud_refs["xp_label"])
	var xp_bar := ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(270, 14)
	left_box.add_child(xp_bar)
	hud_refs["xp_bar"] = xp_bar
	var material_row := HBoxContainer.new()
	material_row.add_theme_constant_override("separation", 8)
	left_box.add_child(material_row)
	var material_icon := TextureRect.new()
	material_icon.texture = material_ui_texture
	material_icon.modulate = MATERIAL_UI_COLOR
	material_icon.custom_minimum_size = Vector2(32, 32)
	material_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	material_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	material_row.add_child(material_icon)
	hud_refs["materials_label"] = _make_label("", 24)
	material_row.add_child(hud_refs["materials_label"])
	_attach_tooltip(material_row, "Asset map 04: material_ui.png is tinted #76FF76 at runtime.")

	var timer_panel := PanelContainer.new()
	timer_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	timer_panel.offset_left = 420
	timer_panel.offset_right = -420
	timer_panel.offset_top = HUD_MARGIN
	timer_panel.custom_minimum_size = Vector2(0, 86)
	timer_panel.add_theme_stylebox_override("panel", _panel_style(Color(0, 0, 0, 0.70), PANEL_BORDER, 4, 8))
	root.add_child(timer_panel)
	var timer_box := VBoxContainer.new()
	timer_box.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_panel.add_child(timer_box)
	hud_refs["wave_label"] = _make_label("", 30, HORIZONTAL_ALIGNMENT_CENTER)
	timer_box.add_child(hud_refs["wave_label"])
	var timeline := ProgressBar.new()
	timeline.show_percentage = false
	timeline.custom_minimum_size = Vector2(360, 12)
	timer_box.add_child(timeline)
	hud_refs["timeline"] = timeline

	var top_right := VBoxContainer.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_left = -300
	top_right.offset_top = HUD_MARGIN
	top_right.offset_right = -HUD_MARGIN
	top_right.add_theme_constant_override("separation", 10)
	root.add_child(top_right)
	top_right.add_child(_make_button("PAUSE", Callable(self, "_show_pause_menu"), "Doc 10 section 9: pause is scene-level, not time-scale.", Vector2(180, 48)))
	var stat_panel := _make_stat_panel()
	top_right.add_child(stat_panel)
	hud_refs["stat_panel"] = stat_panel
	_refresh_hud()

func _show_wave_complete_screen() -> void:
	ui_state = UIState.WAVE_COMPLETE
	_clear_screen_ui()
	_clear_hud_refs()
	var root := _full_rect_control("WaveComplete")
	screen_root.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := _center_panel(root, Vector2(520, 390))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	box.add_child(_make_label("WAVE COMPLETED", 46, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Materials +%d  Harvest +%d  Growth %+d" % [
		int(last_wave_summary.get("ground_materials", 0)),
		int(last_wave_summary.get("harvest_value", 0)),
		int(last_wave_summary.get("harvest_growth", 0)),
	], 24, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Queued: %d crate, %d level-up" % [pending_crates.size(), pending_level_ups], 22, HORIZONTAL_ALIGNMENT_CENTER))
	var bag := TextureRect.new()
	bag.texture = material_bag_texture
	bag.custom_minimum_size = Vector2(84, 84)
	bag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bag.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(bag)
	box.add_child(_make_button("CONTINUE", Callable(self, "continue_wave_end"), "Doc 11 section 6: process crates before level-ups, then shop.", Vector2(220, 54)))

func _show_crate_reward_screen() -> void:
	ui_state = UIState.CRATE_REWARD
	_clear_screen_ui()
	var root := _menu_background("CrateReward")
	_add_screen_title(root, "ITEM BOX", "Doc 11 section 6.3: item boxes are processed before level-up options.")
	var panel := _center_panel(root, Vector2(520, 470))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = _safe_texture(_icon_for_entry(crate_reward_entry))
	icon.custom_minimum_size = Vector2(132, 132)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_make_label(String(crate_reward_entry.get("name", "Reward")), 34, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label(_effects_text(crate_reward_entry), 20, HORIZONTAL_ALIGNMENT_CENTER))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	buttons.add_child(_make_button("TAKE", Callable(self, "accept_crate_reward"), "Apply item effects to PlayerData.", Vector2(150, 52)))
	buttons.add_child(_make_button("RECYCLE", Callable(self, "recycle_crate_reward"), "Convert this preview item box into materials.", Vector2(150, 52)))

func _show_level_up_screen() -> void:
	ui_state = UIState.LEVEL_UP
	_clear_screen_ui()
	var root := _menu_background("LevelUp")
	_add_screen_title(root, "LEVEL UP", "Doc 11 section 6.2: generate up to four upgrade cards; tier colors come from asset map 04 section 7.")
	var grid := _centered_grid(root, 4, Vector2(0, 34))
	for i in current_level_options.size():
		var option: Dictionary = current_level_options[i]
		grid.add_child(_make_upgrade_card(option, Callable(self, "choose_level_option").bind(i)))
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 260
	bottom.offset_right = -260
	bottom.offset_bottom = -HUD_MARGIN
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	bottom.add_child(_make_button("REROLL", Callable(self, "reroll_level_options"), "Uses the same reroll price formula as shop, per doc 11 section 6.2.", Vector2(170, 52)))
	bottom.add_child(_make_label("Materials %d" % player_data.materials, 24, HORIZONTAL_ALIGNMENT_CENTER))

func _show_shop_screen() -> void:
	ui_state = UIState.SHOP
	world_visible = false
	_clear_screen_ui()
	var root := _menu_background("Shop")
	_add_screen_title(root, "SHOP", "Doc 11 section 8: four slots, buy/lock/ban, reroll, equipment/stat panel, then GO.")
	var content := HBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 46
	content.offset_top = 124
	content.offset_right = -46
	content.offset_bottom = -100
	content.add_theme_constant_override("separation", 18)
	root.add_child(content)
	var shop_grid := GridContainer.new()
	shop_grid.columns = 4
	shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_grid.add_theme_constant_override("h_separation", 12)
	content.add_child(shop_grid)
	for i in current_shop.slots.size():
		var slot: Dictionary = current_shop.slots[i]
		shop_grid.add_child(_make_shop_card(i, slot))
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(280, 0)
	side.add_theme_constant_override("separation", 12)
	content.add_child(side)
	side.add_child(_make_wallet_panel())
	side.add_child(_make_stat_panel())
	side.add_child(_make_inventory_panel())
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 220
	bottom.offset_right = -220
	bottom.offset_bottom = -HUD_MARGIN
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 16)
	root.add_child(bottom)
	var reroll_cost: int = formulas.reroll_price(current_wave, current_shop.paid_rerolls, player_data.get_stat("reroll_price"), formulas.endless_factor(current_wave))
	if current_shop.free_rerolls > 0 or current_shop.next_reroll_is_free:
		reroll_cost = 0
	bottom.add_child(_make_button("REROLL - %d" % reroll_cost, Callable(self, "reroll_shop"), "Doc 11 section 8.3 reroll preserves locked slots.", Vector2(210, 56)))
	bottom.add_child(_make_button("GO", Callable(self, "leave_shop"), "Start the next wave.", Vector2(160, 56)))

func _show_pause_menu() -> void:
	if ui_state != UIState.COMBAT:
		return
	previous_state = ui_state
	ui_state = UIState.PAUSE
	_clear_screen_ui()
	var root := _full_rect_control("PauseMenu")
	screen_root.add_child(root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var panel := _center_panel(root, Vector2(380, 390))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_make_label("PAUSED", 42, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_button("RESUME", Callable(self, "_resume_combat"), "Return to combat.", Vector2(220, 54)))
	box.add_child(_make_button("SETTINGS", Callable(self, "_show_settings_from_pause"), "Settings entry point shared with title.", Vector2(220, 54)))
	box.add_child(_make_button("END RUN", Callable(self, "_end_run_from_pause"), "End this run and show the result screen.", Vector2(220, 54)))
	box.add_child(_make_button("TITLE", Callable(self, "_show_title_screen"), "Return to title.", Vector2(220, 54)))

func _resume_combat() -> void:
	ui_state = UIState.COMBAT
	_clear_screen_ui()
	_show_combat_hud()

func _show_settings_from_title() -> void:
	settings_return_state = UIState.TITLE
	_show_settings_screen()

func _show_settings_from_pause() -> void:
	settings_return_state = UIState.PAUSE
	_show_settings_screen()

func _show_settings_screen() -> void:
	ui_state = UIState.SETTINGS
	_clear_screen_ui()
	var root := _menu_background("Settings")
	_add_screen_title(root, "SETTINGS", "Doc 11 section 11: title and pause share the same settings pages.")
	var tabs := HBoxContainer.new()
	tabs.set_anchors_preset(Control.PRESET_TOP_WIDE)
	tabs.offset_left = 120
	tabs.offset_top = 112
	tabs.offset_right = -120
	tabs.add_theme_constant_override("separation", 10)
	root.add_child(tabs)
	for tab in ["Audio", "Video", "Gameplay", "Accessibility", "DLC"]:
		tabs.add_child(_make_button(tab.to_upper(), Callable(self, "_set_settings_tab").bind(tab), "Open %s settings." % tab, Vector2(160, 46)))
	var panel := _center_panel(root, Vector2(760, 430), Vector2(0, 54))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_make_label(settings_tab.to_upper(), 32, HORIZONTAL_ALIGNMENT_CENTER))
	match settings_tab:
		"Audio":
			box.add_child(_make_label("Music Volume 100%    SFX Volume 100%", 24, HORIZONTAL_ALIGNMENT_CENTER))
		"Video":
			box.add_child(_make_setting_check("darken_screen", "Darken Screen"))
			box.add_child(_make_setting_check("pause_on_focus_lost", "Pause On Focus Lost"))
		"Gameplay":
			box.add_child(_make_setting_check("damage_display", "Damage Display"))
			box.add_child(_make_setting_check("optimize_end_waves", "Optimize End Waves"))
			box.add_child(_make_setting_check("retry_wave", "Retry Wave"))
			box.add_child(_make_setting_check("keep_lock", "Keep Lock"))
		"Accessibility":
			box.add_child(_make_setting_check("manual_aim", "Manual Aim"))
			box.add_child(_make_setting_check("manual_aim_on_mouse_press", "Manual Aim On Mouse Press"))
			box.add_child(_make_setting_check("movement_with_gamepad", "Movement With Gamepad"))
		_:
			box.add_child(_make_label("DLC content toggles are represented here; unlock rules are out of scope for this milestone.", 22, HORIZONTAL_ALIGNMENT_CENTER))
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 480
	bottom.offset_right = -480
	bottom.offset_bottom = -HUD_MARGIN
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(bottom)
	bottom.add_child(_make_button("BACK", Callable(self, "_close_settings"), "Save settings and return.", Vector2(180, 52)))

func _set_settings_tab(tab: String) -> void:
	settings_tab = tab
	_show_settings_screen()

func _set_bool_setting(pressed: bool, key: String) -> void:
	settings[key] = pressed

func _close_settings() -> void:
	if settings_return_state == UIState.PAUSE:
		_show_pause_menu()
	else:
		_show_title_screen()

func _end_run_from_pause() -> void:
	_show_result(false)

func _show_result_preview() -> void:
	player_data = PlayerDataScript.new()
	player_data.materials = 42
	current_wave = 5
	selected_character_id = "well_rounded"
	selected_weapon_id = "weapon_pistol"
	_show_result(true)

func _show_result(won: bool) -> void:
	ui_state = UIState.RESULT
	world_visible = false
	run_result = {
		"won": won,
		"wave": current_wave,
		"danger": current_danger,
		"materials": player_data.materials if player_data != null else 0,
		"level": player_data.level if player_data != null else 0,
		"items": player_data.items.size() if player_data != null else 0,
		"weapons": player_data.weapons.size() if player_data != null else 0,
	}
	_clear_screen_ui()
	var root := _menu_background("Result")
	_add_screen_title(root, "RUN WON" if won else "RUN LOST", "Doc 11 section 9 result screen shows progress, inventory, and unlock summary.")
	var panel := _center_panel(root, Vector2(640, 430))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(_make_label("Wave %d  Danger %d" % [current_wave, current_danger], 30, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Level %d  Materials %d" % [int(run_result["level"]), int(run_result["materials"])], 26, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Items %d  Weapons %d" % [int(run_result["items"]), int(run_result["weapons"])], 24, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("New danger progress and challenge rewards attach here when unlock runtime lands.", 20, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_button("TITLE", Callable(self, "_show_title_screen"), "Return to title.", Vector2(190, 54)))

func _update_presentation(delta: float) -> void:
	audio_rules.dequeue_frame()
	var shake_duration: float = max(0.0, float(screen_shake.get("duration", 0.0)) - delta)
	if shake_duration <= 0.0:
		screen_shake = {"intensity": 0.0, "duration": 0.0}
		screen_shake_offset = Vector2.ZERO
	else:
		screen_shake["duration"] = shake_duration
		screen_shake_offset = PresentationRulesScript.screen_shake_offset(float(screen_shake.get("intensity", 0.0)), randf(), randf())

func _update_player(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	player_position += input_vector * player_data.get_speed() * delta
	var bounds: Vector2 = _viewport_size()
	player_position.x = clamp(player_position.x, 40.0, bounds.x - 40.0)
	player_position.y = clamp(player_position.y, 40.0, bounds.y - 40.0)

func _update_enemies(delta: float) -> void:
	for i in enemies.size():
		var enemy: Dictionary = enemies[i]
		enemy["flash_seconds"] = max(0.0, float(enemy.get("flash_seconds", 0.0)) - delta)
		var enemy_pos: Vector2 = enemy["position"]
		var movement_mode := String(enemy.get("movement_mode", "chase"))
		if movement_mode == "stationary" or movement_mode == "stationary_summon":
			continue
		var to_player := player_position - enemy_pos
		var direction := to_player.normalized()
		if movement_mode == "keep_distance":
			var distance := to_player.length()
			if distance < 260.0:
				direction = -direction
			elif distance <= 360.0:
				direction = Vector2.ZERO
		var movement_velocity := direction * float(enemy["speed"])
		var knockback_velocity: Vector2 = combat_runtime.enemy_knockback_velocity(enemy)
		enemy["position"] = enemy_pos + (movement_velocity + knockback_velocity) * delta
		combat_runtime.decay_enemy_knockback(enemy)
		enemies[i] = enemy

func _update_contact_damage() -> void:
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		if not combat_runtime.enemy_is_touching_player(enemy_data, player_position):
			continue
		if not combat_runtime.enemy_can_contact_damage(enemy_data):
			continue
		var result: Dictionary = combat_runtime.resolve_player_damage(int(enemy_data.get("damage", 1)))
		if bool(result.get("accepted", false)):
			_request_screen_shake(PresentationRulesScript.screen_shake_for_player_damage())
			_queue_sound("player_hit", player_position)
			var damage := int(result.get("damage", 0))
			if bool(result.get("dodged", false)):
				_spawn_floating_text("DODGE", player_position + Vector2(0, -64), "dodge", true)
			elif bool(result.get("blocked", false)) or damage <= 0:
				_spawn_floating_text("0", player_position + Vector2(0, -64), "nullified", true)
			elif damage > 0:
				_spawn_floating_text("-%d" % damage, player_position + Vector2(0, -64), "player_damage", true)
		if combat_runtime.state == CombatRuntimeScript.STATE_LOST:
			_show_result(false)
		return

func _update_weapon(delta: float) -> void:
	weapon_cooldown_ticks = weapon_attack_runtime.tick_cooldown(weapon_cooldown_ticks, delta)
	var readiness: Dictionary = weapon_attack_runtime.can_start_attack(weapon_stats, player_data, enemies, player_position, weapon_cooldown_ticks)
	if not bool(readiness["can_attack"]):
		return
	var target: Variant = readiness["target"]
	var target_distance: float = player_position.distance_to(target["position"])
	var aim_angle: float = (target["position"] - player_position).angle()
	weapon_attack_sequence += 1
	var attack: Dictionary = weapon_attack_runtime.start_attack(weapon_stats, player_data, player_position, aim_angle, target_distance, weapon_attack_sequence)
	weapon_cooldown_ticks = float(attack["cooldown_ticks"])
	var weapon_visual: Dictionary = asset_manifest.weapon_visual(weapon_stats.weapon_id)
	_queue_sound(String(weapon_visual.get("shooting_sound_event", "")), player_position)
	if weapon_stats.type == WeaponStatsScript.TYPE_RANGED:
		for projectile in attack["projectiles"]:
			_resolve_projectile_chain(projectile, target)
	else:
		_apply_weapon_hit(weapon_attack_runtime.apply_attack_to_target(attack, target, player_data), target)

func _resolve_projectile_chain(projectile: Dictionary, initial_target: Dictionary) -> void:
	var target: Variant = initial_target
	while target != null and not bool(projectile.get("stopped", false)):
		_apply_weapon_hit(weapon_attack_runtime.apply_projectile_hit(projectile, target, player_data, enemies), target)
		if bool(projectile.get("stopped", false)):
			return
		target = _nearest_projectile_target(projectile)

func _nearest_projectile_target(projectile: Dictionary) -> Variant:
	var ignored: Array = projectile.get("ignored_enemy_ids", [])
	var best: Variant = null
	var best_distance := INF
	var origin: Vector2 = projectile.get("position", player_position)
	for enemy in enemies:
		var enemy_data: Dictionary = enemy
		var enemy_id := String(enemy_data.get("id", enemy_data.get("instance_id", "")))
		if bool(enemy_data.get("dead", false)) or ignored.has(enemy_id):
			continue
		var distance := origin.distance_to(enemy_data.get("position", origin))
		if distance < best_distance:
			best = enemy_data
			best_distance = distance
	return best

func _apply_weapon_hit(result: Dictionary, target: Dictionary) -> void:
	var explosion = result.get("explosion", null)
	if explosion != null:
		var explosion_packet: Dictionary = explosion.get("hit_packet", {}).duplicate(true)
		explosion_packet["damage"] = int(explosion.get("damage", explosion_packet.get("damage", 1)))
		explosion_packet["explosion_chance"] = 0.0
		result = weapon_attack_runtime.apply_hit_packet(explosion_packet, target, player_data)
	if not bool(result.get("hit", false)):
		return
	var direct_damage := int(result.get("direct_damage", 0))
	if direct_damage <= 0:
		return
	var knockback_origin: Vector2 = result.get("knockback_origin", player_position)
	var hit_result: Dictionary = combat_runtime.apply_enemy_damage(target, direct_damage, knockback_origin, float(result.get("knockback", 0.0)))
	var resolved_damage := int(hit_result.get("damage", direct_damage))
	var critical := bool(result.get("critical", false))
	target["flash_seconds"] = PresentationRulesScript.FLASH_DURATION_SECONDS
	_request_screen_shake(PresentationRulesScript.screen_shake_for_enemy_damage(resolved_damage))
	_spawn_floating_text(str(resolved_damage), target["position"] + Vector2(0, -36), "enemy_critical" if critical else "enemy_damage")
	_queue_sound("enemy_crit" if critical else "enemy_hit", target["position"])
	if bool(hit_result.get("dead", false)):
		var before_count := materials.size()
		var dropped: bool = combat_runtime.spawn_material_from_enemy(target, materials, current_wave)
		if dropped and materials.size() > before_count:
			var material_data: Dictionary = materials[materials.size() - 1]
			_assign_material_visual(material_data)
			materials[materials.size() - 1] = material_data
		enemies.erase(target)

func _update_materials(delta: float) -> void:
	var events: Array = combat_runtime.update_materials(materials, player_position, delta)
	for event in events:
		var pickup: Dictionary = event
		if bool(pickup.get("collected", false)):
			_queue_sound("material_pickup", player_position)
			_spawn_floating_text("+%d" % int(pickup.get("value", 0)), player_position + Vector2(0, -48), "material", true)
			if int(pickup.get("gained_levels", 0)) > 0:
				pending_level_ups += int(pickup.get("gained_levels", 0))
			if int(pickup.get("healed", 0)) > 0:
				_spawn_floating_text("+%d" % int(pickup.get("healed", 0)), player_position + Vector2(0, -72), "player_heal", true)

func _update_wave(delta: float) -> void:
	var requests: Array = wave_scheduler.advance(delta, current_danger, enemies.size())
	for request in requests:
		_performance_cull_enemies(int(request.get("performance_cull", 0)))
		for _i in range(int(request.get("count", 1))):
			var single_request: Dictionary = request.duplicate(true)
			single_request["count"] = 1
			wave_scheduler.enqueue_warning(single_request, _random_spawn_position(String(request.get("spawn_area", "full"))))
	var materialized: Array = wave_scheduler.physics_tick(player_position, Callable(self, "_random_spawn_position"))
	for request in materialized:
		_spawn_enemy_from_request(request)
	if wave_scheduler.elapsed_seconds >= wave_scheduler.duration_seconds:
		_complete_wave(true)

func _spawn_enemy_from_request(request: Dictionary) -> void:
	var enemy_id := _enemy_id_from_request(request)
	var stats: Variant = enemy_stats_by_id.get(enemy_id, null)
	if stats == null:
		push_warning("Missing enemy stats for %s" % enemy_id)
		return
	var difficulty_multiplier: float = formulas.danger_enemy_stat_multiplier(current_danger)
	enemies.append(stats.instantiate(current_wave, request.get("position", player_position), player_data, randf_range(-1.0, 1.0), difficulty_multiplier))

func _drop_material(pos: Vector2, value: int) -> void:
	if combat_runtime != null:
		var before_count := materials.size()
		combat_runtime.add_material_drop(materials, pos, value)
		if materials.size() > before_count:
			_assign_material_visual(materials[materials.size() - 1])
	else:
		var material := {
			"position": pos,
			"value": value,
			"flight_time": 0.0,
			"scale": 1.0,
		}
		_assign_material_visual(material)
		materials.append(material)

func _enemy_id_from_request(request: Dictionary) -> String:
	var enemy_id := String(request.get("enemy_id", ""))
	if not enemy_id.is_empty():
		return enemy_id
	var enemy_pool: Array = request.get("enemy_pool", [])
	if not enemy_pool.is_empty():
		return String(enemy_pool[randi() % enemy_pool.size()])
	return "baby_alien"

func _complete_current_wave() -> void:
	wave_scheduler.warning_queue.clear()
	wave_scheduler.spawn_queue.clear()
	var result: Dictionary = combat_runtime.complete_wave(enemies, materials)
	current_wave = int(result.get("next_wave", current_wave))
	if combat_runtime.state == CombatRuntimeScript.STATE_RUNNING:
		wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number[current_wave], common_wave_groups)
		combat_runtime.start_wave(current_wave)

func _performance_cull_enemies(count: int) -> void:
	for _i in range(maxi(0, count)):
		if enemies.is_empty():
			return
		enemies.remove_at(_random_performance_cull_index())
		performance_clears += 1

func _random_performance_cull_index() -> int:
	var priority_indexes: Array = []
	for i in enemies.size():
		if bool(enemies[i].get("priority_clear", false)):
			priority_indexes.append(i)
	if not priority_indexes.is_empty():
		return int(priority_indexes[randi() % priority_indexes.size()])
	return randi() % enemies.size()

func _random_spawn_position(area: String) -> Vector2:
	var viewport_size: Vector2 = _viewport_size()
	var min_distance := 300.0
	for _attempt in range(32):
		var pos := _raw_spawn_position(area, viewport_size)
		if pos.distance_to(player_position) >= min_distance:
			return pos
		min_distance = max(25.0, min_distance - 5.0)
	return _raw_spawn_position("edge", viewport_size)

func _raw_spawn_position(area: String, viewport_size: Vector2) -> Vector2:
	var margin := 64.0
	if area == "edge":
		match randi() % 4:
			0:
				return Vector2(randf_range(margin, viewport_size.x - margin), margin)
			1:
				return Vector2(viewport_size.x - margin, randf_range(margin, viewport_size.y - margin))
			2:
				return Vector2(randf_range(margin, viewport_size.x - margin), viewport_size.y - margin)
			_:
				return Vector2(margin, randf_range(margin, viewport_size.y - margin))
	if area.begins_with("cluster_"):
		var radius := float(area.get_slice("_", 1))
		var center := Vector2(randf_range(margin, viewport_size.x - margin), randf_range(margin, viewport_size.y - margin))
		var offset := Vector2.RIGHT.rotated(randf() * TAU) * randf() * radius
		return (center + offset).clamp(Vector2(margin, margin), viewport_size - Vector2(margin, margin))
	if area.begins_with("inner_"):
		var inner_margin: float = min(float(area.get_slice("_", 1)), min(viewport_size.x, viewport_size.y) * 0.2)
		return Vector2(randf_range(inner_margin, viewport_size.x - inner_margin), randf_range(inner_margin, viewport_size.y - inner_margin))
	return Vector2(randf_range(margin, viewport_size.x - margin), randf_range(margin, viewport_size.y - margin))

func _texture_for_enemy(enemy_data: Dictionary) -> Texture2D:
	var path := String(enemy_data.get("texture", ""))
	if path.is_empty():
		return null
	if not enemy_textures.has(path):
		enemy_textures[path] = _safe_texture(path)
	return enemy_textures[path]

func _texture_for_material(material_data: Dictionary) -> Texture2D:
	if material_textures.is_empty():
		return material_texture
	return material_textures[int(material_data.get("texture_index", 0)) % material_textures.size()]

func _assign_material_visual(material: Dictionary) -> void:
	if material_textures.is_empty():
		return
	if not material.has("texture_index"):
		material["texture_index"] = randi() % material_textures.size()

func _draw_ground(viewport_size: Vector2) -> void:
	if ground_texture == null:
		for x in range(0, int(viewport_size.x), 64):
			draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), Color(0.22, 0.36, 0.2), 1.0)
		for y in range(0, int(viewport_size.y), 64):
			draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(0.22, 0.36, 0.2), 1.0)
		return
	var cell_size := int(asset_manifest.ground_data().get("cell_size", 64))
	for x in range(-cell_size, int(viewport_size.x) + cell_size, cell_size):
		for y in range(-cell_size, int(viewport_size.y) + cell_size, cell_size):
			var cell := Vector2i(floori(float(x) / float(cell_size)), floori(float(y) / float(cell_size)))
			var subtile: Vector2i = PresentationRulesScript.pick_weighted_ground_subtile(PresentationRulesScript.deterministic_ground_roll(cell, current_wave), ground_subtiles)
			var src_rect := Rect2(Vector2(subtile.x * cell_size, subtile.y * cell_size), Vector2(cell_size, cell_size))
			draw_texture_rect_region(ground_texture, Rect2(Vector2(x, y), Vector2(cell_size, cell_size)), src_rect)
	var outline_color := _color_from_array(ground_theme.get("outline_color", [0.267, 0.267, 0.267]))
	draw_rect(Rect2(Vector2.ZERO, viewport_size), outline_color, false, 6.0)

func _request_screen_shake(incoming: Dictionary) -> void:
	if float(screen_shake.get("duration", 0.0)) <= 0.0 or PresentationRulesScript.should_replace_screen_shake(screen_shake, incoming):
		screen_shake = incoming.duplicate(true)

func _queue_sound(event_id: String, pos: Vector2 = Vector2.ZERO) -> void:
	if event_id.is_empty() or asset_manifest == null:
		return
	audio_rules.request_sound(event_id, asset_manifest.sound_event(event_id), randf(), randf(), pos)

func _load_m5_presentation() -> void:
	asset_manifest = AssetManifestScript.load_from_path(ASSET_MANIFEST_PATH)
	player_visual = asset_manifest.player_visual()
	ground_subtiles = PresentationRulesScript.weighted_ground_subtiles()
	var themes: Array = asset_manifest.ground_themes()
	if not themes.is_empty():
		ground_theme = themes[0]
		ground_texture = _safe_texture(String(ground_theme.get("texture", "")))
	for path in asset_manifest.material_texture_paths():
		var texture := _safe_texture(String(path))
		if texture != null:
			material_textures.append(texture)

func _load_m2_data() -> void:
	starter_weapons.clear()
	weapon_icon_by_id.clear()
	if economy_catalog != null:
		for weapon_id in STARTER_WEAPON_IDS:
			var entry: Dictionary = economy_catalog.get_entry(String(weapon_id))
			if entry.is_empty():
				continue
			starter_weapons.append(entry)
			_register_weapon_icon(entry)
	if starter_weapons.is_empty():
		var weapon_json: Dictionary = _load_json(WEAPON_DATA_PATH)
		starter_weapons = weapon_json.get("weapons", [])
		for weapon in starter_weapons:
			var row: Dictionary = weapon
			_register_weapon_icon(row)
	if starter_weapons.size() > 0:
		selected_weapon_row = starter_weapons[0].duplicate(true)
		weapon_stats = WeaponStatsScript.from_dict(starter_weapons[0])
		weapon_texture = _safe_texture(weapon_stats.texture_path)
	var enemy_json: Dictionary = _load_json(ENEMY_DATA_PATH)
	for row in enemy_json.get("enemies", []):
		var stats: Variant = EnemyStatsScript.from_dict(row)
		enemy_stats_by_id[stats.enemy_id] = stats
	var wave_json: Dictionary = _load_json(WAVE_DATA_PATH)
	common_wave_groups = wave_json.get("common_groups", [])
	for row in wave_json.get("waves", []):
		waves_by_number[int(row.get("wave", 1))] = row
	wave_scheduler = WaveSchedulerScript.from_dict(waves_by_number.get(current_wave, waves_by_number.get(1, {})), common_wave_groups)

func _load_bitmap_assets() -> void:
	# Raw asset files are kept in the devkit tree without committed Godot import metadata.
	player_texture = _safe_texture(PLAYER_TEXTURE_PATH)
	material_texture = _safe_texture(MATERIAL_TEXTURE_PATH)
	material_ui_texture = _safe_texture(MATERIAL_UI_TEXTURE_PATH)
	material_bag_texture = _safe_texture(MATERIAL_BAG_TEXTURE_PATH)
	shop_background_texture = _safe_texture(SHOP_BACKGROUND_TEXTURE_PATH)
	title_background_texture = _safe_texture(TITLE_BACKGROUND_TEXTURE_PATH)
	title_brotato_texture = _safe_texture(TITLE_BROTATO_TEXTURE_PATH)
	title_logo_texture = _safe_texture(TITLE_LOGO_TEXTURE_PATH)
	upgrade_icon_texture = _safe_texture(UPGRADE_ICON_TEXTURE_PATH)
	menu_font = null

func _texture_from_file(path: String) -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image := Image.new()
	var error := image.load(absolute_path)
	if error != OK:
		push_warning("Could not load image asset: %s" % path)
		return null
	return ImageTexture.create_from_image(image)

func _load_json(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Could not parse JSON: %s" % path)
		return {}
	return parsed

func _highest_wave_number() -> int:
	var highest := current_wave
	for wave_number in waves_by_number.keys():
		highest = maxi(highest, int(wave_number))
	return highest

func _viewport_size() -> Vector2:
	if is_inside_tree():
		return get_viewport_rect().size
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
	)

func _apply_selected_character() -> void:
	var character_row := _character_row_for_id(selected_character_id)
	if not character_row.is_empty():
		player_data.wanted_tags = character_row.get("wanted_tags", []).duplicate(true)
		player_data.banned_shop_ids = character_row.get("banned_items", []).duplicate(true)
		for effect_data in character_row.get("effects", []):
			var effect: Variant = _effect_from_dict(effect_data)
			if effect != null:
				player_data.apply_effect(effect)
		for item_id in character_row.get("starting_items", []):
			_grant_item(economy_catalog.get_entry(String(item_id)))
		return
	for character in CHARACTER_OPTIONS:
		var data: Dictionary = character
		if String(data.get("id", "")) != selected_character_id:
			continue
		for key in data.get("stats", {}).keys():
			player_data.add_permanent_stat(String(key), int(data["stats"][key]))
		return

func _grant_starting_weapon() -> void:
	var entry: Dictionary = selected_weapon_row.duplicate(true)
	if entry.is_empty():
		entry = _starter_weapon_entry_for_id(selected_weapon_id)
	if not entry.is_empty():
		player_data.add_weapon(entry)

func _grant_item(entry: Dictionary) -> void:
	if entry.is_empty():
		return
	player_data.add_item(entry)
	for effect_data in entry.get("effects", []):
		var effect: Variant = _effect_from_dict(effect_data)
		if effect != null:
			player_data.apply_effect(effect)

func _starter_weapon_entry_for_id(weapon_id: String) -> Dictionary:
	for row in starter_weapons:
		var weapon_row: Dictionary = row
		if String(weapon_row.get("id", "")) == weapon_id or String(weapon_row.get("weapon_id", "")) == weapon_id:
			return weapon_row.duplicate(true)
	if economy_catalog == null:
		return {}
	var entry: Dictionary = economy_catalog.get_entry(weapon_id)
	if not entry.is_empty():
		return entry
	if not weapon_id.ends_with("_1"):
		return economy_catalog.get_entry("%s_1" % weapon_id)
	return {}

func _refresh_active_weapon_stats() -> void:
	var weapon_entry := _best_inventory_weapon()
	if weapon_entry.is_empty():
		return
	weapon_stats = WeaponStatsScript.from_dict(weapon_entry)
	weapon_texture = _safe_texture(weapon_stats.texture_path)
	weapon_cooldown_ticks = min(weapon_cooldown_ticks, weapon_stats.resolved_cooldown_ticks(player_data))

func _best_inventory_weapon() -> Dictionary:
	if player_data == null:
		return {}
	var best: Dictionary = {}
	for weapon in player_data.weapons:
		var weapon_data: Dictionary = weapon
		if best.is_empty():
			best = weapon_data
			continue
		if int(weapon_data.get("tier", 0)) > int(best.get("tier", 0)):
			best = weapon_data
		elif int(weapon_data.get("tier", 0)) == int(best.get("tier", 0)) and int(weapon_data.get("value", 0)) > int(best.get("value", 0)):
			best = weapon_data
	return best.duplicate(true)

func _character_row_for_id(character_id: String) -> Dictionary:
	var lookup_id := character_id
	if lookup_id.is_empty():
		lookup_id = "well_rounded"
	if not lookup_id.begins_with("character_"):
		lookup_id = "character_%s" % lookup_id
	var parsed: Dictionary = _load_json(CHARACTER_DATA_PATH)
	for row in parsed.get("characters", []):
		var character: Dictionary = row
		if String(character.get("id", "")) == lookup_id:
			return character
	return {}

func _effect_from_dict(data: Dictionary) -> Variant:
	var key := String(data.get("key", ""))
	if key.is_empty():
		return null
	var storage_method := _storage_method_id(data.get("storage_method", EffectEntryScript.StorageMethod.SUM))
	if storage_method < 0:
		return null
	return EffectEntryScript.make(
		key,
		data.get("value", 0),
		storage_method,
		String(data.get("custom_key", ""))
	)

func _storage_method_id(value: Variant) -> int:
	if value is int:
		return int(value)
	match String(value).to_upper():
		"SUM":
			return EffectEntryScript.StorageMethod.SUM
		"KEY_VALUE":
			return EffectEntryScript.StorageMethod.KEY_VALUE
		"REPLACE":
			return EffectEntryScript.StorageMethod.REPLACE
		"APPEND_KEY":
			return EffectEntryScript.StorageMethod.APPEND_KEY
		"APPEND_KEY_VALUE":
			return EffectEntryScript.StorageMethod.APPEND_KEY_VALUE
	return -1

func _register_weapon_icon(entry: Dictionary) -> void:
	var icon_path := String(entry.get("icon", ""))
	if icon_path.is_empty():
		var asset_refs: Dictionary = entry.get("asset_refs", {})
		icon_path = String(asset_refs.get("icon", ""))
	if icon_path.is_empty():
		return
	weapon_icon_by_id[String(entry.get("id", ""))] = icon_path
	weapon_icon_by_id[String(entry.get("weapon_id", entry.get("family_id", "")))] = icon_path

func _generate_level_options() -> void:
	current_level_options = level_up_pool.generate_options(maxi(1, player_data.level), player_data, last_level_option_ids)

func _create_ui_roots() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	screen_root = _full_rect_control("ScreenRoot")
	ui_layer.add_child(screen_root)
	hud_root = _full_rect_control("HudRoot")
	ui_layer.add_child(hud_root)
	floating_root = _full_rect_control("FloatingTextRoot")
	floating_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(floating_root)
	tooltip_panel = PanelContainer.new()
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.059, 0.059, 0.059, 0.92), Color(0, 0, 0, 0.78), 5, 8))
	ui_layer.add_child(tooltip_panel)
	tooltip_label = _make_label("", 18)
	tooltip_label.custom_minimum_size = Vector2(260, 0)
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_panel.add_child(tooltip_label)

func _clear_screen_ui() -> void:
	if screen_root != null:
		for child in screen_root.get_children():
			child.queue_free()
	if hud_root != null:
		for child in hud_root.get_children():
			child.queue_free()
	_clear_hud_refs()
	_hide_tooltip()

func _clear_hud_refs() -> void:
	hud_refs.clear()

func _screen_container(name: String) -> Control:
	var root := _full_rect_control(name)
	screen_root.add_child(root)
	return root

func _full_rect_control(name: String) -> Control:
	var control := Control.new()
	control.name = name
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
	return control

func _menu_background(name: String) -> Control:
	var root := _screen_container(name)
	var bg := TextureRect.new()
	bg.texture = shop_background_texture
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(bg)
	return root

func _add_title_background(root: Control) -> void:
	# Doc 11 section 2.2 uses keyart plus logo for the title screen; asset map 05 section 5.5 maps these title textures.
	var bg := TextureRect.new()
	bg.texture = title_background_texture
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(bg)
	var brotato := TextureRect.new()
	brotato.texture = title_brotato_texture
	brotato.set_anchors_preset(Control.PRESET_FULL_RECT)
	brotato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	brotato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(brotato)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.20)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

func _margin_container(parent: Control, margin: int) -> MarginContainer:
	var container := MarginContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("margin_left", margin)
	container.add_theme_constant_override("margin_top", margin)
	container.add_theme_constant_override("margin_right", margin)
	container.add_theme_constant_override("margin_bottom", margin)
	parent.add_child(container)
	return container

func _add_screen_title(root: Control, title: String, tooltip: String) -> void:
	var label := _make_label(title, 46, HORIZONTAL_ALIGNMENT_CENTER)
	label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 28
	label.offset_left = 220
	label.offset_right = -220
	label.custom_minimum_size = Vector2(0, 70)
	root.add_child(label)
	_attach_tooltip(label, tooltip)

func _add_back_button(root: Control, callback: Callable) -> void:
	var back := _make_button("BACK", callback, "Return to the previous screen.", Vector2(140, 50))
	back.position = Vector2(HUD_MARGIN, HUD_MARGIN)
	root.add_child(back)

func _centered_grid(root: Control, columns: int, offset: Vector2 = Vector2.ZERO) -> GridContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 92 + offset.y
	center.offset_left = 40 + offset.x
	center.offset_right = -40 + offset.x
	center.offset_bottom = -70
	root.add_child(center)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	center.add_child(grid)
	return grid

func _center_panel(root: Control, size: Vector2, offset: Vector2 = Vector2.ZERO) -> PanelContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.offset_left = offset.x
	center.offset_right = offset.x
	center.offset_top = offset.y
	center.offset_bottom = offset.y
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 5, 8))
	center.add_child(panel)
	return panel

func _make_selection_card(title: String, subtitle: String, icon_path: String, tier: int, callback: Callable, tooltip: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SELECTION_CARD_SIZE
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.07, 0.07, 0.88), _tier_color(tier), 5, 8))
	_attach_tooltip(panel, tooltip)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = _safe_texture(icon_path)
	icon.custom_minimum_size = Vector2(104, 104)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_make_label(title, 27, HORIZONTAL_ALIGNMENT_CENTER))
	var sub := _make_label(subtitle, 18, HORIZONTAL_ALIGNMENT_CENTER)
	sub.custom_minimum_size = Vector2(210, 44)
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	box.add_child(_make_button("SELECT", callback, tooltip, Vector2(150, 48)))
	return panel

func _make_upgrade_card(option: Dictionary, callback: Callable) -> PanelContainer:
	var key := String(option.get("key", ""))
	var tier := int(option.get("tier", 0))
	var title := _stat_display_name(key)
	var value := int(option.get("value", 0))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(230, 280)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.07, 0.07, 0.9), _tier_color(tier), 5, 8))
	_attach_tooltip(panel, "Tier %d upgrade generated by LevelUpPool." % (tier + 1))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = _safe_texture(String(UPGRADE_ICON_BY_KEY.get(key, "")))
	if icon.texture == null:
		icon.texture = upgrade_icon_texture
	icon.custom_minimum_size = Vector2(108, 108)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_make_label(title, 24, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("%+d" % value, 34, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_button("CHOOSE", callback, "Apply this upgrade.", Vector2(150, 48)))
	return panel

func _make_shop_card(index: int, slot: Dictionary) -> PanelContainer:
	var tier := int(slot.get("tier", 0))
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SHOP_CARD_SIZE
	var border := Color.WHITE if bool(slot.get("locked", false)) else _tier_color(tier)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.055, 0.055, 0.92), border, 5, 8))
	_attach_tooltip(panel, _effects_text(slot))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = _safe_texture(_icon_for_entry(slot))
	icon.custom_minimum_size = Vector2(94, 94)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	var name_label := _make_label(String(slot.get("name", slot.get("id", ""))), 22, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.custom_minimum_size = Vector2(190, 44)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)
	var price: int = current_shop.slot_price(index, player_data)
	var status := "SOLD" if bool(slot.get("sold", false)) else ("LOCKED" if bool(slot.get("locked", false)) else "Price %d" % price)
	box.add_child(_make_label(status, 20, HORIZONTAL_ALIGNMENT_CENTER))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var buy := _make_button("BUY", Callable(self, "buy_shop_slot").bind(index), "Purchase through ShopState.buy_slot.", Vector2(70, 40))
	buy.disabled = bool(slot.get("sold", false))
	row.add_child(buy)
	var lock := _make_button("LOCK", Callable(self, "lock_shop_slot").bind(index), "Doc 11 section 8.2 lock preserves the slot on reroll.", Vector2(76, 40))
	lock.disabled = bool(slot.get("sold", false))
	row.add_child(lock)
	var ban := _make_button("BAN", Callable(self, "ban_shop_slot").bind(index), "Preview ban action for the shop card contract.", Vector2(70, 40))
	ban.disabled = bool(slot.get("sold", false))
	row.add_child(ban)
	if bool(slot.get("sold", false)):
		panel.modulate = Color(1, 1, 1, 0.45)
	return panel

func _make_wallet_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 5, 8))
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var icon := TextureRect.new()
	icon.texture = material_ui_texture
	icon.modulate = MATERIAL_UI_COLOR
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	box.add_child(_make_label("%d" % player_data.materials, 30))
	return panel

func _make_inventory_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 5, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(_make_label("INVENTORY", 22, HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_make_label("Weapons %d/%d" % [player_data.weapons.size(), int(player_data.get_stat("weapon_slot"))], 20))
	box.add_child(_make_label("Items %d" % player_data.items.size(), 20))
	return panel

func _make_stat_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260, 250)
	panel.add_theme_stylebox_override("panel", _panel_style(PANEL_BG, PANEL_BORDER, 5, 8))
	_attach_tooltip(panel, "Doc 11 section 12: stat panel refreshes after purchases, rerolls, and upgrades.")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	box.add_child(_make_label("STATS", 22, HORIZONTAL_ALIGNMENT_CENTER))
	for key in ["stat_max_hp", "stat_ranged_damage", "stat_melee_damage", "stat_percent_damage", "stat_attack_speed", "stat_speed", "stat_harvesting", "stat_luck", "stat_armor", "stat_dodge"]:
		box.add_child(_make_stat_row(key))
	return panel

func _make_stat_row(key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon := TextureRect.new()
	icon.texture = _safe_texture(String(STAT_ICON_BY_KEY.get(key, "")))
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	row.add_child(_make_label("%s %s" % [_stat_display_name(key), _format_stat_value(key)], 17))
	return row

func _make_setting_check(key: String, title: String) -> CheckButton:
	var check := CheckButton.new()
	check.text = title
	check.button_pressed = bool(settings.get(key, false))
	check.custom_minimum_size = Vector2(520, 42)
	if menu_font != null:
		check.add_theme_font_override("font", menu_font)
	check.add_theme_font_size_override("font_size", 22)
	check.toggled.connect(Callable(self, "_set_bool_setting").bind(key))
	_attach_tooltip(check, "Setting key: %s" % key)
	return check

func _make_button(text: String, callback: Callable, tooltip: String = "", min_size: Vector2 = Vector2(220, 54)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.focus_mode = Control.FOCUS_ALL
	if menu_font != null:
		button.add_theme_font_override("font", menu_font)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", _panel_style(BUTTON_BG, Color(0, 0, 0, 1), 3, 8))
	button.add_theme_stylebox_override("hover", _panel_style(Color(1, 1, 1, 0.784), Color(0, 0, 0, 1), 3, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.396, 0.357, 0.196, 0.92), Color(0, 0, 0, 1), 3, 8))
	button.add_theme_color_override("font_color", Color(0.92, 0.92, 0.88))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	button.pressed.connect(callback)
	if not tooltip.is_empty():
		_attach_tooltip(button, tooltip)
	return button

func _make_label(text: String, size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if menu_font != null:
		label.add_theme_font_override("font", menu_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.88))
	return label

func _panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _safe_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not texture_cache.has(path):
		texture_cache[path] = _texture_from_file(path)
	return texture_cache[path]

func _tier_color(tier: int) -> Color:
	return TIER_COLORS[clampi(tier, 0, TIER_COLORS.size() - 1)]

func _icon_for_entry(entry: Dictionary) -> String:
	var id := String(entry.get("id", ""))
	var icon_path := String(entry.get("icon", ""))
	if not icon_path.is_empty():
		return icon_path
	var asset_refs: Dictionary = entry.get("asset_refs", {})
	icon_path = String(asset_refs.get("icon", ""))
	if not icon_path.is_empty():
		return icon_path
	if ITEM_ICON_BY_ID.has(id):
		return String(ITEM_ICON_BY_ID[id])
	if String(entry.get("kind", "")) == "weapon":
		var weapon_id := String(entry.get("weapon_id", entry.get("id", "")))
		if weapon_icon_by_id.has(weapon_id):
			return String(weapon_icon_by_id[weapon_id])
	return ""

func _effects_text(entry: Dictionary) -> String:
	var effects: Array = entry.get("effects", [])
	if effects.is_empty():
		return "No stat effect in the current fixture data."
	var parts: Array = []
	for effect in effects:
		var data: Dictionary = effect
		parts.append("%s %+d" % [_stat_display_name(String(data.get("key", ""))), int(data.get("value", 0))])
	return ", ".join(parts)

func _stat_display_name(key: String) -> String:
	var name := key
	if name.begins_with("stat_"):
		name = name.substr(5)
	return name.replace("_", " ").capitalize()

func _format_stat_value(key: String) -> String:
	if player_data == null:
		return "0"
	match key:
		"stat_max_hp":
			return "%d/%d" % [player_data.current_health, player_data.get_max_health()]
		"stat_dodge":
			return "%d%%" % roundi(player_data.get_dodge_probability() * 100.0)
		"stat_speed":
			return "%d" % roundi(player_data.get_speed())
	return "%d" % roundi(player_data.get_stat(key))

func _refresh_hud() -> void:
	if player_data == null or wave_scheduler == null or hud_refs.is_empty():
		return
	var max_hp: int = player_data.get_max_health()
	hud_refs["hp_label"].text = "HP %d/%d" % [player_data.current_health, max_hp]
	hud_refs["hp_bar"].max_value = max_hp
	hud_refs["hp_bar"].value = player_data.current_health
	var needed: float = formulas.next_level_xp_needed(player_data.level, player_data.get_stat("next_level_xp_needed"))
	hud_refs["xp_label"].text = "LV.%d  XP %d/%d" % [player_data.level, floori(player_data.current_xp), ceili(needed)]
	hud_refs["xp_bar"].max_value = needed
	hud_refs["xp_bar"].value = player_data.current_xp
	hud_refs["materials_label"].text = "%d" % player_data.materials
	var remaining: int = maxi(0, ceili(wave_scheduler.duration_seconds - wave_scheduler.elapsed_seconds))
	hud_refs["wave_label"].text = "WAVE %d  %02d" % [current_wave, remaining]
	hud_refs["timeline"].max_value = wave_scheduler.duration_seconds
	hud_refs["timeline"].value = wave_scheduler.elapsed_seconds

func _spawn_floating_text(text: String, position: Vector2, kind: String, force: bool = false) -> void:
	var rule := floating_text_rule(kind)
	if not force and bool(rule.get("uses_damage_toggle", true)) and not bool(settings.get("damage_display", true)) and not bool(rule.get("always_display", false)):
		return
	if floating_root == null:
		return
	var label := _make_label(text, 24, HORIZONTAL_ALIGNMENT_CENTER)
	label.add_theme_color_override("font_color", rule.get("color", Color.WHITE))
	label.position = position
	label.custom_minimum_size = Vector2(140, 34)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floating_root.add_child(label)
	floating_texts.append({
		"label": label,
		"velocity": Vector2(randf_range(-12.0, 12.0), -62.0),
		"age": 0.0,
		"lifetime": FLOATING_TEXT_LIFETIME,
	})

func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		var data: Dictionary = floating_texts[i]
		var label: Label = data["label"]
		if not is_instance_valid(label):
			floating_texts.remove_at(i)
			continue
		data["age"] = float(data["age"]) + delta
		label.position += data["velocity"] * delta
		label.modulate.a = clamp(1.0 - float(data["age"]) / float(data["lifetime"]), 0.0, 1.0)
		if float(data["age"]) >= float(data["lifetime"]):
			label.queue_free()
			floating_texts.remove_at(i)
		else:
			floating_texts[i] = data

func _attach_tooltip(control: Control, text: String) -> void:
	if text.is_empty():
		return
	control.mouse_entered.connect(Callable(self, "_show_tooltip").bind(text))
	control.mouse_exited.connect(Callable(self, "_hide_tooltip"))

func _show_tooltip(text: String) -> void:
	if tooltip_panel == null:
		return
	tooltip_label.text = text
	tooltip_panel.visible = true
	_update_tooltip_position()

func _hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

func _update_tooltip_position() -> void:
	if tooltip_panel == null or not tooltip_panel.visible:
		return
	var viewport_size: Vector2 = _viewport_size()
	var pos := get_viewport().get_mouse_position() + Vector2(18, 18)
	pos.x = min(pos.x, viewport_size.x - 300)
	pos.y = min(pos.y, viewport_size.y - 120)
	tooltip_panel.position = pos

func _vec2(values: Variant) -> Vector2:
	if values is Vector2:
		return values
	if values is Array and values.size() >= 2:
		return Vector2(float(values[0]), float(values[1]))
	return Vector2.ZERO

func _color_from_array(values: Variant) -> Color:
	if values is Array and values.size() >= 3:
		return Color(float(values[0]), float(values[1]), float(values[2]), 1.0)
	return Color.WHITE
