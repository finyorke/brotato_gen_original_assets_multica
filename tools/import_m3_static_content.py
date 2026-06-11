#!/usr/bin/env python3
"""Import M3 static content from the bundled Brotato design docs.

The docs are the source of truth for this repository. This importer keeps the
JSON data deterministic while preserving source line references for every row.
"""

from __future__ import annotations

import json
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DOC_ROOT = ROOT / "devkit" / "brotato_original_devkit" / "game_mechanics_docs"
ASSET_ROOT = ROOT / "devkit" / "brotato_original_devkit" / "asset_pack" / "assets"
DATA_ROOT = ROOT / "data" / "m3"

DOC_02 = DOC_ROOT / "02_角色系统.md"
DOC_03 = DOC_ROOT / "03_武器系统.md"
DOC_05 = DOC_ROOT / "05_道具清单.md"
DOC_08 = DOC_ROOT / "08_效果系统.md"
EFFECT_KEYS_PATH = ROOT / "src" / "core" / "effect_keys.gd"

TIER_TO_INDEX = {"I": 0, "II": 1, "III": 2, "IV": 3}
INDEX_TO_TIER = {value: key for key, value in TIER_TO_INDEX.items()}

SET_ALIASES = {
    "精准": "precise",
    "刀剑": "blade",
    "钝器": "blunt",
    "徒手": "unarmed",
    "原始": "primitive",
    "中世纪": "medieval",
    "虚灵": "ethereal",
    "重型": "heavy",
    "枪械": "gun",
    "元素": "fire",
    "爆炸": "explosive",
    "医疗": "medical",
    "支援": "support",
    "工具": "tool",
    "传奇": "legendary",
}

STAT_ALIASES = [
    ("最大生命值", "stat_max_hp"),
    ("最大生命", "stat_max_hp"),
    ("生命再生", "stat_hp_regeneration"),
    ("生命回复", "stat_hp_regeneration"),
    ("生命窃取", "stat_lifesteal"),
    ("吸血", "stat_lifesteal"),
    ("% 伤害", "stat_percent_damage"),
    ("%伤害", "stat_percent_damage"),
    ("% 速度", "stat_speed"),
    ("%速度", "stat_speed"),
    ("% 攻击速度", "stat_attack_speed"),
    ("%攻击速度", "stat_attack_speed"),
    ("% 暴击率", "stat_crit_chance"),
    ("%暴击率", "stat_crit_chance"),
    ("% 闪避", "stat_dodge"),
    ("%闪避", "stat_dodge"),
    ("近战伤害", "stat_melee_damage"),
    ("远程伤害", "stat_ranged_damage"),
    ("元素伤害", "stat_elemental_damage"),
    ("工程学", "stat_engineering"),
    ("工程", "stat_engineering"),
    ("攻击速度", "stat_attack_speed"),
    ("攻速", "stat_attack_speed"),
    ("暴击率", "stat_crit_chance"),
    ("暴击", "stat_crit_chance"),
    ("射程", "stat_range"),
    ("范围", "stat_range"),
    ("护甲", "stat_armor"),
    ("闪避", "stat_dodge"),
    ("移速", "stat_speed"),
    ("速度", "stat_speed"),
    ("幸运", "stat_luck"),
    ("收获", "stat_harvesting"),
]

SCALING_ALIASES = {
    "近战": "stat_melee_damage",
    "远程": "stat_ranged_damage",
    "元素": "stat_elemental_damage",
    "工程": "stat_engineering",
    "工程学": "stat_engineering",
    "最大生命": "stat_max_hp",
    "生命": "stat_max_hp",
    "护甲": "stat_armor",
    "吸血": "stat_lifesteal",
    "攻速": "stat_attack_speed",
    "攻击速度": "stat_attack_speed",
    "移速": "stat_speed",
    "速度": "stat_speed",
    "射程": "stat_range",
    "范围": "stat_range",
    "等级": "stat_levels",
}

