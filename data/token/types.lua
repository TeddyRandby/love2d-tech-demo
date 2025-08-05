---@alias TokenType "coin" | "mana" | "corruption" | "lint" | "bomb" | "ooze" | "elemental" | "imp" | "customer" | "parrot" | "skeleton"
---@alias TokenDropTable table<TokenType, integer>
---
---@class Token
---@field type TokenType
---@field desc string
---@field primary_color number[]
---@field secondary_color number[]
---
local function color(r, g, b)
	return r / 255, g / 255, b / 255
end

---@type table<TokenType, Token>
local M = {
	{
		type = "coin",
		desc = "A coin - useful for buying things in the shop!",
		primary_color = { color(0xff, 0xdb, 0x59) },
		secondary_color = { color(0xa9, 0x54, 0x36) },
	},
	{
		type = "bomb",
		desc = "Uh oh - this will blow up in combat!",
		primary_color = { 1, 1, 1 },
		secondary_color = { 1, 1, 1 },
	},
	{
		type = "mana",
		desc = "Useful for casting spells in combat.",
		primary_color = { color(0x4b, 0x70, 0xcc) },
		secondary_color = { color(0x21, 0x56, 0xdb) },
	},
	{
		type = "corruption",
		desc = "Uh oh! Draw too many of these, and you'll take damage!",
		primary_color = { color(0x8f, 0x64, 0xcc) },
		secondary_color = { color(0x51, 0x18, 0xa1) },
	},
	{
		type = "lint",
		desc = "Just a piece of lint.",
		primary_color = { 1, 1, 1 },
		secondary_color = { 1, 1, 1 },
	},
	{
		type = "ooze",
		desc = "A little oozeling. Will fight for you!",
		primary_color = { color(0x5b, 0x7d, 0x54) },
		secondary_color = { color(0x30, 0x42, 0x2c) },
	},
	{
		type = "elemental",
		desc = "An elemental. Will fight for you!",
		primary_color = { 1, 0, 0 },
		secondary_color = { 1, 1, 1 },
	},
	{
		type = "customer",
		desc = "A loyal customer. Will fight for you!",
		primary_color = {color(0x42, 0x2c, 0x21)},
		secondary_color = {color(0x24, 0x0F, 0x05)},
	},
	{
		type = "imp",
		desc = "An imp. Will fight for you!",
		primary_color = { color(0xcc, 0x64, 0x64) },
		secondary_color = { color(0xab, 0x35, 0x35) },
	},
	{
		type = "skeleton",
		desc = "A skeleton. Will fight for you!",
		primary_color = { 0, 0, 0 },
		secondary_color = { 1, 1, 1 },
	},
	{
		type = "parrot",
		desc = "A parrot. Will fight for you!",
		primary_color = { 0, 1, 1 },
		secondary_color = { 1, 1, 1 },
	},
}

for _, v in ipairs(M) do
	M[v.type] = v
end

return M
