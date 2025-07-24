---@alias Component fun()

local M = {}

local Card = require("data.card")
local Token = require("data.token")

---@param x number
---@param y number
---@param f fun(): Token[]
function M.bag(x, y, f)
	---@type Component
	return function()
		View:bag(f(), x, y)
	end
end

---@param x number
---@param y number
---@param f fun(): Card[]
---@param card_ueh? fun(i: integer, v: Card): UserEventHandler
function M.hand(x, y, f, card_ueh)
	---@type Component
	return function()
		local thisx = View.normalize_x(x)
		local w = View.normalize_x(Card.width())

		for i, v in ipairs(f()) do
			View:card(v, thisx, y)

			if card_ueh then
				View:register(v, card_ueh(i, v))
			end

			thisx = thisx + w + 10
		end
	end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param text string
---@param f function
function M.button(x, y, w, h, text, f)
	---@type Component
	return function()
		View:button(x, y, w, h, text, f)
	end
end

---@param x number
---@param y number
---@param n number
function M.token_selector(x, y, n)
	---@type table<Token, boolean>?
	local tokens = nil

	---@type Component
	return function()
		if tokens then
			local thisx = View.normalize_x(x)
			local thisy = View.normalize_y(y)

			local tokenr = View.normalize_x(Token.radius())

			local totalw = #tokens * Token.radius() + (#tokens - 1) * 0.01

			View:button(totalw - 0.1, y, 0.1, 0.1, "confirm", function()
				---@type Token[]
				local chosen = {}

				---@type Token[]
				local not_chosen = {}

				for k, v in pairs(tokens) do
					if v then
						table.insert(chosen, k)
					else
						table.insert(not_chosen, k)
					end
				end

				tokens = nil

				Engine.player:push(chosen)
				Engine.player:push(not_chosen)

				Engine:transition("upgrading")
			end)

			for v, is_chosen in pairs(tokens) do
				if is_chosen then
					View:token(v, thisx, thisy + tokenr)
				else
					View:token(v, thisx, thisy)
				end

				View:register(v, {
					click = function()
						tokens[v] = not tokens[v]
					end,
				})

				thisx = thisx + tokenr * 2 + 10
			end
		else
			-- Will get drawn on the next frame
			tokens = {}
			for _, v in ipairs(Engine.player:pop()) do
				tokens[v] = false
			end
		end
	end
end

---@param x number
---@param y number
---@param n number
function M.card_selector(x, y, n)
	local cardpool = nil

	---@type Component
	return function()
		if cardpool then
			local thisx = View.normalize_x(x)
			local w = View.normalize_x(Card.width())

			for i, c in ipairs(cardpool) do
				View:card(c, thisx, y)

				View:register(c, {
					click = function()
						table.insert(Engine.player.hand, c)
						table.remove(cardpool, i)

						-- Unregister handlers for card when it is drawn.
						View:register(c)

						-- TODO: Add more intelligence than this
						-- Use the enemy.enemy.draft_stats.likes table
						table.sample(cardpool, 1, Engine.enemy.hand)
						View:register(Engine.enemy.hand[#Engine.enemy.hand])

						if table.isempty(cardpool) then
							cardpool = nil
							Engine:transition("upgrading")
						end
					end,
				})

				thisx = thisx + 10 + w
			end
		else
			-- Will get drawn on the next frame
			cardpool = Engine.player:fish(10)
		end
	end
end

---@param x number
---@param y number
function M.enemy(x, y)
	---@type Component
	return function()
		local enemy = Engine.enemy
		if enemy then
			View:text(
				enemy.enemy.type .. "(" .. Engine.enemy.lives .. "/" .. Engine.enemy.enemy.battle_stats.lives .. ")",
				x,
				y
			)
		end
	end
end

---@param x number
---@param y number
---@param active_f fun(): Token[]
---@param exhausted_f fun(): Token[]
---@param token_ueh? fun(i: integer, v: Token): UserEventHandler
function M.board(x, y, active_f, exhausted_f, token_ueh)
	---@type Component
	return function()
		local tokenr = View.normalize_x(Token.radius())
		local tokenw = tokenr * 2

		local thisx = View.normalize_x(x) + tokenr
		local thisy = View.normalize_y(y) + tokenr

		local active, exhausted = active_f(), exhausted_f()

		for i, v in ipairs(active) do
			View:token(v, thisx, thisy)
			View:register(v, token_ueh and token_ueh(i, v))

			thisx = thisx + tokenw + 10
		end

		thisx = thisx + tokenw + tokenw
		for i, v in ipairs(exhausted) do
			View:token(v, thisx, thisy)
			View:register(v, token_ueh and token_ueh(i, v))

			thisx = thisx + tokenw + 10
		end
	end
end

return M
