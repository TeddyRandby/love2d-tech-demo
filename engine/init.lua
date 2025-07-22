---@alias Draggable Card | Token

---@class Dragging
---@field ox integer
---@field oy integer
---@field target Draggable

---@class Engine
---@field scene "main" | "drafting" | "upgrading" | "battling" | "shopping"
---@field rng love.RandomGenerator
---@field TokenTable Token[]
---@field TokenTypes Token[]
---@field CardTable Card[]
---@field CardTypes Card[]
---@field SceneTypes table<string, Scene>
---@field bag Token[]
---@field field Token[]
---@field exhausted Token[]
---@field hand Card[]
---@field dragging Dragging?
---@field scene_data table<SceneType, table>
local M = {
	scene = "main",
	scene_data = {},
	hand = {},
	bag = {},
	field = {},
	exhausted = {},
	TokenTable = {},
	CardTable = {},
	SceneTypes = require("data.scene.types"),
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),

	stats = { draw = 3 },
}

local Card = require("data.card")
local Token = require("data.token")

---@param scene SceneType
function M:transition(scene)
	self.scene = scene
end

---@param component Component
---@param val? unknown
function M:component_data(component, val)
	if val ~= nil then
		self.scene_data[self.scene][component.type][component] = val
	end

	return self.scene_data[self.scene][component.type][component]
end

---@param component Component
function M:reset_component_data(component)
	self.scene_data[self.scene][component.type][component] = nil
end

---@param o Draggable
---@param ox? integer
---@param oy? integer
--- Begin dragging game object o, with offset ox and oy into the sprite.
function M:begin_drag(o, ox, oy)
	self.dragging = {
		target = o,
		ox = ox or 0,
		oy = oy or 0,
	}
end

--- End dragging
function M:end_drag()
	assert(self.dragging ~= nil)
	self.dragging = nil
end

---@param o? Draggable
---@return boolean
function M:is_dragging(o)
	if o then
		return self.dragging ~= nil and self.dragging.target == o
	else
		return self.dragging ~= nil
	end
end

function M:round()
	self:draw(self.stats.draw)
end

---@param n integer
---@param tab? Card[]
---@return Card[]
--- Draw cards at random from the card table. Because the work 'draw' is already taken
--- for drawing tokens from your bag during combat, the word 'fish' is used instead.
--- This is inspired by the french translations of 'draw a card' in other card games.
function M:fish(n, tab)
	-- We copy each sampled element so that they are unique game objects.
	return table.replacement_sample(self.CardTable, n, tab, table.copy)
end

---@param n integer
--- Draw n tokens from the bag and move them into the playing field.
function M:draw(n)
	table.sample(self.bag, n, self.field, table.copy)
end

---@param n integer
---@param tab? Token[]
---@return Token[]
function M:pull_into(n, tab)
	return table.replacement_sample(self.TokenTable, n, tab)
end

-- TODO: Fix this to not repeat.
---@param n integer
---@param tab? Token[]
---@return Token[]
function M:peek_into(n, tab)
	return table.sample(self.bag, n, tab)
end

---@param n integer
---@return Token[]
function M:pull(n)
	return self:pull_into(n)
end

---@param n integer
---@return Token[]
function M:peek(n)
	return self:peek_into(n)
end

---@param ts Token[]
function M:draft(ts)
	-- TODO: Fire event handlers!
	for _, v in ipairs(ts) do
		table.insert(self.bag, v)
	end
end

