---@alias ClassType "ooze"

---@class Class
---@field type ClassType
---@field draw integer
---@field lives integer
---@field token_table TokenDropTable
---@field card_table CardDropTable
---@field move_table MoveDropTable
---@field effect_table EffectDropTable
---@field signature TokenType
---@field moves MoveType[]
---@field effects EffectType[]
---@field oppeffects EffectType[]

---@type Class[]
local M = {
	{
		type = "ooze",
		signature = "ooze",
    draw = 3,
    lives = 3,
		battle_stats = { draw = 3, lives = 3 },
		token_table = {
			ooze = 3,
			coin = 1,
			bomb = 1,
			mana = 2,
			skeleton = 1,
			corruption = 1,
		},
		card_table = {
			sacrifice = 1,
			discover = 1,
			refine = 1,
			pillage = 1,
			bargain = 1,
			meditate = 1,
			recruit = 1,
		},
		move_table = {
			ooze_shop_draft_ooze = 1,
			ooze_exhaust_donate = 1,
		},
    effect_table = {
			ooze_draft_opponent_does_too = 1,
			ooze_opponent_draw_donate = 1,
    },
		moves = {
			"minion_attack",
		},
		effects = {
			"bomb_explode",
			"corruption_hit",
		},
		oppeffects = {},
	},
}

return M
