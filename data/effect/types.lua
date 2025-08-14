---@alias EffectType "bomb_explode" | "corruption_hit" | "ooze_exhaust_donate" | "ooze_opponent_draw_donate" | "ooze_draft_opponent_does_too" | "draft_coin_draft_ooze" | "coin_draft" | "parrot_draft_steal" | "opponent_bomb_draw_activate_parrot" | "player_draw_bomb_donate" | "draft_imp_draft_mana" | "move_activate_elemental" | "draft_corruption_draft_skeleton" | "draw_customer_activate_coin" | "draft_customer_draft_coin" |  "exhaust_corruption_activate_skeleton"

---@alias TokenEventType "draft" | "discard" | "donate" | "draw" | "exhaust" | "activate" | "opponent_draft" | "opponent_discard" | "opponent_donate" | "opponent_draw" | "opponent_exhaust" | "opponent_activate"

---@alias EffectCause EventType

---@class Effect
---@field type EffectType
---@field cause EffectCause | (EffectCause[])
---@field desc string
---@field icon IconType[]
---@field active boolean
---@field effect fun(g: GameplayData, t: EventTarget)
---@field should? boolean | fun(g: GameplayData, t: Token | Card | Move): boolean

---@alias EffectDropTable table<EffectType, integer>

local Token = require("data.token")

---@param t TokenType
local function token_is(t)
	---@type fun(self: GameplayData, token: Token): boolean
	return function(self, token)
		return token.type == t
	end
end

---@type Effect[]
return {
	{
		type = "coin_draft",
		desc = "When you draft a coin, gain a gold.",
		active = true,
		cause = "draft",
		icon = { "coin", "draft" },
		should = token_is("coin"),
		effect = function(self, token)
			self.gold = self.gold + 1
		end,
	},
	{
		type = "bomb_explode",
		desc = "When you draw a bomb, discard a random minion.",
		active = true,
		cause = "draw",
		icon = { "token", "draw" },
		should = token_is("bomb"),
		effect = function(self, token)
			local minion = table.find(self:active(), Token.isMinion)

			if minion then
				self:discard({ minion })
			end

			self:discard({ token })
		end,
	},
	{
		type = "corruption_hit",
		desc = "When you draw corruption and are already corrupt, take a hit!",
		active = true,
		cause = "draw",
		icon = { "token", "draw" },
		should = function(self, token)
			return table.count(self:active(), Token.isCorruption) > 1
		end,
		effect = function(self, token)
			local corruptions = table.filter(self:active(), Token.isCorruption)
			assert(#corruptions >= 2)

			self:exhaust(corruptions)
			self:hit()
		end,
	},
	{
		type = "ooze_opponent_draw_donate",
		desc = "When an opponent draws an ooze, they donate it to you!",
		active = true,
		cause = "opponent_draw",
		icon = { "ooze", "opponent_draw", "draft" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:opponent():donate({ token }, self)
		end,
	},
	{
		type = "ooze_exhaust_donate",
		desc = "When you exhaust an ooze, donate it to your opponent",
		active = true,
		cause = "exhaust",
		icon = { "ooze", "exhaust", "opponent_donate" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:donate({ token }, self:opponent())
		end,
	},
	{
		type = "ooze_draft_opponent_does_too",
		desc = "When you draft an ooze, your opponent does as well!",
		active = true,
		cause = "draft",
		icon = { "ooze", "draft", "opponent_draft" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:opponent():draft({ Token.create("ooze") })
		end,
	},
	{
		type = "parrot_draft_steal",
		desc = "When you draft a parrot, steal.",
		active = true,
		cause = "draft",
		icon = { "token", "draft" },
		should = token_is("parrot"),
		effect = function(self, token)
			self:playcardtype("steal")
		end,
	},
	{
		type = "player_draw_bomb_donate",
		desc = "When a player draws a bomb, donate it!",
		active = true,
		cause = { "draw", "opponent_draw" },
		icon = { "token", "draw", "opponent_draw" },
		should = token_is("bomb"),
		effect = function(self, token)
			self:donate({ token })
		end,
	},
	{
		type = "opponent_bomb_draw_activate_parrot",
		desc = "When an opponent draws a bomb, activate a parrot.",
		active = true,
		cause = "opponent_draw",
		icon = { "token", "opponent_draw" },
		should = token_is("bomb"),
		effect = function(self, token)
			local possible = table.filter(self:exhausted(), function(t)
				return t.type == "parrot"
			end)

			self:activate(table.sample(possible, 1))
		end,
	},
	{
		type = "draft_imp_draft_mana",
		desc = "When you draft an imp, draft a mana.",
		active = true,
		cause = "draft",
		should = token_is("imp"),
		icon = { "token", "draft" },
		effect = function(self, token)
			self:draft({ Token.create("mana") })
		end,
	},
	{
		type = "move_activate_elemental",
		desc = "When you spend mana to make a move, activate an elemental",
		active = true,
		cause = "do",
		icon = { "token" },
		should = function(self, move)
			return move.cost.type == "manapool"
		end,
		effect = function(self, move)
			local possible = table.filter(self:exhausted(), Token.isMana)
			self:activate(table.sample(possible, 1))
		end,
	},
	{
		type = "draft_corruption_draft_skeleton",
		desc = "When you draft a corruption, draft a skeleton",
		active = true,
		cause = "draft",
		icon = { "token", "draft", "draft" },
		should = token_is("corruption"),
		effect = function(self, token)
			self:draft({ Token.create("skeleton") })
		end,
	},
	{
		type = "draft_customer_draft_coin",
		desc = "When you draft a customer, draft a coin",
		active = true,
		cause = "draft",
		icon = { "token", "draft" },
		should = token_is("customer"),
		effect = function(self, token)
			self:draft({ Token.create("coin") })
		end,
	},
	{
		type = "draw_customer_activate_coin",
		desc = "When you draw a customer, activate a coin",
		active = true,
		cause = "draw",
		icon = { "token", "draw" },
		should = token_is("customer"),
		effect = function(self, token)
			local possible = table.filter(self:exhausted(), function(t)
				return t.type == "coin"
			end)

			self:activate(table.sample(possible, 1))
		end,
	},
	{
		type = "exhaust_corruption_activate_skeleton",
		desc = "When you exhaust a corruption, activate a skeleton.",
    active = true,
    cause = "exhaust",
		icon = { "token", "exhaust" },
		should = token_is("corruption"),
		effect = function(g)
			local possible = table.filter(g:exhausted(), function(t)
				return t.type == "skeleton"
			end)

			g:activate(table.sample(possible, 1))
		end,
	},
}
