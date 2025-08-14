local M = {}

local SceneTypes = require("data.scene.types")

for _, v in ipairs(SceneTypes) do
	M[v.name] = v
end

function M.create(type)
  return table.copy(M[type])
end

return M
