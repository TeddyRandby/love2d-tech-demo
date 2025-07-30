local Token = require("data.token")

local M = {
  input = {},
  intermediate = {},
  output = {},
}

---@class ActionInputMicroOpPull
---@field type "pull"
---@field amount integer

---@class ActionInputMicroOpPeek
---@field type "peek"
---@field amount integer
---
---@class ActionInputMicroOpConstant
---@field type "constant"
---@field amount integer
---@field token Token
---
---@class ActionInputMicroOpSignature
---@field type "signature"
---@field amount integer

---@alias ActionInputMicroOp ActionInputMicroOpPull | ActionInputMicroOpPeek | ActionInputMicroOpConstant | ActionInputMicroOpSignature

---@param n integer
function M.input.pull(n)
  ---@type ActionInputMicroOp
  return {
    type = "pull",
    amount = n,
  }
end

---@param n integer
function M.input.signature(n)
  ---@type ActionInputMicroOp
  return {
    type = "signature",
    amount = n,
  }
end

---@param n integer
---@param t Token
function M.input.constant(n, t)
  ---@type ActionInputMicroOp
  return {
    type = "constant",
    amount = n,
    token = t,
  }
end

---@param n integer
function M.input.peek(n)
  ---@type ActionInputMicroOp
  return {
    type = "peek",
    amount = n,
  }
end

---@class ActionOutputMicroOpDraft
---@field type "draft"

---@class ActionOutputMicroOpDiscard
---@field type "discard"

---@class ActionOutputMicroOpDonate
---@field type "donate"

---@alias ActionOutputMicroOp ActionOutputMicroOpDraft | ActionOutputMicroOpDiscard | ActionOutputMicroOpDonate

function M.output.draft()
  ---@type ActionOutputMicroOp
  return {
    type = "draft",
  }
end

function M.output.donate()
  ---@type ActionOutputMicroOp
  return {
    type = "donate",
  }
end

function M.output.discard()
  ---@type ActionOutputMicroOp
  return {
    type = "discard",
  }
end

---@class ActionIntermediateMicroOpFilter
---@field type "filter"
---@field fun fun(t: Token): boolean

---@class ActionIntermediateMicroOpChoose
---@field type "choose"
---@field amount integer

---@alias ActionIntermediateMicroOp ActionIntermediateMicroOpFilter | ActionIntermediateMicroOpChoose

---@param f fun(t: Token): boolean
function M.intermediate.filter(f)
  ---@type ActionIntermediateMicroOp
  return {
    type = "filter",
    fun = f,
  }
end

---@param n integer
function M.intermediate.choose(n)
  ---@type ActionIntermediateMicroOp
  return {
    type = "choose",
    amount = n,
  }
end

---@alias ActionMicroOp ActionInputMicroOp | ActionIntermediateMicroOp | ActionOutputMicroOp

---@class ActionOp
---@field name string
---@field desc string | fun(self: ActionOp): string
---@field microops ActionMicroOp[]

---@param n integer
function M.dig_mana(n)
  ---@type ActionOp
  return {
    name = "sift",
    desc = "Look at " .. n .. " tokens. Draft all which are mana.",
    microops = {
      M.input.pull(n),
      M.intermediate.filter(Token.isMana),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.dig_minion(n)
  ---@type ActionOp
  return {
    name = "recruit",
    desc = "Look at " .. n .. " tokens. Draft all which are minions.",
    microops = {
      M.input.pull(n),
      M.intermediate.filter(Token.isMinion),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.discover(n)
  ---@type ActionOp
  return {
    name = "discover",
    desc = "Look at " .. n .. " tokens and draft 1.",
    microops = {
      M.input.pull(n),
      M.intermediate.choose(1),
      M.output.discard(),
      M.output.draft(),
    },
  }
end

---@param npeek integer
---@param npull integer
function M.loot(npeek, npull)
  ---@type ActionOp
  return {
    name = "loot",
    desc = "Look at " .. npull .. " tokens and " .. npeek .. " from your bag - draft none, either, or both.",
    microops = {
      M.input.pull(npull),
      M.input.peek(npeek),
      M.intermediate.choose(1),
      M.output.discard(),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.refine(n)
  ---@type ActionOp
  return {
    name = "refine",
    desc = "Look at " .. n .. " tokens from your bag - discard one.",
    microops = {
      M.input.peek(n),
      M.intermediate.choose(1),
      M.output.discard(),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.draft_corruption(n)
  ---@type ActionOp
  return {
    name = "draft_corruption",
    desc = "Draft a corrupt token.",
    microops = {
      M.input.constant(n, Token.Corruption),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.draft_coin(n)
  ---@type ActionOp
  return {
    name = "draft_coin",
    desc = "Draft a coin token.",
    microops = {
      M.input.constant(n, Token.Coin),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.draft(n)
  ---@type ActionOp
  return {
    name = "draft",
    desc = "Draft " .. n .. " tokens.",
    microops = {
      M.input.pull(n),
      M.output.draft(),
    },
  }
end

---@param n integer
function M.draft_signature(n)
  ---@type ActionOp
  return {
    name = "draft_signature",
    desc = "Draft " .. n .. " signature tokens.",
    microops = {
      M.input.signature(n),
      M.output.draft(),
    },
  }
end

return M
