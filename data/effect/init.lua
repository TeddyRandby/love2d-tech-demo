local M = {}

local EffectTypes = require("data.effect.types")

for _, v in ipairs(EffectTypes) do
	M[v.type] = v
end

local function __insert(effects, cause, effect)
	if not effects[cause] then
		effects[cause] = {}
	end

	table.insert(effects[cause], effect)
end

---@param effects table<EffectCause, Effect[]>
---@param effect Effect
function M.insert(effects, effect)
	local cause = effect.cause

	if type(cause) == "table" then
		for _, c in ipairs(cause) do
			__insert(effects, c, effect)
		end
	else
		__insert(effects, cause, effect)
	end
end

---@param effects EffectType[]
---@return table<EffectCause, Effect[]>
function M.table_of(effects)
	---@type table<EffectCause, Effect[]>
	local tmp = {}

	for _, v in ipairs(effects) do
		local eff = M[v]
		assert(eff ~= nil, "Missing effect " .. v)
		M.insert(tmp, table.copy(eff))
	end

	return tmp
end

return M
