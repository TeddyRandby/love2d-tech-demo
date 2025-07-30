local flux = require("util.flux")

---@alias UserEvent "click" | "dragstart" | "dragend" | "receive"

---@alias UserEventHandler table<UserEvent, function>

---@class Dragging
---@field ox integer
---@field oy integer
---@field target RenderCommandTarget
---
---@class RenderPosition
---@field x integer
---@field y integer
---@field r integer
---@field tween? unknown

---@class View
---@field user_event_handlers table<RenderCommandTarget, UserEventHandler>
---@field last_frame_commands RenderCommand[]
---@field commands RenderCommand[]
---@field dragging Dragging?
---@field command_target_positions table<RenderCommandTarget, RenderPosition>
local M = {
  user_event_handlers = {},
  last_frame_commands = {},
  command_target_positions = {},
  commands = {},
}

---@param o RenderCommandTarget
---@param x integer
---@param y integer
---@param ox? integer
---@param oy? integer
--- Begin dragging game object o, with offset ox and oy into the sprite.
function M:begin_drag(o, x, y, ox, oy)
  self.dragging = {
    target = o,
    ox = ox or 0,
    oy = oy or 0,
  }

  self:__fire(o, "dragstart", x, y)
end

function M.getFontSize()
  return 0.03
end

---@param x integer
---@param y integer
function M:end_drag(x, y)
  assert(self.dragging ~= nil)

  self:__fire(self.dragging.target, "dragend", x, y)

  local dragged_to = self:hover(x, y, function(rc)
    return self:receivable(rc.target)
  end)

  if dragged_to then
    self:__fire(dragged_to.target, "receive", x, y, self.dragging.target)
  end

  self.dragging = nil
end

---@param t RenderCommandTarget
---@param x integer
---@param y integer
function M:click(t, x, y)
  self:__fire(t, "click", x, y)
end

---@param o? RenderCommandTarget
---@return boolean
function M:is_dragging(o)
  -- print("DRAGGING " .. tostring(o) .. "?")
  if o then
    return self.dragging ~= nil and self.dragging.target == o
  else
    return self.dragging ~= nil
  end
end

---@param o? RenderCommandTarget
---@return boolean, boolean
function M:is_hovering(o)
  local x, y = love.mouse.getPosition()

  local hover = self:contains(x, y)

  local hovered_at_all = not not table.find(hover, function(t)
    return t.target == o
  end)

  local hovered_on_top = hovered_at_all and table.pop(hover).target == o

  return hovered_on_top, hovered_at_all
end

local Card = require("data.card")
local Token = require("data.token")
local Move = require("data.move")

---@alias RenderCommandTarget Move | Card | Token | Token[] | string | RenderCommandButtonTarget

---@param o RenderCommandTarget
---@param hs? table<UserEvent, function>
function M:register(o, hs)
  assert(self.user_event_handlers ~= nil)
  self.user_event_handlers[o] = hs
end

---@param o RenderCommandTarget
---@param e UserEvent
---@param x integer
---@param y integer
---@param data? any
function M:__fire(o, e, x, y, data)
  local hs = self.user_event_handlers[o]

  if not hs or not hs[e] then
    return
  end

  print("[USEREVENT]", o.type, e, x, y, data)
  hs[e](x, y, data)
end

---@alias RenderCommandButtonTarget { [1]: number, [2]: number, text: string }
---@alias RenderCommandBoardSlotTarget { type: TokenType, amt: integer }
---@alias RenderCommandType "button" | "bag" | "card" | "token" | "text" | "move" | "board"

---@class RenderCommandText
---@field type "text"
---@field target string

---@class RenderCommandButton
---@field type "button"
---@field target RenderCommandButtonTarget

---@class RenderCommandBag
---@field type "bag"
---@field target Token[]

---@class RenderCommandCard
---@field type "card"
---@field target Card

---@class RenderCommandToken
---@field type "token"
---@field target Token
---
---@class RenderCommandMove
---@field type "move"
---@field target Move
---
---@class RenderCommandBoardSlot
---@field type "board"
---@field target RenderCommandBoardSlotTarget

---@class RenderCommandMeta
---@field contains fun(self: RenderCommand, x: integer, y: integer): boolean

---@param c RenderCommandTarget
function M:draggable(c)
  ---@return boolean
  local hs = self.user_event_handlers[c]
  return hs and not not (hs["dragstart"] or hs["dragend"])
end

---@param c RenderCommandTarget
---@return boolean
function M:clickable(c)
  local hs = self.user_event_handlers[c]
  return hs and not not hs["click"]
end

