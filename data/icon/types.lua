---@alias IconType "coin" | "sword" | "ooze" | "card" | "token" | "draft" | "donate" | "exhaust" | "draw" | "discard" | "opponent_draft" | "opponent_donate" | "opponent_exhaust" | "opponent_draw" | "opponent_discard"

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
		type = "opponent_draft",
		offset = 10,
	},
	{
		type = "opponent_donate",
		offset = 11,
	},
	{
		type = "opponent_discard",
		offset = 12,
	},
	{
		type = "opponent_draw",
		offset = 13,
	},
	{
		type = "opponent_exhaust",
		offset = 14,
	},
}
