local M = {}

M.pixelw = 102
M.pixelh = 33

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
	return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

love.graphics.setDefaultFilter("nearest", "nearest")
local MoveBoxSpritesheet = love.graphics.newImage("resources/MoveBoxSpritesheet.png")

local MoveBoxBG = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, MoveBoxSpritesheet)
local MoveBoxMOVES = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, MoveBoxSpritesheet)
local MoveBoxSHOP = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, MoveBoxSpritesheet)

---@param x integer
---@param y integer
---@param label "moves" | "shop"
function M.draw(x, y, label)
	local sx, sy = UI.scale_xy()

	love.graphics.translate(x, y)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(MoveBoxSpritesheet, MoveBoxBG, 0, 0, 0, sx, sy)

	if label == "moves" then
		love.graphics.draw(MoveBoxSpritesheet, MoveBoxMOVES, 0, 0, 0, sx, sy)
	elseif label == "shop" then
		love.graphics.draw(MoveBoxSpritesheet, MoveBoxSHOP, 0, 0, 0, sx, sy)
	else
		assert(false, "Unhandled move box label: " .. label)
	end
end

return M
