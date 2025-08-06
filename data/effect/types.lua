---@alias EffectType "bomb_explode" | "corruption_hit" | "ooze_exhaust_donate" | "ooze_opponent_draw_donate" | "ooze_draft_opponent_does_too" | "draft_coin_draft_ooze"

---@alias TokenEventType "draft" | "discard" | "donate" | "draw" | "exhaust" | "activate" | "opponent_draft" | "opponent_discard" | "opponent_donate" | "opponent_draw" | "opponent_exhaust" | "opponent_activate"

---@alias CardEventType CardType
---@alias EffectCause TokenEventType | CardEventType

---@class Effect
---@field type EffectType
---@field cause EffectCause
---@field desc string
---@field icon IconType[]
---@field active boolean
---@field effect fun(g: GameplayData, t: Token | Card)
---@field should? boolean | fun(g: GameplayData, t: Token | Card): boolean

---@alias EffectDropTable table<EffectType, integer>

local Token = require("data.token")

---@param t TokenType
local function donate(t)
	---@type fun(self: GameplayData, token: Token)
	return function(self, token)
		self:donate({ t }, self:opponent())
	end
end

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
		icon = { "ooze", "enemy_draw", "draft" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:opponent():donate({ token }, self)
		end,
	},
	{
		type = "ooze_exhaust_donate",
		desc = "When you exhaust an ooze, donate it to your enemy",
		active = true,
		cause = "exhaust",
		icon = { "ooze", "exhaust", "enemy_donate" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:donate({ token }, self:opponent())
		end,
	},
	{
		type = "ooze_draft_opponent_does_too",
		desc = "When you draft an ooze, your enemy does as well!",
		active = true,
		cause = "draft",
		icon = { "ooze", "draft", "enemy_draft" },
		should = token_is("ooze"),
		effect = function(self, token)
			self:opponent():draft({ Token.create("ooze") })
		end,
	},
}
