---@alias Component fun()

local M = {}

local Card = require("data.card")
local Token = require("data.token")
local Icon = require("data.icon")

---@param x number
---@param y number
function M.history(x, y)
	---@type Component
	return function()
		local events = table.slice(Engine.event_history, -8)

		local thisx, thisy = x, y

		--TODO: Each history elements time should be a function
		--of how far it is from its destination.
		--We want all history elements to move at a constant rate.
		local time = 1

		for _, event in ipairs(events) do
			if event.truetype == "token" then
				if event.type == "draft" then
					View:icon({ "token", "draft" }, thisx, thisy, event, nil, 1, thisy, time)
				elseif event.type == "discard" then
					View:icon({ "token", "discard" }, thisx, thisy, event, nil, 1, thisy, time)
				elseif event.type == "donate" then
					View:icon({ "token", "donate" }, thisx, thisy, event, nil, 1, thisy, time)
				elseif event.type == "exhaust" then
					View:icon({ "token", "exhaust" }, thisx, thisy, event, nil, 1, thisy, time)
				elseif event.type == "draw" then
					View:icon({ "token", "draw" }, thisx, thisy, event, nil, 1, thisy, time)
				elseif event.type == "activate" then
					View:icon({ "token", "draw" }, thisx, thisy, event, nil, 1, thisy, time)
				else
					assert(false, "Unhandled token type: " .. event.type)
				end
			elseif event.truetype == "card" then
				View:icon({ "card" }, thisx, thisy, event, nil, 1, thisy, time)
			elseif event.truetype == "move" then
				View:icon(event.target.icon, thisx, thisy, event, nil, 1, thisy, time)
			else
				assert(false, "Unhandled event type")
			end

			thisx = thisx + Icon.width() + 0.01
		end
	end
end

---@param x number
---@param y number
---@param prefix string
---@param f fun(): Token[]
function M.bag(x, y, prefix, f)
	---@type Component
	return function()
		local ts = f()

		local grouped = table.group(ts, function(t)
			return t.type
		end)

		local thisy = y
		for _, ttype in ipairs(Engine.TokenTypes) do
			local id = prefix .. ttype.type
			local v = grouped[ttype.type] or {}

			if #v > 0 then
				View:bag(v, id, x, thisy, 0, thisy)

				local _, hovering_at_all = View:is_hovering(id)

				if hovering_at_all then
					local body = #v .. " " .. ttype.type .. " tokens."
          --- Dont like this hack
					if prefix == "Enemy" then
						View:details(body, prefix .. body, x - 0.2, thisy)
					else
						View:details(body, prefix .. body, x + 0.1, thisy)
					end
				end

				-- TODO: If our y coordinate wraps over one, we have to fix that
				-- and wrap properly.
				for _, token in ipairs(v) do
					View:token(
						token,
						x + 4 * (0.06 / 16),
						thisy + 3 * (0.06 * (love.graphics.getWidth() / love.graphics.getHeight()) / 16),
						0.5,
						0,
						0.5
					)
				end
			end

			thisy = thisy + 0.08
		end
	end
end

local function getSpread(n)
	local minSpread = math.rad(5)
	local maxSpread = math.rad(30)
	return minSpread + (maxSpread - minSpread) * ((n - 1) / 4)
end

---@param x number
---@param y number
---@param f fun(): Card[]
---@param card_ueh? fun(i: integer, v: Card): UserEventHandler
function M.hand(x, y, f, card_ueh)
	---@type Component
	return function()
		local handx = View.normalize_x(x)
		local handy = View.normalize_y(y)

		local w = View.normalize_x(Card.width())
		local h = View.normalize_y(Card.height())

		local cards = f()

		local n = #cards
		local spread = getSpread(n)
		local spacing = -(h / 5)

		local anglestep = n == 1 and 0 or spread / math.max(n - 1, 1)
		local startAngle = -spread / 2

		local detail = nil

		for i, v in ipairs(cards) do
			local angle = startAngle + (i - 1) * anglestep

			-- Dip based on rotation: more rotated cards are lower
			local dip = math.pow(angle, 2) * h * 2

			local thisx = handx + (spacing * (i - 1)) + (w * (i - 1))
			local thisy = handy + dip

			if View:is_hovering(v) then
				thisy = thisy - h / 2 - dip
				angle = 0

				local pos = View:post(v)
				if pos and pos.y == thisy and not View:is_dragging(v) then
					local details_x = thisx + w + View.normalize_x(0.02)

					if thisx > View.normalize_x(0.5) then
						details_x = thisx - View.normalize_x(0.22)
					end

					detail = function()
						View:details(Card.describe_long(v), tostring(v) .. "hand", details_x, thisy)
					end
				end
			end

			View:card(v, thisx, thisy, angle, nil, nil, 0.4)

			if card_ueh then
				View:register(v, card_ueh(i, v))
			end
		end

		if detail then
			detail()
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
	local target = { w, h, text = text }
	---@type Component
	return function()
		View:button(x, y, target, f)
	end
end

