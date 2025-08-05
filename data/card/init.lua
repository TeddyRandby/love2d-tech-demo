local M = {}
local Shaders = require("util.shaders")

---@param card Card
function M.describe(card)
	local str = ""

	for _, op in ipairs(card.ops) do
		local desc = op.name

		if type(desc) == "function" then
			desc = desc(op)
		end

		str = str .. desc .. "\n"
	end

	return str
end

---@param card Card
function M.describe_long(card)
	local str = ""

	for _, op in ipairs(card.ops) do
		local desc = op.desc

		if type(desc) == "function" then
			desc = desc(op)
		end

		str = str .. desc .. "\n"
	end

	return str
end

function M.width()
	return 0.2
end

function M.height()
	local ratio = love.graphics.getWidth() / love.graphics.getHeight()
	return M.width() * 1.5 * ratio
end

love.graphics.setDefaultFilter("nearest", "nearest")
local CardSpritesheet = love.graphics.newImage("resources/CardSpritesheet.png")
local CardImage = love.graphics.newImage("resources/Card.png")
local CardImageWidth = 48
local CardImageHeight = 64

local CardBG = love.graphics.newQuad(CardImageWidth * 0, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardHL = love.graphics.newQuad(CardImageWidth * 1, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardRECRUIT = love.graphics.newQuad(CardImageWidth * 2, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardREFINE = love.graphics.newQuad(CardImageWidth * 3, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardDISCOVER = love.graphics.newQuad(CardImageWidth * 4, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardPILLAGE = love.graphics.newQuad(CardImageWidth * 5, 0, CardImageWidth, CardImageHeight, CardSpritesheet)
local CardBD = love.graphics.newQuad(CardImageWidth * 6, 0, CardImageWidth, CardImageHeight, CardSpritesheet)

local FontHeight = love.graphics.getFont():getHeight()

local meshargs = {
	{ 0, 0, 0, 0 }, -- top-left
	{ CardImageWidth, 0, 1, 0 }, -- top-right
	{ CardImageWidth, CardImageHeight, 1, 1 }, -- bottom-right
	{ 0, CardImageHeight, 0, 1 }, -- bottom-left
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

local function mesh_set_quad(realw, realh, quad, mesh, texture, cb)
	-- Get UVs from the quad
	local x, y, w, h = quad:getViewport()
	local tw, th = texture:getDimensions()
	local u0, v0 = x / tw, y / th
	local u1, v1 = (x + w) / tw, (y + h) / th

	-- Define a 2D rectangle using UVs from the quad
	local vertices = {
		{ 0, 0, u0, v0 }, -- top-left
		{ realw, 0, u1, v0 }, -- top-right
		{ realw, realh, u1, v1 }, -- bottom-right
		{ 0, realh, u0, v1 }, -- bottom-left
	}

  mesh:setVertices(cb(vertices))
	mesh:setTexture(texture)
end

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
local function draw_mesh(card, x, y, r)
	local w, h = View.normalize_xy(M.width(), M.height(), M.width(), M.height())

	local depth = 4
	local skew = depth / 100

	local sx = w / CardImageWidth
	local sy = h / CardImageHeight
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
	love.graphics.draw(CardMeshHL, -View.normalize_x(0.01), -View.normalize_y(0.01), 0, 1.1, 1.05)
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
	love.graphics.printf(M.describe(card), 8 * sx, 15 * sy, (34 * sx / fsy), "left", 0, fsy, fsy, nil, nil)
end

---@param card Card
---@param x integer
---@param y integer
---@param r? integer
function M.draw(card, x, y, r)
	draw_mesh(card, x, y, r)
end

return M
