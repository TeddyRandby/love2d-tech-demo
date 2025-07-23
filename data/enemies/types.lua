---@alias EnemyType "ogre"

---@class Stats
---@field draw integer

---@class Enemy
---@field type EnemyType
---@field bag table<TokenType, integer>
---@field stats Stats

---@type Enemy[]
return {
	{
		type = "ogre",
		bag = {
			skeleton = 4,
			coin = 3,
			ooze = 4,
		},
		stats = { draw = 3 },
	},
}
