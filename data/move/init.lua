local M = {}

local MoveTypes = require("data.move.types")

---@alias MoveEventType MoveType

for _, v in ipairs(MoveTypes) do
	M[v.type] = v
end

---@param types MoveType[]
function M.array_of(types)
	return table.map(types, function(t)
		return M[t]
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
---@param tokens Token[]
---@param token_states table<Token, TokenState>
function M.cost_is_met(m, tokens, token_states)
	return #M.matches_cost(m, tokens, token_states) >= m.cost.amount
end

return M
