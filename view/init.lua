---@class View
---@field last_frame_commands RenderCommand[]
---@field commands RenderCommand[]
local M = {
	last_frame_commands = {},
	commands = {},
}

local Card = require("data.card")
local Token = require("data.token")

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
---@field draggable fun(self: RenderCommand): boolean
---@field clickable fun(self: RenderCommand): boolean
---@field drag? fun(x: integer, y: integer)
---@field click? fun(x: integer, y: integer)

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

---@param x number
---@param y number
---@return integer, integer
local function normalize_xy(x, y)
	return normalize_dim(x, love.graphics.getWidth()), normalize_dim(y, love.graphics.getHeight())
end

local function rect_collision(x, y, rx, ry, rw, rh)
	local l, r, b, t = rx, rx + rw, ry, ry + rh
	return x > l and x < r and y > b and y < t
end

---@param self RenderCommandButton
---@param x integer
---@param y integer
local function box_contains(self, x, y)
	local w, h = table.unpack(self.target)
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
	local cardw, cardh = Card.width(), Card.height()
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
	local tokenr = Token.radius()
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

---@param self RenderCommand
local function draggable(self)
	return self.drag ~= nil
end

---@param self RenderCommand
local function clickable(self)
	return self.click ~= nil
end

---@param type RenderCommandType
---@param target unknown
---@param x integer
---@param y integer
---@param opts? RenderableOptions
function M:push_renderable(type, target, contain_f, x, y, opts)
	table.insert(self.commands, {
		type = type,
		target = target,
		x = x,
		y = y,
		contains = contain_f,
		draggable = draggable,
		clickable = clickable,
		drag = opts and opts.drag,
		click = opts and opts.click,
	})
end

---@param card Card
---@param x integer
---@param y integer
---@param opts? RenderableOptions
function M:card(card, x, y, opts)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("card", card, card_contains, x, y, opts)
end

---@param token Token
---@param x integer
---@param y integer
---@param opts? RenderableOptions
function M:token(token, x, y, opts)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("token", token, token_contains, x, y, opts)
end

---@param bag Token[]
---@param x integer
---@param y integer
---@param opts? RenderableOptions
function M:bag(bag, x, y, opts)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("bag", bag, bag_contains, x, y, opts)
end

---@param f function
---@param x integer
---@param y integer
---@param w number
---@param h number
---@param text string
function M:button(x, y, w, h, text, f)
	self:push_renderable("button", { w, h, text = text }, box_contains, x, y, { click = f })
end

---@param text string
---@param x integer
---@param y integer
---@param opts? RenderableOptions
function M:text(text, x, y, opts)
	self:push_renderable("text", text, text_contains, x, y, opts)
end

---@param x integer
---@param y integer
---@return RenderCommand?
function M:hover(x, y)
	return table.pop(self:contains(x, y))
end

---@param x integer
---@param y integer
---@return RenderCommand[]
function M:contains(x, y)
	return table.filter(self.last_frame_commands, function(v)
		return v:contains(x, y)
	end)
end

function M:draw()
	for _, v in ipairs(self.commands) do
		local t = v.type

		if t == "card" then
			---@type Card
			local card = v.target
			local x, y = normalize_xy(v.x, v.y)
			Card.draw(card, x, y)
		elseif t == "token" then
			---@type Token
			local token = v.target
			local x, y = normalize_xy(v.x, v.y)
			Token.draw(token, x, y)
		elseif t == "text" then
			---@type string
			local text = v.target
			local x, y = normalize_xy(v.x, v.y)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(text, x, y)
		elseif t == "button" then
			---@type RenderCommandButtonTarget
			local target = v.target
			local x, y = normalize_xy(v.x, v.y)
			local w, h = target[1], target[2]
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.rectangle("fill", x, y, w, h)
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(target.text, x + 5, y + 5, w)
		elseif t == "bag" then
			local x, y = normalize_xy(v.x, v.y)
			local tw, th = 10, 30
			-- Silly way of doing this. Since tokens arent game objects,
			-- we can track them smartly in the bag.
			for _, token in ipairs(v.target) do
				love.graphics.setColor(table.unpack(token.color))
				love.graphics.rectangle("fill", x, y, tw, th)
				x = x + tw
			end
		else
			assert(false, "Unhandled case")
		end
	end

	self.last_frame_commands = self.commands
	self.commands = {}
end

return M
