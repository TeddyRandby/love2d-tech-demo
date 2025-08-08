local M = {}

M.pixelw = 102
M.pixelh = 33

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
	return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

love.graphics.setDefaultFilter("nearest", "nearest")
local SkillBoxSpritesheet = love.graphics.newImage("resources/SkillBoxSpritesheet.png")

local SkillBoxBG = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, SkillBoxSpritesheet)
local SkillBoxMOVES = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, SkillBoxSpritesheet)
local SkillBoxEFFECTS = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, SkillBoxSpritesheet)
local SkillBoxSHOPEFFECTS = love.graphics.newQuad(M.pixelw * 3, 0, M.pixelw, M.pixelh, SkillBoxSpritesheet)
local SkillBoxSHOPMOVES = love.graphics.newQuad(M.pixelw * 4, 0, M.pixelw, M.pixelh, SkillBoxSpritesheet)

---@param x integer
---@param y integer
---@param label "moves" | "effects" | "shopmoves" | "shopeffects"
function M.draw(x, y, label)
	local sx, sy = UI.scale_xy()

	love.graphics.translate(x, y)

	love.graphics.setColor(1, 1, 1, 1)

	love.graphics.draw(SkillBoxSpritesheet, SkillBoxBG, 0, 0, 0, sx, sy)

	if label == "moves" then
		love.graphics.draw(SkillBoxSpritesheet, SkillBoxMOVES, 0, 0, 0, sx, sy)
	elseif label == "shopmoves" then
		love.graphics.draw(SkillBoxSpritesheet, SkillBoxSHOPMOVES, 0, 0, 0, sx, sy)
	elseif label == "effects" then
		love.graphics.draw(SkillBoxSpritesheet, SkillBoxEFFECTS, 0, 0, 0, sx, sy)
	elseif label == "shopeffects" then
		love.graphics.draw(SkillBoxSpritesheet, SkillBoxSHOPEFFECTS, 0, 0, 0, sx, sy)
	else
		assert(false, "Unhandled move box label: " .. label)
	end
end

return M