---@param c RenderCommandTarget
---@return boolean
function M:receivable(c)
  local hs = self.user_event_handlers[c]
  return hs and not not hs["receive"]
end

---@alias RenderCommand RenderCommandText | RenderCommandCard | RenderCommandToken | RenderCommandBag | RenderCommandMove | RenderCommandBoardSlot | RenderCommandMeta

---@param n number
---@param max integer
---@return integer
local function normalize_dim(n, max)
  if n > 1 then
    return n
  end

  if n >= 0 then
    return math.floor(n * max)
  end

  if n < -1 then
    return max + n
  end

  return max * (1 + n)
end

function M.normalize_x(x)
  return normalize_dim(x, love.graphics.getWidth())
end

function M.normalize_y(y)
  return normalize_dim(y, love.graphics.getHeight())
end

---@param x number
---@param y number
---@param w? number
---@param h? number
---@return integer, integer
function M.normalize_xy(x, y, w, h)
  return M.normalize_x(x), M.normalize_y(y)
end

local function rect_collision(x, y, rx, ry, rw, rh)
  local l, r, b, t = rx, rx + rw, ry, ry + rh
  return x > l and x < r and y > b and y < t
end

---@param self RenderCommandText | RenderCommandMeta
---@param x integer
---@param y integer
local function text_contains(self, x, y)
  local h = love.graphics.getFont():getHeight()
  local w = love.graphics.getFont():getWidth(self.target)
  local pos = M.command_target_positions[self.target]
  assert(pos ~= nil)
  return rect_collision(x, y, pos.x, pos.y, w, h)
end

local function board_contains(self, x, y)
  local w, h = M.normalize_xy(0.3, 0.4)
  local pos = M.command_target_positions[self.target]
  assert(pos ~= nil)
  return rect_collision(x, y, pos.x, pos.y, w, h)
end

---@param self RenderCommandCard | RenderCommandMeta
---@param x integer
---@param y integer
local function card_contains(self, x, y)
  local ops = M.command_target_positions[self.target]
  assert(ops ~= nil)
  local cardw, cardh = M.normalize_xy(Card.width(), Card.height(), Card.width(), Card.height())

  local cx = ops.x + cardw / 2
  local cy = ops.y + cardh / 2
  local dx = x - cx
  local dy = y - cy

  local angle = ops.r or 0
  local cos_r = math.cos(-angle)
  local sin_r = math.sin(-angle)

  local localx = cos_r * dx - sin_r * dy + cardw / 2
  local localy = sin_r * dx + cos_r * dy + cardh / 2
  return rect_collision(localx, localy, 0, 0, cardw, cardh)
end

