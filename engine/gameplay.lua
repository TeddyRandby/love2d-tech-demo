local Move = require("data.move")
local Effect = require("data.effect")
local Token = require("data.token")

---@alias TokenState "bag" | "active" | "exhausted"

---@class GameplayData
---@field drawn integer
---@field power integer
---@field lives integer
---@field TokenTable Token[]
---@field CardTable Card[]
---@field MoveTable Move[]
---@field EffectTable Move[]
---@field event_handlers table<EffectCause, Effect[]>
---@field token_list Token[]
---@field token_states table<Token, TokenState>
---@field hand Card[]
---@field token_stack Token[][]
---@field token_microops ActionMicroOp[]
---@field choose_impl fun(self:GameplayData)
---@field moves MoveType[]
---@field player? Class
---@field enemy? Enemy
---@field __fire? fun(self: GameplayData, e: TokenEventType, t: Token)
---@field top? fun(self: GameplayData): Token[]
---@field pop? fun(self: GameplayData): Token[]
---@field push? fun(self: GameplayData, e: Token[])
---@field __tokensin? fun(self: GameplayData, s: TokenState): Token[]
---@field bag? fun(self: GameplayData): Token[]
---@field active? fun(self: GameplayData): Token[]
---@field exhausted? fun(self: GameplayData): Token[]
---@field isempty? fun(self: GameplayData): boolean
---@field hit? fun(self: GameplayData)
---@field reset_bag? fun(self: GameplayData)
---@field opponent? fun(self: GameplayData): GameplayData
---@field signature? fun(self: GameplayData): TokenType
---@field play? fun(self: GameplayData, i?: integer)
---@field __play? fun(self: GameplayData)
---@field peek_into? fun(self: GameplayData, n: integer, tab?: Token[]): Token[]
---@field peek? fun(self: GameplayData, n: integer): Token[]
---@field pull? fun(self: GameplayData, n: integer): Token[]
---@field pull_into? fun(self: GameplayData, n: integer, tab?: Token[]): Token[]
---@field fish? fun(self: GameplayData, n: integer, tab?: Card[]): Card[]
---@field levelup? fun(self: GameplayData, n: integer): Move[], Effect[]
---@field choose? fun(self: GameplayData)
---@field useful? fun(self: GameplayData, t: Token, s?: TokenState): boolean
---@field doable? fun(self: GameplayData, move: Move): boolean
---@field domove? fun(self: GameplayData, move: Move)
---@field domoves? fun(self: GameplayData, moves?: Move[])
---@field learn? fun(self: GameplayData, skill: Move | Effect)
---@field draw? fun(self: GameplayData, n: integer?)
---@field draft? fun(self: GameplayData, ts: Token[])
---@field exhaust? fun(self: GameplayData, ts: Token[])
---@field activate? fun(self: GameplayData, ts: Token[])
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

	function m:pull(n)
		return self:pull_into(n)
	end

	function m:pull_into(n, tab)
		-- Copy each sampled token so that they are unique game objects.
		return table.replacement_sample(self.TokenTable, n, tab, table.copy)
	end

	function m:opponent()
		if self.player then
			return Engine.enemy
		else
			return Engine.player
		end
	end

	function m:signature()
		if self.player then
			return self.player.signature
		else
			return self.enemy.signature
		end
	end

	--- Draw cards at random from the card table. Because the work 'draw' is already taken
	--- for drawing tokens from your bag during combat, the word 'fish' is used instead.
	--- This is inspired by the french translations of 'draw a card' in other card games.
	function m:fish(n, tab)
		-- We copy each sampled element so that they are unique game objects.
		return table.replacement_sample(self.CardTable, n, tab, table.copy)
	end

	function m:levelup(n)
		return table.replacement_sample(self.MoveTable, n, {}, table.copy),
			table.replacement_sample(self.EffectTable, n, {}, table.copy)
	end

	function m:hit()
		self.lives = self.lives - 1
	end

	function m:reset_bag()
		for _, v in ipairs(self.token_list) do
			self.token_states[v] = "bag"
		end

		assert(#self:bag() == #self.token_list)
		assert(#self:active() == 0)
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

	function m:active()
		return self:__tokensin("active")
	end

	function m:exhausted()
		return self:__tokensin("exhausted")
	end

	function m:isempty()
		return table.isempty(self:bag())
	end

	function m:__fire(e, t)
		local handlers = self.event_handlers[e]

		if handlers then
			for _, h in ipairs(handlers) do
				if h.active then
					if h.should then
						if type(h.should) ~= "function" or h.should(self, t) then
							print("[EFFECT] ", h.cause, h.type .. ": " .. t.type)
							h.effect(self, t)

              -- If the cause doesn't begin with opponent,
              -- Then we fire an opponent event.
              if not e:match("^opponent") then
                self:opponent():__fire("opponent_" .. e, t)
              end
						end
					end
				end
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

			Engine:log_tokenevent("draft", v, self)
		end

		for _, v in ipairs(ts) do
			self:__fire("draft", v)
		end
	end

	function m:exhaust(ts)
		for _, v in ipairs(ts) do
			self.token_states[v] = "exhausted"
			Engine:log_tokenevent("exhaust", v, self)
		end

		for _, v in ipairs(ts) do
			self:__fire("exhaust", v)
		end
	end

	function m:activate(ts)
		for _, v in ipairs(ts) do
			assert(self.token_states[v] == "exhausted")
			self.token_states[v] = "active"
			Engine:log_tokenevent("activate", v, self)
		end

		for _, v in ipairs(ts) do
			self:__fire("activate", v)
		end
	end

	--- Draw n tokens from the bag and move them into the playing field.
	function m:draw(n)
		n = n or self.drawn

		local drawn = table.sample(self:bag(), n)

		for _, v in ipairs(drawn) do
			assert(
				self.token_states[v] == "bag",
				"Expected token in bag, found: " .. v.type .. " in " .. self.token_states[v]
			)
			self.token_states[v] = "active"
			Engine:log_tokenevent("draw", v, self)
		end

		for _, v in ipairs(drawn) do
			self:__fire("draw", v)
		end
	end

	function m:discard(ts)
		for _, v in ipairs(ts) do

			for i, discarded in ipairs(self.token_list) do
				if discarded == v then
					table.remove(self.token_list, i)
					-- Early exit if we find the token
					goto found
				end
			end

			::found::
			self.token_states[v] = nil
			Engine:log_tokenevent("discard", v, self)
		end

		for _, v in ipairs(ts) do
			self:__fire("discard", v)
		end
	end

	function m:donate(ts, to)
		for _, donated in ipairs(ts) do
			for i, v in ipairs(self.token_list) do
				if donated == v then
					table.remove(self.token_list, i)
					-- Early exit if we find the token
					goto found
				end
			end

			::found::
			Engine:log_tokenevent("donate", donated, self)
			self.token_states[donated] = nil
		end

		for _, donated in ipairs(ts) do
			self:__fire("donate", donated)
		end

		to:draft(ts)
	end

	function m:doable(move)
		return Move.cost_is_met(move, self.token_list, self.token_states)
	end

	function m:domove(move)
		assert(self:doable(move))

		local could_pay_with = Move.matches_cost(move, self.token_list, self.token_states)
		assert(#could_pay_with >= move.cost.amount)

		Engine:log_moveevent(move, self)

		if move.cost.pay_by == "exhaust" then
			self:exhaust(table.take(could_pay_with, move.cost.amount))
		elseif move.cost.pay_by == "draft" then
			self:draft(table.take(could_pay_with, move.cost.amount))
		elseif move.cost.pay_by == "discard" then
			self:discard(table.take(could_pay_with, move.cost.amount))
		elseif move.cost.pay_by == "donate" then
			self:donate(table.take(could_pay_with, move.cost.amount), self:opponent())
		elseif move.cost.pay_by == "transmute" then
			self:discard(table.take(could_pay_with, move.cost.amount))

			self:draft(table.of(move.cost.amount, function()
				return Token.create("lint")
			end))
		else
			assert(false, "Unhandled move cost pay type: " .. move.cost.pay_by)
		end

		move.effect(self)
	end

	function m:learn(skill)
		if Move[skill.type] then
      table.insert(self.moves, skill.type)
		elseif Effect[skill.type] then
      ---@type Effect
      local eff = skill

      Effect.insert(self.event_handlers, eff)
		else
			assert(false, "Unknown skill " .. skill.type)
		end
	end

	function m:domoves(moves)
		moves = moves or Move.array_of(moves or self.moves)
		for _, move in ipairs(moves) do
			while self:doable(move) do
				self:domove(move)
			end
		end
	end

	function m:useful(t, s)
		local state = self.token_states[t]
		s = s or state

		-- A token we don't have or in the bag isn't useful
		if not state then
			return false
		end

		-- A token is only useful a we have a move
		-- available which requires it.
		return not not table.find(self.moves, function(move)
			local movedata = Move[move]
			return Move.needs(movedata, t, s)
		end)
	end

	function m:play(n)
		n = n or Engine.rng:random(#self.hand)

		if Engine.scene ~= "upgrading" or table.isempty(self.hand) then
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

		-- Log this card as played in the event log.
		Engine:log_cardevent(card, self)

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
				self:pull_into(microop.amount, self:top())
			elseif t == "peek" then
				self:peek_into(microop.amount, self:top())
			elseif t == "signature" then
				for _ = 1, microop.amount do
					table.insert(self:top(), Token.create(self:signature()))
				end
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

---@generic T: { type: string }
---@param srctable T[]
---@param freqtable table<T, integer>
---@return T[]
local function construct_droptable(srctable, freqtable)
	local dt = {}

	for _, v in ipairs(srctable) do
		local freq = freqtable[v.type]
		if freq then
			for _ = 1, freq do
				table.insert(dt, v)
			end
		end
	end

	return dt
end

---@param class Class
function M.player(class)
	return inherit({
		CardTable = construct_droptable(Engine.CardTypes, class.card_table),
		TokenTable = construct_droptable(Engine.TokenTypes, class.token_table),
		MoveTable = construct_droptable(Engine.MoveTypes, class.move_table),
		EffectTable = construct_droptable(Engine.EffectTypes, class.effect_table),
		power = 0,
		drawn = class.battle_stats.draw,
		lives = class.battle_stats.lives,
		hand = {},
		token_list = {},
		token_states = {},
		token_stack = {},
		token_microops = {},
		event_handlers = Effect.table_of(class.effects),
		moves = class.moves,
		choose_impl = function()
			return Engine:transition("choosing")
		end,
		player = class,
	})
end

---@param enemy Enemy
function M.enemy(enemy)
	return inherit({
		moves = enemy.moves,
		CardTable = construct_droptable(Engine.CardTypes, enemy.card_table),
		TokenTable = construct_droptable(Engine.TokenTypes, enemy.token_table),
		MoveTable = construct_droptable(Engine.MoveTypes, enemy.move_table),
		EffectTable = construct_droptable(Engine.EffectTypes, enemy.effect_table),
		drawn = enemy.battle_stats.draw,
		power = 0,
		lives = enemy.battle_stats.lives,
		hand = {},
		token_list = {},
		token_states = {},
		token_stack = {},
		token_microops = {},
		event_handlers = Effect.table_of(enemy.effects),
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
