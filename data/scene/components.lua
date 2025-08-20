---@alias Component fun()

local M = {}

local Card = require("data.card")
local Move = require("data.move")

---@param x number
---@param y number
function M.history(x, y)
  ---@type Component
  return function()
    local relevant_events = table.filter(Engine.event_history, function(e)
      return e.owner == Engine:player() or e.owner == Engine:enemy()
    end)

    local events = table.slice(relevant_events, -8)

    local thisx, thisy = x, y

    --TODO: Each history elements time should be a function
    --of how far it is from its destination.
    --We want all history elements to move at a constant rate.
    local time = 1

    for _, event in ipairs(events) do
      if event.truetype == "token" then
        if event.type == "draft" then
          View:icon({ "token", "draft" }, thisx, thisy, event, nil, 1, thisy, time)
        elseif event.type == "discard" then
          View:icon({ "token", "discard" }, thisx, thisy, event, nil, 1, thisy, time)
        elseif event.type == "donate" then
          View:icon({ "token", "donate" }, thisx, thisy, event, nil, 1, thisy, time)
        elseif event.type == "exhaust" then
          View:icon({ "token", "exhaust" }, thisx, thisy, event, nil, 1, thisy, time)
        elseif event.type == "draw" then
          View:icon({ "token", "draw" }, thisx, thisy, event, nil, 1, thisy, time)
        elseif event.type == "activate" then
          View:icon({ "token", "draw" }, thisx, thisy, event, nil, 1, thisy, time)
        else
          assert(false, "Unhandled token type: " .. event.type)
        end
      elseif event.truetype == "card" then
        View:icon({ "card" }, thisx, thisy, event, nil, 1, thisy, time)
      elseif event.truetype == "move" then
        View:icon(event.target.icon, thisx, thisy, event, nil, 1, thisy, time)
      else
        assert(false, "Unhandled event type")
      end

      local _, at_all = View:is_hovering(event)
      if at_all then
        local text = event.owner.class.type .. " " .. event.type .. " " ..  event.target.type
        View:details(text, text, thisx, thisy + 0.1)
      end

      thisx = thisx + UI.icon.getNormalizedDim() + 0.01
    end
  end
end

---@param x number
---@param y number
---@param prefix string
---@param t "active" | "bag" | "exhausted"
---@param f fun(): Token[]
function M.bag(x, y, prefix, t, f)
  ---@type Component
  return function()
    local ts = f()

    local grouped = table.group(ts, function(t)
      return t.type
    end)

    local thisx = UI.realize_x(x)
    local thisy = UI.realize_y(y)
    local id = prefix .. t

    local pixelsz = UI.realize_x(UI.width(2))

    View:bag(t, id, thisx, thisy, 0, thisy)

    thisx = thisx + UI.realize_x(UI.width(2))
    thisy = thisy + UI.realize_y(UI.height(1))

    for _, ttype in ipairs(Engine.TokenTypes) do
      local v = grouped[ttype.type] or {}

      if #v > 0 then
        local useful = false

        for _, move in ipairs(Engine:player().moves) do
          if View:is_hovering(move) then
            if Move.needs(move, v[1]) then
              useful = true
              break
            end
          end
        end

        for _, token in ipairs(v) do
          local y = thisy

          if useful then
            y = y - UI.realize_y(UI.height(2))
          end

          View:token(token, thisx, y, 0.5, 0, 0.5)

          thisx = thisx + pixelsz
        end

        if useful then
          thisx = thisx + UI.token.getRealizedDim()
        end
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
    local handx = UI.realize_x(x)
    local handy = UI.realize_y(y)

    local w, h = UI.card.getRealizedDim()

    local cards = f()

    local n = #cards
    local spread = getSpread(n)
    local spacing = -(h / 5)

    local anglestep = n == 1 and 0 or spread / math.max(n - 1, 1)
    local startAngle = -spread / 2

    local detail = nil

    for i, v in ipairs(cards) do
      local angle = startAngle + (i - 1) * anglestep

      -- Dip based on rotation: more rotated cards are lower
      local dip = math.pow(angle, 2) * h * 2

      local thisx = handx + (spacing * (i - 1)) + (w * (i - 1))
      local thisy = handy + dip

      if View:is_hovering(v) then
        thisy = thisy - h / 2 - dip
        angle = 0

        local pos = View:post(v)
        if pos and pos.y == thisy and not View:is_dragging(v) then
          local details_x = thisx + w + UI.realize_x(0.02)

          if thisx > UI.realize_x(0.5) then
            details_x = thisx - UI.realize_x(0.22)
          end

          detail = function()
            View:details(Card.describe_long(v), tostring(v) .. "hand", details_x, thisy)
          end
        end
      end

      View:card(v, thisx, thisy, angle, nil, nil, 0.4)

      if card_ueh then
        View:register(v, card_ueh(i, v))
      end
    end

    if detail then
      detail()
    end
  end
