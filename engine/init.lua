---@alias Draggable Card

---@class Dragging
---@field ox integer
---@field oy integer
---@field target Draggable

---@class Engine
---@field rng love.RandomGenerator
---@field TokenTable Token[]
---@field TokenTypes Token[]
---@field CardTable Card[]
---@field CardTypes Card[]
---@field bag Token[]
---@field hand Card[]
---@field dragging Dragging?
local M = {
	dragging_target = nil,
	hand = {},
	pool = {},
	bag = {},
	TokenTable = {},
	CardTable = {},
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
}

local Card = require("data.card")

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
	self:activate(card)
end

---@param card Card
function M:activate(card)
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
								print("\t DONATE " .. v.name)
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

  self:fish(5, self.hand)

  for _, v in ipairs(self.hand) do
    print(v)
  end

	return self
end

function M:update()
	local cardw, cardh = Card.width(), Card.height()
	local x, y = 0, love.graphics.getHeight() - cardh - 10

	for _, v in ipairs(self.hand) do
		if self:is_dragging(v) then
      local mousex, mousey = love.mouse.getPosition()
			View:card(v, mousex - self.dragging.ox, mousey - self.dragging.oy)
		else
			View:card(v, x, y)
		end
		x = x + cardw + 10
	end
end

function M:draw()
	for i, v in ipairs(self.bag) do
		love.graphics.print(v.name, 100, 20 * i)
	end
end

return M
