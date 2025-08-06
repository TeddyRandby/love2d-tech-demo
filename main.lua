require("util")

UI = require("ui")
View = require("view")
Engine = require("engine")

function love.load()
  Engine:load()
end

function love.draw()

  View:draw()
end

function love.update(dt)
  Engine:update(dt)

  require("util.flux").update(dt)
end

function love.mousepressed(x, y, button, istouch, presses)
  local e = View:hover(x, y)

  if not e then
    return
  end

  if not View:is_dragging() then
    if View:draggable(e.target) then
      local pos = View:pos(e)
      assert(pos ~= nil)
      View:begin_drag(e.target, x, y, x - pos.x, y - pos.y)
    end
  else
    View:end_drag(x, y)
  end

  if View:clickable(e.target) then
    View:click(e.target, x, y)
  end
end

function love.keypressed(key, scancode, isrepeat)
  print("[KEY] " .. tostring(key) .. "," .. tostring(scancode) .. "," .. tostring(isrepeat))
  if key == "escape" then
    love.event.quit(0)
  end

  if key == "r" then
    love.event.quit("restart")
  end
end
