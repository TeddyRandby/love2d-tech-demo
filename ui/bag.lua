local M = {}

love.graphics.setDefaultFilter("nearest", "nearest")
local BagSpritesheet = love.graphics.newImage("resources/BagSpritesheet.png")

M.pixelw = 102
M.pixelh = 13

local BagBG = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, BagSpritesheet)
local BagEXHAUSTED = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, BagSpritesheet)
local BagBAG = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, BagSpritesheet)
local BagACTIVE = love.graphics.newQuad(M.pixelw * 3, 0, M.pixelw, M.pixelh, BagSpritesheet)

---@param x integer
---@param y integer
---@param label "active" | "exhausted" | "bag"
function M.draw(x, y, label)
	local sx, sy = UI.scale_xy()

	love.graphics.translate(x, y)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(BagSpritesheet, BagBG, 0, 0, 0, sx, sy)

	if label == "active" then
		love.graphics.draw(BagSpritesheet, BagACTIVE, 0, 0, 0, sx, sy)
	elseif label == "exhausted" then
		love.graphics.draw(BagSpritesheet, BagEXHAUSTED, 0, 0, 0, sx, sy)
	elseif label == "bag" then
		love.graphics.draw(BagSpritesheet, BagBAG, 0, 0, 0, sx, sy)
	else
		assert(false, "Unhandled bag label: " .. label)
	end
end

return M
