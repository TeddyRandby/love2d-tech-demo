---@alias ComponentType "bag" | "hand" | "button" | "card_selector" | "board"

---@class Component
---@field type ComponentType
---@field x number
---@field y number
---@field w? number
---@field h? number
---@field f? function
---@field text? string
---@field amount? number

local M = {}

---@param x number
---@param y number
---@return Component
function M.bag(x, y)
  ---@type Component
	return {
		type = "bag",
		x = x,
		y = y,
	}
end

---@param x number
---@param y number
---@return Component
function M.hand(x, y)
  ---@type Component
	return {
		type = "hand",
		x = x,
		y = y,
	}
end

---@param text string
---@param f function
---@param x number
---@param y number
---@param w number
---@param h number
---@return Component
function M.button(text, f, x, y, w, h)
  ---@type Component
  return {
    type = "button",
		x = x,
		y = y,
    f = f,
    text = text,
    w = w,
    h = h,
  }
end

---@param x number
---@param y number
---@param n number
function M.card_selector(x, y, n)
  ---@type Component
  return {
    type = "card_selector",
    x = x,
    y = y,
    amount = n,
  }
end

---@param x number
---@param y number
function M.board(x, y)
  ---@type Component
  return {
    type = "board",
    x = x,
    y = y,
  }
end

return M