SPECIAL_EFFECT_ALIASES = [
    ("燃烧跳伤间隔", "burning_cooldown_reduction"),
    ("燃烧蔓延", "burning_spread"),
    ("贯通伤害", "piercing_damage"),
    ("穿透伤害", "piercing_damage"),
    ("投射物贯通", "piercing"),
    ("贯通", "piercing"),
    ("穿透", "piercing"),
    ("反弹伤害", "bounce_damage"),
    ("反弹", "bounce"),
    ("拾取范围", "pickup_range"),
    ("击退", "knockback"),
    ("爆炸伤害", "explosion_damage"),
    ("爆炸范围", "explosion_size"),
    ("道具价格", "items_price"),
    ("物品价格", "items_price"),
    ("武器价格", "weapons_price"),
    ("回收", "recycling_gains"),
    ("免费刷新", "free_rerolls"),
    ("敌人掉落材料价值", "enemy_gold_drops"),
    ("敌人材料掉落率", "gold_drops"),
    ("材料掉落价值", "gold_drops"),
    ("材料掉落", "gold_drops"),
    ("敌人数量", "number_of_enemies"),
    ("敌人生命值", "enemy_health"),
    ("敌人生命", "enemy_health"),
    ("敌人伤害", "enemy_damage"),
    ("敌人移动速度", "enemy_speed"),
    ("敌人速度", "enemy_speed"),
    ("地图尺寸", "map_size"),
    ("获得%经验", "xp_gain"),
    ("获得 %经验", "xp_gain"),
    ("经验获取", "xp_gain"),
    ("升级所需经验", "next_level_xp_needed"),
    ("下场敌袭期间+50 获得%经验", "xp_gain"),
    ("消耗品恢复", "consumable_heal"),
    ("使用消耗品恢复", "consumable_heal"),
    ("使用消耗品时恢复", "consumable_heal"),
    ("构建物的攻击速度", "structure_attack_speed"),
    ("构筑物的攻击速度", "structure_attack_speed"),
    ("构筑物攻速", "structure_attack_speed"),
    ("构建物攻速", "structure_attack_speed"),
    ("结构攻速", "structure_attack_speed"),
    ("结构范围", "structure_range"),
    ("结构%伤害", "structure_percent_damage"),
    ("对 Boss", "damage_against_bosses"),
    ("对 Boss/精英伤害", "damage_against_bosses"),
    ("对头目和精英", "damage_against_bosses"),
    ("闪避上限", "dodge_cap"),
    ("武器栏升级", "weapon_slot_upgrades"),
    ("武器栏位", "weapon_slot"),
    ("武器档位上限", "max_weapon_tier"),
    ("武器档位下限", "min_weapon_tier"),
    ("商店保底武器数", "minimum_weapons_in_shop"),
    ("销毁武器", "destroy_weapons"),
    ("移动时无法攻击", "can_attack_while_moving"),
    ("近战武器 | 禁止", "no_melee_weapons"),
    ("远程武器 | 禁止", "no_ranged_weapons"),
    ("无近战武器", "no_melee_weapons"),
    ("无远程武器", "no_ranged_weapons"),
    ("武器去重", "no_duplicate_weapons"),
    ("套装计数", "all_weapons_count_for_sets"),
    ("树木生成时机", "trees_start_wave"),
    ("树木", "trees"),
    ("无法治疗", "no_heal"),
    ("商店货币", "hp_shop"),
    ("强化鱼饵", "upgraded_baits"),
    ("投射物", "projectiles"),
    ("精准", "accuracy"),
    ("精准度", "accuracy"),
    ("立即吸收", "instant_gold_attracting"),
    ("水果", "enemy_fruit_drops"),
    ("箱子", "crate_chance"),
    ("补给箱", "item_box_gold"),
    ("每秒受到", "lose_hp_per_second"),
    ("一击毙命", "one_shot_trees"),
    ("无法通过其他途径恢复", "torture"),
]

WEAPON_SLUG_OVERRIDES = {
    "cactus_club": "cactus_mace",
    "flaming_brass_knuckles": "flaming_knuckles",
}

ITEM_ASSET_OVERRIDES = {
    "item_broken_hourglass": "hourglass",
    "item_evil_hat": "evil_hat",
    "item_gobbler_s_hat": "evil_hat",
}

TRACKING_TEXT_BY_PHRASE = {
    "造成的伤害": "DAMAGE_DEALT",
    "获得的材料": "MATERIALS_GAINED",
    "恢复的生命": "HP_HEALED",
    "获得的属性": "STATS_GAINED",
    "节省的材料": "MATERIALS_SAVED",
    "爆炸造成的伤害": "DAMAGE_DEALT",
}


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines()


def rel_doc(path: Path) -> str:
    return str(path.relative_to(ROOT)).replace("\\", "/")


def source_ref(path: Path, line: int, section: str = "") -> dict[str, Any]:
    ref: dict[str, Any] = {"doc": rel_doc(path), "line": line}
    if section:
        ref["section"] = section
    return ref


def clean_markup(value: str) -> str:
    value = re.sub(r"<br\s*/?>", "\n", value)
    value = value.replace("`", "")
    value = value.replace("**", "")
    value = value.replace("（", "(").replace("）", ")")
    value = value.replace("，", ",").replace("；", ";")
    value = value.replace("×", "x")
    value = re.sub(r"\*\((.*?)\)\*", r"\1", value)
    return value.strip()


def strip_markdown_table_cell(value: str) -> str:
    return value.replace("<br>", "\n").strip()


def split_md_row(line: str) -> list[str] | None:
    stripped = line.strip()
    if not stripped.startswith("|") or not stripped.endswith("|"):
        return None
    cells = [cell.strip() for cell in stripped.strip("|").split("|")]
    if not cells:
        return None
    if all(re.fullmatch(r"[:\-\s]+", cell or "") for cell in cells):
        return None
    return cells


def extract_backtick_tokens(text: str) -> list[str]:
    return re.findall(r"`([^`]+)`", text)


def signed_numbers(text: str) -> list[float]:
    normalized = clean_markup(text).replace("+-", "-")
    values = [float(match) for match in re.findall(r"(?<![\w.])([+-]\d+(?:\.\d+)?)", normalized)]
    if values:
        return values
    return [float(match) for match in re.findall(r"(?<![\w.])(\d+(?:\.\d+)?)(?![\w.])", normalized)]


