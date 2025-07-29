---@alias Component fun()

local M = {}

local Card = require("data.card")
local Token = require("data.token")

---@param x number
---@param y number
---@param f fun(): Token[]
function M.bag(x, y, f)
  ---@type Component
  return function()
    local ts = f()

    View:bag(ts, x, y)

    for i, token in ipairs(ts) do
      if View:is_hovering(token) then
        View:token(token, x + Token.radius(), y + (i * 0.03), 0.5, 0, 0.6)
      else
        View:token(token, x, y + i * 0.03, 0.5, 0, 0.6)
      end
    end
  end
end

local function getSpread(n)
  local minSpread = math.rad(5)
  local maxSpread = math.rad(30)
  return minSpread + (maxSpread - minSpread) * ((n - 1) / 4)
end

---@param x number
---@param y number
---@param f fun(): Card[]
---@param card_ueh? fun(i: integer, v: Card): UserEventHandler
function M.hand(x, y, f, card_ueh)
  ---@type Component
  return function()
    local handx = View.normalize_x(x)
    local handy = View.normalize_y(y)

    local w = View.normalize_x(Card.width())
    local h = View.normalize_y(Card.height())

    local cards = f()

    local n = #cards
    local spread = getSpread(n)
    local spacing = -(h / 5)

    local anglestep = n == 1 and 0 or spread / math.max(n - 1, 1)
    local startAngle = -spread / 2

    for i, v in ipairs(cards) do
      local angle = startAngle + (i - 1) * anglestep

      -- Dip based on rotation: more rotated cards are lower
      local dip = math.pow(angle, 2) * h * 2

      local thisx = handx + (spacing * (i - 1)) + (w * (i - 1))
      local thisy = handy + dip

      if View:is_hovering(v) then
        thisy = thisy - h / 2 - dip
        angle = 0
      end

      View:card(v, thisx, thisy, angle, 0.4)

      if card_ueh then
        View:register(v, card_ueh(i, v))
      end
    end
  end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param text string
---@param f function
function M.button(x, y, w, h, text, f)
  ---@type Component
  return function()
    View:button(x, y, w, h, text, f)
  end
end

---@param x number
---@param y number
function M.token_selector(x, y)
  ---@type table<Token, boolean>?
  local tokens = nil

  ---@type Token[]?
  local tokenlist = nil

  ---@type Component
  return function()
    if tokens and tokenlist then
      local tokenr = View.normalize_x(Token.radius())

      View:button(x - 0.05, y + Token.radius() * 4 - 0.05, 0.1, 0.1, "confirm", function()
        ---@type Token[]
        local chosen = {}

        ---@type Token[]
        local not_chosen = {}

        for k, v in pairs(tokens) do
          if v then
            table.insert(chosen, k)
          else
            table.insert(not_chosen, k)
          end
        end

        tokens = nil
        tokenlist = nil

        Engine.player:push(chosen)
        Engine.player:push(not_chosen)

        Engine:transition("upgrading")
      end)

      local thisx = View.normalize_x(x)
      local thisy = View.normalize_y(y) - tokenr
      local n = #tokenlist

      thisx = thisx - (n * tokenr) - ((n - 1) * 5)

      for v, is_chosen in pairs(tokens) do
        if is_chosen then
          View:token(v, thisx, thisy + tokenr, 0.5, 0, 0.1)
        else
          View:token(v, thisx, thisy, 0.5, 0, 0.1)
        end

        View:register(v, {
          click = function()
            View:cancel_tween(v)
            tokens[v] = not tokens[v]
          end,
        })

        thisx = thisx + tokenr * 2 + 10
      end
    else
      -- Will get drawn on the next frame
      tokens = {}
      tokenlist = Engine.player:pop()
      for _, v in ipairs(tokenlist) do
        tokens[v] = false
      end
    end
  end
end

---@param x number
---@param y number
function M.card_selector(x, y)
  local cardpool = nil

  ---@type Component
  return function()
    if cardpool then
      local thisx = View.normalize_x(x)
      local w = View.normalize_x(Card.width())

      local left, right = cardpool[1], cardpool[2]

      assert(left ~= nil)
      assert(right ~= nil)

      ---@param a Card
      ---@param b Card
      ---@param position integer
      local function drawcard(a, b, position)
        View:card(a, position, y)

        View:register(a, {
          click = function()
            table.insert(Engine.player.hand, a)

            -- TODO: Add more intelligence than this
            -- Use the enemy.enemy.draft_stats.likes table
            table.insert(Engine.enemy.hand, b)

            -- Unregister handlers for cards when it is drawn.
            View:register(a)
            View:register(b)

            -- Shift out our two chosen cards
            table.shift(cardpool)
            table.shift(cardpool)

            if table.isempty(cardpool) then
              cardpool = nil
              Engine:transition("upgrading")
            end
          end,
        })
      end

      drawcard(left, right, thisx)
      drawcard(right, left, thisx + View.normalize_x(0.03) + w)
    else
      -- Will get drawn on the next frame
      cardpool = Engine.player:fish(10)
    end
  end
end

---@param x number
---@param y number
function M.enemy(x, y)
  ---@type Component
  return function()
    local enemy = Engine.enemy
    if enemy then
      View:text(
        enemy.enemy.type .. "(" .. Engine.enemy.lives .. "/" .. Engine.enemy.enemy.battle_stats.lives .. ")",
        x,
        y
      )
    end
  end
end

---@param x number
---@param y number
---@param active_f fun(): Token[]
---@param exhausted_f fun(): Token[]
---@param token_ueh? fun(i: integer, v: Token): UserEventHandler
function M.board(x, y, active_f, exhausted_f, token_ueh)
  ---@type Component
  return function()
    local tokenr = View.normalize_x(Token.radius())
    local tokenw = tokenr * 2

    local thisx = View.normalize_x(x)
    local thisy = View.normalize_y(y)

    local active, exhausted = active_f(), exhausted_f()

    for i, v in ipairs(active) do
      View:token(v, thisx, thisy, nil, nil, 0.6)
      View:register(v, token_ueh and token_ueh(i, v))

      thisx = thisx + tokenw + 10
    end

    thisx = thisx + tokenw + tokenw
    for i, v in ipairs(exhausted) do
      View:token(v, thisx, thisy, nil, nil, 0.6)
      View:register(v, token_ueh and token_ueh(i, v))

      thisx = thisx + tokenw + 10
    end
  end
end

return M
