local Class = require("data.class")

---@class Engine
---@field scene SceneType
---@field rng love.RandomGenerator
---@field TokenTypes Token[]
---@field CardTypes Card[]
---@field SceneTypes table<string, Scene>
---@field player GameplayData?
---@field enemy GameplayData?
local M = {
  scene = "main",

  EnemyTable = {},

  SceneTypes = require("data.scene.types"),
  TokenTypes = require("data.token.types"),
  CardTypes = require("data.card.types"),
  EnemyTypes = require("data.enemy.types"),

  player = nil,
  enemy = nil,
}

local Gameplay = require("engine.gameplay")

---@param scene SceneType
function M:transition(scene)
  self.scene = scene

  if scene == "drafting" then
    self:encounter()
  elseif scene == "upgrading" then
    -- This will complete any pending micro-ops.
    -- As we may have yielded in the middle of playing a card
    -- (For example, to choose a token as an effect of playing a card)
    self.player:__play()
    self.enemy:__play()
  elseif scene == "gameover" then
    self.player.token_list = {}
    self.player.token_states = {}
  elseif scene == "battling" then
  end
end

function M:begin_round()
  if self.player:isempty() then
    self.player:hit()
  end

  if self.enemy:isempty() then
    self.enemy:hit()
  end

  self.player:draw()
  self.enemy:draw()

  self.enemy:domoves() -- Enemy exhaustively plays its moves, in order.
end

function M:end_round()

  if self.player.power > self.enemy.power then
    self.enemy:hit()
  elseif self.player.power < self.enemy.power then
    self.player:hit()
  end

  self.enemy.power = 0
  self.player.power = 0

  if self.player.lives <= 0 then
    self.player.lives = self.player.player.battle_stats.lives
    return Engine:transition("gameover")
  end

  if self.enemy.lives <= 0 then
    self.player.lives = self.player.player.battle_stats.lives
    self.player:reset_bag()

    return Engine:transition("drafting")
  end

  self.player.lives = self.player.player.battle_stats.lives
end

--- Sample a random enemy
function M:encounter()
  ---@type Enemy
  local enemy = table.unpack(table.replacement_sample(self.EnemyTable, 1))
  self.enemy = Gameplay.enemy(enemy)
end

function M:load()
  self.rng = love.math.newRandomGenerator(os.clock())

  for _, v in ipairs(self.EnemyTypes) do
    for _ = 1, 1 do
      table.insert(self.EnemyTable, v)
    end
  end

  self.player = Gameplay.player(Class.ooze)

  return self
end

function M:update()
  local scene = self.SceneTypes[self.scene]
  assert(scene ~= nil)

  for _, component in ipairs(scene.layout) do
    component()
  end
end

return M
