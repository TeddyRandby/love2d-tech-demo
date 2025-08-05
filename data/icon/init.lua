love.graphics.setDefaultFilter("nearest", "nearest")
local IconSpritesheet = love.graphics.newImage("resources/IconSpritesheet.png")
local IconImageWidth = 16
local IconImageHeight = 16

local M = {
  types = {}
}

for _, v in ipairs(require("data.icon.types")) do
	local quad = love.graphics.newQuad(IconImageWidth * v.offset, 0, IconImageWidth, IconImageHeight, IconSpritesheet)

  v.quad = quad
	M.types[v.type] = v
end

function M.width()
	local ratio = love.graphics.getHeight() / love.graphics.getWidth()
	return M.height() * ratio
end

function M.height()
	return 0.1
end

---@param icon IconType
---@param x integer
---@param y integer
---@param r? integer
function M.draw(icon, x, y, r)
	local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

	local sx = w / IconImageWidth
	local sy = h / IconImageHeight

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(IconSpritesheet, M.types[icon].quad, x, y, r, sx, sy)
end

return M
