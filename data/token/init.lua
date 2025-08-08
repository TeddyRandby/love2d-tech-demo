local TokenTypes = require("data.token.types")

-- TODO: Replace this with using token-create
local M = {
	Coin = require("data.token.types")[1],
	Bomb = require("data.token.types")[2],
	Mana = require("data.token.types")[3],
	Corruption = require("data.token.types")[4],
}

for _, v in ipairs(TokenTypes) do
	M[v.type] = v
end

---@param t Token
function M.isAny(t)
	return true
end

---@param t Token
function M.isMana(t)
	return t.type == "mana"
end

---@param t Token
function M.isCorruption(t)
	return t.type == "corruption"
end

---@param t Token
function M.isCoin(t)
	return t.type == "coin"
end

---@param token Token
function M.isMinion(token)
	local t = token.type
	return not (t == "coin" or t == "corruption" or t == "mana")
end

---@param t TokenType
function M.create(t)
	return table.copy(M[t])
end

return M
