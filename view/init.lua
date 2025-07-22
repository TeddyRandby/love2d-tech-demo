---@class View
---@field last_frame_commands RenderCommand[]
---@field commands RenderCommand[]
local M = {
	last_frame_commands = {},
	commands = {},
}

local Card = require("data.card")

---@class RenderCommandCard
---@field type "card"
---@field target Card
---@field x integer
---@field y integer

---@alias RenderCommand RenderCommandCard

---@param self RenderCommandCard
---@param x integer
---@param y integer
local function card_contains(self, x, y)
	local cardw, cardh = Card.width(), Card.height()
	local l, r, b, t = self.x, self.x + cardw, self.y, self.y + cardh
	return x > l and x < r and y > b and y < t
end

---@param card Card
---@param x integer
---@param y integer
function M:card(card, x, y)
	table.insert(
		self.commands,
		{
			type = "card",
			target = card,
			x = x,
			y = y,
			contains = card_contains,
		})
end

---@param x integer
---@param y integer
---@return RenderCommand?
function M:hover(x, y)
	for _, v in reversedipairs(self.last_frame_commands) do
		if v:contains(x, y) then
			return v
		end
	end
end

function M:draw()
	for _, v in ipairs(self.commands) do
		local t = v.type

		if t == "card" then
			Card.draw(v.target, v.x, v.y)
		else
			assert(false, "Unhandled case")
		end
	end

	self.last_frame_commands = self.commands
	self.commands = {}
end

return M
