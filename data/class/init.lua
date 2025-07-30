local M = {}

local ClassTypes = require "data.class.types"

for _, v in ipairs(ClassTypes) do
  M[v.type] = v
end

return M