---@param x number
---@param y number
function M.token_selector(x, y)
	---@type table<Token, boolean>?
	local tokens = nil

	---@type Token[]?
	local tokenlist = nil

	local btndata = { 0.1, 0.1, text = "confirm" }

	---@type Component
	return function()
		if tokens and tokenlist then
			local tokenr = View.normalize_x(Token.radius())

			View:button(x - 0.05, y + Token.radius() * 2 * 4 - 0.05, btndata, function()
				---@type Token[]
				local chosen = {}

				---@type Token[]
				local not_chosen = {}

				for k, v in pairs(tokens) do
					View:register(v)
					if v then
						table.insert(chosen, k)
					else
						table.insert(not_chosen, k)
					end
				end

				tokens = nil
				tokenlist = nil

				Engine.player:push(chosen)
				Engine.player:push(not_chosen)

				Engine:transition("upgrading")
			end)

			local thisx = View.normalize_x(x)
			local thisy = View.normalize_y(y) - tokenr
			local n = #tokenlist

			thisx = thisx - (n * tokenr * 2) - ((n - 1) * 5)

			local detail = nil

			for v, is_chosen in pairs(tokens) do
				if is_chosen then
					View:token(v, thisx, thisy - tokenr, 0.5, 0, 0.5, 2)
				else
					View:token(v, thisx, thisy, 0.5, 0, 0.5, 2)
				end

				if View:is_hovering(v) then
					local details_x = thisx + tokenr * 4 + View.normalize_x(0.02)

					if thisx > View.normalize_x(0.5) then
						details_x = thisx - View.normalize_x(0.22)
					end

					detail = function()
						View:details(v.desc, tostring(v) .. "hand", details_x, thisy)
					end
				end

				View:register(v, {
					click = function()
						View:cancel_tween(v)
						tokens[v] = not tokens[v]
					end,
				})

				thisx = thisx + tokenr * 4 + 10
			end

			if detail then
				detail()
			end
		else
			-- Will get drawn on the next frame
			tokens = {}
			tokenlist = Engine.player:pop()
			for _, v in ipairs(tokenlist) do
				tokens[v] = false
			end
		end
	end
end

---@param x number
---@param y number
function M.card_selector(x, y)
	local cardpool = nil
	local chosen = nil

	---@type Component
	return function()
		if cardpool then
			local thisx = View.normalize_x(x)
			local w = View.normalize_x(Card.width())

			local left, right = cardpool[1], cardpool[2]

			if chosen and View:post(chosen) and View:post(chosen).tween then
				return
			end
			chosen = nil

			assert(left ~= nil)
			assert(right ~= nil)

			---@param a Card
			---@param b Card
			---@param position integer
			---@param details_position integer
			local function drawcard(a, b, position, details_position)
				if View:is_hovering(a) then
					local hover_r = 0.03
					if love.mouse.getX() - position < View.normalize_x(Card.width()) / 2 then
						hover_r = -hover_r
					end
					View:card(a, position, y, hover_r, position, 0, 0.5)
					View:details(Card.describe_long(a), tostring(a) .. "selector", details_position, y)
				else
					View:card(a, position, y, nil, position, 0, 0.5)
				end

				View:register(a, {
					click = function()
						chosen = a

						table.insert(Engine.player.hand, a)

						table.insert(Engine.enemy.hand, b)

						-- Unregister handlers for cards when it is drawn.
						View:register(a)
						View:register(b)

						-- Shift out our two chosen cards
						table.shift(cardpool)
						table.shift(cardpool)

						if table.isempty(cardpool) then
							cardpool = nil
							Engine:transition("upgrading")
						end
					end,
				})
			end

			drawcard(left, right, thisx, math.max(thisx - View.normalize_x(0.22), 0))
			drawcard(right, left, thisx + View.normalize_x(0.03) + w, thisx + View.normalize_x(Card.width() * 2 + 0.05))
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
				enemy.enemy.type
					.. "("
					.. Engine.enemy.lives
					.. "/"
					.. Engine.enemy.enemy.battle_stats.lives
					.. ")"
					.. ". Power: "
					.. Engine.enemy.power,
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
	local token_types = require("data.token.types")

	local active_slot_data = {}
	local exhausted_slot_data = {}

	for _, token_type in ipairs(token_types) do
		active_slot_data[token_type.type] = { type = token_type.type, amt = 0 }
		exhausted_slot_data[token_type.type] = { type = token_type.type, amt = 0 }
	end

	---@type Component
	return function()
		local w, h = View.normalize_xy(0.16, 0.04)

		local active, exhausted = active_f(), exhausted_f()

		local thisx = View.normalize_x(x)
		local thisy = View.normalize_y(y)

		local sloty = thisy

		for i, token_type in ipairs(token_types) do
			local active_of_type = table.filter(active, function(t)
				return t.type == token_type.type
			end)

			local exhausted_of_type = table.filter(exhausted, function(t)
				return t.type == token_type.type
			end)

			active_slot_data[token_type.type].amt = #active_of_type
			exhausted_slot_data[token_type.type].amt = #exhausted_of_type

			if #active_of_type > 0 then
				View:boardslot(active_slot_data[token_type.type], thisx, sloty, nil, 0, sloty, 0.2 + i * 0.1)
			end

			if #exhausted_of_type > 0 then
				View:boardslot(exhausted_slot_data[token_type.type], thisx + w, sloty, nil, 0, sloty, 0.2 + i * 0.1)
			end

			if #active_of_type > 0 or #exhausted_of_type > 0 then
				sloty = sloty + h
			end
		end

		local tokenr = View.normalize_x(Token.radius())
		local pd = View.normalize_x(4)

		local tokx = thisx
		local toky = thisy + h * #token_types
		for i, v in ipairs(active) do
			View:token(v, tokx + (i - 1) * pd, toky)
		end

		toky = toky + tokenr * 2 + pd * 2
		for i, v in ipairs(exhausted) do
			View:token(v, tokx + (i - 1) * pd, toky)
		end
	end
end

return M