def best_value(text: str, default: float = 1.0) -> float:
    values = signed_numbers(text)
    if not values:
        return default
    if clean_markup(text).startswith("每"):
        return values[-1]
    return values[0]


def int_if_whole(value: float) -> int | float:
    return int(value) if float(value).is_integer() else value


def slugify(value: str) -> str:
    value = value.replace("’", "").replace("'", "")
    value = value.replace("&", " and ")
    value = re.sub(r"[^A-Za-z0-9]+", "_", value).strip("_").lower()
    return re.sub(r"_+", "_", value)


def english_name_from_mixed(value: str) -> tuple[str, str]:
    value = clean_markup(value)
    match = re.match(r"^(.*?)([A-Za-z][A-Za-z0-9'’\-\s]+)$", value)
    if not match:
        return value, value
    zh = match.group(1).strip()
    en = match.group(2).strip()
    return zh, en


def parse_bool_unlocked(value: str) -> bool:
    return "✓" in value or "默认" in value


def parse_max_nb(value: str) -> int:
    value = clean_markup(value)
    if value in {"∞", "不限"}:
        return -1
    match = re.search(r"-?\d+", value)
    return int(match.group(0)) if match else -1


def parse_effect_key_defaults() -> tuple[dict[str, Any], set[str]]:
    text = EFFECT_KEYS_PATH.read_text(encoding="utf-8")
    defaults: dict[str, Any] = {}
    for line in text.splitlines():
        match = re.match(r'\s*"([^"]+)":\s*(.*?),?\s*$', line)
        if not match:
            continue
        key, raw = match.group(1), match.group(2).strip().rstrip(",")
        if raw == "INF_CAP":
            value: Any = 99999999
        elif raw == "[]":
            value = []
        elif raw == "{}":
            value = {}
        elif raw in {"true", "false"}:
            value = raw == "true"
        else:
            try:
                value = int(raw)
            except ValueError:
                try:
                    value = float(raw)
                except ValueError:
                    value = raw
        defaults[key] = value
    return defaults, set(defaults.keys())


EFFECT_DEFAULTS, EFFECT_KEYS = parse_effect_key_defaults()


def find_direct_effect_key(text: str) -> str | None:
    normalized = clean_markup(text)
    for phrase, key in SPECIAL_EFFECT_ALIASES:
        if phrase in normalized:
            return key
    for phrase, key in STAT_ALIASES:
        if phrase in normalized:
            return key
    return None


def effect_record(
    key: str,
    value: Any,
    source_text: str,
    effect_type: str = "effect",
    storage_method: str = "SUM",
    custom_key: str = "",
    payload: dict[str, Any] | None = None,
) -> dict[str, Any]:
    record: dict[str, Any] = {
        "type": effect_type,
        "key": key,
        "value": value,
        "storage_method": storage_method,
        "source_text": clean_markup(source_text),
    }
    if custom_key:
        record["custom_key"] = custom_key
    if payload:
        record["payload"] = payload
    return record


def parse_effects_from_text(text: str) -> list[dict[str, Any]]:
    effects: list[dict[str, Any]] = []
    raw = text.strip()
    if not raw or raw == "—":
        return effects

    cleaned = clean_markup(raw)
    tokens = extract_backtick_tokens(raw)
    for token in tokens:
        if token in EFFECT_KEYS:
            effects.append(
                effect_record(
                    token,
                    int_if_whole(best_value(raw)),
                    raw,
                    effect_type="source_key_reference",
                    storage_method="REFERENCE",
                )
            )

    if "获取效率" in cleaned:
        if "全部 8 项伤害" in cleaned:
            for key in [
                "gain_stat_percent_damage",
                "gain_stat_ranged_damage",
                "gain_stat_melee_damage",
                "gain_stat_elemental_damage",
                "gain_explosion_damage",
                "gain_piercing_damage",
                "gain_bounce_damage",
                "gain_damage_against_bosses",
            ]:
                effects.append(effect_record(key, int_if_whole(best_value(raw)), raw, "stat_gain_mod"))
            return effects
        base_key = find_direct_effect_key(cleaned.replace("获取效率", ""))
        if base_key:
            effects.append(effect_record("gain_" + base_key, int_if_whole(best_value(raw)), raw, "stat_gain_mod"))
            return effects

    if "起始物品" in cleaned:
        for item_id in extract_ids_from_text(raw, "item"):
            effects.append(effect_record(item_id, 1, raw, "append_item", "APPEND_KEY", "starting_item"))
    if "起始武器" in cleaned:
        for weapon_id in extract_ids_from_text(raw, "weapon"):
            effects.append(effect_record(weapon_id, 1, raw, "append_weapon", "APPEND_KEY", "starting_weapon"))

    if "波次结束" in cleaned or "敌袭结束" in cleaned or "每级" in cleaned or "升级时" in cleaned:
        key = find_direct_effect_key(cleaned)
        custom_key = "stats_on_level_up" if ("每级" in cleaned or "升级时" in cleaned) else "stats_end_of_wave"
        if key and key in EFFECT_KEYS:
            effects.append(
                effect_record(
                    key,
                    int_if_whole(best_value(raw)),
                    raw,
                    "timed_stat",
                    "KEY_VALUE",
                    custom_key,
                )
            )
            return effects

    if cleaned.startswith("每") or "每 1" in cleaned:
        key = find_direct_effect_key(cleaned)
        if key and key in EFFECT_KEYS:
            effects.append(
                effect_record(
                    key,
                    int_if_whole(best_value(raw)),
                    raw,
                    "stat_link_or_counted_bonus",
                    "APPEND_KEY_VALUE",
                    "stat_links",
                )
            )
            return effects

    direct_key = find_direct_effect_key(cleaned)
    if direct_key and direct_key in EFFECT_KEYS:
        storage = "REPLACE" if "REPLACE" in cleaned or "上限" in cleaned or direct_key.endswith("_cap") else "SUM"
        effects.append(effect_record(direct_key, int_if_whole(best_value(raw)), raw, "effect", storage))

    if not effects:
        effects.append(
            {
                "type": "raw_effect_text",
                "source_text": cleaned,
                "payload": {"parse_status": "raw_unmapped"},
            }
        )
    return effects


