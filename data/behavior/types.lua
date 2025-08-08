---@alias BehaviorType "greedy" | "reckless"
---
---@class Behavior
---@field token_weights table<TokenType, integer>
---@field type BehaviorType

---@type Behavior[]
return {
	{
		type = "greedy",
		token_weights = {
			coin = 5,
			corruption = 0,
			bomb = 0,
		},
		move_weights = {},
	},
	{
		type = "reckless",
		token_weights = {
			coin = 3,
			corruption = 1,
		},
		move_weights = {},
	},
}
