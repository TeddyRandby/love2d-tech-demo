---@alias CardType "Discover" | "Refine" | "Pillage" | "Bargain" | "Meditate" | "Recruit"
---@class Card
---@field type CardType
---@field ops ActionOp[]
---@field freq integer

Actions = require("data.card.actions")

---@type Card[]
return {
	{
		type = "Discover",
		freq = 1,
		ops = {
			Actions.discover(3),
		},
	},
	{
		type = "Refine",
		freq = 1,
		ops = {
			Actions.refine(3),
		},
	},
	{
		type = "Pillage",
		freq = 1,
		ops = {
			Actions.loot(1, 1),
			Actions.draft_coin(1),
		},
	},
	{
		type = "Bargain",
		freq = 1,
		ops = {
			Actions.draft_coin(1),
			Actions.draft_corruption(1),
		},
	},
	{
		type = "Meditate",
		freq = 1,
		ops = {
			Actions.dig_mana(6),
			Actions.draft_corruption(1),
		},
	},
	{
		type = "Recruit",
		freq = 1,
		ops = {
			Actions.dig_minion(6),
			Actions.draft_corruption(1),
		},
	},
}
