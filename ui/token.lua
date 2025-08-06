local M = {}

love.graphics.setDefaultFilter("nearest", "nearest")
local TokenSpritesheet = love.graphics.newImage("resources/TokenSpritesheet.png")

M.pixelw = 8
M.pixelh = 8

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
  return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

local TokenBG = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, TokenSpritesheet)
local TokenHL = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, TokenSpritesheet)
local TokenMIDDLE = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, TokenSpritesheet)

---@param token Token
---@param x integer
---@param y integer
---@param s? number
function M.draw(token, x, y, s)
	s = s or 1.0

	local sr = UI.sx() * s

	local sx = sr
	local sy = sr

	love.graphics.translate(x, y)

	-- local canvas = love.graphics.newCanvas(r * 2, r * 2)
	-- love.graphics.setCanvas(canvas)
	-- love.graphics.origin()

	-- love.graphics.setColor(0, 0, 0)
	-- love.graphics.draw(TokenSpritesheet, TokenBG, 0, sy, 0, sx, sy)

	love.graphics.setColor(table.unpack(token.primary_color))
	love.graphics.draw(TokenSpritesheet, TokenBG, 0, 0, 0, sx, sy)

	love.graphics.setColor(table.unpack(token.secondary_color))
	love.graphics.draw(TokenSpritesheet, TokenHL, 0, 0, 0, sx, sy)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(TokenSpritesheet, TokenMIDDLE, 0, 0, 0, sx, sy)

	-- love.graphics.setCanvas()

	-- love.graphics.translate(x, y)
	-- Shaders.pixel(r, r, sr, sr, 0)
	-- love.graphics.draw(canvas)
	-- Shaders.reset()
	-- love.graphics.printf(token.type, 8 * sr, 13 * sr, (32 * sr / fsy), "center", 0, fsy, fsy, nil, nil)
end

return M
