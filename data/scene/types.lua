---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover" | "round" | "settling"

---@class Scene
---@field name SceneType
---@field layout Component[]

local Components = require("data.scene.components")
local Card = require("data.card")
local Move = require("data.move")

local Inputs = {}

---@return Card[]
function Inputs.PlayerHand()
  return Engine:player().hand
end

---@return Token[]
function Inputs.PlayerBag()
  return Engine:player():bag()
end

---@return Token[]
function Inputs.PlayerActive()
  return Engine:player():active()
end

---@return Move[]
function Inputs.PlayerEffects()
  return Engine:player():effects()
end

---@return Move[]
function Inputs.EnemyEffects()
  return Engine:enemy():effects()
end

---@return Move[]
function Inputs.PlayerMoves()
  return Engine:player().moves
end

---@return Move[]
function Inputs.EnemyMoves()
  return Engine:enemy().moves
end

---@return Token[]
function Inputs.PlayerExhausted()
  return Engine:player():exhausted()
end

---@return Card[]
function Inputs.EnemyHand()
  return Engine:enemy().hand
end

---@return Token[]
function Inputs.EnemyBag()
  return Engine:enemy():bag()
end

---@return Token[]
function Inputs.EnemyActive()
  return Engine:enemy():active()
end

---@return Token[]
function Inputs.EnemyExhausted()
  return Engine:enemy():exhausted()
end

---@param cb? fun(i: integer, card: Card): UserEventHandler
local function PlayerHandUp(cb)
  if cb then
    return Components.hand(0.1, -(Card.height() / 2), Inputs.PlayerHand, cb)
  else
    return Components.hand(0.1, -(Card.height() / 2), Inputs.PlayerHand)
  end
end

local PlayerHandDown = Components.hand(0.01 + 0.2, 1, Inputs.PlayerHand)

local PlayerBag = Components.bag(0.01, 0.2, "Player", "bag", Inputs.PlayerBag)
local PlayerActive = Components.bag(0.01, 0.3, "Player", "active", Inputs.PlayerActive)
local PlayerExhausted = Components.bag(0.01, 0.4, "Player", "exhausted", Inputs.PlayerExhausted)

local EnemyBag = Components.bag(-0.41, 0.2, "Enemy", "bag", Inputs.EnemyBag)
local EnemyActive = Components.bag(-0.41, 0.3, "Enemy", "active", Inputs.EnemyActive)
local EnemyExhausted = Components.bag(-0.41, 0.4, "Enemy", "exhausted", Inputs.EnemyExhausted)

local TokenSelector = Components.token_selector(0.5, 0.5)

local PlayerProfile = function()
  local player = Engine:player()
  local str = player.class.type
      .. " -- Lives: "
      .. player.lives
      .. "/"
      .. player.class.lives
      .. ". Power: "
      .. player.power
      .. ". Manapool: "
      .. player.mana
      .. ". Gold: "
      .. player.gold
      .. ". Actions: "
      .. player.actions

  View:text(str, 0.01, 0.01)
end

local EnemyProfile = Components.enemy(-0.2, 0.01)
local NormalMoveWidth, NormalMoveHeight = UI.skill.getNormalizedDim()

---@param x number
---@param y number
---@param get_effects fun(): Effect[]
---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function EffectsComponent(x, y, get_effects, cb)
  return function()
    local detail = nil

    View:movelist("effects", get_effects, x, y, x, 1)

    local thisx = x + UI.width(5)
    local thisy = y + UI.height(11)

    local total = 0

    for _, effect in ipairs(get_effects()) do
      View:move(effect, thisx, thisy, effect)

      local _, at_all = View:is_hovering(effect)
      if at_all then
        local detailx = thisx + NormalMoveWidth + UI.width(4)
        detail = function()
          View:details(effect.desc, tostring(effect), detailx, thisy)
        end
      end

      -- if cb then
      -- 	View:register(effect, cb(i, effect))
      -- end

      thisx = thisx + NormalMoveWidth + UI.width(2)
      total = total + 1
    end

    while total < 5 do
      View:move(nil, thisx, thisy, "emptyeffect" .. tostring(get_effects) .. total)

      thisx = thisx + NormalMoveWidth + UI.width(2)
      total = total + 1
    end

    if detail then
      detail()
    end
  end
end

---@param x number
---@param y number
---@param get_moves fun(): Move[]
---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function MovesComponent(x, y, get_moves, cb)
  return function()
    local detail = nil

    View:movelist("moves", get_moves, x, y, x, 1)

    local thisx = x + UI.width(5)
    local thisy = y + UI.height(11)
    local total = 0

    for i, move in ipairs(get_moves()) do
      View:move(move, thisx, thisy, move)

      local _, at_all = View:is_hovering(move)
      if at_all then
        local detailx = thisx + NormalMoveWidth + UI.width(4)
        detail = function()
          View:details(Move.describe(move), tostring(move), detailx, thisy)
        end
      end

      if cb then
        View:register(move, cb(i, move))
      end

      thisx = thisx + NormalMoveWidth + UI.width(2)
      total = total + 1
    end

    while total < 5 do
      View:move(nil, thisx, thisy, "emptymove" .. tostring(get_moves) .. total)

      thisx = thisx + NormalMoveWidth + UI.width(2)
      total = total + 1
    end

    if detail then
      detail()
    end
  end
