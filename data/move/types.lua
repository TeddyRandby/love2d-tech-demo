---@alias MoveType "minion_attack" | "mana_makemana" | "ooze_shop_draft_ooze" | "ooze_exhaust_draw_tokens" | "refine_twice" | "elemental_makemana" | "corruption_makemana" | "draft_imp_and_corruption" | "exhaust_elemental_mana" | "exhaust_token_refine_opponent" | "discard_coin_draft_opponent_token" | "exhaust_coin_draw_two" | "gold_recruit" | "opponents_draft_bomb" | "activate_one_units" | "activate_all_units" | "exhaust_ten_from_bag"  | "draft_opponents_token" | "discard_opponents_token" | "shop_refine_opponent" | "corruption_attack" | "coin_attack"

---@class MoveCost
---@field type "manapool" | "gold" | TokenType | fun(t: Token): boolean
---@field amount integer
---@field state? TokenState
---@field method? TokenEventType

---@class Move
---@field type MoveType
---@field cost MoveCost
---@field icon IconType[]
---@field desc string
---@field should boolean | fun(g: GameplayData): boolean
---@field effect fun(g: GameplayData)

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
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g.power = g.power + 1
    end,
  },
  {
    type = "coin_attack",
    desc = "Exhaust a coin token to attack your opponent!",
    icon = { "sword" },
    cost = {
      type = Token.isCoin,
      amount = 1,
      state = "active",
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g.power = g.power + 1
    end,
  },
  {
    type = "corruption_attack",
    desc = "Exhaust a corruption token to attack your opponent!",
    icon = { "sword" },
    cost = {
      type = Token.isCorruption,
      amount = 1,
      state = "active",
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g.power = g.power + 1
    end,
  },
  {
    type = "mana_makemana",
    desc = "Exhaust a mana token to produce mana",
    icon = { "sword" },
    cost = {
      type = Token.isMana,
      amount = 1,
      state = "active",
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g.mana = g.mana + 1
    end,
  },
  {
    type = "elemental_makemana",
    desc = "Exhaust an elemental token to produce mana",
    icon = { "sword" },
    cost = {
      type = function(t)
        return t.type == "elemental"
      end,
      amount = 1,
      state = "active",
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g.mana = g.mana + 1
    end,
  },
  {
    type = "ooze_shop_draft_ooze",
    desc = "Spend a coin while upgrading to draft an ooze.",
    icon = { "ooze", "draft" },
    cost = {
      amount = 1,
      type = "gold",
    },
    should = true,
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
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g:draw(2)
    end,
  },
  {
    type = "shop_refine_opponent",
    desc = "Refine twice",
    icon = { "coin" },
    cost = {
      amount = 1,
      type = "gold",
    },
    should = true,
    effect = function(g)
      g:playcardtype("refine_two")
    end,
  },
  {
    type = "opponents_draft_bomb",
    desc = "Your opponent drafts a bomb token.",
    icon = {},
    cost = {
      amount = 1,
      type = "gold",
    },
    should = true,
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
      type = "gold",
    },
    should = true,
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
      type = "manapool",
    },
    should = true,
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
      type = "manapool",
    },
    should = true,
    effect = function(g)
      local exhausted = g:exhausted()
      g:activate(table.filter(exhausted, Token.isMinion))
    end,
  },
  {
    type = "discard_opponents_token",
    desc = "Discard one of your opponents active tokens.",
    icon = { "token", "opponent_discard" },
    cost = {
      amount = 1,
      type = "manapool",
    },
    should = true,
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
      type = "manapool",
    },
    should = true,
    effect = function(g)
      local active = g:opponent():active()
      g:opponent():donate(table.sample(active, 1))
    end,
  },
  {
    type = "exhaust_ten_from_bag",
    desc = "Your opponent exhausts 10 tokens from their bag",
    icon = { "token", "opponent_exhaust" },
    cost = {
      amount = 3,
      type = "manapool",
    },
    should = true,
    effect = function(g)
      local bag = g:opponent():bag()
      g:opponent():exhaust(table.take(bag, 10))
    end,
  },
  {
    type = "draft_two_mana",
    desc = "Draft two mana",
    icon = {},
    cost = {
      amount = 1,
      type = "gold",
    },
    should = true,
    effect = function(g)
      g:draft({ Token.create("mana"), Token.create("mana") })
    end,
  },
  {
    type = "exhaust_coin_draw_two",
    desc = "Exhaust a coin: draw two tokens.",
    icon = { "coin", "exhaust" },
    cost = {
      amount = 1,
      type = "coin",
      state = "active",
      method = "exhaust",
    },
    should = true,
    effect = function(g)
      g:draw(2)
    end,
  },
  {
    type = "gold_recruit",
    desc = "Recruit",
    icon = { "token", "draft", "opponent_discard" },
    cost = { amount = 1, type = "gold" },
    should = true,
    effect = function(g)
      g:playcardtype("recruit")
    end,
  },
  {
    type = "exhaust_token_refine_opponent",
    desc = "Exhaust a token to refine your opponents bag.",
    icon = { "token", "opponent_discard" },
    cost = { amount = 1, type = Token.isAny, state = "active", method = "exhaust" },
    should = true,
    effect = function(g)
      g:playcardtype("opponent_refine")
    end,
  },
  {
    type = "discard_coin_draft_opponent_token",
    desc = "Discard a coin to draft an opponents token.",
    icon = { "token", "discard", "opponent_draft" },
    cost = { amount = 1, type = Token.isCoin, state = "active", method = "discard" },
    should = true,
    effect = function(g)
      local todonate = table.sample(g:opponent():active(), 1)
      g:opponent():donate(todonate)
    end,
  },
}