end

---@param x number
---@param y number
---@param text string
---@param f function
function M.button(x, y, text, f)
  local target = { text = text }
  ---@type Component
  return function()
    View:button(x, y, target, f)
  end
end

---@param x integer
---@param y integer
function M.move_selector(x, y)
  ---@type table<Move, boolean>?
  local moves = nil

  ---@type Move[]?
  local movelist = nil

  ---@type table<Effect, boolean>?
  local effects = nil

  ---@type Move[]?
  local effectlist = nil

  ---@type Component
  return function()
    local detail = nil

    if moves and movelist then
      local thisx, thisy = UI.realize_xy(x, y)

      local movew = UI.skill.getRealizedDim()

      local pad = UI.realize_x(UI.width(2))

      View:movelist("shopmoves", "shopmoves", x, y)

      thisx = thisx + UI.realize_x(UI.width(4.2))
      thisy = thisy + UI.realize_y(UI.height(11))
      local total = 0

      for v, is_chosen in pairs(moves) do
        total = total + 1
        if not is_chosen then
          View:move(v, thisx, thisy, v)

          local _, at_all = View:is_hovering(v)
          if at_all then
            local details_x = thisx + movew + UI.realize_x(0.02)

            -- if thisx > 0.5 then
            -- 	details_x = thisx - 0.22
            -- end

            detail = function()
              View:details(Move.describe(v), tostring(v) .. "hand", details_x, thisy)
            end
          end

          View:register(v, {
            click = function()
              if Engine:player().gold > 0 then
                moves[v] = not moves[v]
                --TODO: Is this how I want gold and stuff to work?
                --Shop-abilities are weird then
                Engine:player().gold = Engine:player().gold - 1
                Engine:player():learn(v)
              end
            end,
          })
        end

        thisx = thisx + movew + pad
      end

      while total < 5 do
        View:move(nil, thisx, thisy, "emptyshopmove" .. total)

        thisx = thisx + movew + pad
        total = total + 1
      end
    end

    if effects and effectlist then
      local thisx, thisy = UI.realize_xy(x, y)

      thisy = thisy + UI.realize_y(0.2)

      local movew = UI.skill.getRealizedDim()

      local pad = UI.realize_x(UI.width(2))

      View:movelist("shopeffects", "shopeffects", thisx, thisy)

      thisx = thisx + UI.realize_x(UI.width(4.2))
      thisy = thisy + UI.realize_y(UI.height(11))
      local total = 0

      for v, is_chosen in pairs(effects) do
        total = total + 1
        if not is_chosen then
          ---@diagnostic disable-next-line: param-type-mismatch
          View:move(v, thisx, thisy, v)

          if View:is_hovering(v) then
            local details_x = thisx + movew + UI.realize_x(0.02)

            -- if thisx > 0.5 then
            -- 	details_x = thisx - 0.22
            -- end

            detail = function()
              View:details(v.desc, tostring(v) .. "hand", details_x, thisy)
            end
          end

          View:register(v, {
            click = function()
              if Engine:player().gold > 0 then
                effects[v] = not effects[v]
                Engine:player().gold = Engine:player().gold - 1
                Engine:player():learn(v)
              end
            end,
          })
        end

        thisx = thisx + movew + pad
      end

      while total < 5 do
        View:move(nil, thisx, thisy, "emptyshopeffect" .. total)

        thisx = thisx + movew + pad
        total = total + 1
      end
    end

    if detail then
      detail()
    end

    if not moves and not effects then
      -- Will get drawn on the next frame
      moves = {}
      effects = {}

      movelist, effectlist = Engine:player():levelup(3)

      for _, v in ipairs(movelist) do
        moves[v] = false
      end

      for _, v in ipairs(effectlist) do
        effects[v] = false
      end
    end
  end
end

