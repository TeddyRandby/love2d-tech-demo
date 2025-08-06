local M = {}

local EffectTypes = require("data.effect.types")

for _, v in ipairs(EffectTypes) do
  M[v.type] = v
end

---@param effects table<EffectCause, Effect[]>
---@param effect Effect
function M.insert(effects, effect)
  if not effects[effect.cause] then
    effects[effect.cause] = {}
  end

  table.insert(effects[effect.cause], effect)
end

---@param effects EffectType[]
---@return table<EffectCause, Effect[]>
function M.table_of(effects)
  ---@type table<EffectCause, Effect[]>
  local tmp = {}


  for _, v in ipairs(effects) do
    local eff = M[v]
    assert(eff ~= nil, "Missing effect " .. v)
    M.insert(tmp, eff)
  end

  return tmp
end

return M
