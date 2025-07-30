---@alias MoveType "minion_attack"

---@class MoveCost
---@field type TokenType | fun(t: Token): boolean
---@field amount integer
---@field state TokenState

---@class Move
---@field type MoveType
---@field cost MoveCost
---@field effect fun(g: GameplayData)

local Token = require("data.token")

---@type Move[]
return {
  {
    type = "minion_attack",
    cost = {
      type = Token.isMinion,
      amount = 1,
      state = "active",
    },
    effect = function(g)
      g.power = g.power + 1
    end,
  },
}
