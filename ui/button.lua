local Shaders = require("util.shaders")

local M = {}

local ButtonSpritesheet = love.graphics.newImage("resources/ButtonSpritesheet.png")

M.pixelw = 16
M.pixelh = 8

function M.getRealizedDim()
  return UI.realize_xy(M.getNormalizedDim())
end

function M.getNormalizedDim()
  return UI.normalize_xy(M.getPixelDim())
end

function M.getPixelDim()
  return M.pixelw, M.pixelh
end

local ButtonBG = love.graphics.newQuad(M.pixelw * 0, 0, M.pixelw, M.pixelh, ButtonSpritesheet)
local ButtonHL = love.graphics.newQuad(M.pixelw * 1, 0, M.pixelw, M.pixelh, ButtonSpritesheet)
local ButtonBGHL = love.graphics.newQuad(M.pixelw * 2, 0, M.pixelw, M.pixelh, ButtonSpritesheet)

function M.draw(target, x, y, text)
  local sx, sy = UI.scale_xy()
  local FontHeight = love.graphics.getFont():getHeight()
  local fsy = View.normalize_y(View.getFontSize()) / FontHeight

  love.graphics.translate(x, y)
  -- love.graphics.setColor(1, 1, 1, 1)

  -- local mask = love.graphics.newCanvas(w, h)
  -- local canvas = love.graphics.newCanvas(w, h)
  --
  -- mask:setFilter("linear")
  -- canvas:setFilter("linear")
  --
  -- love.graphics.origin()
  -- love.graphics.setCanvas(mask)
  -- -- love.graphics.clear(0, 0, 0, 0)
  -- love.graphics.draw(ButtonHLMaskImage, 0, 0, 0, sx, sy)
  -- love.graphics.setCanvas()
  --
  -- love.graphics.setCanvas(canvas)
  -- love.graphics.clear(0, 0, 0, 0)
  -- -- love.graphics.setBlendMode("multiply", "premultiplied")
  -- -- Shaders.glow(Engine.time, mask, { 255 / 255, 252 / 255, 253 / 255 })
  -- love.graphics.draw(mask, 0, 0) -- same size/coords
  -- -- Shaders.reset()
  -- love.graphics.setCanvas()
  -- love.graphics.setBlendMode("alpha")
  --
  -- love.graphics.setColor(1, 1, 1, 1)
  -- love.graphics.translate(x, y)
  -- love.graphics.draw(canvas, 0, 0, 0)

  local w, h = M.getRealizedDim()
  Shaders.pixel_scanline(x, y, w, h, sx, sy, 0)

  love.graphics.setColor(1, 1, 1, 1)
  if View:is_hovering(target) then
    love.graphics.translate(0, sy)
  else
    love.graphics.draw(ButtonSpritesheet, ButtonHL, 0, 0, 0, sx, sy)
  end

  love.graphics.draw(ButtonSpritesheet, ButtonBG, 0, 0, 0, sx, sy)
  love.graphics.draw(ButtonSpritesheet, ButtonBGHL, 0, 0, 0, sx, sy)

  Shaders.reset()

  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.printf(text, 1 * sx / fsy, 1 * fsy, 14 * sx / fsy, "center", 0, fsy, fsy)
  love.graphics.setColor(1, 1, 1, 1)
end

return M
