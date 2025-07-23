---@alias Draggable Card | Token

---@class Dragging
---@field ox integer
---@field oy integer
---@field target Draggable

---@class Engine
---@field scene SceneType
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
---@field player_stats Stats
---@field enemy Enemy?
---@field play_token_stack Token[][]
---@field play_token_microops ActionMicroOp[]
local M = {
	scene = "main",
	hand = {},
	bag = {},
	field = {},
	exhausted = {},

	TokenTable = {},
	CardTable = {},
	EnemyTable = {},

	SceneTypes = require("data.scene.types"),
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
	EnemyTypes = require("data.enemies.types"),

	enemy = nil,
	player_stats = { draw = 3 },

	play_token_stack = {},
	play_token_microops = {},
}

function M:top()
	---@type Token[]
	return self.play_token_stack[#self.play_token_stack]
end

function M:pop()
	---@type Token[]
	return table.remove(self.play_token_stack, #self.play_token_stack)
end

---@param e Token[]
function M:push(e)
	table.insert(self.play_token_stack, e)
end

---@param scene SceneType
function M:transition(scene)
	self.scene = scene

	if scene == "upgrading" then
    -- This will complete any pending micro-ops.
    -- As we may have yielded in the middle of playing a card
    -- (For example, to choose a token as an effect of playing a card)
		self:doplay()
  elseif scene == "gameover" then
    self.bag = {}
    self.field = {}
    self.exhausted = {}
	end
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
	self:draw(self.player_stats.draw)
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
  if #self.bag < n then
    return Engine:transition "gameover"
  end

	table.sample(self.bag, n, self.field, table.copy)
end

--- Sample a random enemy
function M:encounter()
	local enemy = table.unpack(table.replacement_sample(self.EnemyTable, 1))
	self.enemy = enemy
end

---@param n integer
---@param tab? Token[]
---@return Token[]
function M:pull_into(n, tab)
	return table.replacement_sample(self.TokenTable, n, tab)
end

---@param n integer
---@param tab? Token[]
---@return Token[]
function M:peek_into(n, tab)
	return table.sample(self.bag, n, tab)
end

--@param n integer
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
function M:exhaust(n)
	assert(n <= #self.field)
	local token = table.remove(self.field, n)
	self:doexhaust(token)
end

---@param token Token
function M:doexhaust(token)
	table.insert(self.exhausted, token)
end

---@param n integer
function M:play(n)
	assert(n <= #self.hand)

	---@type Card
	local card = table.remove(self.hand, n)

	assert(#self.play_token_stack == 0)
	-- Push an empty table onto the play stack for each card operation we intend to do.
	for _ = 1, #card.ops do
		self:push({})
	end

	self.play_token_microops = table.flatmap(card.ops, function(c)
		return c.microops
	end)

	-- Now we can play
	self:doplay()
end

function M:doplay()
	if table.isempty(self.play_token_microops) then
		return
	end

	repeat
		local microop = table.shift(self.play_token_microops)
		assert(microop ~= nil)

		local t = microop.type

		print("[MICROOP] " .. t)

		if t == "pull" then
			self:pull_into(microop.amount, self:top())
		elseif t == "peek" then
			self:peek_into(microop.amount, self:top())
		elseif t == "constant" then
			for _ = 1, microop.amount do
				table.insert(self:top(), microop.token)
			end
		elseif t == "filter" then
			local tmp = {}

			for _, v in ipairs(self:pop()) do
				if microop.fun(v) then
					table.insert(tmp, v)
				end
			end

			self:push(tmp)
		elseif t == "choose" then
			self:transition("choosing")
			return
		-- local not_chosen, chosen = self:pop(), {}
		--
		-- self:push(chosen)
		-- self:push(not_chosen)
		elseif t == "draft" then
			self:draft(self:pop())
		elseif t == "discard" then
			-- TODO: Terrible solution!
			-- Store source on token somewhere.
			for _, v in ipairs(self:pop()) do
				for i, b in ipairs(self.bag) do
					if b.type == v.type then
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
			for _, v in ipairs(self:pop()) do
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
	until table.isempty(self.play_token_microops)
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

	for _, v in ipairs(self.EnemyTypes) do
		for _ = 1, 1 do
			table.insert(self.EnemyTable, v)
		end
	end

	return self
end

function M:update()
	local scene = self.SceneTypes[self.scene]
	assert(scene ~= nil)

	for _, component in ipairs(scene.layout) do
		component()
	end
end

return M
