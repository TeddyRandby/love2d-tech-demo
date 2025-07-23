---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover" | "round"

---@class Scene
---@field name SceneType
---@field layout Component[]

local Components = require("data.scene.components")
local Card = require("data.card")

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
	return Engine.player:field()
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
	return Engine.enemy:field()
end

---@return Token[]
function Inputs.EnemyExhausted()
	return Engine.enemy:exhausted()
end

---@type table<string, Scene>
return {
	main = {
		name = "main",
		layout = {
			Components.button("Play", function()
				Engine:transition("drafting")
			end, 200, 200, 50, 50),
		},
	},
	gameover = {
		name = "gameover",
		layout = {
			Components.button("Play", function()
				Engine:transition("drafting")
			end, 200, 200, 50, 50),
		},
	},
	drafting = {
		name = "drafting",
		layout = {
			Components.enemy(400, 0),
			Components.hand(200, 10, Inputs.EnemyHand),
			Components.bag(200, 20 + Card.height(), Inputs.EnemyBag),
			Components.card_selector(200, 200, 3),
			Components.bag(0, 460, Inputs.PlayerBag),
			Components.hand(0, 500, Inputs.PlayerHand),
		},
	},
	choosing = {
		name = "choosing",
		layout = {
			Components.bag(0, 100, Inputs.PlayerBag),
			Components.enemy(300, 100),
			Components.token_selector(200, 200, 6),
			Components.hand(0, 500, Inputs.PlayerHand),
		},
	},
	upgrading = {
		name = "upgrading",
		layout = {
			Components.enemy(400, 0),
			Components.hand(200, 10, Inputs.EnemyHand),
			Components.bag(200, 20 + Card.height(), Inputs.EnemyBag),
			Components.bag(0, 460, Inputs.PlayerBag),
			Components.hand(0, 500, Inputs.PlayerHand, function(i)
        -- Play a random enemy card
				Engine.enemy:play()

				-- Player plays may change the scene.
				-- This would cause all further plays to early-exit.
				Engine.player:play(i)
			end),
			Components.button("Battle", function()
				Engine:transition "battling"
			end, 400, 200, 50, 50),
		},
	},
	battling = {
		name = "battling",
		layout = {
			Components.enemy(400, 0),
			Components.bag(400, 20, Inputs.EnemyBag),
			Components.board(300, 200, Inputs.EnemyField, Inputs.EnemyExhausted),

			Components.bag(0, 460, Inputs.PlayerBag),
			Components.board(0, 500, Inputs.PlayerField, Inputs.PlayerExhausted),

			Components.button("Fight!", function()
				Engine:begin_round()

				if Engine.scene == "battling" then
					Engine:transition("round")
				end
			end, 200, 200, 50, 50),
		},
	},
	round = {
		name = "round",
		layout = {
			Components.enemy(400, 0),
			Components.bag(400, 20, Inputs.EnemyBag),
			Components.board(300, 200, Inputs.EnemyField, Inputs.EnemyExhausted),
			Components.bag(0, 460, Inputs.PlayerBag),
			Components.board(0, 500, Inputs.PlayerField, Inputs.PlayerExhausted, function(_, v)
				Engine.player:exhaust({ v })
			end),
			function()
				View:text("Lives: " .. Engine.player.lives .. "/3. Power: " .. Engine.player.power, 0, 430)
			end,
			Components.button("Done", function()
				Engine:end_round()
				if Engine.scene == "round" then
					Engine:transition("battling")
				end
			end, 200, 200, 50, 50),
		},
	},
}
