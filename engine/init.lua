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
---@field scene_buffer SceneType[]
---@field rng love.RandomGenerator
---@field TokenTypes Token[]
---@field CardTypes Card[]
---@field SceneTypes Scene[]
---@field MoveTypes Move[]
---@field ClassTypes Class[]
---@field EffectTypes Effect[]
---@field BehaviorTypes Behavior[]
---@field players GameplayData[]
---@field matchups table<GameplayData, GameplayData>
---@field time number
---@field event_history Event[]
local M = {

	MoveTypes = require("data.move.types"),
	SceneTypes = require("data.scene.types"),
	TokenTypes = require("data.token.types"),
	CardTypes = require("data.card.types"),
	ClassTypes = require("data.class.types"),
	EffectTypes = require("data.effect.types"),
	BehaviorTypes = require("data.behavior.types"),

	players = {},
	matchups = {},

	onsettle_cb = nil,

	event_history = {},
	scene = { "main" },
	scene_buffer = {},
	time = 0,
}

local Gameplay = require("engine.gameplay")

---@param cb? function
function M:onsettle(cb)
	if cb then
		self.onsettle_cb = cb
	elseif self.onsettle_cb then
		self:onsettle_cb()
	end
end

---@return GameplayData
function M:player()
	return self.players[1]
end

---@return GameplayData
function M:enemy()
	return self.matchups[self:player()]
end

---@param player_class Class
---@param opps integer
function M:begin_game(player_class, opps)
	local tmp = {}
	table.insert(tmp, Gameplay.player(player_class))

	for _ = 1, opps do
		table.insert(tmp, self:encounter())
	end

	self.players = tmp
end

---Create random matchups for each player
function M:matchup()
	local players = table.copy(self.players)
	assert(#players % 2 == 0)

	repeat
		local l, r = table.unpack(table.sample(players, 2))
		assert(l ~= nil)
		assert(r ~= nil)
		self.matchups[l] = r
		self.matchups[r] = l
	until table.isempty(players)

	for i, v in ipairs(self.players) do
		assert(v:opponent() ~= nil, "No opponent made for " .. i .. " : " .. v.class.type)
	end
end

function M:current_scene()
	return table.peek(self.scene)
end

---@param scene SceneType
function M:__exitscene(scene)
	print("[EXITSCENE]", scene)
	if scene == "choosing" then
		-- This will complete any pending micro-ops.
		-- As we may have yielded in the middle of playing a card
		-- (For example, to choose a token as an effect of playing a card)
		for _, v in ipairs(self.players) do
			v:__play()
		end
	end
end

---@param scene SceneType
function M:__enterscene(scene)
	print("[ENTERSCENE]", scene)
	if scene == "drafting" then
		self:matchup()

		for _, v in ipairs(self.players) do
			v:reset_bag()
			v.lives = v.class.lives
			v.power = 0
			v.mana = 0
			v.actions = 0
		end
	elseif scene == "battling" then
		for i = 2, #self.players do
			local bot = self.players[i]
			table.sort(bot.hand, function(a, b)
				return a.priority + b.priority <= 0
			end)
		end
	elseif scene == "round" then
	elseif scene == "gameover" then
		self.players = {}
		self.matchups = {}
	elseif scene == "battling" then
	end
end

function M:bots_pickcard()
	for i = 2, #self.players do
		local bot = self.players[i]
		--- TODO: Do I need to pass table.copy here?
		table.replacement_sample(bot.CardTable, 1, bot.hand)
	end
end

function M:bots_playcard()
	for i = 2, #self.players do
		local bot = self.players[i]
		bot:play()
	end
end

function M:bots_buyskill()
	for i = 2, #self.players do
		local bot = self.players[i]
		if bot.gold > 0 then
			local skills = table.append(bot:levelup(1))
			local chosen = table.unpack(table.sample(skills, 1))
			bot:learn(chosen)
			bot.gold = bot.gold - 1
		end
	end
end

--- Rewind to the previous scene.
function M:rewind()
	local scene = table.pop(self.scene)

	if scene ~= nil then
		print("REWIND OVER .. ", scene)
		self:__exitscene(scene)
	end

	if scene ~= "settling" then
		self:__enterscene(self:current_scene())
	end
end

---@param scene SceneType
function M:rewindto(scene)
	repeat
		local popped_scene = table.pop(self.scene)

		if popped_scene ~= nil then
			print("REWINDTO OVER .. ", popped_scene)
			self:__exitscene(popped_scene)
		end
	until self:current_scene() == scene

	self:__enterscene(self:current_scene())
end

---@param scene SceneType
function M:transition(scene)
	table.insert(self.scene_buffer, scene)
	-- self:__enterscene(scene)
end

function M:begin_round()
	for _, v in ipairs(self.players) do
		if v:isempty() then
			v:hit()
		end

		v:draw()
	end
end

function M:battling()
	-- We are still battling if some player *and* their opponent
	-- still have lives left. This is redundant bc it checks every matchup twice,
	-- but thats okay.
	return not not table.find(self.players, function(p)
		return p.lives > 0 and p:opponent().lives > 0
	end)
end

function M:end_round()
  for _, v in ipairs(self.players) do
    v.actions = 5
  end

	for i, v in ipairs(self.players) do
		v:domoves()
	end

	for i, v in ipairs(self.players) do
		if v.power < v:opponent().power then
			v:hit()
		end

		v.power = 0

		if v.lives <= 0 then
			-- A little scuffed
			if v == self:player() then
				return Engine:rewindto("main")
			elseif v == self:enemy() then
				-- Complete all the other battles
				-- repeat
				-- 	self:begin_round()
				-- 	self:end_round()
				-- until not self:battling()

				-- Complete the round without player input
				-- This rewinds *over* the choose that moves above may leave us in.
				-- This bad
				Engine:rewindto("drafting")
			end
		end
	end
end

--- Sample a random enemy
---@return GameplayData
function M:encounter()
	local enemy = table.unpack(table.replacement_sample(self.ClassTypes, 1))
	local behavior = table.unpack(table.replacement_sample(self.BehaviorTypes, 1))
	return Gameplay.enemy(enemy, behavior)
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

---@param player_class Class
function M:game(player_class)
	self:begin_game(player_class, 11)
	self:transition("drafting")
end

function M:load()
	self.rng = love.math.newRandomGenerator(os.clock())
	return self
end

---@param dt number
function M:update(dt)
	self.time = self.time + dt

	local scene_type = table.peek(self.scene)

	---@type Scene
	local scene = Scene[scene_type]
	assert(scene ~= nil, "No scene: " .. scene_type)

	for _, component in ipairs(scene.layout) do
		component()
	end

	if #self.scene_buffer > 0 then
		table.append(self.scene, self.scene_buffer)
		self.scene_buffer = {}
		self:__enterscene(self:current_scene())
	end
end

return M
