local M = {}

---@param card Card
function M.describe(card)
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
	return .1
end

function M.height()
	return M.width() * 2
end

---@param card Card
---@param x integer
---@param y integer
function M.draw(card, x, y)
	local pd = 10
	local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

	love.graphics.setColor(0, 0.5, 0.5, 1)
	love.graphics.rectangle("fill", x, y, w, h)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.printf(card.type, x + pd, y + pd, w - pd)
	love.graphics.printf(M.describe(card), x + pd, y + (h / 2), w - pd, "justify")
end

return M
