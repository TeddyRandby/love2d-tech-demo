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

---@alias ActionInputMicroOp ActionInputMicroOpPull | ActionInputMicroOpPeek | ActionInputMicroOpConstant

---@param n integer
function M.input.pull(n)
	---@type ActionInputMicroOp
	return {
		type = "pull",
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
---@field token Token

---@class ActionOutputMicroOpDiscard
---@field type "discard"
---@field token Token

---@class ActionOutputMicroOpDonate
---@field type "donate"
---@field token Token

---@alias ActionOutputMicroOpGenrator fun(ts: Token[]): ActionOutputMicroOp[]
---@alias ActionOutputMicroOp ActionOutputMicroOpDraft | ActionOutputMicroOpDiscard | ActionOutputMicroOpDonate | ActionOutputMicroOpGenrator
---
---@param t Token
function M.output.draft(t)
	---@type ActionOutputMicroOp
	return {
		type = "draft",
		token = t,
	}
end

---@param t Token
function M.output.donate(t)
	---@type ActionOutputMicroOp
	return {
		type = "donate",
		token = t,
	}
end

---@param t Token
function M.output.discard(t)
	---@type ActionOutputMicroOp
	return {
		type = "discard",
		token = t,
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

---@param ts Token[]
function M.output.draftAll(ts)
	---@type ActionOutputMicroOp[]
	local t = {}

	for _, v in ipairs(ts) do
		table.insert(t, M.output.draft(v))
	end

	return t
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
			M.output.draftAll,
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
			M.output.draftAll,
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
			M.output.draftAll,
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
			M.output.draftAll,
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
			M.output.discard,
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
			M.output.draftAll,
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
			M.output.draftAll,
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
			M.output.draftAll,
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
			M.input.constant(n, Token.sig),
			M.output.draftAll,
		},
	}
end

return M
