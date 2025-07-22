---@alias SceneType "main" | "drafting" | "upgrading" | "battling"

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
	drafting = {
		name = "drafting",
		layout = {
			Components.bag(0, 100),
			Components.card_selector(200, 200, 3),
			Components.hand(0, 500),
		},
	},
	upgrading = {
		name = "upgrading",
		layout = {
			Components.bag(0, 100),
			Components.hand(0, 500),
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
