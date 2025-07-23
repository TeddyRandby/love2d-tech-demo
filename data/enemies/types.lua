---@alias EnemyType "ogre"

---@class DraftStats
---@field likes CardType[]

---@class BattleStats
---@field draw integer
---@field lives integer

---@class Enemy
---@field type EnemyType
---@field bag table<TokenType, integer>
---@field draft_stats DraftStats
---@field battle_stats BattleStats

---@type Enemy[]
return {
	{
		type = "ogre",
		bag = {
			skeleton = 4,
			coin = 3,
			ooze = 4,
		},
		battle_stats = { draw = 3, lives = 3 },
		draft_stats = {
			likes = {
				"Recruit",
			},
		},
	},
}
