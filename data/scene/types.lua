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
			Components.bag(-0.1, 0.05, Inputs.EnemyBag),
			Components.hand(0.01, 0.08, Inputs.EnemyHand),

			Components.card_selector(Card.width() / 2, 0.5 - (Card.height() / 2), 3),

			Components.bag(0.01, -Card.height() - 0.01 - 0.04, Inputs.PlayerBag),
			Components.hand(0.01, -Card.height() - 0.01, Inputs.PlayerHand),
		},
	},
	upgrading = {
		name = "upgrading",
		layout = {
			Components.enemy(-0.1, 0.01),
			Components.bag(-0.1, 0.05, Inputs.EnemyBag),
			Components.hand(0.01, 0.08, Inputs.EnemyHand),

			Components.bag(0.01, -Card.height() - 0.01 - 0.04, Inputs.PlayerBag),
			Components.hand(0.01, -Card.height() - 0.01, Inputs.PlayerHand, function(i)
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
			Components.button(-0.11, -0.21, 0.1, 0.2, "Battle", function()
				Engine:transition("battling")
			end),
		},
	},
	choosing = {
		name = "choosing",
		layout = {
			Components.enemy(-0.1, 0.01),
			Components.bag(-0.1, 0.05, Inputs.EnemyBag),

			Components.token_selector(0.4, 0.4, 6),

			Components.hand(0.01, -Card.height() - 0.01, Inputs.PlayerHand),
		},
	},
	battling = {
		name = "battling",
		layout = {
			Components.enemy(-0.1, 0.01),
			Components.bag(-0.1, 0.05, Inputs.EnemyBag),
			Components.board(0.01, Token.radius() * 2 + 0.1, Inputs.EnemyField, Inputs.EnemyExhausted),

			function()
				local str = "Lives: " .. Engine.player.lives .. "/3. Power: " .. Engine.player.power
				View:text(str, 0.01, View.normalize_y(-0.01) - love.graphics.getFont():getHeight())
			end,
			Components.bag(0.01, -0.06, Inputs.PlayerBag),
			Components.board(0.01, -Token.radius() * 2 - 0.1, Inputs.PlayerField, Inputs.PlayerExhausted),

			function()
				for i, v in ipairs(Engine.player.moves) do
					View:text(v, -0.1, -0.4 + i * 0.01)
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
			Components.bag(-0.1, 0.05, Inputs.EnemyBag),
			Components.board(0.01, Token.radius() * 2 + 0.1, Inputs.EnemyField, Inputs.EnemyExhausted),

			Components.bag(0.01, -0.06, Inputs.PlayerBag),
			Components.board(
				0.01,
				-Token.radius() * 2 - 0.1,
				Inputs.PlayerField,
				Inputs.PlayerExhausted,
				function(_, v)
					if Engine.player:useful(v) then
						return {
							dragend = function() end,
						}
					end
				end
			),

			function()
				local str = "Lives: " .. Engine.player.lives .. "/3. Power: " .. Engine.player.power
				View:text(str, 0.01, View.normalize_y(-0.01) - love.graphics.getFont():getHeight())
			end,
			function()
				for i, v in ipairs(Engine.player.moves) do
					View:text(v, -0.1, -0.4 + i * 0.01)
					View:register(v, {
						receive = function(x, y, t)
							local move = require("data.move.types")[v]
							if Move.needs(move, t, Engine.player.token_states[t]) then
								Engine.player:exhaust({ t })
								move.effect(Engine.player)
							end
						end,
					})
				end
			end,

			Components.button(-0.11, -0.21, 0.1, 0.2, "Done", function()
				Engine:end_round()
				if Engine.scene == "round" then
					Engine:transition("battling")
				end
			end),
		},
	},
}
