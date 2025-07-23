---@class TokenEventHandler
---@field name string
---@field effect fun(self: GameplayData, t: Token)
---@field valid fun(self: GameplayData, t: Token): boolean
---@field active boolean

---@alias TokenEventType "draft" | "discard" | "donate" | "draw" | "exhaust"

local Token = require("data.token")

---@alias TokenState "bag" | "field" | "exhausted"

---@class GameplayData
---@field drawn integer
---@field power integer
---@field lives integer
---@field token_event_handlers table<TokenEventType, TokenEventHandler[]>
---@field token_list Token[]
---@field token_states table<Token, TokenState>
---@field hand Card[]
---@field token_stack Token[][]
---@field token_microops ActionMicroOp[]
---@field choose_impl fun(self:GameplayData)
---@field player? BattleStats
---@field enemy? Enemy
---@field __wouldfire? fun(self: GameplayData, e: TokenEventType, t: Token): TokenEventHandler[]
---@field __fire? fun(self: GameplayData, e: TokenEventType, t: Token)
---@field top? fun(self: GameplayData): Token[]
---@field pop? fun(self: GameplayData): Token[]
---@field push? fun(self: GameplayData, e: Token[])
---@field __tokensin? fun(self: GameplayData, s: TokenState): Token[]
---@field bag? fun(self: GameplayData): Token[]
---@field field? fun(self: GameplayData): Token[]
---@field exhausted? fun(self: GameplayData): Token[]
---@field isempty? fun(self: GameplayData): boolean
---@field hit? fun(self: GameplayData)
---@field reset_bag? fun(self: GameplayData)
---@field play? fun(self: GameplayData, i?: integer)
---@field __play? fun(self: GameplayData)
---@field peek_into? fun(self: GameplayData, n: integer, tab?: Token[]): Token[]
---@field peek? fun(self: GameplayData, n: integer): Token[]
---@field choose? fun(self: GameplayData)
---@field draw? fun(self: GameplayData, n: integer?)
---@field draft? fun(self: GameplayData, ts: Token[])
---@field exhaust? fun(self: GameplayData, ts: Token[])
---@field discard? fun(self: GameplayData, t: Token[])
---@field donate? fun(self: GameplayData, t: Token[], o: GameplayData)

local M = {}