end

---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function PlayerMoves(cb)
  return MovesComponent(0.1, 0.2, Inputs.PlayerMoves, cb)
end

local NormalButtonWidth, NormalButtonHeight = UI.button.getNormalizedDim()

local ButtonCenterX, ButtonCenterY = 0.5 - (NormalButtonWidth / 2), 0.5 - (NormalButtonHeight / 2)

local BattleButton = Components.button(ButtonCenterX, ButtonCenterY, "Battle", function()
  Engine:transition("battling")
end)

local History = Components.history(0.01, 0.1)

local mainx, mainy = 0.01, 0.4
local Main = table.map(require("data.class.types"), function(v)
  local cmp = Components.button(mainx, mainy, v.type, function()
    Engine:game(v)
  end)
  mainx = mainx + 0.1 + 0.01
  return cmp
end)

---@type Scene[]
return {
  {
    name = "settling",
    layout = {
      function()
        View.commands = View.last_frame_commands

        local still_settling = table.find(View.commands, function(c)
          return View:pos(c).tween ~= nil
        end)

        if not still_settling then
          Engine:rewind()
        else
          -- local pos = View:pos(still_settling)
        end
      end,
    },
  },
  {
    name = "main",
    layout = Main,
  },
  {
    name = "gameover",
    layout = {
      Components.button(0.4, 0.4, "Play", function()
        Engine:transition("drafting")
      end),
    },
  },
  {
    name = "drafting",
    layout = {
      EnemyProfile,
      EnemyBag,

      PlayerProfile,
      PlayerBag,
      Components.card_selector(0.5 - Card.width() - 0.03, 0.5 - (Card.height() / 2)),

      PlayerHandUp(),
    },
  },
  {
    name = "upgrading",
    layout = {
      EnemyProfile,
      EnemyBag,

      History,

      EffectsComponent(0.01, 0.6, Inputs.PlayerEffects),
      MovesComponent(0.01, 0.4, Inputs.PlayerMoves, function(i, move)
        return {
          click = function()
            if Engine:player():doable(move) then
              Engine:player():domove(move)
            end
          end,
        }
      end),

      Components.move_selector(-0.01 - UI.skillbox.getNormalizedDim(), 0.4),

      PlayerProfile,
      PlayerBag,
      PlayerHandUp(function(i)
        return {
          dragend = function(x, y)
            -- If we're above the hand play the card
            local _, cardheight = UI.card.getNormalizedDim()

            if y > UI.realize_y(-cardheight) then
              return
            end

            Engine:bots_playcard()

            Engine:bots_buyskill()

            Engine:player():play(i)
          end,
        }
      end),

      function()
        if #Engine:player().hand == 0 then
          BattleButton()
        end
      end,
    },
  },
  {
    name = "choosing",
    layout = {
      EnemyProfile,
      EnemyBag,
      History,
      TokenSelector,
      PlayerProfile,
      PlayerBag,
      PlayerHandDown,
    },
  },
  {
    name = "battling",
    layout = {
      EnemyProfile,
      EnemyActive,
      EnemyExhausted,
      EnemyBag,

      History,

      MovesComponent(0.01, 0.5, Inputs.PlayerMoves),
      EffectsComponent(0.01, 0.7, Inputs.PlayerEffects),

      MovesComponent(-0.01 - UI.skillbox.getNormalizedDim(), 0.5, Inputs.EnemyMoves),
      EffectsComponent(-0.01 - UI.skillbox.getNormalizedDim(), 0.7, Inputs.EnemyEffects),

      PlayerProfile,
      PlayerBag,
      PlayerActive,
      PlayerExhausted,

      Components.button(ButtonCenterX, ButtonCenterY, "Draw", function()
        Engine:begin_round()
        Engine:transition("round")
      end),
    },
  },
  {
    name = "round",
    layout = {
      EnemyProfile,
      EnemyActive,
      EnemyExhausted,
      EnemyBag,

      History,

      PlayerProfile,
      PlayerBag,
      PlayerActive,
      PlayerExhausted,

      MovesComponent(0.01, 0.5, Inputs.PlayerMoves, function(_, move)
        return {
          click = function(x, y)
            if Engine:player():doable(move) then
              Engine:player():domove(move)
            end
          end,
        }
      end),
      EffectsComponent(0.01, 0.7, Inputs.PlayerEffects),

      MovesComponent(-0.01 - UI.skillbox.getNormalizedDim(), 0.5, Inputs.EnemyMoves),
      EffectsComponent(-0.01 - UI.skillbox.getNormalizedDim(), 0.7, Inputs.EnemyEffects),

      Components.button(ButtonCenterX, ButtonCenterY, "Done", function()
        Engine:end_round()

        if Engine:current_scene() == "round" then
          Engine:rewind()
        end
      end),
    },
  },
}
