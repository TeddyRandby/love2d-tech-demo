local TokenTypes = require("data.token.types")
local Shaders = require("util.shaders")

-- TODO: Replace this with using token-create
local M = {
	Coin = require("data.token.types")[1],
	Bomb = require("data.token.types")[2],
	Mana = require("data.token.types")[3],
	Corruption = require("data.token.types")[4],
	Lint = require("data.token.types")[5],
}

for _, v in ipairs(TokenTypes) do
	M[v.type] = v
end

function M.radius()
	return 0.015
end

function M.isMana(t)
	return t.type == "mana"
end

function M.isCorruption(t)
	return t.type == "corruption"
end

function M.isCoin(t)
	return t.type == "coin"
end

function M.isMinion(token)
	local t = token.type
	return not (t == "coin" or t == "corruption" or t == "mana" or t == "lint")
end

---@param t TokenType
function M.create(t)
	return table.copy(M[t])
end

love.graphics.setDefaultFilter("nearest", "nearest")
local TokenSpritesheet = love.graphics.newImage("resources/TokenSpritesheet.png")
local TokenImageWidth = 8
local TokenImageHeight = 8

local TokenBG = love.graphics.newQuad(TokenImageWidth * 0, 0, TokenImageWidth, TokenImageHeight, TokenSpritesheet)
local TokenHL = love.graphics.newQuad(TokenImageWidth * 1, 0, TokenImageWidth, TokenImageHeight, TokenSpritesheet)
local TokenMIDDLE = love.graphics.newQuad(TokenImageWidth * 2, 0, TokenImageWidth, TokenImageHeight, TokenSpritesheet)

local FontHeight = love.graphics.getFont():getHeight()

---@param token Token
---@param x integer
---@param y integer
---@param s? number
function M.draw(token, x, y, s)
	s = s or 1.0

	local r = View.normalize_x(M.radius())
	local sr = r / (TokenImageWidth / 2) * s
	local fsy = View.normalize_y(View.getFontSize()) / FontHeight

	local sx = sr
	local sy = sr

	love.graphics.translate(x, y)

	-- local canvas = love.graphics.newCanvas(r * 2, r * 2)
	-- love.graphics.setCanvas(canvas)
	-- love.graphics.origin()

	love.graphics.setColor(0, 0, 0)
	love.graphics.draw(TokenSpritesheet, TokenBG, 0, sy, 0, sx, sy)

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
