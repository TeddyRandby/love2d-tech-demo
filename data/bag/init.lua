local M = {}

local BagSlotSpritesheet = love.graphics.newImage("resources/BagSlot.png")
local BagSlotImageWidth = 16
local BagSlotImageHeight = 16

local BagSlotBG =
	love.graphics.newQuad(BagSlotImageWidth * 0, 0, BagSlotImageWidth, BagSlotImageHeight, BagSlotSpritesheet)
local BagSlotHL =
	love.graphics.newQuad(BagSlotImageWidth * 1, 0, BagSlotImageWidth, BagSlotImageHeight, BagSlotSpritesheet)
local BagSlotHLBG =
	love.graphics.newQuad(BagSlotImageWidth * 2, 0, BagSlotImageWidth, BagSlotImageHeight, BagSlotSpritesheet)

local BagWidth = 0.06
local BagHeight = BagWidth

function M.width()
  return 0.06
end

function M.height()
  local ratio = love.graphics.getWidth() / love.graphics.getHeight()
  return M.width() * ratio
end

---@param x integer
---@param y integer
---@param t Token
function M.draw(x, y, t)
	-- Account for w/h screen ratio
	local w, h = View.normalize_xy(M.width(), M.height())
	local sx = w / BagSlotImageWidth
	local sy = h / BagSlotImageHeight

	love.graphics.translate(x, y)

	-- local itemw, itemh = self.normalize_xy(BagItemWidth, BagItemHeight)
	-- local canvas = love.graphics.newCanvas(w, h)
	-- love.graphics.setCanvas(canvas)
	-- love.graphics.origin()

	love.graphics.draw(BagSlotSpritesheet, BagSlotBG, 0, 0, 0, sx, sy)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(BagSlotSpritesheet, BagSlotHL, 0, 0, 0, sx, sy)

  if t and Engine.player:useful(t, "bag") then
    love.graphics.draw(BagSlotSpritesheet, BagSlotHLBG, 0, 0, 0, sx, sy)
  end

	-- love.graphics.setCanvas()

	-- love.graphics.translate(x, y)
	-- Shaders.pixel(w, h, sx, sy, 0)
	-- love.graphics.draw(canvas)
	-- Shaders.reset()
end

return M
