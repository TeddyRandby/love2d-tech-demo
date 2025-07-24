local M = {}

---@param m Move
---@param t Token
---@param s TokenState
function M.needs(m, t, s)
  if m.cost.state ~= s then
    return false
  end

  if type(m.cost.type) == "function" then
    return m.cost.type(t)
  else
    return m.cost.type == t
  end
end

return M
