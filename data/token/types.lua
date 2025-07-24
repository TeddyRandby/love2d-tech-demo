---@alias TokenType "coin" | "mana" | "corruption" | "bomb" | "ooze" | "elemental" | "imp" | "customer" | "parrot" | "skeleton"
---@alias TokenDropTable table<TokenType, integer>
---
---@class Token
---@field type TokenType
---@field color number[]

---@type table<TokenType, Token>
local M = {
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

for _, v in ipairs(M) do
  M[v.type] = v
end

return M