def parse_scaling(text: str) -> dict[str, float]:
    text = clean_markup(text)
    scaling: dict[str, float] = {}
    if not text or text == "—":
        return scaling
    for part in re.split(r"\s*\+\s*", text):
        match = re.match(r"(.+?)x([+-]?\d+(?:\.\d+)?)$", part.strip())
        if not match:
            continue
        label = match.group(1).strip()
        key = SCALING_ALIASES.get(label)
        if key:
            scaling[key] = float(match.group(2))
    return scaling


def parse_crit(text: str) -> tuple[float, float]:
    match = re.search(r"(\d+(?:\.\d+)?)%x(\d+(?:\.\d+)?)", clean_markup(text))
    if not match:
        return 0.03, 1.5
    return float(match.group(1)) / 100.0, float(match.group(2))


def parse_cooldown(text: str) -> dict[str, Any]:
    cleaned = clean_markup(text)
    match = re.search(r"\d+", cleaned)
    result: dict[str, Any] = {"cooldown": int(match.group(0)) if match else 60}
    reload_match = re.search(r"每(\d+)发换弹x(\d+(?:\.\d+)?)", cleaned)
    if reload_match:
        result["additional_cooldown_every_x_shots"] = int(reload_match.group(1))
        result["additional_cooldown_multiplier"] = float(reload_match.group(2))
    return result


def parse_damage_projectiles(text: str) -> dict[str, Any]:
    cleaned = clean_markup(text)
    match = re.match(r"(\d+(?:\.\d+)?)x(\d+)", cleaned)
    if match:
        result: dict[str, Any] = {
            "damage": int_if_whole(float(match.group(1))),
            "projectiles": int(match.group(2)),
        }
        spread = re.search(r"散射(\d+(?:\.\d+)?)", cleaned)
        if spread:
            result["projectile_spread"] = float(spread.group(1))
        return result
    numbers = signed_numbers(cleaned)
    return {"damage": int_if_whole(numbers[0]) if numbers else 1, "projectiles": 1}


def parse_percent(text: str, default: float = 0.0) -> float:
    match = re.search(r"([+-]?\d+(?:\.\d+)?)%", clean_markup(text))
    return float(match.group(1)) / 100.0 if match else default


def parse_count_reduction(text: str) -> tuple[int, float, bool]:
    cleaned = clean_markup(text)
    if "不可反弹" in cleaned:
        return 0, 0.0, False
    match = re.match(r"(\d+)\((\d+(?:\.\d+)?)%\)", cleaned)
    if match:
        return int(match.group(1)), float(match.group(2)) / 100.0, True
    match = re.match(r"(\d+)$", cleaned)
    if match:
        return int(match.group(1)), 0.0, True
    return 0, 0.0, True


def extract_ids_from_text(text: str, kind: str) -> list[str]:
    prefix = f"{kind}_"
    ids = [token for token in extract_backtick_tokens(text) if token.startswith(prefix)]
    return ids


def weapon_id_for_name(name: str, tier: str | None = None) -> str:
    slug = WEAPON_SLUG_OVERRIDES.get(slugify(name), slugify(name))
    return f"weapon_{slug}_{TIER_TO_INDEX[tier] + 1}" if tier else f"weapon_{slug}"


def weapon_id_from_choice(choice: str, weapon_name_to_slug: dict[str, str]) -> str | None:
    choice = clean_markup(choice).strip(" 。.;")
    match = re.match(r"(.+?)\s+(I|II|III|IV)$", choice)
    if not match:
        return None
    name, tier = match.group(1).strip(), match.group(2)
    slug = weapon_name_to_slug.get(name) or WEAPON_SLUG_OVERRIDES.get(slugify(name), slugify(name))
    return f"weapon_{slug}_{TIER_TO_INDEX[tier] + 1}"


def item_id_from_name(name: str, item_name_to_id: dict[str, str]) -> str | None:
    cleaned = clean_markup(name).strip(" 。.;")
    if cleaned.startswith("item_"):
        return cleaned
    return item_name_to_id.get(cleaned) or item_name_to_id.get(cleaned.replace("-", " "))


