local M = {
  Coin = require("data.token.types")[1],
  Bomb = require("data.token.types")[2],
  Mana = require("data.token.types")[3],
  Corruption = require("data.token.types")[4],
}

function M.radius()
  return 0.05
end

function M.isMana(t)
  return t.type == "mana"
end

function M.isCorruption(t)
  return t.type == "corruption"
end

function M.isMinion(token)
  local t = token.type
  return not (t == "coin" or t == "corruption" or t == "mana")
end

love.graphics.setDefaultFilter("nearest", "nearest")
local TokenImage = love.graphics.newImage("resources/token.png")
local TokenImageWidth = TokenImage:getWidth()
local TokenImageHeight = TokenImage:getHeight()

local FontHeight = love.graphics.getFont():getHeight()

---@param token Token
---@param x integer
---@param y integer
function M.draw(token, x, y)
  local r = View.normalize_x(M.radius())
  local sr = r / (TokenImageWidth / 2)
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)

  if View:is_hovering(token) then
    love.graphics.setColor(table.unpack(token.color))
    love.graphics.circle("fill", r, r, r * 1.05)
  else
    love.graphics.setColor(28 / 255, 26 / 255, 48 / 255, 1)
    love.graphics.circle("fill", r, r, r * 1.05)
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(TokenImage, 0, 0, 0, sr, sr)
  love.graphics.printf(token.type, 8 * sr, 13 * sr, (32 * sr / fsy), "center", 0, fsy, fsy, nil, nil)
end

return M