---@param x number
---@param y number
function M.token_selector(x, y)
  ---@type table<Token, boolean>?
  local tokens = nil

  ---@type Token[]?
  local tokenlist = nil

  local btndata = { 0.1, 0.1, text = "confirm" }

  ---@type Component
  return function()
    if tokens and tokenlist then
      local tokenr = UI.token.getRealizedDim() / 2

      View:button(x - 0.05, y + UI.token.getRealizedDim() * 4 - 0.05, btndata, function()
        ---@type Token[]
        local chosen = {}

        ---@type Token[]
        local not_chosen = {}

        for k, v in pairs(tokens) do
          View:register(k)

          if v then
            table.insert(chosen, k)
          else
            table.insert(not_chosen, k)
          end
        end

        tokens = nil
        tokenlist = nil

        Engine:player():push(chosen)
        Engine:player():push(not_chosen)
        Engine:rewind()
      end)

      local thisx = UI.realize_x(x)
      local thisy = UI.realize_y(y) - tokenr
      local n = #tokenlist

      thisx = thisx - (n * tokenr * 2) - ((n - 1) * 5)

      local detail = nil

      for v, is_chosen in pairs(tokens) do
        if is_chosen then
          View:token(v, thisx, thisy - tokenr, 0.5, 0, 0.5, 2)
        else
          View:token(v, thisx, thisy, 0.5, 0, 0.5, 2)
        end

        if View:is_hovering(v) then
          local details_x = thisx + tokenr * 4 + UI.realize_x(0.02)

          if thisx > UI.realize_x(0.5) then
            details_x = thisx - UI.realize_x(0.22)
          end

          detail = function()
            View:details(v.desc, tostring(v) .. "hand", details_x, thisy)
          end
        end

        View:register(v, {
          click = function()
            View:cancel_tween(v)
            tokens[v] = not tokens[v]
          end,
        })

        thisx = thisx + tokenr * 4 + 10
      end

      if detail then
        detail()
      end
    else
      -- Will get drawn on the next frame
      tokens = {}
      tokenlist = Engine:player():pop()

      if #tokenlist == 0 then
        Engine:player():push({})
        Engine:player():push({})
        Engine:rewind()
      else
        for _, v in ipairs(tokenlist) do
          tokens[v] = false
        end
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
      ---@param details_position integer
      local function drawcard(a, b, position, details_position)
        local _, cardh = UI.card.getRealizedDim()

        if View:is_hovering(a) then
          local hover_r = 0.03
          if love.mouse.getX() - position < View.normalize_x(Card.width()) / 2 then
            hover_r = -hover_r
          end
          View:card(a, position, y, hover_r, position, -cardh)
          View:details(Card.describe_long(a), tostring(a) .. "selector", details_position, y)
        else
          View:card(a, position, y, nil, position, -cardh, 0.5)
        end

        View:register(a, {
          click = function()
            Engine:bots_pickcard()

            table.insert(Engine:player().hand, a)

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

            Engine:transition("settling")
          end,
        })
      end

      drawcard(left, right, thisx, math.max(thisx - View.normalize_x(0.22), 0))
      drawcard(right, left, thisx + View.normalize_x(0.03) + w, thisx + View.normalize_x(Card.width() * 2 + 0.05))
    else
      -- Will get drawn on the next frame
      cardpool = Engine:player():fish(10)
    end
  end
end

---@param x number
---@param y number
function M.enemy(x, y)
  ---@type Component
  return function()
    local enemy = Engine:enemy()
    if enemy then
      View:text(
        enemy.class.type .. "(" .. enemy.lives .. "/" .. enemy.class.lives .. ")" .. ". Power: " .. enemy.power,
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
  local token_types = require("data.token.types")

  local active_slot_data = {}
  local exhausted_slot_data = {}

  for _, token_type in ipairs(token_types) do
    active_slot_data[token_type.type] = { type = token_type.type, amt = 0 }
    exhausted_slot_data[token_type.type] = { type = token_type.type, amt = 0 }
  end

  ---@type Component
  return function()
    local w, h = View.normalize_xy(0.16, 0.04)

    local active, exhausted = active_f(), exhausted_f()

    local thisx = View.normalize_x(x)
    local thisy = View.normalize_y(y)

    local sloty = thisy

    for i, token_type in ipairs(token_types) do
      local active_of_type = table.filter(active, function(t)
        return t.type == token_type.type
      end)

      local exhausted_of_type = table.filter(exhausted, function(t)
        return t.type == token_type.type
      end)

      active_slot_data[token_type.type].amt = #active_of_type
      exhausted_slot_data[token_type.type].amt = #exhausted_of_type

      if #active_of_type > 0 then
        View:boardslot(active_slot_data[token_type.type], thisx, sloty, nil, 0, sloty, 0.2 + i * 0.1)
      end

      if #exhausted_of_type > 0 then
        View:boardslot(exhausted_slot_data[token_type.type], thisx + w, sloty, nil, 0, sloty, 0.2 + i * 0.1)
      end

      if #active_of_type > 0 or #exhausted_of_type > 0 then
        sloty = sloty + h
      end
    end

    local tokenr = UI.token.getRealizedDim() / 2
    local pd = UI.width(4)

    local tokx = thisx
    local toky = thisy + h * #token_types
    for i, v in ipairs(active) do
      View:token(v, tokx + (i - 1) * pd, toky)
    end

    toky = toky + tokenr * 2 + pd * 2
    for i, v in ipairs(exhausted) do
      View:token(v, tokx + (i - 1) * pd, toky)
    end
  end
end

return M