def find_asset_file(directory: Path, candidates: list[str]) -> str:
    for candidate in candidates:
        path = directory / candidate
        if path.exists():
            return "res://" + str(path.relative_to(ROOT)).replace("\\", "/")
    pngs = sorted(directory.glob("*.png"))
    return "res://" + str(pngs[0].relative_to(ROOT)).replace("\\", "/") if pngs else ""


def weapon_asset_refs(slug: str) -> dict[str, str]:
    directory = ASSET_ROOT / "weapons" / slug
    if not directory.exists():
        return {"icon": "", "texture": ""}
    return {
        "icon": find_asset_file(directory, [f"{slug}_icon.png"]),
        "texture": find_asset_file(directory, [f"{slug}.png", f"{slug}_short.png"]),
    }


def item_asset_refs(item_id: str) -> dict[str, str]:
    slug = ITEM_ASSET_OVERRIDES.get(item_id, item_id.removeprefix("item_"))
    directory = ASSET_ROOT / "item_icons" / slug
    if not directory.exists():
        return {"icon": ""}
    return {"icon": find_asset_file(directory, [f"{slug}_icon.png", f"{slug}.png"])}


def parse_items() -> tuple[list[dict[str, Any]], dict[str, str]]:
    lines = read_lines(DOC_05)
    items: list[dict[str, Any]] = []
    current_tier = -1
    for line_no, line in enumerate(lines, start=1):
        tier_match = re.match(r"### Tier (IV|III|II|I)\b", line)
        if tier_match:
            current_tier = TIER_TO_INDEX[tier_match.group(1)]
            continue
        cells = split_md_row(line)
        if not cells or current_tier < 0 or len(cells) < 8 or not cells[0].startswith("`item_"):
            continue
        item_id = cells[0].strip("`")
        tags = extract_backtick_tokens(cells[6])
        effect_lines = [part.strip() for part in strip_markdown_table_cell(cells[7]).split("\n") if part.strip()]
        effects: list[dict[str, Any]] = []
        for effect_line in effect_lines:
            effects.extend(parse_effects_from_text(effect_line))
        tracking = ""
        for phrase, key in TRACKING_TEXT_BY_PHRASE.items():
            if phrase in cells[7]:
                tracking = key
                break
        item = {
            "id": item_id,
            "name_key": "ITEM_" + item_id.removeprefix("item_").upper().replace("-", "_").replace("'", ""),
            "name": {"zh": clean_markup(cells[1]), "en": clean_markup(cells[2])},
            "tier": current_tier,
            "tier_name": INDEX_TO_TIER[current_tier],
            "value": int(best_value(cells[3], 0)),
            "max_nb": parse_max_nb(cells[4]),
            "unlocked_by_default": parse_bool_unlocked(cells[5]),
            "can_be_looted": "不可购买" not in cells[5],
            "tags": tags,
            "tracking_text": tracking,
            "replaced_by": "item_broken_hourglass" if item_id == "item_hourglass" else "",
            "effects": effects,
            "asset_refs": item_asset_refs(item_id),
            "source_ref": source_ref(DOC_05, line_no, f"Tier {INDEX_TO_TIER[current_tier]}"),
        }
        items.append(item)

    name_to_id: dict[str, str] = {}
    for item in items:
        name_to_id[item["name"]["en"]] = item["id"]
        name_to_id[item["name"]["zh"]] = item["id"]
        name_to_id[item["id"].removeprefix("item_").replace("_", " ").title()] = item["id"]
    return items, name_to_id


def parse_weapon_sets() -> list[dict[str, Any]]:
    lines = read_lines(DOC_03)
    sets: list[dict[str, Any]] = []
    in_table = False
    for line_no, line in enumerate(lines, start=1):
        if line.startswith("| 类别 (my_id) |"):
            in_table = True
            continue
        if in_table:
            cells = split_md_row(line)
            if not cells:
                if sets:
                    break
                continue
            if len(cells) < 6 or cells[0].startswith("类别"):
                continue
            raw_name = cells[0]
            explicit_id = extract_backtick_tokens(raw_name)
            set_id = explicit_id[0] if explicit_id else None
            if not set_id:
                match = re.search(r"([A-Za-z]+)", raw_name)
                set_id = match.group(1).lower() if match else SET_ALIASES.get(raw_name.split()[0], slugify(raw_name))
            zh = raw_name.split()[0]
            sets.append(
                {
                    "id": set_id,
                    "name": {"zh": zh, "en": set_id},
                    "bonuses": [
                        {
                            "required_weapon_count": index + 2,
                            "source_text": clean_markup(cell),
                            "effects": parse_effects_from_text(cell),
                        }
                        for index, cell in enumerate(cells[1:6])
                    ],
                    "source_ref": source_ref(DOC_03, line_no, "9.2 weapon sets"),
                }
            )
    return sets


