require("util")

Engine = require("engine")
View = require("view")

function love.load()
	Engine:load()
end

function love.draw()
	View:draw()
end

function love.update()
	Engine:update()
end

function love.mousepressed(x, y, button, istouch, presses)
  if not Engine:is_dragging() then
		local e = View:hover(x, y)
    if e then
      Engine:begin_drag(e.target, x - e.x, y - e.y)
    end
  else
    Engine:end_drag()
  end
end

function love.keypressed(key, scancode, isrepeat)
	print("[KEY] " .. tostring(key) .. "," .. tostring(scancode) .. "," .. tostring(isrepeat))
	if key == "escape" then
		love.event.quit(0)
	end

	if key == "1" then
		Engine:play(1)
	end

	if key == "2" then
		Engine:play(2)
	end

	if key == "3" then
		Engine:play(3)
	end

	if key == "4" then
		Engine:play(4)
	end

	if key == "5" then
		Engine:play(5)
	end
end
