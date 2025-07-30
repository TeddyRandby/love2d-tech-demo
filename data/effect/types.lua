---@alias EffectType "bomb_explode" | "corruption_hit" | "ooze_exhaust_donate" | "ooze_opponent_draw_donate" | "ooze_draft_opponent_does_too" | "draft_coin_draft_ooze"
---
---@alias TokenEventCause "draft" | "discard" | "donate" | "draw" | "exhaust"
---@alias CardEventCause CardType
---@alias EffectCause TokenEventCause | CardEventCause
---
---@class Effect
---@field type EffectType
---@field cause EffectCause
---@field active boolean
---@field effect fun(g: GameplayData, t: Token | Card)
---@field should? boolean | fun(g: GameplayData, t: Token | Card): boolean

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
    active = true,
    cause = "draw",
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
    active = true,
    cause = "draw",
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
    active = true,
    cause = "draw",
    should = token_is("ooze"),
    effect = function (self, token)
      self:donate({ token }, self:opponent())
    end
  },
  {
    type = "ooze_exhaust_donate",
    active = true,
    cause = "exhaust",
    should = token_is("ooze"),
    effect = function (self, token)
      self:donate({ token }, self:opponent())
    end
  },
  {
    type = "ooze_draft_opponent_does_too",
    active = true,
    cause = "draft",
    should = token_is("ooze"),
    effect = function(self, token)
      self:opponent():draft({ Token.create("ooze") })
    end,
  },
  {
    type = "draft_coin_draft_ooze",
    active = true,
    cause = "draft",
    should = Token.isCoin,
    effect = function(g)
      g:draft({ Token.create("ooze") })
    end,
  },
}
