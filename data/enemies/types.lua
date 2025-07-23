---@alias EnemyType "ogre"

---@class Stats
---@field draw integer
---@field lives integer

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
		stats = { draw = 3, lives = 3 },
	},
}
