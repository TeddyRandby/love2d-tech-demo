local Shaders = require("util.shaders")
local Card = require("data.card")
local M = {}

love.graphics.setDefaultFilter("nearest", "nearest")
-- local CardSpritesheet = love.graphics.newImage("resources/CardSpritesheet.png")
local CardImage = love.graphics.newImage("resources/Card.png")
-- Because the card image isn't a spritesheet, we can do this
M.pixelw = CardImage:getPixelWidth()
M.pixelh = CardImage:getPixelHeight()

function M.getRealizedDim()
	return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
	return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
	return M.pixelw, M.pixelh
end

-- local CardBG = love.graphics.newQuad(CardImageWidth * 0, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardHL = love.graphics.newQuad(CardImageWidth * 1, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardRECRUIT = love.graphics.newQuad(CardImageWidth * 2, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardREFINE = love.graphics.newQuad(CardImageWidth * 3, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardDISCOVER = love.graphics.newQuad(CardImageWidth * 4, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardPILLAGE = love.graphics.newQuad(CardImageWidth * 5, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
-- local CardBD = love.graphics.newQuad(CardImageWidth * 6, 0, CardImageWidth, CardImageHeight, CardSpritesheet)

local meshargs = {
	{ 0, 0, 0, 0 }, -- top-left
	{ M.pixelw, 0, 1, 0 }, -- top-right
	{ M.pixelw, M.pixelh, 1, 1 }, -- bottom-right
	{ 0, M.pixelh, 0, 1 }, -- bottom-left
}

-- Define 4 mesh vertices in clockwise order: top-left, top-right, bottom-right, bottom-left
-- Draw the card as a mesh so that we can perform better operations on it!
local CardMesh = love.graphics.newMesh(meshargs, "fan", "static")
local CardMeshHL = love.graphics.newMesh(meshargs, "fan", "static")
CardMesh:setTexture(CardImage)

local function deform_verts(verts, card, x, y, w, h, depth)
	-- Deform one corner by pushing it inward
	if View:is_hovering(card) then
		local ox, oy = love.mouse.getPosition()

		local cx = x + w / 2
		local cy = y + h / 2

		local dx = (ox - cx) / (w / 2)
		local dy = (oy - cy) / (w / 2)

		local function push(x, y, fx, fy)
			return x + fx * depth * dx, y + fy * depth * dy
		end

		if dx < 0 and dy < 0 then -- top-left
			verts[1][1], verts[1][2] = push(verts[1][1], verts[1][2], -1, -1)
			verts[3][1], verts[3][2] = push(verts[3][1], verts[3][2], 1, 1)
		elseif dx > 0 and dy < 0 then -- top-right
			verts[2][1], verts[2][2] = push(verts[2][1], verts[2][2], -1, -1)
			verts[4][1], verts[4][2] = push(verts[4][1], verts[4][2], 1, 1)
		elseif dx > 0 and dy > 0 then -- bottom-right
			verts[3][1], verts[3][2] = push(verts[3][1], verts[3][2], -1, -1)
			verts[1][1], verts[1][2] = push(verts[1][1], verts[1][2], 1, 1)
		elseif dx < 0 and dy > 0 then -- bottom-left
			verts[4][1], verts[4][2] = push(verts[4][1], verts[4][2], -1, -1)
			verts[2][1], verts[2][2] = push(verts[2][1], verts[2][2], 1, 1)
		end
	end

	return verts
end

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
function M.draw(card, x, y, r)
	local w, h = M.getRealizedDim()

	local depth = 4
	local skew = depth / 100
	local FontHeight = love.graphics.getFont():getHeight()

	local sx, sy = UI.scale_xy()
	local fsy = View.normalize_y(View.getFontSize()) / FontHeight

	-- Update mesh vertices
	local verts = {
		{ 0, 0, 0, 0 },
		{ w, 0, 1, 0 },
		{ w, h, 1, 1 },
		{ 0, h, 0, 1 },
	}

	local cx, cy = w / 2, h / 2

	love.graphics.translate(x + cx, y + cy)
	love.graphics.rotate(r or 0)
	love.graphics.translate(-cx, -cy)

	if View:is_hovering(card) then
		love.graphics.setColor(1, 1, 1, 1)
	else
		love.graphics.setColor(28 / 255, 26 / 255, 48 / 255, 1)
	end

	deform_verts(verts, card, x, y, w, h, depth)

	CardMeshHL:setVertices(verts)
	CardMesh:setVertices(verts)

	Shaders.pixel_scanline(x, y, w, h, sx, sy, r or 0)

	love.graphics.draw(
		CardMeshHL,
		-UI.realize_x(UI.normalize_x(1)),
		-UI.realize_y(UI.normalize_y(1)),
		0,
		(M.pixelw + 2) / M.pixelw,
		(M.pixelh + 2) / M.pixelh
	)

	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(CardMesh)
	Shaders.reset()

	-- love.graphics.setColor(1, 1, 1)
	--
	--  local canvas = love.graphics.newCanvas(w, h)
	--  love.graphics.setCanvas(canvas)
	--  love.graphics.origin()
	--
	--  mesh_set_quad(w, h, CardBG, CardMesh, CardSpritesheet, function(vs)
	--    return deform_verts(vs, card, x, y, w, h, depth)
	--  end)
	--
	-- love.graphics.draw(CardMesh)
	--
	--  mesh_set_quad(w, h, CardHL, CardMesh, CardSpritesheet, function(vs)
	--    return deform_verts(vs, card, x, y, w, h, depth)
	--  end)
	--
	-- love.graphics.draw(CardMesh)
	--
	--  mesh_set_quad(w, h, CardBD, CardMesh, CardSpritesheet, function(vs)
	--    return deform_verts(vs, card, x, y, w, h, depth)
	--  end)
	--
	-- love.graphics.draw(CardMesh)
	--
	-- --  mesh_set_quad(w, h, CardDISCOVER, CardMesh, CardSpritesheet, function(vs)
	-- --    return deform_verts(vs, card, x, y, w, h, depth)
	-- --  end)
	-- --
	-- -- love.graphics.draw(CardMesh)
	--
	--  love.graphics.setCanvas()
	--  --re-rotate everything after moving to origin to draw to scanvas
	-- love.graphics.translate(x + cx, y + cy)
	-- love.graphics.rotate(r or 0)
	-- love.graphics.translate(-cx, -cy)
	--
	-- Shaders.pixel_scanline(x, y, w, h, sx, sy, r or 0)
	--  love.graphics.draw(canvas)
	-- Shaders.reset()

	if View:is_hovering(card) then
		local xshear, yshear = 0, 0
		local ox, oy = love.mouse.getPosition()

		local cx = x + w / 2
		local cy = y + h / 2

		local dx = (ox - cx) / (w / 2)
		local dy = (oy - cy) / (w / 2)

		if dx < 0 and dy < 0 then
			xshear = skew * dx
			yshear = skew * dy
		elseif dx < 0 and dy > 0 then
			xshear = skew * -dx * dy
			yshear = skew * dy
		elseif dx > 0 and dy < 0 then
			xshear = skew * dx
			yshear = skew * -dy * dx
		else
			xshear = skew * -dx
			yshear = skew * -dy
		end

		love.graphics.translate(ox - x, oy - y)

		-- Apply skew and scale
		love.graphics.shear(xshear, yshear)

		-- Move back so sprite is drawn in correct position
		love.graphics.translate(-(ox - x), -(oy - y))
	end

	love.graphics.printf(card.type, 10 * sx, 1 * sy, (30 * sx / fsy), "center", 0, fsy, fsy, nil, nil)
	love.graphics.printf(Card.describe(card), 8 * sx, 15 * sy, (34 * sx / fsy), "left", 0, fsy, fsy, nil, nil)
end

return M
