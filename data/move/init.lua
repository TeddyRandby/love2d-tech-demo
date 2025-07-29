local M = {}

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

  local mousex, mousey = love.mouse.getPosition()

  local sx = w / MoveImageWidth
  local sy = h / MoveImageHeight
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)

  local hovered = View:hover(mousex, mousey)

  -- This is a type-cast such that M.needs will approve of the call.
  -- If hovered is not a token, M.needs will return false.
  ---@type Token
  local token = hovered and hovered.target

  if hovered and M.needs(move, token) then
    if View:is_dragging(token) then
      local _, hovered_under = View:is_hovering(move)
      if hovered_under then
        love.graphics.setColor(1, 1, 1, 1)
      else
        love.graphics.setColor(1, 1, 1, 0.75)
      end
    else
      love.graphics.setColor(1, 1, 1, 0.50)
    end
  else
    love.graphics.setColor(28 / 255, 26 / 255, 48 / 255, 1)
  end

  love.graphics.rectangle("fill", -View.normalize_x(0.01), -View.normalize_y(0.01), w * 1.1, h * 1.2)

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(MoveImage, 0, 0, 0, sx, sy)

  love.graphics.printf(move.type, 5 * sx, 4 * sy, (41 * sx / fsy), "center", 0, fsy, fsy, nil, nil)
end

return M
