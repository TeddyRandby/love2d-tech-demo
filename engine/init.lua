---@class Engine
---@field rng love.RandomGenerator
---@field TokenTable Token[]
---@field TokenTypes Token[]
---@field CardTable Card[]
---@field CardTypes Card[]
---@field bag Token[]
---@field hand Card[]
local M = {
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
}

Card = require("data.card")

---@param n integer
---@param tab Token[]
function M:pull_into(n, tab)
	for _ = 1, n do
		local idx = self.rng:random(1, #self.TokenTable)
		table.insert(tab, self.TokenTable[idx])
	end
end

-- TODO: Fix this to not repeat.
---@param n integer
---@param tab Token[]
function M:peek_into(n, tab)
	for _ = 1, n do
		local idx = self.rng:random(1, #self.bag)
		table.insert(tab, self.bag[idx])
	end
end

---@param n integer
function M:pull(n)
	local results = {}

	self:pull_into(n, results)

	return results
end

---@param card Card
function M:play(card)
	---@type Token[]

	for _, op in ipairs(card.ops) do
		---@type Token[]
		local ts = {}

		for _, potential_microop in ipairs(op.microops) do
			---@type ActionMicroOp[]
			local final_microops = { potential_microop }

			if type(potential_microop) == "function" then
				final_microops = potential_microop(ts)
			end

			for _, microop in ipairs(final_microops) do
				local t = microop.type

				print("[MICROOP] " .. t)

				if t == "pull" then
					self:pull_into(microop.amount, ts)
				elseif t == "peek" then
					self:peek_into(microop.amount, ts)
				elseif t == "constant" then
					for _ = 1, microop.amount do
						table.insert(ts, microop.token)
					end
				elseif t == "filter" then
					local tmp = {}

					for _, v in ipairs(ts) do
						if microop.fun(v) then
							table.insert(tmp, v)
						end
					end

					ts = tmp
				elseif t == "choose" then
          -- TODO: USE UI, DON"T CHOOSE AT RANDOM
					local tmp = {}

					for _ = 1, microop.amount do
						local idx = self.rng:random(1, #ts)
            table.insert(tmp, ts[idx])
					end

					ts = tmp
				elseif t == "draft" then
          table.insert(self.bag, microop.token)
				elseif t == "discard" then
					-- TODO: Terrible solution!
					-- Store source on token somewhere.
					for _, v in ipairs(ts) do
						for i, b in ipairs(self.bag) do
							if b.type == v.type then
								table.remove(self.bag, i)
							end
						end
					end
				elseif t == "donate" then
					-- TODO: Terrible solution!
					-- Store source on token somewhere.
					-- Give away token somehow!
					for _, v in ipairs(ts) do
						for i, b in ipairs(self.bag) do
							if b.type == v.type then
								table.remove(self.bag, i)
							end
						end
					end
				else
					assert(false, "Unhandled micro op type")
				end
			end
		end
	end
end

function M:load()
	self.hand = {}
	self.pool = {}
	self.bag = {}

	self.TokenTable = {}
	self.CardTable = {}

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

	for i = 1, 5 do
		local n = self.rng:random(1, #self.CardTable)
		table.insert(self.hand, self.CardTable[n])
	end

	return self
end

function M:update() end

function M:draw()
	for i, v in ipairs(self.bag) do
		love.graphics.print(v.name, 100, 20 * i)
	end

	local cardw, cardh = Card.width(), Card.height()

	local x, y = 0, love.graphics.getHeight() - cardh - 10

	for _, v in ipairs(self.hand) do
		Card.draw(v, x, y)
		x = x + cardw + 10
	end
end

return M
