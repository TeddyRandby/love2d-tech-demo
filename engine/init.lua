local Class = require("data.class")
local Scene = require("data.scene")

---@alias CardEventType CardType | "play"
---@alias MoveEventType MoveType | "do"
---@alias EventType TokenEventType | CardEventType | MoveEventType
---@alias EventTarget Token | Card | Move

---@class Event
---@field truetype "token" | "card" | "move"
---@field type EventType
---@field owner GameplayData
---@field target EventTarget

---@class Engine
---@field scene SceneType[]
---@field rng love.RandomGenerator
---@field TokenTypes Token[]
---@field CardTypes Card[]
---@field SceneTypes Scene[]
---@field MoveTypes Move[]
---@field ClassTypes Class[]
---@field EffectTypes Effect[]
---@field BehaviorTypes Behavior[]
---@field player GameplayData?
---@field enemy GameplayData?
---@field time number
---@field event_history Event[]
local M = {
	scene = {},
	time = 0,

	MoveTypes = require("data.move.types"),
	SceneTypes = require("data.scene.types"),
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
	ClassTypes = require("data.class.types"),
	EffectTypes = require("data.effect.types"),
	BehaviorTypes = require("data.behavior.types"),

	player = nil,
	enemy = nil,
	event_history = {},
}

local Gameplay = require("engine.gameplay")

function M:current_scene()
	return table.peek(self.scene)
end

function M:__enterscene()
	local scene = self:current_scene()

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

--- Rewind to the previous scene.
function M:rewind()
	table.pop(self.scene)
	self:__enterscene()
end

---@param scene SceneType
function M:transition(scene)
	table.insert(self.scene, scene)
	self:__enterscene()
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
end

function M:end_round()
	self.enemy:domoves() -- Enemy exhaustively plays its moves, in order.

	if self.player.power > self.enemy.power then
		self.enemy:hit()
	elseif self.player.power < self.enemy.power then
		self.player:hit()
	end

	self.enemy.power = 0
	self.player.power = 0

	if self.player.lives <= 0 then
		self.player.lives = self.player.lives
		return Engine:transition("gameover")
	end

	if self.enemy.lives <= 0 then
		self.player.lives = self.player.lives
		self.player:reset_bag()

		return Engine:transition("drafting")
	end

	self.player.lives = self.player.lives
end

--- Sample a random enemy
function M:encounter()
	local enemy = table.unpack(table.replacement_sample(self.ClassTypes, 1))
	local behavior = table.unpack(table.replacement_sample(self.BehaviorTypes, 1))
	self.enemy = Gameplay.enemy(enemy, behavior)
  self.player.lives = self.player.maxlives
  self.enemy.lives = self.enemy.maxlives
end

--- Push events into the engine's event history.

---@param t TokenEventType
---@param target Token
---@param owner GameplayData
function M:log_tokenevent(t, target, owner)
	---@type Event
	local e = {
		truetype = "token",
		type = t,
		owner = owner,
		target = target,
	}

	table.insert(self.event_history, e)
end

---@param target Move
---@param owner GameplayData
function M:log_moveevent(target, owner)
	---@type Event
	local e = {
		truetype = "move",
		type = target.type,
		owner = owner,
		target = target,
	}

	table.insert(self.event_history, e)
end

---@param target Card
---@param owner GameplayData
function M:log_cardevent(target, owner)
	---@type Event
	local e = {
		truetype = "card",
		type = target.type,
		owner = owner,
		target = target,
	}

	table.insert(self.event_history, e)
end

function M:load()
	self.rng = love.math.newRandomGenerator(os.clock())

	self.player = Gameplay.player(Class.ooze)

	self:transition("main")

	return self
end

---@param dt number
function M:update(dt)
	self.time = self.time + dt
	local scene_type = table.peek(self.scene)

	---@type Scene
	local scene = Scene[scene_type]
	assert(scene ~= nil)

	for _, component in ipairs(scene.layout) do
		component()
	end
end

return M
