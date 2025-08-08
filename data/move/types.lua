---@alias MoveType "minion_attack" | "ooze_shop_draft_ooze" | "ooze_exhaust_draw_tokens" | "refine_twice"

---@class MoveCost
---@field type TokenType | fun(t: Token): boolean
---@field amount integer
---@field state TokenState
---@field pay_by TokenEventType | "transmute"

---@class Move
---@field type MoveType
---@field cost MoveCost
---@field icon IconType[]
---@field desc string
---@field effect fun(g: GameplayData)
---
---@alias MoveDropTable table<MoveType, integer>

local Token = require("data.token")

---@type Move[]
return {
	{
		type = "minion_attack",
		desc = "Exhaust a minion token to attack your opponent!",
		icon = { "sword" },
		cost = {
			type = Token.isMinion,
			amount = 1,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			g.power = g.power + 1
		end,
	},
	{
		type = "ooze_shop_draft_ooze",
		desc = "Spend a coin while upgrading to draft an ooze.",
		icon = { "ooze", "draft" },
		cost = {
			amount = 1,
			type = "coin",
			state = "bag",
			pay_by = "transmute",
		},
		effect = function(g)
			g:draft({ Token.create("ooze") })
		end,
	},
	{
		type = "ooze_exhaust_draw_tokens",
		desc = "Exhaust an ooze to draw two tokens.",
		icon = { "ooze", "exhaust" },
		cost = {
			amount = 1,
			type = "ooze",
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			g:draw(2)
		end,
	},
	{
		type = "refine_twice",
		desc = "",
		icon = { "coin" },
		cost = {
			amount = 1,
			type = "coin",
			state = "bag",
			pay_by = "transmute",
		},
		effect = function(g)
			--g:refine(3)
		end,
	},
	{
		type = "opponents_draft_bomb",
		desc = "",
		icon = {},
		cost = {
			amount = 1,
			type = "coin",
			state = "bag",
			pay_by = "transmute",
		},
		effect = function(g)
			g:opponent():draft({ Token.create("bomb") })
		end,
	},
	{
		type = "refine_twice",
		desc = "Refine twice",
		icon = { "card", "discard" },
		cost = {
			amount = 1,
			type = "coin",
			state = "bag",
			pay_by = "transmute",
		},
		effect = function(g)
			g:playcardtype("refine_two")
		end,
	},
	{
		type = "activate_one_units",
		desc = "Activate a units",
		icon = { "token" },
		cost = {
			amount = 1,
			type = Token.isMana,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			local exhausted = g:exhausted()
			g:activate(table.sample(table.filter(exhausted, Token.isMinion), 1))
		end,
	},
	{
		type = "activate_all_units",
		desc = "Activate all units",
		icon = { "token" },
		cost = {
			amount = 3,
			type = Token.isMana,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			local exhausted = g:exhausted()
			g:activate(table.filter(exhausted, Token.isMinion))
		end,
	},
	{
		type = "discard_opponents_token",
		desc = "Discard one of your opponents active tokens.",
		icon = { "token", "enemy_discard" },
		cost = {
			amount = 1,
			type = Token.isMana,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			local active = g:opponent():active()
			g:opponent():discard(table.sample(active, 1))
		end,
	},
	{
		type = "draft_opponents_token",
		desc = "Draft one of your opponents active tokens.",
		icon = { "token", "draft" },
		cost = {
			amount = 2,
			type = Token.isMana,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			local active = g:opponent():active()
			g:opponent():donate(table.sample(active, 1))
		end,
	},
	{
		type = "exhaust_ten_from_bag",
		desc = "Your opponent exhausts 10 tokens from their bag",
		icon = { "token", "enemy_exhaust" },
		cost = {
			amount = 3,
			type = Token.isMana,
			state = "active",
			pay_by = "exhaust",
		},
		effect = function(g)
			local bag = g:opponent():bag()
			g:opponent():exhaust(table.take(bag, 10))
		end,
	},
	{
		type = "draft_two_mana",
		desc = "",
		icon = {},
		cost = {
			amount = 1,
			type = "coin",
			state = "bag",
			pay_by = "transmute",
		},
		effect = function(g)
			g:draft({ Token.create("mana"), Token.create("mana") })
		end,
	},
}
