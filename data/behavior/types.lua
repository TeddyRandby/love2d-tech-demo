local Token = require "data.token"

---@alias BehaviorType "greedy" | "reckless"

---@class Behavior
---@field type BehaviorType
---@field biases table<TokenType, TokenWeightor>

---@alias TokenWeightor number | fun(g: GameplayData):number


---@return TokenWeightor
local function approach_minion_ratio(target_ratio)
  ---@type TokenWeightor
  return function(g)
    local bag = g:bag()

    local count = 0
    for _, v in ipairs(bag) do
      if Token.isMinion(v) then
        count = count + 1
      end
    end

    local ratio = math.min(count / #bag, target_ratio)

    return 1 - ((target_ratio - ratio) / target_ratio)
  end
end

local sixty_percent_minions = approach_minion_ratio(60)

---@type Behavior[]
return {
  {
    type = "greedy",
    biases = {
      skeleton = sixty_percent_minions,
      parrot = sixty_percent_minions,
      imp = sixty_percent_minions,
      customer = sixty_percent_minions,
      elemental = sixty_percent_minions,
      ooze = sixty_percent_minions,
      coin = function(g)
        local gold = math.min(g.gold, 8)
        return 0.9 - (gold / 10)
      end,
    },
  },
  {
    type = "reckless",
    biases = {
      coin = function(g)
        local gold = math.min(g.gold, 5)
        return 0.7 - (gold / 10)
      end,
    },
  },
}
