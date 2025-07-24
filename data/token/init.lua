local M = {
	Coin = require("data.token.types")[1],
	Bomb = require("data.token.types")[2],
	Mana = require("data.token.types")[3],
	Corruption = require("data.token.types")[4],
}

function M.radius()
	return .03
end

function M.isMana(t)
	return t.type == "mana"
end

function M.isCorruption(t)
	return t.type == "corruption"
end

function M.isMinion(token)
	local t = token.type
	return not (t == "coin" or t == "corruption" or t == "mana")
end

---@param token Token
---@param x integer
---@param y integer
function M.draw(token, x, y)
	local pd = 10
	local r = View.normalize_x(M.radius())

	love.graphics.setColor(0, 0.5, 0.5, 1)
	love.graphics.circle("line", x, y, r)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(token.type, x - r + pd, y, r - pd)
end

return M
