---@alias Draggable Card | Token

---@class Dragging
---@field ox integer
---@field oy integer
---@field target Draggable

local Gameplay = require("engine.gameplay")

---@class Engine
---@field scene SceneType
---@field rng love.RandomGenerator
---@field TokenTable Token[]
---@field TokenTypes Token[]
---@field CardTable Card[]
---@field CardTypes Card[]
---@field SceneTypes table<string, Scene>
---@field dragging Dragging?
---@field player GameplayData
---@field enemy GameplayData?
local M = {
	scene = "main",

	TokenTable = {},
	CardTable = {},
	EnemyTable = {},

	SceneTypes = require("data.scene.types"),
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
	EnemyTypes = require("data.enemies.types"),

	player = Gameplay.player({ draw = 3, lives = 3 }),
	enemy = nil,
}

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

---@param o Draggable
---@param ox? integer
---@param oy? integer
--- Begin dragging game object o, with offset ox and oy into the sprite.
function M:begin_drag(o, ox, oy)
	self.dragging = {
		target = o,
		ox = ox or 0,
		oy = oy or 0,
	}
end

function M:end_drag()
	assert(self.dragging ~= nil)
	self.dragging = nil
end

---@param o? Draggable
---@return boolean
function M:is_dragging(o)
	if o then
		return self.dragging ~= nil and self.dragging.target == o
	else
		return self.dragging ~= nil
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
	--self.enemy.behaviors()
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
		return Engine:transition("gameover")
	end

	if self.enemy.lives <= 0 then
		self.player:reset_bag()

		for _, v in ipairs(Engine.player.token_list) do
			assert(Engine.player.token_states[v] == "bag", v.type .. " was not in bag")
		end

		return Engine:transition("drafting")
	end
end

---@param n integer
---@return Token[]
function M:pull(n)
	return self:pull_into(n)
end

---@param n integer
---@param tab? Token[]
---@return Token[]
function M:pull_into(n, tab)
	-- Copy each sampled token so that they are unique game objects.
	return table.replacement_sample(self.TokenTable, n, tab, table.copy)
end

---@param n integer
---@param tab? Card[]
---@return Card[]
--- Draw cards at random from the card table. Because the work 'draw' is already taken
--- for drawing tokens from your bag during combat, the word 'fish' is used instead.
--- This is inspired by the french translations of 'draw a card' in other card games.
function M:fish(n, tab)
	-- We copy each sampled element so that they are unique game objects.
	return table.replacement_sample(self.CardTable, n, tab, table.copy)
end

--- Sample a random enemy
function M:encounter()
	---@type Enemy
	local enemy = table.unpack(table.replacement_sample(self.EnemyTable, 1))
	self.enemy = Gameplay.enemy(enemy)
end

function M:load()
	self.rng = love.math.newRandomGenerator(os.clock())

	for _, v in ipairs(self.TokenTypes) do
		for _ = 1, v.freq do
			table.insert(self.TokenTable, v)
		end
	end

	for _, v in ipairs(self.CardTypes) do
		for _ = 1, v.freq do
			table.insert(self.CardTable, v)
		end
	end

	for _, v in ipairs(self.EnemyTypes) do
		for _ = 1, 1 do
			table.insert(self.EnemyTable, v)
		end
	end

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
