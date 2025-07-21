function love.draw()
  love.graphics.print("Hello World!", 100, 10)
end

function love.update()
end

function love.keypressed(key, scancode, isrepeat)
  if (key == "escape") then
    love.event.quit(0)
  end
end
