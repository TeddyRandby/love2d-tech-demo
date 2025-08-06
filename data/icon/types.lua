---@alias IconType "coin" | "sword" | "ooze" | "card" | "token" | "draft" | "donate" | "exhaust" | "draw" | "discard" | "enemy_draft" | "enemy_donate" | "enemy_exhaust" | "enemy_draw" | "enemy_discard"

---@class Icon
---@field type IconType
---@field offset integer
---@field quad? love.Quad

---@type Icon[]
return {
	{
		type = "card",
		offset = 0,
	},
	{
		type = "coin",
		offset = 1,
	},
	{
		type = "sword",
		offset = 2,
	},
	{
		type = "ooze",
		offset = 3,
	},
	{
		type = "token",
		offset = 4,
	},
	{
		type = "draft",
		offset = 5,
	},
	{
		type = "donate",
		offset = 6,
	},
	{
		type = "discard",
		offset = 7,
	},
	{
		type = "draw",
		offset = 8,
	},
	{
		type = "exhaust",
		offset = 9,
	},
	{
		type = "enemy_draft",
		offset = 10,
	},
	{
		type = "enemy_donate",
		offset = 11,
	},
	{
		type = "enemy_discard",
		offset = 12,
	},
	{
		type = "enemy_draw",
		offset = 13,
	},
	{
		type = "enemy_exhaust",
		offset = 14,
	},
}
