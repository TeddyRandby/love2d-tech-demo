---@alias TokenType "coin" | "mana" | "corruption" | "bomb" | "ooze" | "elemental" | "imp" | "customer" | "parrot" | "skeleton"

---@class Token
---@field type TokenType
---@field freq integer
---@field color number[]

---@type Token[]
return {
  {
    type = "coin",
    freq = 1,
    color = { 1, 1, 0, 1 }
  },
  {
    type = "bomb",
    freq = 1,
    color = { 1, 1, 1, 1 }
  },
  {
    type = "mana",
    freq = 2,
    color = { 0, 0, 1, 1 }
  },
  {
    type = "corruption",
    freq = 1,
    color = { 1, 0, 1, 1 }
  },
  {
    type = "ooze",
    freq = 1,
    color = { 0, 1, 0, 1 }
  },
  {
    type = "elemental",
    freq = 1,
    color = { 1, 0, 0, 1 }
  },
  {
    type = "customer",
    freq = 1,
    color = { .5, .5, .5, 1 }
  },
  {
    type = "imp",
    freq = 1,
    color = { .5, 0, .5, 1 }
  },
  {
    type = "skeleton",
    freq = 1,
    color = { 0, 0, 0, 1 }
  },
  {
    type = "parrot",
    freq = 1,
    color = { 0, 1, 1, 1 }
  },
}
