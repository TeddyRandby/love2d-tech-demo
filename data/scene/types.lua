---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover"

---@class Scene
---@field name SceneType
---@field layout Component[]

local Components = require("data.scene.components")

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
			Components.bag(0, 100),
			Components.card_selector(200, 200, 3),
			Components.hand(0, 500),
		},
	},
	choosing = {
		name = "choosing",
		layout = {
			Components.bag(0, 100),
			Components.token_selector(200, 200, 6),
			Components.hand(0, 500),
		},
	},
	upgrading = {
		name = "upgrading",
		layout = {
			Components.bag(0, 100),
			Components.hand(0, 500),
			function()
				if #Engine.hand == 0 then
					Components.button("play", function()
						Engine:transition("battling")
					end, 200, 200, 50, 50)()
				end
			end,
		},
	},
	battling = {
		name = "battling",
		layout = {
			Components.bag(0, 100),
			Components.button("Draw", function()
				Engine:round()
			end, 200, 200, 50, 50),
			Components.board(0, 500),
		},
	},
}