---@param self RenderCommandBag | RenderCommandMeta
---@param x integer
---@param y integer
local function bag_contains(self, x, y)
  local pos = M.command_target_positions[self.target]
  assert(pos ~= nil)
  return rect_collision(x, y, pos.x, pos.y, #self.target * 10, 30)
end

---@param self RenderCommandMove
---@param x integer
---@param y integer
local function move_contains(self, x, y)
  local w, h = M.normalize_xy(Move.width(), Move.height(), Move.width(), Move.height())
  local pos = M.command_target_positions[self.target]
  assert(pos ~= nil)
  return rect_collision(x, y, pos.x, pos.y, w, h)
end

---@param self RenderCommandButton | RenderCommandMeta
---@param x integer
---@param y integer
local function button_contains(self, x, y)
  local w, h = table.unpack(self.target)
  local ops = M.command_target_positions[self.target]
  assert(ops ~= nil)
  w, h = M.normalize_xy(w, h, w, h)
  return rect_collision(x, y, ops.x, ops.y, w, h)
end

---@param self RenderCommandToken | RenderCommandMeta
---@param x integer
---@param y integer
local function token_contains(self, x, y)
  local tokenr = M.normalize_x(Token.radius())
  local pos = M.command_target_positions[self.target]
  assert(pos ~= nil)
  local dx = math.abs(x - (pos.x + tokenr))
  local dy = math.abs(y - (pos.y + tokenr))
  -- if dx > tokenr then
  -- 	return false
  -- end
  --
  -- if dy > tokenr then
  -- 	return false
  -- end
  --
  -- if dx + dy <= tokenr then
  -- 	return true
  -- end

  local contains = (dx * dx + dy * dy) <= (tokenr * tokenr)
  return contains
end

---@class RenderableOptions
---@field drag? fun(x: integer, y: integer)
---@field click? fun(x: integer, y: integer)

---@param type RenderCommandType
---@param target unknown
---@param x integer
---@param y integer
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param time? number
function M:push_renderable(type, target, contain_f, x, y, r, ox, oy, time)
  local existing = self.command_target_positions[target]

  x, y = M.normalize_xy(x, y)

  if not existing then
    existing = { x = ox and M.normalize_x(ox) or x, y = oy and M.normalize_y(oy) or y, r = r or 0 }
    self.command_target_positions[target] = existing
  else
    -- This version fixes card bug but creates slow-feeling ui
    if not existing.tween then
      if existing.x ~= x or existing.y ~= y or existing.r ~= r then
        existing.tween = flux
            .to(existing, time or 0.2, { x = x, y = y, r = r or 0 })
            :ease("sineinout") -- Experiement with the easing function
            :oncomplete(function()
              existing.tween = nil
            end)
      end
    end

    -- This version feels faster but creates visual bug issues
    -- if existing.tween then
    --   existing.tween:stop()
    -- end
    --
    -- existing.tween = flux.to(existing, time or 0.14, { x = x, y = y, r = r or 0 }):ease("cubicout") -- Experiement with the easing function
  end

  assert(contain_f ~= nil)
  table.insert(self.commands, {
    type = type,
    target = target,
    contains = contain_f,
  })
end

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param t? number
function M:card(card, x, y, r, ox, oy, t)
  -- Is there a better way to do this, with meta tables?
  self:push_renderable("card", card, card_contains, x, y, r, ox, oy, t)
end

---@param board_slot RenderCommandBoardSlotTarget
---@param x integer
---@param y integer
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param t? number
function M:boardslot(board_slot, x, y, r, ox, oy, t)
  self:push_renderable("board", board_slot, board_contains, x, y, r, ox, oy, t)
end

---@param move Move
---@param x integer
---@param y integer
function M:move(move, x, y)
  self:push_renderable("move", move, move_contains, x, y)
end

---@param t RenderCommandTarget
function M:cancel_tween(t)
  local existing = self.command_target_positions[t]
  if existing and existing.tween then
    existing.tween:stop()
    existing.tween = nil
  end
end

---@param token Token
---@param x integer
---@param y integer
---@param ox? integer
---@param oy? integer
---@param time? number
function M:token(token, x, y, ox, oy, time)
  -- Is there a better way to do this, with meta tables?
  self:push_renderable("token", token, token_contains, x, y, nil, ox, oy, time)
end

---@param bag Token[]
---@param x integer
---@param y integer
function M:bag(bag, x, y)
  -- Is there a better way to do this, with meta tables?
  self:push_renderable("bag", bag, bag_contains, x, y)
end

---@param f function
---@param x integer
---@param y integer
---@param w number
---@param h number
---@param text string
function M:button(x, y, w, h, text, f)
  local target = { w, h, text = text }
  self:push_renderable("button", target, button_contains, x, y)
  self:register(target, { click = f })
end

---@param text string
---@param x integer
---@param y integer
function M:text(text, x, y)
  self:push_renderable("text", text, text_contains, x, y)
end

---@param x integer
---@param y integer
---@param f? fun(c: RenderCommand): boolean
---@return RenderCommand?
function M:hover(x, y, f)
  return table.pop(self:contains(x, y, f))
end

---@param x integer
---@param y integer
---@param f? fun(c: RenderCommand): boolean
---@return RenderCommand[]
function M:contains(x, y, f)
  if f then
    return table.filter(self.last_frame_commands, function(v)
      return v:contains(x, y) and f(v)
    end)
  else
    return table.filter(self.last_frame_commands, function(v)
      return v:contains(x, y)
    end)
  end
end

---@param c RenderCommand
function M:pos(c)
  return self.command_target_positions[c.target]
end

---@param t RenderCommandTarget
function M:post(t)
  return self.command_target_positions[t]
end

-- Prevent blurring when scaling png images
-- Set this globally
love.graphics.setDefaultFilter("nearest", "nearest")

local BG_TileImage = love.graphics.newImage("resources/bg-tile.png")
local BG_TileImageWidth = BG_TileImage:getWidth()
local BG_TileImageHeight = BG_TileImage:getWidth()

function M:fill_background()
  local w, h = self.normalize_xy(1, 1, 1, 1)

  local sx = w / BG_TileImageWidth
  local sy = h / BG_TileImageHeight

  love.graphics.draw(BG_TileImage, 0, 0, 0, sx, sy)
end

local ButtonImage = love.graphics.newImage("resources/button.png")
local ButtonImageWidth = ButtonImage:getWidth()
local ButtonImageHeight = ButtonImage:getHeight()
local FontHeight = love.graphics.getFont():getHeight()

function M:__drawbutton(x, y, w, h, text)
  x, y = self.normalize_xy(x, y, w, h)
  w, h = self.normalize_xy(w, h)
  local sx = w / ButtonImageWidth
  local sy = h / ButtonImageHeight
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)
  love.graphics.draw(ButtonImage, 0, 0, 0, sx, sy)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf(text, 5 * sx, 5 * sy, 40 * sx / fsy, "center", 0, fsy, fsy)
  love.graphics.setColor(1, 1, 1, 1)
