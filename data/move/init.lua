local M = {}

local MoveTypes = require "data.move.types"

for _, v in ipairs(MoveTypes) do
  M[v.type] = v
end

---@param types MoveType[]
function M.array_of(types)
  return table.map(types, function(t) return M[t] end)
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
    return m.cost.type == t
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
  return M.height() * 2
end

function M.height()
  return 0.1
end

local FontHeight = love.graphics.getFont():getHeight()

love.graphics.setDefaultFilter("nearest", "nearest")
local MoveImage = love.graphics.newImage("resources/move.png")
local MoveImageWidth = MoveImage:getWidth()
local MoveImageHeight = MoveImage:getHeight()

---@param move Move
---@param x integer
---@param y integer
function M.draw(move, x, y)
  local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

  local sx = w / MoveImageWidth
  local sy = h / MoveImageHeight
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)

  if Engine.player:doable(move) and View:is_hovering(move)then
    love.graphics.setColor(1, 1, 1, 1)
  else
    love.graphics.setColor(28 / 255, 26 / 255, 48 / 255, 1)
  end
  love.graphics.rectangle("fill", -View.normalize_x(0.01), -View.normalize_y(0.01), w * 1.1, h * 1.2)

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(MoveImage, 0, 0, 0, sx, sy)

  love.graphics.printf(move.type, 5 * sx, 4 * sy, (41 * sx / fsy), "center", 0, fsy, fsy, nil, nil)
end

return M