---@param n integer
function M:play(n)
	assert(n <= #self.hand)
	local card = table.remove(self.hand, n)
	self:doplay(card)
end

---@param n integer
function M:exhaust(n)
	assert(n <= #self.field)
	local token = table.remove(self.field, n)
	self:doexhaust(token)
end

---@param token Token
function M:doexhaust(token)
	table.insert(self.exhausted, token)
end

---@param card Card
function M:doplay(card)
	---@type Token[]

	for _, op in ipairs(card.ops) do
		---@type Token[][]
		local ts = { {} }

		local function peek()
			---@type Token[]
			return ts[#ts]
		end

		local function pop()
			---@type Token[]
			return table.remove(ts, #ts)
		end

		---@param e Token[]
		local function push(e)
			table.insert(ts, e)
		end

		for _, potential_microop in ipairs(op.microops) do
			---@type ActionMicroOp[]
			local final_microops = { potential_microop }

			for _, microop in ipairs(final_microops) do
				local t = microop.type

				print("[MICROOP] " .. t)

				if t == "pull" then
					self:pull_into(microop.amount, peek())
				elseif t == "peek" then
					self:peek_into(microop.amount, peek())
				elseif t == "constant" then
					for _ = 1, microop.amount do
						table.insert(peek(), microop.token)
					end
				elseif t == "filter" then
					local tmp = {}

					for _, v in ipairs(pop()) do
						if microop.fun(v) then
							table.insert(tmp, v)
						end
					end

					push(tmp)
				elseif t == "choose" then
					-- TODO: USE UI, DON"T CHOOSE AT RANDOM
					local not_chosen, chosen = pop(), {}

					for _ = 1, microop.amount do
						if #not_chosen then
							local idx = self.rng:random(1, #not_chosen)
							table.insert(chosen, table.remove(not_chosen, idx))
						end
					end

					push(chosen)
					push(not_chosen)
				elseif t == "draft" then
					self:draft(pop())
				elseif t == "discard" then
					-- TODO: Terrible solution!
					-- Store source on token somewhere.
					for _, v in ipairs(pop()) do
						for i, b in ipairs(self.bag) do
							if b.type == v.type then
								print("\t DISCARD " .. v.name)
								table.remove(self.bag, i)
								goto next
							end
						end
						::next::
					end
				elseif t == "donate" then
					-- TODO: Terrible solution!
					-- Store source on token somewhere.
					-- Give away token somehow!
					for _, v in ipairs(pop()) do
						for i, b in ipairs(self.bag) do
							if b.type == v.type then
								table.remove(self.bag, i)
								goto next
							end
						end
						::next::
					end
				else
					assert(false, "Unhandled micro op type")
				end
			end
		end
	end
end

function M:load()
	self.rng = love.math.newRandomGenerator(os.clock())

	for _, v in ipairs(self.TokenTypes) do
		for _ = 1, v.freq do
			table.insert(self.TokenTable, v)
		end
	end

	for _, v in ipairs(self.CardTypes) do
		for _ = 1, v.freq do
			table.insert(self.CardTable, v)
		end
	end

	-- TODO: Do this automatically
	self.scene_data.drafting = {}
	self.scene_data.upgrading = {}
	self.scene_data.battling = {}
	self.scene_data.upgrading.card_selector = {}
	self.scene_data.drafting.card_selector = {}

	return self
end

local function card_in_hand_on_drag() end

function M:update()
	local scene = self.SceneTypes[self.scene]
	assert(scene ~= nil)

	for _, component in ipairs(scene.layout) do
		local t = component.type

		if t == "hand" then
			local cardw = Card.width()
			local x, y = component.x, component.y

			for i, v in ipairs(self.hand) do
				if self:is_dragging(v) then
					local mousex, mousey = love.mouse.getPosition()
					View:card(v, mousex - self.dragging.ox, mousey - self.dragging.oy, {
						drag = function()
							self:play(i)
							if #self.hand == 0 then
								self:transition("battling")
							end
						end,
					})
				else
					View:card(v, x, y, { drag = card_in_hand_on_drag })
				end
				x = x + cardw + 10
			end
		elseif t == "button" then
			local x, y, w, h = component.x, component.y, component.w, component.h
			assert(w ~= nil)
			assert(h ~= nil)

			View:button(x, y, w, h, component.text, component.f)
		elseif t == "board" then
			local tokenr = Token.radius()
			local tokenw = tokenr * 2

			local x, y = component.x, component.y

			x = x + Token.radius()
			y = y + Token.radius()

			for i, v in ipairs(self.field) do
				if self:is_dragging(v) then
					local mousex, mousey = love.mouse.getPosition()
					View:token(v, mousex - self.dragging.ox, mousey - self.dragging.oy, { drag = function()
            self:exhaust(i)
          end })
				else
					View:token(v, x, y, { drag = card_in_hand_on_drag })
				end
				x = x + tokenw + 10
			end

			x = component.x + 400
			for _, v in ipairs(self.exhausted) do
				View:token(v, x, y)
				x = x + tokenw + 10
			end
		elseif t == "card_selector" then
			local component_data = self:component_data(component)

			if component_data then
				local x, y = component.x, component.y

				---@type Card[]
				local cards = component_data.cards
				assert(cards ~= nil)

				for _, v in ipairs(cards) do
					View:card(v, x, y, {
						click = function()
							self:reset_component_data(component)
							table.insert(self.hand, v)
							if #self.hand >= 5 then
								self:transition("upgrading")
							end
						end,
					})

					x = x + 10 + Card.width()
				end
			else
				-- Will get drawn on the next frame
				self:component_data(component, {
					cards = self:fish(component.amount),
				})
			end
		elseif t == "bag" then
			View:bag(self.bag, 10, 10)
		else
			assert(false, "Unhandled component " .. t)
		end
	end
end

return M