end

local BoardSlotImage = love.graphics.newImage("resources/board-slot.png")
local BoardSlotImageWidth = BoardSlotImage:getWidth()
local BoardSlotImageHeight = BoardSlotImage:getHeight()

---@param x integer
---@param y integer
---@param t RenderCommandBoardSlotTarget
function M:__drawboardslot(x, y, t)
  x, y = self.normalize_xy(x, y)
  local w, h = View.normalize_xy(0.16, 0.04)
  local sx = w / BoardSlotImageWidth
  local sy = h / BoardSlotImageHeight

  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)
  love.graphics.draw(BoardSlotImage, 0, 0, 0, sx, sy)
  love.graphics.setColor(1,1,1)
  love.graphics.printf(t.type, 5 * sx, 4 * sy / fsy, (45 * sx / fsy), "left", 0, fsy, fsy)
  love.graphics.printf("" .. t.amt, 53 * sx, 4 * sy / fsy, (19 * sx / fsy), "left", 0, fsy, fsy)
end

local BagImage = love.graphics.newImage("resources/bag.png")
local BagImageWidth = BagImage:getWidth()
local BagImageHeight = BagImage:getHeight()

local BagWidth = 0.1
local BagHeight = BagWidth * 8

function M:__drawbag(x, y)
  -- Silly way of doing this. Since tokens arent game objects,
  -- we can track them smartly in the bag.
  local w, h = self.normalize_xy(BagWidth, BagHeight)
  local sx = w / BagImageWidth
  local sy = h / BagImageHeight

  -- local itemw, itemh = self.normalize_xy(BagItemWidth, BagItemHeight)

  love.graphics.translate(x, y)

  -- for i, token in ipairs(tokens) do
  --   local ytr = i * itemh
  --   love.graphics.setColor(table.unpack(token.color))
  --   love.graphics.rectangle("fill", 0, ytr, itemw, itemh)
  -- end
  love.graphics.setColor(1, 1, 1)

  love.graphics.draw(BagImage, 0, 0, 0, sx, sy)
end

-- TODO: Updating dragging positions *here* causes some real confusing behavior.
function M:draw()
  -- Update position of dragged elements to match mouse
  if View:is_dragging() then
    assert(View.dragging ~= nil)

    local pos = View.command_target_positions[View.dragging.target]
    assert(pos ~= nil)

    local mousex, mousey = love.mouse.getPosition()
    local x = mousex - View.dragging.ox
    local y = mousey - View.dragging.oy
    pos.x = x
    pos.y = y
  end

  self:fill_background()

  for _, v in ipairs(self.commands) do
    local t = v.type

    love.graphics.push()
    if t == "card" then
      ---@type Card
      local card = v.target
      local pos = self.command_target_positions[card]

      Card.draw(card, pos.x, pos.y, pos.r)
    elseif t == "token" then
      ---@type Token
      local token = v.target
      local pos = self.command_target_positions[token]

      Token.draw(token, pos.x, pos.y)
    elseif t == "move" then
      ---@type Move
      local move = v.target
      local pos = self.command_target_positions[move]

      Move.draw(move, pos.x, pos.y)
    elseif t == "text" then
      ---@type string
      local text = v.target
      local pos = self.command_target_positions[text]

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.print(text, pos.x, pos.y)
    elseif t == "board" then
      ---@type RenderCommandBoardSlotTarget
      local target = v.target
      local pos = self.command_target_positions[target]
      self:__drawboardslot(pos.x, pos.y, target)
    elseif t == "button" then
      ---@type RenderCommandButtonTarget
      local target = v.target
      local pos = self.command_target_positions[target]
      local w, h = target[1], target[2]
      self:__drawbutton(pos.x, pos.y, w, h, target.text)
    elseif t == "bag" then
      ---@type Token[]
      local target = v.target

      local pos = self.command_target_positions[target]
      self:__drawbag(pos.x, pos.y)
    else
      assert(false, "Unhandled case")
    end

    love.graphics.pop()
  end

  self.last_frame_commands = self.commands
  self.commands = {}
end

return M
