local M = {}

local MoveTypes = require("data.move.types")

---@alias MoveEventType MoveType

for _, v in ipairs(MoveTypes) do
	M[v.type] = v
end

---@param types MoveType[]
function M.array_of(types)
	return table.map(types, function(t)
		return M[t]
	end)
end

---@param m Move
---@param t Token
---@param s? TokenState
function M.needs(m, t, s)
	s = s or Engine.player.token_states[t]

	if m.cost.state ~= s then
		return false
	end

	if type(m.cost.type) == "function" then
		return m.cost.type(t)
	else
		return m.cost.type == t.type
	end
end

---@param m Move
---@param token_states table<Token, TokenState>
function M.cost_matcher(m, token_states)
	if type(m.cost.type) == "function" then
		return function(t)
			return m.cost.type(t) and token_states[t] == m.cost.state
		end
	else
		return function(t)
			return t.type == m.cost.type and token_states[t] == m.cost.state
		end
	end
end

---@param m Move
---@param tokens Token[]
---@param token_states table<Token, TokenState>
function M.matches_cost(m, tokens, token_states)
	return table.filter(tokens, M.cost_matcher(m, token_states))
end

---@param m Move
---@param tokens Token[]
---@param token_states table<Token, TokenState>
function M.cost_is_met(m, tokens, token_states)
	return #M.matches_cost(m, tokens, token_states) >= m.cost.amount
end

function M.width()
	local ratio = love.graphics.getHeight() / love.graphics.getWidth()
	return M.height() * ratio
end

function M.height()
	return 0.1
end

local FontHeight = love.graphics.getFont():getHeight()

love.graphics.setDefaultFilter("nearest", "nearest")
local MoveSpritesheet = love.graphics.newImage("resources/move.png")
local SPWidth = MoveSpritesheet:getPixelWidth()
local SPHeight = MoveSpritesheet:getPixelHeight()

local MoveImageWidth = 16
local MoveImageHeight = 16

local MoveBGHL = love.graphics.newQuad(MoveImageWidth * 0, 0, MoveImageWidth, MoveImageHeight, SPWidth, SPHeight)
local MoveHL = love.graphics.newQuad(MoveImageWidth * 1, 0, MoveImageWidth, MoveImageHeight, SPWidth, SPHeight)
local MoveBG = love.graphics.newQuad(MoveImageWidth * 2, 0, MoveImageWidth, MoveImageHeight, SPWidth, SPHeight)

---@param move Move
---@param x integer
---@param y integer
function M.draw(move, x, y)
	local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

	local sx = w / MoveImageWidth
	local sy = h / MoveImageHeight

	love.graphics.translate(x, y)

	if Engine.player:doable(move) then
		-- Shaders.glow(Engine.time)
		love.graphics.draw(MoveSpritesheet, MoveBGHL, 0, 0, 0, sx, sy)
		-- Shaders.reset()
	end

	love.graphics.setColor(1, 1, 1, 1)

	-- Shaders.pixel_scanline(x, y, w, h, sx, sy, 0)
	love.graphics.draw(MoveSpritesheet, MoveBG, 0, 0, 0, sx, sy)
	love.graphics.draw(MoveSpritesheet, MoveHL, 0, 0, 0, sx, sy)
	-- Shaders.reset()

	love.graphics.setColor(0, 0, 0)
end

return M
