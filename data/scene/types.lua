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
local PlayerBoard = Components.board(0.12, -Token.radius() * 3, Inputs.PlayerField, Inputs.PlayerExhausted)
local EnemyBoard = Components.board(0.12, Token.radius() * 3, Inputs.EnemyField, Inputs.EnemyExhausted)

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
      Components.enemy(-0.1, 0.01),
      EnemyBag,

      Components.card_selector(0.5 - Card.width() - 0.03, 0.5 - (Card.height() / 2)),
      PlayerBag,
      PlayerHandUp(),
    },
  },
  upgrading = {
    name = "upgrading",
    layout = {
      Components.enemy(-0.1, 0.01),
      EnemyBag,

      PlayerBag,
      PlayerHandUp(function(i)
        return {
          dragend = function()
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
      Components.enemy(-0.1, 0.01),
      EnemyBag,
      TokenSelector,
      PlayerBag,
      PlayerHandDown,
    },
  },
  battling = {
    name = "battling",
    layout = {
      Components.enemy(-0.1, 0.01),
      EnemyBoard,
      EnemyBag,

      function()
        local str = "Lives: "
            .. Engine.player.lives
            .. "/"
            .. Engine.player.player.battle_stats.lives
            .. ". Power: "
            .. Engine.player.power
        View:text(str, 0.01, -View.getFontSize() - 0.01)
      end,

      PlayerBag,
      PlayerBoard,

      function()
        for i, v in ipairs(Engine.player.moves) do
          View:move(require("data.move.types")[v], -Move.width() - 0.1, -0.4 + i * Move.height())
        end
      end,

      Components.button(-0.11, -0.21, 0.1, 0.2, "Fight!", function()
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
      Components.enemy(-0.1, 0.01),
      EnemyBoard,
      EnemyBag,

      function()
        local str = "Lives: " .. Engine.player.lives .. "/3. Power: " .. Engine.player.power
        View:text(str, 0.01, View.normalize_y(-0.01) - love.graphics.getFont():getHeight())
      end,

      Components.button(-0.11, -0.21, 0.1, 0.2, "Done", function()
        Engine:end_round()
        if Engine.scene == "round" then
          Engine:transition("battling")
        end
      end),

      PlayerBoard,
      PlayerBag,

      function()
        for i, v in ipairs(Engine.player.moves) do
          local move = require("data.move.types")[v]
          View:move(move, -Move.width() - 0.1, -0.4 + i * Move.height())
          View:register(move, {
            receive = function(x, y, t)
              if Move.needs(move, t, Engine.player.token_states[t]) then
                Engine.player:exhaust({ t })
                move.effect(Engine.player)
              end
            end,
          })
        end
      end,

      -- Components.board(0.01, (-Token.radius()) * 3, Inputs.PlayerField, Inputs.PlayerExhausted, function(_, v)
      --   if Engine.player:useful(v) then
      --     return {
      --       dragend = function() end,
      --     }
      --   end
      -- end),
    },
  },
}
