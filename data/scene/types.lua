---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover" | "round"

---@class Scene
---@field name SceneType
---@field layout Component[]

local Components = require("data.scene.components")
local Card = require("data.card")
local Token = require("data.token")
local Move = require("data.move")

local Inputs = {}

---@return Card[]
function Inputs.PlayerHand()
  return Engine.player.hand
end

---@return Token[]
function Inputs.PlayerBag()
  return Engine.player:bag()
end

---@return Token[]
function Inputs.PlayerField()
  return Engine.player:active()
end

---@return Token[]
function Inputs.PlayerExhausted()
  return Engine.player:exhausted()
end

---@return Card[]
function Inputs.EnemyHand()
  return Engine.enemy.hand
end

---@return Token[]
function Inputs.EnemyBag()
  return Engine.enemy:bag()
end

---@return Token[]
function Inputs.EnemyField()
  return Engine.enemy:active()
end

---@return Token[]
function Inputs.EnemyExhausted()
  return Engine.enemy:exhausted()
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

local PlayerBag = Components.bag(0.01, 0.2, Inputs.PlayerBag)
local EnemyBag = Components.bag(-0.11, 0.2, Inputs.EnemyBag)

local TokenSelector = Components.token_selector(0.5, 0.5)
local PlayerBoard = Components.board(0.12, 0.2, Inputs.PlayerField, Inputs.PlayerExhausted)
local EnemyBoard = Components.board(-0.12 - 0.32, 0.2, Inputs.EnemyField, Inputs.EnemyExhausted)

local PlayerProfile = function()
  local str = Engine.player.player.type
      .. " -- Lives: "
      .. Engine.player.lives
      .. "/"
      .. Engine.player.player.battle_stats.lives
      .. ". Power: "
      .. Engine.player.power

  View:text(str, 0.1, 0.01)
end

local EnemyProfile = Components.enemy(-0.2, 0.01)

local function PlayerMoves(cb)
  if cb then
    return function()
      for i, v in ipairs(Engine.player.moves) do
        local move = Move[v]
        View:move(move, 0.12 + (i - 1) * Move.width(), -0.01 - Move.height())
        View:register(move, cb(i, move))
      end
    end
  else
    return function()
      for i, v in ipairs(Engine.player.moves) do
        local move = Move[v]
        View:move(move, 0.12 + (i - 1) * Move.width(), -0.01 - Move.height())
      end
    end
  end
end

---@type table<SceneType, Scene>
return {
  main = {
    name = "main",
    layout = {
      Components.button(0.4, 0.4, 0.1, 0.1, "Play", function()
        Engine:transition("drafting")
      end),
    },
  },
  gameover = {
    name = "gameover",
    layout = {
      Components.button(0.4, 0.4, 0.1, 0.1, "Play", function()
        Engine:transition("drafting")
      end),
    },
  },
  drafting = {
    name = "drafting",
    layout = {
      EnemyProfile,
      EnemyBag,

      Components.card_selector(0.5 - Card.width() - 0.03, 0.5 - (Card.height() / 2)),

      PlayerProfile,
      PlayerBag,
      PlayerHandUp(),
    },
  },
  upgrading = {
    name = "upgrading",
    layout = {
      EnemyProfile,
      EnemyBag,

      PlayerProfile,
      PlayerBag,
      PlayerHandUp(function(i)
        return {
          dragend = function(x, y)
            -- If we're above the hand play the card 
            if y > View.normalize_y(0.5)then
              return
            end

            -- Play a random enemy card
            Engine.enemy:play()

            -- Player plays may change the scene.
            -- This would cause all further plays to early-exit.
            Engine.player:play(i)
          end,
        }
      end),

      function()
        if #Engine.player.hand == 0 then
          Components.button(0.4, 0.4, 0.1, 0.1, "Battle", function()
            Engine:transition("battling")
          end)()
        end
      end,
    },
  },
  choosing = {
    name = "choosing",
    layout = {
      EnemyProfile,
      EnemyBag,
      TokenSelector,
      PlayerProfile,
      PlayerBag,
      PlayerHandDown,
    },
  },
  battling = {
    name = "battling",
    layout = {
      EnemyProfile,
      EnemyBoard,
      EnemyBag,

      PlayerProfile,
      PlayerBag,
      PlayerBoard,

      PlayerMoves(),

      Components.button(-0.11 - Move.width(), -Move.height(), Move.width(), Move.height(), "Draw", function()
        Engine:begin_round()
        if Engine.scene == "battling" then
          Engine:transition("round")
        end
      end),
    },
  },
  round = {
    name = "round",
    layout = {
      EnemyProfile,
      EnemyBoard,
      EnemyBag,

      PlayerProfile,
      PlayerBoard,
      PlayerBag,
      PlayerMoves(function(_, move)
        return {
          click = function(x, y)
            if Engine.player:doable(move) then
              Engine.player:domove(move)
            end
          end,
        }
      end),

      Components.button(-0.11 - Move.width(), -Move.height(), Move.width(), Move.height(), "Done", function()
        Engine:end_round()
        if Engine.scene == "round" then
          Engine:transition("battling")
        end
      end),
    },
  },
}
