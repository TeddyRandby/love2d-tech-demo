local M = {}

love.graphics.setDefaultFilter("nearest", "nearest")
local SkillSpritesheet = love.graphics.newImage("resources/MoveSpritesheet.png")

M.pixelw = 16
M.pixelh = 16

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
	return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

local SkillEMPTY = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, SkillSpritesheet)
local SkillHL = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, SkillSpritesheet)
local SkillBG = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, SkillSpritesheet)
local SkillBG2 = love.graphics.newQuad(M.pixelw * 3, 0, M.pixelw, M.pixelh, SkillSpritesheet)
local SkillBGHL = love.graphics.newQuad(M.pixelw * 4, 0, M.pixelw, M.pixelh, SkillSpritesheet)

---@param x integer
---@param y integer
function M.empty(x, y)
	local sx, sy = UI.scale_xy()

	love.graphics.translate(x, y)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(SkillSpritesheet, SkillEMPTY, 0, 0, 0, sx, sy)
end

---@param skill Move | Effect | nil
---@param x integer
---@param y integer
function M.draw(skill, x, y)
	local sx, sy = UI.scale_xy()

	love.graphics.translate(x, y)
	love.graphics.setColor(1, 1, 1, 1)

	if not skill then
		love.graphics.draw(SkillSpritesheet, SkillEMPTY, 0, 0, 0, sx, sy)
		return
	end

	if skill.cost then
		---@type Move
		local move = skill

		if Engine.player:doable(move) then
			-- Shaders.glow(Engine.time)
			love.graphics.draw(SkillSpritesheet, SkillBGHL, 0, 0, 0, sx, sy)
			-- Shaders.reset()
		end
	end

	-- Shaders.pixel_scanline(x, y, w, h, sx, sy, 0)
	love.graphics.draw(SkillSpritesheet, SkillBG, 0, 0, 0, sx, sy)
	love.graphics.draw(SkillSpritesheet, SkillHL, 0, 0, 0, sx, sy)
	-- Shaders.reset()
end

return M
