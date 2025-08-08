local M = {}

local MoveTypes = require("data.move.types")

for _, v in ipairs(MoveTypes) do
	M[v.type] = v
end

---@param move Move
function M.describe(move)
	return move.type .. "\n\n" .. move.cost.amount .. " " .. tostring(move.cost.type) .. ":\n\n" .. move.desc
end

---@param types MoveType[]
function M.array_of(types)
	return table.map(types, function(t)
		return table.copy(M[t])
	end)
end

---@param m Move
---@param t Token
---@param s? TokenState
function M.needs(m, t, s)
	s = s or Engine.player.token_states[t]

	if m.cost.state ~= s then
		return false
	end

	if type(m.cost.type) == "function" then
		return m.cost.type(t)
	else
		return m.cost.type == t.type
	end
end

---@param m Move
---@param token_states table<Token, TokenState>
function M.cost_matcher(m, token_states)
	if type(m.cost.type) == "function" then
		return function(t)
			return m.cost.type(t) and token_states[t] == m.cost.state
		end
	else
		return function(t)
			return t.type == m.cost.type and token_states[t] == m.cost.state
		end
	end
end

---@param m Move
---@param tokens Token[]
---@param token_states table<Token, TokenState>
function M.matches_cost(m, tokens, token_states)
	return table.filter(tokens, M.cost_matcher(m, token_states))
end

---@param m Move
---@param g GameplayData
function M.cost_is_met(m, g)
	if m.cost.type == "gold" then
		return g.gold >= m.cost.amount
	elseif m.cost.type == "manapool" then
		return g.mana >= m.cost.amount
	else
		return #M.matches_cost(m, g.token_list, g.token_states) >= m.cost.amount
	end
end

return M