---@param m GameplayData
local function inherit(m)
	function m:top()
		return self.token_stack[#self.token_stack]
	end

	function m:pop()
		return table.remove(self.token_stack, #self.token_stack)
	end

	function m:push(e)
		table.insert(self.token_stack, e)
	end

	function m:peek_into(n, tab)
		return table.sample(self.token_list, n, tab)
	end

	function m:peek(n)
		return self:peek_into(n)
	end

	function m:hit()
		self.lives = self.lives - 1
	end

	function m:reset_bag()
		for _, v in ipairs(self.token_list) do
			self.token_states[v] = "bag"
		end

		assert(#self:bag() == #self.token_list)
		assert(#self:field() == 0)
		assert(#self:exhausted() == 0)
	end

	function m:__tokensin(state)
		---@type Token[]
		local tmp = {}

		for _, v in ipairs(self.token_list) do
			if self.token_states[v] == state then
				table.insert(tmp, v)
			end
		end

		return tmp
	end

	function m:bag()
		return self:__tokensin("bag")
	end

	function m:field()
		return self:__tokensin("field")
	end

	function m:exhausted()
		return self:__tokensin("exhausted")
	end

	function m:isempty()
		return table.isempty(self:bag())
	end

	function m:__wouldfire(e, t)
		local handlers = self.token_event_handlers[e]
		if not handlers then
			return {}
		end

		return table.filter(handlers, function(h)
			return h.active and h.valid(self, t)
		end)
	end

	function m:__fire(e, t)
		local handlers = self:__wouldfire(e, t)

		for _, h in ipairs(handlers) do
			if h.active then
				h.effect(self, t)
				print("[EFFECT] " .. h.name .. ": " .. t.type)
			end
		end
	end

	function m:choose()
		self:choose_impl()
	end

	function m:draft(ts)
		for _, v in ipairs(ts) do
			table.insert(self.token_list, v)
			self.token_states[v] = "bag"
		end

		for _, v in ipairs(ts) do
			self:__fire("draft", v)
		end
	end

	function m:exhaust(ts)
		for _, v in ipairs(ts) do
			self.token_states[v] = "exhausted"
		end

		for _, v in ipairs(ts) do
			self:__fire("exhaust", v)
		end
	end

	--- Draw n tokens from the bag and move them into the playing field.
	function m:draw(n)
		n = n or self.drawn

		local drawn = table.sample(self:bag(), n)

		for _, v in ipairs(drawn) do
			assert(self.token_states[v] == "bag")
			self.token_states[v] = "field"
		end

		for _, v in ipairs(drawn) do
			self:__fire("draw", v)
		end
	end

	function m:discard(ts)
		for _, discarded in ipairs(ts) do
			self.token_states[discarded] = nil
		end

		for _, discarded in ipairs(ts) do
			self:__fire("discard", discarded)
		end
	end

	function m:donate(ts, to)
		for _, donated in ipairs(ts) do
			self.token_states[donated] = nil
		end

		for _, donated in ipairs(ts) do
			self:__fire("donate", donated)
		end

		to:draft(ts)
	end

	function m:play(n)
		n = n or Engine.rng:random(#self.hand)

		if Engine.scene ~= "upgrading" then
			return
		end

		---@type Card
		local card = table.remove(self.hand, n)

		assert(#self.token_stack == 0)
		-- Push an empty table onto the play stack for each card operation we intend to do.
		for _ = 1, #card.ops do
			self:push({})
		end

		self.token_microops = table.flatmap(card.ops, function(c)
			return c.microops
		end)

		-- Now we can play
		self:__play()
	end

	function m:__play()
		if table.isempty(self.token_microops) then
			return
		end

		repeat
			local microop = table.shift(self.token_microops)
			assert(microop ~= nil)

			local t = microop.type

			print("[MICROOP] " .. t)

			if t == "pull" then
				Engine:pull_into(microop.amount, self:top())
			elseif t == "peek" then
				self:peek_into(microop.amount, self:top())
			elseif t == "constant" then
				for _ = 1, microop.amount do
					table.insert(self:top(), table.copy(microop.token))
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
				self:choose()
			elseif t == "draft" then
				self:draft(self:pop())
			elseif t == "discard" then
				self:discard(self:pop())
			elseif t == "donate" then
				-- If we are the player (self.player != nil) then donate to the enemy, and vice-versa.
				self:donate(self:pop(), self.player and Engine.enemy or Engine.player)
			else
				assert(false, "Unhandled micro op type")
			end

		-- Repeat until we run out of micro ops, or the scene changed.
		until table.isempty(self.token_microops) or Engine.scene ~= "upgrading"
	end

	return m
end

---@type table<TokenEventType, TokenEventHandler[]>
local universal_token_handlers = {
	draw = {
		{
			name = "bomb_explode",
			effect = function(self, token)
				local minion = table.find(self:field(), Token.isMinion)

				if minion then
					self:discard({ minion })
				end

				self:discard({ token })
			end,
			valid = function(self, token)
				return token.type == "bomb"
			end,
			active = true,
		},
	},
	exhaust = {
		{
			name = "minion_attack",
			effect = function(self, token)
				self.power = self.power + 1
			end,
			valid = function(self, token)
				return Token.isMinion(token)
			end,
			active = true,
		},
	},
}

---@param stats BattleStats
function M.player(stats)
	return inherit({
		drawn = stats.draw,
		power = 0,
		lives = stats.lives,
		hand = {},
		token_list = {},
		token_states = {},
		token_stack = {},
		token_microops = {},
		token_event_handlers = universal_token_handlers,
		choose_impl = function()
			return Engine:transition("choosing")
		end,
		player = stats,
	})
end

---@param enemy Enemy
function M.enemy(enemy)
	return inherit({
		drawn = enemy.battle_stats.draw,
		power = 0,
		lives = enemy.battle_stats.lives,
		hand = {},
		token_list = {},
		token_states = {},
		token_stack = {},
		token_microops = {},
		token_event_handlers = universal_token_handlers,
		choose_impl = function(self)
			local not_chosen, chosen = self:pop(), {}

			table.sample(not_chosen, 1, chosen)

			self:push(chosen)
			self:push(not_chosen)
		end,
		enemy = enemy,
	})
end

return M
