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
---@param on_drag? fun(i: integer)
function M.hand(x, y, f, on_drag)
	if on_drag then
		---@type Component
		return function()
			local cardw = Card.width()
			local thisx = x

			for i, v in ipairs(f()) do
				if Engine:is_dragging(v) then
					local mousex, mousey = love.mouse.getPosition()
					View:card(v, mousex - Engine.dragging.ox, mousey - Engine.dragging.oy, {
						drag = function()
							on_drag(i)
						end,
					})
				else
					View:card(v, thisx, y, { drag = function() end })
				end
				thisx = thisx + cardw + 10
			end
		end
	else
		---@type Component
		return function()
			local cardw = Card.width()
			local thisx = x
			for _, v in ipairs(f()) do
				View:card(v, thisx, y)
				thisx = thisx + cardw + 10
			end
		end
	end
end

---@param text string
---@param f function
---@param x number
---@param y number
---@param w number
---@param h number
function M.button(text, f, x, y, w, h)
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
			local thisx = x

			View:button(x + 300, y, 50, 50, "confirm", function()
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
				local thisy = y

				if is_chosen then
					thisy = thisy + 20
				end

				View:token(v, thisx, thisy, {
					click = function()
						tokens[v] = not is_chosen
					end,
				})

				thisx = thisx + 10 + Card.width()
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
			local thisx = x

			for i, v in ipairs(cardpool) do
				View:card(v, thisx, y, {
					click = function()
						table.insert(Engine.player.hand, v)
						table.remove(cardpool, i)

						-- TODO: Add more intelligence than this
						-- Use the enemy.enemy.draft_stats.likes table
						table.sample(cardpool, 1, Engine.enemy.hand)

						if table.isempty(cardpool) then
							cardpool = nil
							Engine:transition("upgrading")
						end
					end,
				})

				thisx = thisx + 10 + Card.width()
			end
		else
			-- Will get drawn on the next frame
			cardpool = Engine:fish(10)
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
---@param field_f fun(): Token[]
---@param exhausted_f fun(): Token[]
---@param on_drag? fun(i: integer, v: Token)
function M.board(x, y, field_f, exhausted_f, on_drag)
	if on_drag then
		---@type Component
		return function()
			local tokenr = Token.radius()
			local tokenw = tokenr * 2

			local thisx = x + Token.radius()
			local thisy = y + Token.radius()

			for i, v in ipairs(field_f()) do
				if Engine:is_dragging(v) then
					local mousex, mousey = love.mouse.getPosition()
					View:token(v, mousex - Engine.dragging.ox, mousey - Engine.dragging.oy, {
						drag = function()
							on_drag(i, v)
						end,
					})
				else
					View:token(v, thisx, thisy, { drag = function() end })
				end

				thisx = thisx + tokenw + 10
			end

			thisx = x + 400
			for _, v in ipairs(exhausted_f()) do
				View:token(v, thisx, thisy)
				thisx = thisx + tokenw + 10
			end
		end
	else
		---@type Component
		return function()
			local tokenr = Token.radius()
			local tokenw = tokenr * 2

			local thisx = x + Token.radius()
			local thisy = y + Token.radius()

			for _, v in ipairs(field_f()) do
				View:token(v, thisx, thisy, { drag = function() end })
				thisx = thisx + tokenw + 10
			end

			thisx = x + 400
			for _, v in ipairs(exhausted_f()) do
				View:token(v, thisx, thisy)
				thisx = thisx + tokenw + 10
			end
		end
	end
end

return M
