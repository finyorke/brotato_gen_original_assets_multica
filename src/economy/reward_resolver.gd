class_name RewardResolver
extends RefCounted

const FormulasScript = preload("res://src/core/formulas.gd")

var _formulas: Variant = FormulasScript.new()

func pickup_material(player: Variant, value: int, double_roll: float = -1.0) -> Dictionary:
	var adjusted: float = float(maxi(0, value)) * (1.0 + player.get_stat("increase_material_value") / 100.0)
	var amount: int = floori(adjusted)
	if adjusted - float(amount) > 0.0:
		var fractional_roll: float = randf() if double_roll < 0.0 else double_roll
		if fractional_roll <= adjusted - float(amount):
			amount += 1
	var doubled: bool = false
	var chance: float = player.get_stat("chance_double_gold") / 100.0
	if chance > 0.0:
		var roll: float = randf() if double_roll < 0.0 else double_roll
		if roll <= chance:
			amount *= 2
			doubled = true
	player.materials += amount
	var levels: int = player.gain_xp(amount)
	return {"materials": amount, "xp_value": amount, "levels": levels, "doubled": doubled}

func settle_harvesting(player: Variant, wave: int, living_enemies: int = 0, living_trees: int = 0, is_horde_wave: bool = false, charmed_enemy_materials: int = 0) -> Dictionary:
	var pacifist: float = player.get_stat("pacifist")
	if is_horde_wave:
		pacifist *= 0.5
	var value: int = _formulas.harvest_value(
		player.get_stat("stat_harvesting"),
		living_enemies,
		pacifist,
		living_trees,
		int(player.get_stat("cryptid")),
		int(player.get_stat("materials_per_living_enemy")),
		charmed_enemy_materials
	)
	var levels: int = 0
	if value >= 0:
		player.materials += value
		levels = player.gain_xp(value)
	else:
		player.materials = maxi(0, player.materials + value)
	var growth: int = _formulas.harvesting_growth_delta(player.get_stat("stat_harvesting"), player.get_stat("harvesting_growth"), wave)
	if growth != 0:
		player.add_permanent_stat("stat_harvesting", growth)
	return {"value": value, "growth": growth, "levels": levels}

func apply_start_wave_interest(player: Variant, wave: int) -> int:
	var percent: float = player.get_stat("gain_pct_gold_start_wave")
	if wave > 20:
		percent = -100.0 if percent < 0.0 else 0.0
	var amount: int = floori(float(player.materials) * percent / 100.0)
	player.materials = maxi(0, player.materials + amount)
	return amount

func collect_bonus_gold(ground_materials: Array) -> int:
	var total := 0
	for material in ground_materials:
		total += int(material.get("value", 0))
	return total

func repay_bonus_gold(material_value: int, bonus_gold: int) -> Dictionary:
	var repayment: int = mini(maxi(0, material_value), maxi(0, bonus_gold))
	return {
		"value": material_value + repayment,
		"remaining_bonus_gold": maxi(0, bonus_gold - repayment),
		"repaid": repayment,
	}
