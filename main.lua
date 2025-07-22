local Engine = require("engine")

function love.load()
  Engine:load()
end

function love.draw()
  Engine:draw()
end

function love.update()
  Engine:update()
end

function love.keypressed(key, scancode, isrepeat)
  if key == "escape" then
    love.event.quit(0)
  end

  if key == '1' then
    Engine:play(Engine.hand[1])
  end

  if key == '2' then
    Engine:play(Engine.hand[2])
  end

  if key == '3' then
    Engine:play(Engine.hand[3])
  end
end
