---@alias UserEvent "click" | "dragstart" | "dragend" | "receive"

---@alias UserEventHandler table<UserEvent, function>

---@class Dragging
---@field ox integer
---@field oy integer
---@field target RenderCommandTarget

---@class View
---@field user_event_handlers table<RenderCommandTarget, UserEventHandler>
---@field last_frame_commands RenderCommand[]
---@field commands RenderCommand[]
---@field dragging Dragging?
local M = {
	user_event_handlers = {},
	last_frame_commands = {},
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

local Card = require("data.card")
local Token = require("data.token")

---@alias RenderCommandTarget Card | Token | Token[] | string | RenderCommandButtonTarget

---@param o RenderCommandTarget
---@param hs? table<UserEvent, function>
function M:register(o, hs)
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

	-- print("[USEREVENT]", o.type, e, x, y, data)
	hs[e](x, y, data)
end

---@alias RenderCommandButtonTarget { [1]: number, [2]: number, text: string }
---@alias RenderCommandType "button" | "bag" | "card" | "token" | "text"

---@class RenderCommandText
---@field type "text"
---@field target string
---@field x integer
---@field y integer

---@class RenderCommandButton
---@field type "button"
---@field target RenderCommandButtonTarget
---@field x integer
---@field y integer

---@class RenderCommandBag
---@field type "bag"
---@field target Token[]
---@field x integer
---@field y integer

---@class RenderCommandCard
---@field type "card"
---@field target Card
---@field x integer
---@field y integer

---@class RenderCommandToken
---@field type "token"
---@field target Token
---@field x integer
---@field y integer

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

---@alias RenderCommand RenderCommandText | RenderCommandCard | RenderCommandToken | RenderCommandBag | RenderCommandMeta

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
---@param w number
---@param h number
---@return integer, integer
function M.normalize_xy(x, y, w, h)
	return M.normalize_x(x), M.normalize_y(y)
end

local function rect_collision(x, y, rx, ry, rw, rh)
	local l, r, b, t = rx, rx + rw, ry, ry + rh
	return x > l and x < r and y > b and y < t
end

---@param self RenderCommandButton
---@param x integer
---@param y integer
local function button_contains(self, x, y)
	local w, h = table.unpack(self.target)
  w, h = M.normalize_xy(w, h, w, h)
	return rect_collision(x, y, self.x, self.y, w, h)
end

---@param self RenderCommandText
---@param x integer
---@param y integer
local function text_contains(self, x, y)
	local h = love.graphics.getFont():getHeight()
	local w = love.graphics.getFont():getWidth(self.target)
	return rect_collision(x, y, self.x, self.y, w, h)
end

---@param self RenderCommandCard
---@param x integer
---@param y integer
local function card_contains(self, x, y)
	local cardw, cardh = M.normalize_xy(Card.width(), Card.height(), Card.width(), Card.height())
	return rect_collision(x, y, self.x, self.y, cardw, cardh)
end

---@param self RenderCommandBag
---@param x integer
---@param y integer
local function bag_contains(self, x, y)
	return rect_collision(x, y, self.x, self.y, #self.target * 10, 30)
end

---@param self RenderCommandToken
---@param x integer
---@param y integer
local function token_contains(self, x, y)
	local tokenr = M.normalize_x(Token.radius())
	local dx = math.abs(x - self.x)
	local dy = math.abs(y - self.y)
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
function M:push_renderable(type, target, contain_f, x, y)
	table.insert(self.commands, {
		type = type,
		target = target,
		x = x,
		y = y,
		contains = contain_f,
	})
end

---@param card Card
---@param x integer
---@param y integer
function M:card(card, x, y)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("card", card, card_contains, x, y)
end

---@param token Token
---@param x integer
---@param y integer
function M:token(token, x, y)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("token", token, token_contains, x, y)
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

function M:draw()
	for _, v in ipairs(self.commands) do
		local t = v.type

		if t == "card" then
			---@type Card
			local card = v.target

			if self:is_dragging(card) then
				local mousex, mousey = love.mouse.getPosition()
				v.x = mousex - View.dragging.ox
				v.y = mousey - View.dragging.oy
			end

			v.x, v.y = M.normalize_xy(v.x, v.y, Card.width(), Card.height())

			Card.draw(card, v.x, v.y)
		elseif t == "token" then
			---@type Token
			local token = v.target

			if self:is_dragging(token) then
				local mousex, mousey = love.mouse.getPosition()
				v.x = mousex - View.dragging.ox
				v.y = mousey - View.dragging.oy
			end

			v.x, v.y = M.normalize_xy(v.x, v.y, Token.radius(), Token.radius())
			Token.draw(token, v.x, v.y)
		elseif t == "text" then
			---@type string
			local text = v.target
			v.x, v.y =
				M.normalize_xy(v.x, v.y, love.graphics.getFont():getWidth(text), love.graphics.getFont():getHeight())
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(text, v.x, v.y)
		elseif t == "button" then
			---@type RenderCommandButtonTarget
			local target = v.target
			local w, h = target[1], target[2]
			w, h = M.normalize_xy(w, h, w, h)
			v.x, v.y = M.normalize_xy(v.x, v.y, w, h)

			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("fill", v.x, v.y, w, h)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(target.text, v.x + 5, v.y + 5, w)
		elseif t == "bag" then
			local tw, th = 10, 30
			v.x, v.y = M.normalize_xy(v.x, v.y, tw * #v.target, th)
			-- Silly way of doing this. Since tokens arent game objects,
			-- we can track them smartly in the bag.
			local thisx = v.x
			for _, token in ipairs(v.target) do
				love.graphics.setColor(table.unpack(token.color))
				love.graphics.rectangle("fill", thisx, v.y, tw, th)
				thisx = thisx + tw
			end
		else
			assert(false, "Unhandled case")
		end
	end

	self.last_frame_commands = self.commands
	self.commands = {}
end

return M
