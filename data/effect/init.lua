local M = {}

local EffectTypes = require("data.effect.types")

for _, v in ipairs(EffectTypes) do
  M[v.type] = v
end

---@param effects EffectType[]
---@return table<EffectCause, Effect>
function M.table_of(effects)
  ---@type table<EffectCause, Effect[]>
  local tmp = {}

  for _, v in ipairs(EffectTypes) do
    tmp[v.cause] = {}
  end

  for _, v in ipairs(effects) do
    ---@type Effect
    local eff = M[v]
    assert(eff ~= nil, "Missing effect " .. v)
    table.insert(tmp[eff.cause], eff)
  end

  return tmp
end

return M
