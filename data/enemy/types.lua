---@alias EnemyType "ogre"

---@class DraftStats
---@field likes CardType[]

---@class BattleStats
---@field draw integer
---@field lives integer

---@class Enemy
---@field type EnemyType
---@field draft_stats DraftStats
---@field battle_stats BattleStats
---@field token_table TokenDropTable
---@field card_table CardDropTable

---@type Enemy[]
return {
	{
		type = "ogre",
		token_table = {
			skeleton = 2,
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
		battle_stats = { draw = 3, lives = 3 },
		draft_stats = {
			likes = {
				"Recruit",
			},
		},
	},
}
