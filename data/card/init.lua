local M = {}
local CardTypes = require("data.card.types")

for _, v in ipairs(CardTypes) do
	M[v.type] = v
end

---@param card Card
function M.describe(card)
	local str = ""

	for _, op in ipairs(card.ops) do
		local desc = op.name

		if type(desc) == "function" then
			desc = desc(op)
		end

		str = str .. desc .. "\n"
	end

	return str
end

---@param card Card
function M.describe_long(card)
	local str = ""

	for _, op in ipairs(card.ops) do
		local desc = op.desc

		if type(desc) == "function" then
			desc = desc(op)
		end

		str = str .. desc .. "\n"
	end

	return str
end

function M.width()
	return 0.2
end

function M.height()
	local ratio = love.graphics.getWidth() / love.graphics.getHeight()
	return M.width() * 1.5 * ratio
end


return M