def parse_weapons() -> tuple[dict[str, Any], dict[str, str]]:
    lines = read_lines(DOC_03)
    variants: list[dict[str, Any]] = []
    family_map: dict[str, dict[str, Any]] = {}
    current_type = ""
    current_section = ""
    for line_no, line in enumerate(lines, start=1):
        if line.startswith("### 10.1"):
            current_type = "melee"
            current_section = "10.1 melee weapons"
            continue
        if line.startswith("### 10.2"):
            current_type = "ranged"
            current_section = "10.2 ranged weapons"
            continue
        if line.startswith("### 10.3"):
            current_type = ""
            continue
        cells = split_md_row(line)
        if not cells or not current_type or cells[0] == "武器":
            continue
        if current_type == "melee" and len(cells) != 12:
            continue
        if current_type == "ranged" and len(cells) != 15:
            continue

        zh_name, en_name = english_name_from_mixed(cells[0])
        slug = WEAPON_SLUG_OVERRIDES.get(slugify(en_name), slugify(en_name))
        family_id = f"weapon_{slug}"
        tier_roman = clean_markup(cells[2])
        tier = TIER_TO_INDEX[tier_roman]
        asset_refs = weapon_asset_refs(slug)
        common = {
            "id": f"{family_id}_{tier + 1}",
            "family_id": family_id,
            "name_key": "WEAPON_" + family_id.removeprefix("weapon_").upper(),
            "name": {"zh": zh_name, "en": en_name},
            "type": current_type,
            "sets": [SET_ALIASES.get(part.strip(), slugify(part.strip())) for part in cells[1].split("/")],
            "tier": tier,
            "tier_name": tier_roman,
            "value": int(best_value(cells[3], 0)),
            "scaling_stats": parse_scaling(cells[5]),
            "crit_chance": parse_crit(cells[7])[0],
            "crit_damage": parse_crit(cells[7])[1],
            "max_range": int(best_value(cells[8], 0)),
            "knockback": int(best_value(cells[9], 0)),
            "effects": parse_effects_from_text(cells[-1]),
            "special_notes": clean_markup(cells[-1]) if clean_markup(cells[-1]) != "—" else "",
            "asset_refs": asset_refs,
            "source_ref": source_ref(DOC_03, line_no, current_section),
        }
        common.update(parse_cooldown(cells[6]))
        if current_type == "melee":
            common.update(
                {
                    "damage": int_if_whole(best_value(cells[4], 1)),
                    "accuracy": 1.0,
                    "attack_type": "alternate" if "交替" in cells[10] else ("sweep" if "挥击" in cells[10] else "thrust"),
                    "projectiles": 0,
                }
            )
        else:
            common.update(parse_damage_projectiles(cells[4]))
            common["accuracy"] = parse_percent(cells[10], 1.0)
            piercing, piercing_reduction, _ = parse_count_reduction(cells[11])
            bounce, bounce_reduction, can_bounce = parse_count_reduction(cells[12])
            common.update(
                {
                    "piercing": piercing,
                    "piercing_dmg_reduction": piercing_reduction,
                    "bounce": bounce,
                    "bounce_dmg_reduction": bounce_reduction,
                    "can_bounce": can_bounce,
                    "projectile_speed": int(best_value(cells[13], 0)),
                    "increase_projectile_speed_with_range": "+" in clean_markup(cells[13]),
                }
            )
        variants.append(common)
        if family_id not in family_map:
            family_map[family_id] = {
                "id": family_id,
                "name_key": common["name_key"],
                "name": common["name"],
                "type": current_type,
                "sets": common["sets"],
                "asset_refs": asset_refs,
                "quality_slots": [],
                "source_ref": common["source_ref"],
            }

    variants_by_family_tier = {(variant["family_id"], variant["tier"]): variant for variant in variants}
    families = []
    for family_id in sorted(family_map.keys()):
        family = family_map[family_id]
        slots = []
        for tier in range(4):
            variant = variants_by_family_tier.get((family_id, tier))
            if variant:
                slots.append({"tier": tier, "tier_name": INDEX_TO_TIER[tier], "available": True, "variant_id": variant["id"]})
            else:
                slots.append(
                    {
                        "tier": tier,
                        "tier_name": INDEX_TO_TIER[tier],
                        "available": False,
                        "source_status": "not_documented_in_ch03_table",
                    }
                )
        family["quality_slots"] = slots
        families.append(family)

    weapon_name_to_slug: dict[str, str] = {}
    for family in families:
        slug = family["id"].removeprefix("weapon_")
        weapon_name_to_slug[family["name"]["en"]] = slug
        weapon_name_to_slug[family["name"]["zh"]] = slug
        weapon_name_to_slug[family["id"].removeprefix("weapon_").replace("_", " ").title()] = slug
    # Character docs use the older Cactus Mace display name.
    weapon_name_to_slug["Cactus Mace"] = "cactus_mace"
    weapon_name_to_slug["Flaming Knuckles"] = "flaming_knuckles"

    return {
        "source": rel_doc(DOC_03),
        "families": families,
        "variants": sorted(variants, key=lambda item: (item["family_id"], item["tier"])),
        "summary": {
            "family_count": len(families),
            "documented_variant_count": len(variants),
            "quality_slot_count": len(families) * 4,
        },
    }, weapon_name_to_slug


