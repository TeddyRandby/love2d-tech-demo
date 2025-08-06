local M = {}
local BagWidth = 0.4

function M.width()
	return BagWidth
end

function M.height()
	local ratio = love.graphics.getWidth() / love.graphics.getHeight()
	return M.width() * ratio * (13 / 102)
end

love.graphics.setDefaultFilter("nearest", "nearest")
local BagSpritesheet = love.graphics.newImage("resources/BagSpritesheet.png")
local BagImageWidth = 102
local BagImageHeight = 13

local BagBG = love.graphics.newQuad(BagImageWidth * 0, 0, BagImageWidth, BagImageHeight, BagSpritesheet)
local BagEXHAUSTED = love.graphics.newQuad(BagImageWidth * 1, 0, BagImageWidth, BagImageHeight, BagSpritesheet)
local BagBAG = love.graphics.newQuad(BagImageWidth * 2, 0, BagImageWidth, BagImageHeight, BagSpritesheet)
local BagACTIVE = love.graphics.newQuad(BagImageWidth * 3, 0, BagImageWidth, BagImageHeight, BagSpritesheet)

---@param x integer
---@param y integer
---@param label "active" | "exhausted" | "bag"
function M.draw(x, y, label)
	-- Account for w/h screen ratio
	local w, h = View.normalize_xy(M.width(), M.height())
	local sx = w / BagImageWidth
	local sy = h / BagImageHeight

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
