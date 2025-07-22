---@class Token
---@field type string
---@field name string
---@field freq integer
---@field color number[]

---@type Token[]
return {
  {
    type = "coin",
    name = "coin",
    freq = 1,
    color = { 1, 1, 0, 1 }
  },
  {
    type = "mana",
    name = "mana",
    freq = 2,
    color = { 0, 0, 1, 1 }
  },
  {
    type = "corruption",
    name = "corruption",
    freq = 1,
    color = { 1, 0, 1, 1 }
  },
  {
    type = "minion",
    name = "ooze",
    freq = 1,
    color = { 0, 1, 0, 1 }
  },
  {
    type = "minion",
    name = "elemental",
    freq = 1,
    color = { 1, 0, 0, 1 }
  },
  {
    type = "minion",
    name = "customer",
    freq = 1,
    color = { .5, .5, .5, 1 }
  },
  {
    type = "minion",
    name = "imp",
    freq = 1,
    color = { .5, 0, .5, 1 }
  },
  {
    type = "minion",
    name = "skeleton",
    freq = 1,
    color = { 0, 0, 0, 1 }
  },
  {
    type = "minion",
    name = "pirate",
    freq = 1,
    color = { 0, 1, 1, 1 }
  },
}
