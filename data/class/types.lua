---@alias ClassType "ooze" | "pirate" | "wizard" | "warlock" | "dark_knight" | "shopkeeper"

---@class Class
---@field type ClassType
---@field draw integer
---@field lives integer
---@field token_table TokenDropTable
---@field card_table CardDropTable
---@field move_table MoveDropTable
---@field token_weights table<TokenType, integer>
---@field effect_table EffectDropTable
---@field signature TokenType
---@field moves MoveType[]
---@field effects EffectType[]

---@type MoveType[]
local default_moves = {
	"minion_attack",
	"mana_makemana",
}

---@type EffectType[]
local default_effects = {
	"coin_draft",
	"bomb_explode",
	"corruption_hit",
}

---@type table<TokenType, integer>
local default_token_table = {
	bomb = 1,
	corruption = 1,
	coin = 2,
	mana = 3,
	skeleton = 1,
	ooze = 1,
	parrot = 1,
	elemental = 1,
	customer = 1,
	imp = 1,
}

---@type table<CardType, integer>
local default_card_table = {
	sacrifice = 1,
	discover = 1,
	refine = 1,
	pillage = 1,
	bargain = 1,
	meditate = 1,
	recruit = 1,
	steal = 1,
}

---@type table<MoveType, integer>
local neutral_moves = {
	exhaust_ten_from_bag = 1,
	discard_opponents_token = 2,
	activate_one_units = 2,
	activate_all_units = 1,
}

---@type table<EffectType, integer>
local neutral_effects = {}

---@type Class[]
local M = {
	{
		type = "dark_knight",
		signature = "skeleton",
		draw = 3,
		lives = 3,
		token_weights = {
			skeleton = 3,
			corruption = 1,
			bomb = 0,
		},
		token_table = table.merge_over(default_token_table, {
			skeleton = 3,
			corruption = 2,
		}),
		card_table = table.merge_over(default_card_table, {}),
		move_table = table.merge_over(neutral_moves, {
			refine_twice = 1,
			exhaust_token_refine_opponent = 1,
			corruption_attack = 1,
		}),
		effect_table = table.merge_over(neutral_effects, {
			exhaust_corruption_activate_skeleton = 1,
			draft_corruption_draft_skeleton = 1,
		}),
		moves = {
			table.unpack(default_moves),
		},
		effects = {
			table.unpack(default_effects),
		},
	},
	{
		type = "shopkeeper",
		signature = "customer",
		draw = 3,
		lives = 3,
		token_weights = {
			customer = 3,
			corruption = 0,
			bomb = 0,
		},
		token_table = table.merge_over(default_token_table, {
			customer = 3,
			coin = 1,
		}),
		card_table = table.merge_over(default_card_table, {}),
		move_table = table.merge_over(neutral_moves, {
			exhaust_coin_draw_two = 1,
			discard_coin_draft_opponent_token = 1,
		}),
		effect_table = table.merge_over(neutral_effects, {
			draw_customer_activate_coin = 1,
			draft_customer_draft_coin = 1,
		}),
		moves = {
			table.unpack(default_moves),
		},
		effects = {
			table.unpack(default_effects),
		},
	},
	{
		type = "pirate",
		signature = "parrot",
		draw = 3,
		lives = 3,
		token_weights = {
			parrot = 3,
			corruption = 0,
		},
		token_table = table.merge_over(default_token_table, {
			parrot = 3,
			bomb = 2,
		}),
		card_table = table.merge_over(default_card_table, {}),
		move_table = table.merge_over(neutral_moves, {
			opponents_draft_bomb = 1,
		}),
		effect_table = table.merge_over(neutral_effects, {
			opponent_bomb_draw_activate_parrot = 1,
			player_draw_bomb_donate = 1,
			parrot_draft_steal = 1,
		}),
		moves = {
			table.unpack(default_moves),
		},
		effects = {
			table.unpack(default_effects),
		},
	},
	{
		type = "ooze",
		signature = "ooze",
		draw = 3,
		lives = 3,
		token_weights = {
			ooze = 3,
			bomb = 0,
			corruption = 0,
		},
		token_table = table.merge_over(default_token_table, {
			ooze = 4,
		}),
		card_table = table.merge_over(default_card_table, {}),
		move_table = table.merge_over(neutral_moves, {
			ooze_exhaust_donate = 1,
		}),
		effect_table = table.merge_over(neutral_effects, {
			ooze_draft_opponent_does_too = 1,
			ooze_opponent_draw_donate = 1,
		}),
		moves = {
			"ooze_shop_draft_ooze",
			table.unpack(default_moves),
		},
		effects = {
			table.unpack(default_effects),
		},
	},
}

return M