def parse_unlocks() -> dict[str, dict[str, Any]]:
    lines = read_lines(DOC_02)
    unlocks: dict[str, dict[str, Any]] = {}
    in_table = False
    for line_no, line in enumerate(lines, start=1):
        if line.startswith("| 角色 | 解锁方式 | 挑战 ID | 精确条件 |"):
            in_table = True
            continue
        if in_table:
            cells = split_md_row(line)
            if not cells:
                if unlocks:
                    break
                continue
            if len(cells) != 4 or cells[0] == "角色":
                continue
            names = [name.strip() for name in cells[0].split("/") if name.strip()]
            for name in names:
                character_id = f"character_{slugify(name)}"
                unlocks[character_id] = {
                    "method": clean_markup(cells[1]),
                    "challenge_id": "" if cells[2] == "—" else clean_markup(cells[2]).strip("`"),
                    "condition": clean_markup(cells[3]),
                    "source_ref": source_ref(DOC_02, line_no, "2 unlock table"),
                }
    return unlocks


def parse_character_sections(
    weapon_name_to_slug: dict[str, str],
    item_name_to_id: dict[str, str],
) -> list[dict[str, Any]]:
    lines = read_lines(DOC_02)
    unlocks = parse_unlocks()
    heading_indexes: list[tuple[int, re.Match[str]]] = []
    pattern = re.compile(r"^### 3\.(\d+) (.+?)（(character_[^，]+)，(.+?)）(.*)$")
    for index, line in enumerate(lines):
        match = pattern.match(line)
        if match:
            heading_indexes.append((index, match))

    characters: list[dict[str, Any]] = []
    for pos, (index, match) in enumerate(heading_indexes):
        next_index = heading_indexes[pos + 1][0] if pos + 1 < len(heading_indexes) else len(lines)
        body = lines[index + 1 : next_index]
        number = int(match.group(1))
        en_name = match.group(2).strip()
        character_id = match.group(3).strip()
        zh_name = match.group(4).strip()
        suffix = match.group(5)
        effects: list[dict[str, Any]] = []
        wanted_tags: list[str] = []
        banned_item_groups: list[str] = []
        banned_items: list[str] = []
        starting_weapons: list[str] = []
        starting_items: list[str] = []
        tags: list[str] = []
        tracking_text = "DAMAGE_DEALT" if "tracking：DAMAGE_DEALT" in suffix else ""

        in_effect_table = False
        for offset, row_line in enumerate(body, start=index + 2):
            cells = split_md_row(row_line)
            if cells and len(cells) == 2 and cells[0].startswith("效果"):
                in_effect_table = True
                continue
            if in_effect_table and row_line.strip().startswith("|---"):
                continue
            if in_effect_table and cells and len(cells) == 2 and cells[0] != "---":
                effect_source = f"{cells[0]} | {cells[1]}"
                parsed = parse_effects_from_text(effect_source)
                effects.extend(parsed)
                for item_id in extract_ids_from_text(effect_source, "item"):
                    if item_id not in starting_items and "起始物品" in effect_source:
                        starting_items.append(item_id)
                for weapon_id in extract_ids_from_text(effect_source, "weapon"):
                    if weapon_id not in starting_weapons and "起始武器" in effect_source:
                        starting_weapons.append(weapon_id)
                if "tracking" in clean_markup(effect_source) or "追踪" in clean_markup(effect_source):
                    tracking_text = "DAMAGE_DEALT"
                continue
            if in_effect_table and (not cells or row_line.startswith("- ")):
                in_effect_table = False

            cleaned = clean_markup(row_line)
            if "tracking：DAMAGE_DEALT" in cleaned:
                tracking_text = "DAMAGE_DEALT"
            if "wanted_tags" in cleaned:
                wanted_tags = extract_backtick_tokens(row_line)
                if not wanted_tags and "无" not in cleaned:
                    after = cleaned.split(":", 1)[-1].split("：", 1)[-1]
                    wanted_tags = [part.strip() for part in re.split(r"[,、]", after) if part.strip()]
            if "禁用物品组" in cleaned or "禁用组" in cleaned:
                banned_item_groups = extract_backtick_tokens(row_line)
            if "禁用物品" in cleaned:
                banned_items = [token for token in extract_backtick_tokens(row_line) if token.startswith("item_")]
            if "角色自身 tags" in cleaned:
                tags = extract_backtick_tokens(row_line)
            if "起始武器" in cleaned:
                after = re.split(r"：|:", cleaned, maxsplit=1)[-1].rstrip("。")
                for chunk in re.split(r"[,;、]", after):
                    weapon_id = weapon_id_from_choice(chunk.strip(), weapon_name_to_slug)
                    if weapon_id and weapon_id not in starting_weapons:
                        starting_weapons.append(weapon_id)
            if "起始物品" in cleaned:
                explicit = extract_ids_from_text(row_line, "item")
                for item_id in explicit:
                    if item_id not in starting_items:
                        starting_items.append(item_id)
                if not explicit:
                    after = re.split(r"：|:", cleaned, maxsplit=1)[-1].rstrip("。")
                    for chunk in re.split(r"[,;、]", after):
                        item_id = item_id_from_name(chunk.strip(), item_name_to_id)
                        if item_id and item_id not in starting_items:
                            starting_items.append(item_id)

        unlock = unlocks.get(character_id, {})
        characters.append(
            {
                "id": character_id,
                "name_key": "CHARACTER_" + character_id.removeprefix("character_").upper(),
                "name": {"zh": zh_name, "en": en_name},
                "tier": 0,
                "value": 1,
                "max_nb": -1,
                "unlocked_by_default": "默认解锁" in suffix or unlock.get("method") == "默认解锁",
                "unlock": unlock,
                "wanted_tags": wanted_tags,
                "banned_item_groups": banned_item_groups,
                "banned_items": banned_items,
                "starting_weapons": starting_weapons,
                "starting_items": starting_items,
                "tags": tags,
                "tracking_text": tracking_text,
                "effects": effects,
                "source_ref": source_ref(DOC_02, index + 1, f"3.{number} character"),
            }
        )
    return characters


