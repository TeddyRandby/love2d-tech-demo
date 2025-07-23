---@alias Component fun()

local M = {}

local Card = require("data.card")
local Token = require("data.token")

---@param x number
---@param y number
function M.bag(x, y)
	---@type Component
	return function()
		View:bag(Engine.bag, x, y)
	end
end

---@param x number
---@param y number
function M.hand(x, y)
	---@type Component
	return function()
		local cardw = Card.width()
		local thisx = x

		for i, v in ipairs(Engine.hand) do
			if Engine:is_dragging(v) then
				local mousex, mousey = love.mouse.getPosition()
				View:card(v, mousex - Engine.dragging.ox, mousey - Engine.dragging.oy, {
					drag = function()
						Engine:play(i)
					end,
				})
			else
				View:card(v, thisx, y, { drag = function() end })
			end
			thisx = thisx + cardw + 10
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

				Engine:push(chosen)
				Engine:push(not_chosen)

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
			for _, v in ipairs(Engine:pop()) do
				tokens[v] = false
			end
		end
	end
end

---@param x number
---@param y number
---@param n number
function M.card_selector(x, y, n)
	local component_data = nil
	---@type Component
	return function()
		if component_data then
			---@type Card[]
			local cards = component_data.cards
			assert(cards ~= nil)

			local thisx = x

			for _, v in ipairs(cards) do
				View:card(v, thisx, y, {
					click = function()
						table.insert(Engine.hand, v)

						if #Engine.hand >= 5 then
							Engine:transition("upgrading")
						end

						component_data = nil
					end,
				})

				thisx = thisx + 10 + Card.width()
			end
		else
			-- Will get drawn on the next frame
			component_data = {
				cards = Engine:fish(n),
			}
		end
	end
end

---@param x number
---@param y number
function M.board(x, y)
	---@type Component
	return function()
		local tokenr = Token.radius()
		local tokenw = tokenr * 2

		local thisx = x + Token.radius()
		local thisy = y + Token.radius()

		for i, v in ipairs(Engine.field) do
			if Engine:is_dragging(v) then
				local mousex, mousey = love.mouse.getPosition()
				View:token(v, mousex - Engine.dragging.ox, mousey - Engine.dragging.oy, {
					drag = function()
						Engine:exhaust(i)
					end,
				})
			else
				View:token(v, thisx, thisy, { drag = function() end })
			end
			thisx = thisx + tokenw + 10
		end

		thisx = x + 400
		for _, v in ipairs(Engine.exhausted) do
			View:token(v, thisx, thisy)
			thisx = thisx + tokenw + 10
		end
	end
end

return M
