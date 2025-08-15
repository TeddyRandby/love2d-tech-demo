local M = {}

function M.wh_ratio()
	return love.graphics.getWidth() / love.graphics.getHeight()
end

function M.hw_ratio()
	return 1 / M.wh_ratio()
end

function M.pixel_width()
	--- This is where the resolution of the game is defined.
	--- The screen should be 480 pixels across.
	--- This is normalized! The width of s pixel on the screen, from 0 - 1.
	return (love.graphics.getWidth() / 256) / love.graphics.getWidth()
end

function M.pixel_height()
	--- The height of a pixel is proportional to its width.
	return M.pixel_width() * M.wh_ratio()
end

function M.sx()
  return M.realize_x(M.pixel_width())
end

function M.sy()
  return M.realize_y(M.pixel_height())
end

function M.scale_xy()
  return M.sx(), M.sy()
end

---@param pixels integer
function M.width(pixels)
	return pixels * M.pixel_width()
end

---@param pixels integer
function M.height(pixels)
	return pixels * M.pixel_height()
end

---@param x integer
---@param y integer
function M.normalize_xy(x, y)
	return M.width(x), M.height(y)
end

---@param x integer
function M.normalize_x(x)
	return M.width(x)
end

---@param y integer
function M.normalize_y(y)
	return M.height(y)
end

---@param n number
---@param max integer
---@return integer
local function realize_dim(n, max)
	if n > 1 then
		return n
	end

	if n >= 0 then
		return math.floor(n * max)
	end

	if n < -1 then
		return max + n
	end

	return max * (1 + n)
end

--- Take a normalized x-coordinate (-1, 1) or (-max, max), and
--- realize it into the space (0, screen_width)
---@param x number
function M.realize_x(x)
	return realize_dim(x, love.graphics.getWidth())
end

--- Take a normalized y-coordinate (-1, 1) or (-max, max), and
--- realize it into the space (0, screen_height)
---@param y number
function M.realize_y(y)
	return realize_dim(y, love.graphics.getHeight())
end

---@param x number
---@param y number
---@return number, number
function M.realize_xy(x, y)
	return M.realize_x(x), M.realize_y(y)
end

M.card = require("ui.card")
M.token = require("ui.token")
M.skill = require("ui.skill")
M.icon = require("ui.icon")
M.skillbox = require("ui.skillbox")
M.bag = require("ui.bag")
M.button = require("ui.button")

return M
