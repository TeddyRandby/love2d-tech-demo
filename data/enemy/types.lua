---@alias EnemyType "ogre"
---@class BattleStats
---@field draw integer
---@field lives integer

---@class Enemy
---@field type EnemyType
---@field battle_stats BattleStats
---@field token_table TokenDropTable
---@field card_table CardDropTable
---@field move_table MoveDropTable
---@field signature TokenType
---@field moves MoveType[]
---@field effects EffectType[]
---@field oppeffects EffectType[]

---@type Enemy[]
return {
	{
		type = "ogre",
		signature = "skeleton",
		battle_stats = { draw = 3, lives = 3 },
		token_table = {
			skeleton = 2,
			ooze = 2,
		},
		card_table = {
			discover = 1,
			refine = 1,
			pillage = 1,
			bargain = 1,
			meditate = 1,
			recruit = 1,
		},
		move_table = {},
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
