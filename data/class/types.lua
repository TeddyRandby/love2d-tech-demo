---@alias ClassType "ooze"

---@class Class
---@field type ClassType
---@field battle_stats BattleStats
---@field token_table TokenDropTable
---@field card_table CardDropTable
---@field moves MoveType[]

---@type table<ClassType, Class>
local M = {
	ooze = {
		type = "ooze",
		battle_stats = { draw = 3, lives = 3 },
		token_table = {
			ooze = 2,
		},
		card_table = {
			Discover = 1,
			Refine = 1,
			Pillage = 1,
			Bargain = 1,
			Meditate = 1,
			Recruit = 1,
		},
		moves = {
			"Attack",
		},
	},
}

return M
