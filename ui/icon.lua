local M = {
	types = {},
}

love.graphics.setDefaultFilter("nearest", "nearest")
local IconSpritesheet = love.graphics.newImage("resources/IconSpritesheet.png")

M.pixelw = 16
M.pixelh = 16

for _, v in ipairs(require("data.icon.types")) do
	local quad = love.graphics.newQuad(M.pixelw * v.offset, 0, M.pixelw, M.pixelh, IconSpritesheet)

	v.quad = quad
	M.types[v.type] = v
end

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
	return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

---@param icon IconType
---@param x integer
---@param y integer
---@param r? integer
function M.draw(icon, x, y, r)
	local sx, sy = UI.scale_xy()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(IconSpritesheet, M.types[icon].quad, x, y, r, sx, sy)
end

return M
