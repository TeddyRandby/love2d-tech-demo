local flux = require("util.flux")
local Shaders = require("util.shaders")

---@alias UserEvent "click" | "dragstart" | "dragend" | "receive"

---@alias UserEventHandler table<UserEvent, function>

---@class Dragging
---@field ox integer
---@field oy integer
---@field target RenderCommandTarget

---@class RenderPosition
---@field x integer
---@field y integer
---@field r number
---@field scale number
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
		return t.id == o
	end)

	local hovered_on_top = hovered_at_all and table.pop(hover).target == o

	return hovered_on_top, hovered_at_all
end

local UI = require("ui")

---@alias RenderCommandTarget IconType[] | Move | Card | Token | Token[] | string | RenderCommandButtonTarget

---@param id unknown
---@param hs? table<UserEvent, function>
function M:register(id, hs)
	assert(self.user_event_handlers ~= nil)
	self.user_event_handlers[id] = hs
end

---@param id unknown
---@param e UserEvent
---@param x integer
---@param y integer
---@param data? any
function M:__fire(id, e, x, y, data)
	local hs = self.user_event_handlers[id]

	if not hs or not hs[e] then
		return
	end

	print("[USEREVENT]", id.type, e, x, y, data)
	hs[e](x, y, data)
end

---@alias RenderCommandButtonTarget { [1]: number, [2]: number, text: string }
---@alias RenderCommandBoardSlotTarget { type: TokenType, amt: integer }
---@alias RenderCommandType "button" | "bag" | "card" | "token" | "text" | "move" | "board" | "details" | "icon" | "movelist"

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
---@class RenderCommandMoveList
---@field type "movelist"
---@field target "shop" | "moves"

---@class RenderCommandBoardSlot
---@field type "board"
---@field target RenderCommandBoardSlotTarget
---
---@class RenderCommandDetails
---@field type "details"
---@field target string
---
---@class RenderCommandIcon
---@field type "icon"
---@field target IconType[]

---@class RenderCommandMeta
---@field contains? fun(self: RenderCommand, x: integer, y: integer): boolean
---@field id unknown

---@param id unknown
function M:draggable(id)
	---@return boolean
	local hs = self.user_event_handlers[id]
	return hs and not not (hs["dragstart"] or hs["dragend"])
end

---@param id unknown
---@return boolean
function M:clickable(id)
	local hs = self.user_event_handlers[id]
	return hs and not not hs["click"]
end

---@param id unknown
---@return boolean
function M:receivable(id)
	local hs = self.user_event_handlers[id]
	return hs and not not hs["receive"]
end

---@alias RenderCommand RenderCommandIcon | RenderCommandText | RenderCommandCard | RenderCommandToken | RenderCommandBag | RenderCommandMove | RenderCommandBoardSlot | RenderCommandMeta

---@param n number
---@param max integer
---@return integer
local function normalize_dim(n, max)
	if n > 1 then
		return n
	end

	if n < -1 then
		return n
	end

	if n >= 0 then
		return math.floor(n * max)
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
---@return integer, integer
function M.normalize_xy(x, y)
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
	local pos = M.command_target_positions[self.id]
	assert(pos ~= nil)
	return rect_collision(x, y, pos.x, pos.y, w, h)
end

local function board_contains(self, x, y)
	local w, h = M.normalize_xy(0.3, 0.4)
	local pos = M.command_target_positions[self.id]
	assert(pos ~= nil)
	return rect_collision(x, y, pos.x, pos.y, w, h)
end

---@param self RenderCommandCard | RenderCommandMeta
---@param x integer
---@param y integer
local function card_contains(self, x, y)
	local ops = M.command_target_positions[self.id]
	assert(ops ~= nil)
	local cardw, cardh = UI.card.getRealizedDim()

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
	local pos = M.command_target_positions[self.id]
	local w, h = UI.skill.getRealizedDim()
	assert(pos ~= nil)
	return rect_collision(x, y, pos.x, pos.y, w, h)
end