def parse_banned_item_groups() -> dict[str, list[str]]:
    lines = read_lines(DOC_02)
    groups: dict[str, list[str]] = {}
    in_table = False
    for line in lines:
        if line.startswith("| 组 | 包含物品 |"):
            in_table = True
            continue
        if in_table:
            cells = split_md_row(line)
            if not cells:
                if groups:
                    break
                continue
            if len(cells) != 2 or cells[0] == "组":
                continue
            group = clean_markup(cells[0])
            groups[group] = [f"item_{slugify(part.strip())}" for part in cells[1].split(",") if part.strip()]
    return groups


def build_tags_sets_unlocks(
    characters: list[dict[str, Any]],
    weapons: dict[str, Any],
    items: list[dict[str, Any]],
) -> dict[str, Any]:
    item_tag_counts = Counter(tag for item in items for tag in item["tags"])
    character_wanted_tags = {character["id"]: character["wanted_tags"] for character in characters if character["wanted_tags"]}
    unlocks = {character["id"]: character["unlock"] for character in characters}
    return {
        "source_docs": [rel_doc(DOC_02), rel_doc(DOC_03), rel_doc(DOC_05)],
        "weapon_sets": parse_weapon_sets(),
        "item_tags": dict(sorted(item_tag_counts.items())),
        "character_wanted_tags": character_wanted_tags,
        "banned_item_groups": parse_banned_item_groups(),
        "unlock_metadata": unlocks,
        "summary": {
            "weapon_set_count": 15,
            "item_tag_count": len(item_tag_counts),
            "unlock_count": len(unlocks),
        },
    }


def build_effect_reference() -> dict[str, Any]:
    return {
        "source_doc": rel_doc(DOC_08),
        "effect_defaults": EFFECT_DEFAULTS,
        "storage_methods": ["SUM", "KEY_VALUE", "REPLACE", "APPEND_KEY", "APPEND_KEY_VALUE"],
        "summary": {
            "effect_key_count": len(EFFECT_DEFAULTS),
            "required_default_checks": {
                "stat_max_hp": 10,
                "dodge_cap": 60,
                "weapon_slot": 6,
                "harvesting_growth": 5,
                "hp_cap": 99999999,
            },
        },
    }


def generation_summary(
    characters: list[dict[str, Any]],
    weapons: dict[str, Any],
    items: list[dict[str, Any]],
) -> dict[str, Any]:
    unresolved_weapon_slots = sum(
        1
        for family in weapons["families"]
        for slot in family["quality_slots"]
        if not slot["available"]
    )
    raw_effects = 0
    parsed_effects = 0
    for collection in [characters, items, weapons["variants"]]:
        for record in collection:
            for effect in record.get("effects", []):
                if effect.get("type") == "raw_effect_text":
                    raw_effects += 1
                else:
                    parsed_effects += 1
    return {
        "generated_from": [rel_doc(DOC_02), rel_doc(DOC_03), rel_doc(DOC_05), rel_doc(DOC_08)],
        "characters": len(characters),
        "weapon_families": len(weapons["families"]),
        "weapon_quality_slots": len(weapons["families"]) * 4,
        "weapon_documented_variants": len(weapons["variants"]),
        "weapon_undocumented_quality_slots": unresolved_weapon_slots,
        "items": len(items),
        "parsed_effect_records": parsed_effects,
        "raw_effect_text_records": raw_effects,
    }


def write_json(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> None:
    items, item_name_to_id = parse_items()
    weapons, weapon_name_to_slug = parse_weapons()
    characters = parse_character_sections(weapon_name_to_slug, item_name_to_id)
    tags_sets_unlocks = build_tags_sets_unlocks(characters, weapons, items)
    effect_reference = build_effect_reference()
    summary = generation_summary(characters, weapons, items)

    write_json(DATA_ROOT / "items.json", {"source": rel_doc(DOC_05), "items": items})
    write_json(DATA_ROOT / "weapons.json", weapons)
    write_json(DATA_ROOT / "characters.json", {"source": rel_doc(DOC_02), "characters": characters})
    write_json(DATA_ROOT / "tags_sets_unlocks.json", tags_sets_unlocks)
    write_json(DATA_ROOT / "effect_reference.json", effect_reference)
    write_json(DATA_ROOT / "generation_summary.json", summary)
    print(json.dumps(summary, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
