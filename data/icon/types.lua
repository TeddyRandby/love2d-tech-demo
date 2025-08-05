---@alias IconType "coin" | "sword" | "ooze" | "card" | "token" | "draft" | "donate" | "exhaust" | "draw" | "discard"

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
}