---@param self RenderCommandMove | RenderCommandMeta
---@param x integer
---@param y integer
local function move_contains(self, x, y)
	local w, h = UI.skill.getRealizedDim()
	local pos = M.command_target_positions[self.id]
	assert(pos ~= nil)
	return rect_collision(x, y, pos.x, pos.y, w, h)
end

---@param self RenderCommandButton | RenderCommandMeta
---@param x integer
---@param y integer
local function button_contains(self, x, y)
	local w, h = table.unpack(self.target)
	local ops = M.command_target_positions[self.id]
	assert(ops ~= nil)
	w, h = M.normalize_xy(w, h)
	return rect_collision(x, y, ops.x, ops.y, w, h)
end

---@param self RenderCommandToken | RenderCommandMeta
---@param x integer
---@param y integer
local function token_contains(self, x, y)
	local tokenr = UI.token.getRealizedDim() / 2

	local pos = M.command_target_positions[self.id]
	assert(pos ~= nil)
	tokenr = tokenr * pos.scale
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
---@param id unknown
---@param contain_f? function
---@param x integer
---@param y integer
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param time? number
---@param delay? number
---@param scale? number
function M:push_renderable(type, target, id, contain_f, x, y, r, ox, oy, time, delay, scale)
	local existing = self.command_target_positions[id]

	scale = scale or 1
	time = time or 0.2
	delay = delay or 0
	r = r or 0

	x, y = M.normalize_xy(x, y)

	if not existing then
		existing = { x = ox and M.normalize_x(ox) or x, y = oy and M.normalize_y(oy) or y, r = r or 0, scale = scale }
		self.command_target_positions[id] = existing
	else
		-- This version fixes card bug but creates slow-feeling ui
		if not existing.tween then
			if existing.x ~= x or existing.y ~= y or existing.r ~= r or existing.scale ~= scale then
				-- if existing.x ~= x then
				-- 	print("[TWEENX]", existing.x, x)
				-- end
				--
				-- if existing.y ~= y then
				-- 	print("[TWEENY]", existing.y, y)
				-- end
				--
				-- if existing.r ~= r then
				-- 	print("[TWEENR]", existing.r, r)
				-- end
				--
				-- if existing.scale ~= scale then
				-- 	print("[TWEENS]", existing.scale, scale)
				-- end

				existing.tween = flux
					.to(existing, time, { x = x, y = y, r = r, scale = scale })
					:ease("sineinout") -- Experiement with the easing function
					:delay(delay)
					:oncomplete(function()
						print("[COMPLETETWEEN]", id, x, y, r, scale)
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

	table.insert(self.commands, {
		type = type,
		target = target,
		id = id,
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
---@param delay? number
function M:card(card, x, y, r, ox, oy, t, delay)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("card", card, card, card_contains, x, y, r, ox, oy, t, delay)
end

---@param board_slot RenderCommandBoardSlotTarget
---@param x integer
---@param y integer
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param t? number
function M:boardslot(board_slot, x, y, r, ox, oy, t)
	self:push_renderable("board", board_slot, board_slot, board_contains, x, y, r, ox, oy, t)
end

---@param icons IconType[]
---@param x integer
---@param y integer
---@param id? unknown
---@param r? integer
---@param ox? integer
---@param oy? integer
---@param time? number
function M:icon(icons, x, y, id, r, ox, oy, time)
	self:push_renderable("icon", icons, id or {}, nil, x, y, r, ox, oy, time)
end

---@param move Move | Effect | nil
---@param x integer
---@param y integer
---@param id? unknown
function M:move(move, x, y, id)
	self:push_renderable("move", move, id or {}, move_contains, x, y)

	if move then
		self:icon(move.icon, x, y, move)
	end
end

---@param id unknown
function M:cancel_tween(id)
	local existing = self.command_target_positions[id]
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
---@param scale? number
function M:token(token, x, y, ox, oy, time, scale)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("token", token, token, token_contains, x, y, nil, ox, oy, time, nil, scale)
end

---@param bag "active" | "exhausted" | "bag"
---@param id string
---@param x integer
---@param y integer
---@param ox? integer
---@param oy? integer
function M:bag(bag, id, x, y, ox, oy)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("bag", bag, id, bag_contains, x, y, nil, ox, oy)
end

---@param label "moves" | "effects" | "shopeffects" | "shopmoves"
---@param id unknown
---@param x integer
---@param y integer
---@param ox? integer
---@param oy? integer
function M:movelist(label, id, x, y, ox, oy)
	-- Is there a better way to do this, with meta tables?
	self:push_renderable("movelist", label, id, nil, x, y, nil, ox, oy)
end

---@param f function
---@param x integer
---@param y integer
---@param t RenderCommandButtonTarget
function M:button(x, y, t, f)
	self:push_renderable("button", t, t, button_contains, x, y)
	self:register(t, { click = f })
end

---@param text string
---@param x integer
---@param y integer
function M:text(text, x, y)
	self:push_renderable("text", text, {}, text_contains, x, y)
end

---@param text string
---@param id string
---@param x integer
---@param y integer
function M:details(text, id, x, y)
	-- TODO: Replace text_contains with proper detection
	self:push_renderable("details", text, id, function()
		return false
	end, x, y, nil, nil, 1, nil, 0.2)
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
			if v.contains then
				return v:contains(x, y) and f(v)
			else
				return false
			end
		end)
	else
		return table.filter(self.last_frame_commands, function(v)
			if v.contains then
				return v:contains(x, y)
			else
				return false
			end
		end)
	end
end

---@param c RenderCommand
function M:pos(c)
	return self.command_target_positions[c.id]
end

---@param id RenderCommandTarget
function M:post(id)
	return self.command_target_positions[id]
end

-- Prevent blurring when scaling png images
-- Set this globally
love.graphics.setDefaultFilter("nearest", "nearest")

local BGImage = love.graphics.newImage("resources/bg.png")
local BGImageWidth = BGImage:getWidth()
local BGImageHeight = BGImage:getHeight()

function M:fill_background()
	local w, h = self.normalize_xy(1, 1)

	local sy = h / BGImageHeight
	local sx = w / BGImageWidth

	local realw = BGImageWidth * sy

	love.graphics.draw(BGImage, (w - realw) / 2, 0, 0, sy, sy)
end

local ButtonImage = love.graphics.newImage("resources/button-mask.png")
local ButtonTOPImage = love.graphics.newImage("resources/button-bg.png")
local ButtonUpImage = love.graphics.newImage("resources/button-up.png")
local ButtonHLMaskImage = love.graphics.newImage("resources/button-hl-mask.png")
local ButtonImageWidth = ButtonImage:getWidth()
local ButtonImageHeight = ButtonImage:getHeight()
local FontHeight = love.graphics.getFont():getHeight()

function M:__drawbutton(target, x, y, w, h, text)
	x, y = self.normalize_xy(x, y)
	w, h = self.normalize_xy(w, h)
	local sx = w / ButtonImageWidth
	local sy = h / ButtonImageHeight
	local fsy = View.normalize_y(View.getFontSize()) / FontHeight

	love.graphics.translate(x, y)
	-- love.graphics.setColor(1, 1, 1, 1)

	-- local mask = love.graphics.newCanvas(w, h)
	-- local canvas = love.graphics.newCanvas(w, h)
	--
	-- mask:setFilter("linear")
	-- canvas:setFilter("linear")
	--
	-- love.graphics.origin()
	-- love.graphics.setCanvas(mask)
	-- -- love.graphics.clear(0, 0, 0, 0)
	-- love.graphics.draw(ButtonHLMaskImage, 0, 0, 0, sx, sy)
	-- love.graphics.setCanvas()
	--
	-- love.graphics.setCanvas(canvas)
	-- love.graphics.clear(0, 0, 0, 0)
	-- -- love.graphics.setBlendMode("multiply", "premultiplied")
	-- -- Shaders.glow(Engine.time, mask, { 255 / 255, 252 / 255, 253 / 255 })
	-- love.graphics.draw(mask, 0, 0) -- same size/coords
	-- -- Shaders.reset()
	-- love.graphics.setCanvas()
	-- love.graphics.setBlendMode("alpha")
	--
	-- love.graphics.setColor(1, 1, 1, 1)
	-- love.graphics.translate(x, y)
	-- love.graphics.draw(canvas, 0, 0, 0)
	--
	if View:is_hovering(target) then
		love.graphics.translate(sx, sy)
	else
		Shaders.pixel_scanline(x, y, w, h, sx, sy, 0)
		love.graphics.draw(ButtonHLMaskImage, 0, 0, 0, sx, sy)
		Shaders.reset()
	end

	Shaders.pixel_scanline(x, y, w, h, sx, sy, 0)
	love.graphics.draw(ButtonUpImage, 0, 0, 0, sx, sy)
	Shaders.reset()

	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.printf(text, 2 * sx / fsy, 12 * fsy, 14 * sx / fsy, "center", 0, fsy, fsy)
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
	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(t.type, 5 * sx, 4 * sy / fsy, (45 * sx / fsy), "left", 0, fsy, fsy)
	love.graphics.printf("" .. t.amt, 53 * sx, 4 * sy / fsy, (19 * sx / fsy), "left", 0, fsy, fsy)
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
			local pos = self.command_target_positions[v.id]

			UI.card.draw(card, pos.x, pos.y, pos.r)
		elseif t == "token" then
			---@type Token
			local token = v.target
			local pos = self.command_target_positions[v.id]

			UI.token.draw(token, pos.x, pos.y, pos.scale)
		elseif t == "move" then
			---@type Move | nil
			local move = v.target
			local pos = self.command_target_positions[v.id]

			UI.skill.draw(move, pos.x, pos.y)
		elseif t == "icon" then
			---@type IconType[]
			local icon = v.target
			local pos = self.command_target_positions[v.id]

			for _, i in ipairs(icon) do
				UI.icon.draw(i, pos.x, pos.y)
			end
		elseif t == "text" then
			---@type string
			local text = v.target
			local pos = self.command_target_positions[v.id]
			local fsy = View.normalize_y(View.getFontSize()) / FontHeight

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.print(text, pos.x, pos.y, 0, fsy, fsy)
		elseif t == "details" then
			---@type string
			local target = v.target
			local pos = self.command_target_positions[v.id]
			local x, y = self.normalize_xy(pos.x, pos.y)
			local w, h = self.normalize_xy(0.2, 0.35)
			local fsy = View.normalize_y(View.getFontSize()) / FontHeight

			love.graphics.translate(x, y)

			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("fill", 0, 0, w, h)

			local pdx, pdy = self.normalize_xy(0.01, 0.01)

			love.graphics.setColor(0, 0, 0)
			love.graphics.rectangle("fill", pdx, pdy, w - pdx * 2, h - pdy * 2)

			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.printf(target, pdx * 2, pdy * 2, (w - pdx * 4) / fsy, "left", 0, fsy, fsy)
		elseif t == "board" then
			---@type RenderCommandBoardSlotTarget
			local target = v.target
			local pos = self.command_target_positions[v.id]
			self:__drawboardslot(pos.x, pos.y, target)
		elseif t == "button" then
			---@type RenderCommandButtonTarget
			local target = v.target
			local pos = self.command_target_positions[v.id]
			local w, h = target[1], target[2]
			self:__drawbutton(target, pos.x, pos.y, w, h, target.text)
		elseif t == "movelist" then
			---@type "moves" | "shopmoves" | "effects" | "shopeffects"
			local target = v.target

			local pos = self.command_target_positions[v.id]

			UI.skillbox.draw(pos.x, pos.y, target)
		elseif t == "bag" then
			---@type "active" | "bag" | "exhausted"
			local target = v.target

			local pos = self.command_target_positions[v.id]

			UI.bag.draw(pos.x, pos.y, target)
		else
			assert(false, "Unhandled case")
		end

		love.graphics.pop()
	end

	self.last_frame_commands = self.commands
	self.commands = {}
end

return M
