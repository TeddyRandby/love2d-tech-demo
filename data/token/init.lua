local M = {
	Coin = require("data.token.types")[1],
	Mana = require("data.token.types")[2],
	Corruption = require("data.token.types")[3],
}

function M.isMana(t)
	return t.type == "mana"
end

function M.isMinion(t)
	return t.type == "minion"
end

return M
