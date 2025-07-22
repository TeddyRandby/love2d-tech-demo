---@class Card
---@field name string
---@field ops ActionOp[]
---@field freq integer

Actions = require("data.card.actions")

---@type Card[]
return {
  {
    name = "Discover",
    freq = 1,
    ops = {
      Actions.discover(3),
    }
  },
  {
    name = "Refine",
    freq = 1,
    ops = {
      Actions.refine(3)
    },
  },
  {
    name = "Pillage",
    freq = 1,
    ops = {
      Actions.loot(1, 1),
      Actions.draft_coin(1),
    },
  },
  {
    name = "Bargain",
    freq = 1,
    ops = {
      Actions.draft_coin(1),
      Actions.draft_corruption(1),
    },
  },
  {
    name = "Meditate",
    freq = 1,
    ops = {
      Actions.dig_mana(6),
      Actions.draft_corruption(1)
    },
  },
  {
    name = "Recruit",
    freq = 1,
    ops = {
      Actions.dig_minion(6),
      Actions.draft_corruption(1),
    },
  },
}
