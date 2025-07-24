---@alias CardType "Discover" | "Refine" | "Pillage" | "Bargain" | "Meditate" | "Recruit"
---@alias CardDropTable table<CardType, integer>
---
---@class Card
---@field type CardType
---@field ops ActionOp[]

Actions = require("data.card.actions")

---@type Card[]
return {
	{
		type = "Discover",
		ops = {
			Actions.discover(3),
		},
	},
	{
		type = "Refine",
		ops = {
			Actions.refine(3),
		},
	},
	{
		type = "Pillage",
		ops = {
			Actions.loot(1, 1),
			Actions.draft_coin(1),
		},
	},
	{
		type = "Bargain",
		ops = {
			Actions.draft_coin(1),
			Actions.draft_corruption(1),
		},
	},
	{
		type = "Meditate",
		ops = {
			Actions.dig_mana(6),
			Actions.draft_corruption(1),
		},
	},
	{
		type = "Recruit",
		ops = {
			Actions.dig_minion(6),
			Actions.draft_corruption(1),
		},
	},
}
