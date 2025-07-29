local M = {}

---@param card Card
function M.describe(card)
  local str = ""

  for _, op in ipairs(card.ops) do
    local desc = op.name

    if type(desc) == "function" then
      desc = desc(op)
    end

    str = str .. desc .. "\n"
  end

  return str
end

---@param card Card
function M.describe_long(card)
  local str = ""

  for _, op in ipairs(card.ops) do
    local desc = op.desc

    if type(desc) == "function" then
      desc = desc(op)
    end

    str = str .. desc .. "\n"
  end

  return str
end

function M.width()
  return 0.2
end

function M.height()
  return M.width() * 2
end

love.graphics.setDefaultFilter("nearest", "nearest")
local CardImage = love.graphics.newImage("resources/CardPrototype.png")

local FontHeight = love.graphics.getFont():getHeight()

local CardImageWidth = CardImage:getWidth()
local CardImageHeight = CardImage:getHeight()

local meshargs = {
  { 0,              0,               0, 0 }, -- top-left
  { CardImageWidth, 0,               1, 0 }, -- top-right
  { CardImageWidth, CardImageHeight, 1, 1 }, -- bottom-right
  { 0,              CardImageHeight, 0, 1 }, -- bottom-left
}

-- Define 4 mesh vertices in clockwise order: top-left, top-right, bottom-right, bottom-left
-- Draw the card as a mesh so that we can perform better operations on it!
CardMesh = love.graphics.newMesh(meshargs, "fan", "static")
CardMeshHL = love.graphics.newMesh(meshargs, "fan", "static")

CardMesh:setTexture(CardImage)

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
local function draw_mesh(card, x, y, r)
  local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

  local depth = 4
  local skew = depth / 100

  local sx = w / CardImageWidth
  local sy = h / CardImageHeight
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  -- Update mesh vertices
  local verts = {
    { 0, 0, 0, 0 },
    { w, 0, 1, 0 },
    { w, h, 1, 1 },
    { 0, h, 0, 1 },
  }

  -- Deform one corner by pushing it inward
  if View:is_hovering(card) then
    local ox, oy = love.mouse.getPosition()

    local cx = x + w / 2
    local cy = y + h / 2

    local dx = (ox - cx) / (w / 2)
    local dy = (oy - cy) / (w / 2)

    local function push(x, y, fx, fy)
      return x + fx * depth * dx, y + fy * depth * dy
    end

    if dx < 0 and dy < 0 then -- top-left
      verts[1][1], verts[1][2] = push(verts[1][1], verts[1][2], -1, -1)
      verts[3][1], verts[3][2] = push(verts[3][1], verts[3][2], 1, 1)
    elseif dx > 0 and dy < 0 then -- top-right
      verts[2][1], verts[2][2] = push(verts[2][1], verts[2][2], -1, -1)
      verts[4][1], verts[4][2] = push(verts[4][1], verts[4][2], 1, 1)
    elseif dx > 0 and dy > 0 then -- bottom-right
      verts[3][1], verts[3][2] = push(verts[3][1], verts[3][2], -1, -1)
      verts[1][1], verts[1][2] = push(verts[1][1], verts[1][2], 1, 1)
    elseif dx < 0 and dy > 0 then -- bottom-left
      verts[4][1], verts[4][2] = push(verts[4][1], verts[4][2], -1, -1)
      verts[2][1], verts[2][2] = push(verts[2][1], verts[2][2], 1, 1)
    end
  end

  local cx, cy = w / 2, h / 2

  love.graphics.translate(x + cx, y + cy)
  love.graphics.rotate(r or 0)
  love.graphics.translate(-cx, -cy)

  if View:is_hovering(card) then
    love.graphics.setColor(1, 1, 1, 1)
  else
    love.graphics.setColor(28 / 255, 26 / 255, 48 / 255, 1)
  end

  CardMeshHL:setVertices(verts)
  love.graphics.draw(CardMeshHL, -View.normalize_x(0.01), -View.normalize_y(0.01), 0, 1.1, 1.05)

  love.graphics.setColor(1, 1, 1)

  CardMesh:setVertices(verts)
  love.graphics.draw(CardMesh)

  if View:is_hovering(card) then
    local xshear, yshear = 0, 0
    local ox, oy = love.mouse.getPosition()

    local cx = x + w / 2
    local cy = y + h / 2

    local dx = (ox - cx) / (w / 2)
    local dy = (oy - cy) / (w / 2)

    if dx < 0 and dy < 0 then
      xshear = skew * dx
      yshear = skew * dy
    elseif dx < 0 and dy > 0 then
      xshear = skew * -dx * dy
      yshear = skew * dy
    elseif dx > 0 and dy < 0 then
      xshear = skew * dx
      yshear = skew * -dy * dx
    else
      xshear = skew * -dx
      yshear = skew * -dy
    end

    love.graphics.translate(ox - x, oy - y)

    -- Apply skew and scale
    love.graphics.shear(xshear, yshear)

    -- Move back so sprite is drawn in correct position
    love.graphics.translate(-(ox - x), -(oy - y))
  end

  love.graphics.printf(card.type, 10 * sx, 1 * sy, (30 * sx / fsy), "center", 0, fsy, fsy, nil, nil)
  love.graphics.printf(M.describe(card), 8 * sx, 15 * sy, (34 * sx / fsy), "left", 0, fsy, fsy, nil, nil)
end

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
function M.draw(card, x, y, r)
  draw_mesh(card, x, y, r)
end

return M
