---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover" | "round" | "shopping"

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

local PlayerBag = Components.bag(0.01, 0.2, "Player", Inputs.PlayerBag)
local EnemyBag = Components.bag(-0.11, 0.2, "Enemy", Inputs.EnemyBag)

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

---@param x number
---@param y number
---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
---@param f? fun(move: Move): boolean
local function MovesComponent(x, y, cb, f)
	return function()
		---@type Move[]
		local moves = table.map(Engine.player.moves, function(move_type)
			return Move[move_type]
		end)

		if f then
			moves = table.filter(moves, f)
		end

		local detail = nil

		for i, move in ipairs(moves) do
			local thisx = x + (i - 1) * Move.width()
			View:move(move, thisx, y)

			if View:is_hovering(move) then
				detail = function()
					View:details(move.desc, move.desc, thisx + Move.width() + 0.01, y)
				end
			end

			if cb then
				View:register(move, cb(i, move))
			end
		end

		if detail then
			detail()
		end
	end
end

---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function PlayerMoves(cb)
	return MovesComponent(0.12, -0.01 - Move.height(), cb, function(move)
		return move.cost.state ~= "bag"
	end)
end

local BattleButton = Components.button(0.4, -Card.height(), 0.1, 0.1, "Battle", function()
	Engine:transition("battling")
end)

local History = Components.history(0.2, 0.1)

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

			PlayerProfile,
			PlayerBag,

			Components.card_selector(0.5 - Card.width() - 0.03, 0.5 - (Card.height() / 2)),

			PlayerHandUp(),
		},
	},
	upgrading = {
		name = "upgrading",
		layout = {
			EnemyProfile,
			EnemyBag,

			History,

			MovesComponent(0.2, 0.5 - Move.height() / 2, function(i, move)
				return {
					click = function()
						if Engine.player:doable(move) then
							Engine.player:domove(move)
						end
					end,
				}
			end, function(move)
				return move.cost.state == "bag"
			end),

      function()

      end,

			PlayerProfile,
			PlayerBag,
			PlayerHandUp(function(i)
				return {
					dragend = function(x, y)
						-- If we're above the hand play the card
						if y > View.normalize_y(-Card.height()) then
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
					BattleButton()
				end
			end,
		},
	},
	choosing = {
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
	battling = {
		name = "battling",
		layout = {
			EnemyProfile,
			EnemyBoard,
			EnemyBag,

			History,

			PlayerMoves(),

			PlayerProfile,
			PlayerBag,
			PlayerBoard,

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

			History,

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
