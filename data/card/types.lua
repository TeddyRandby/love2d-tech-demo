---@alias CardType "discover" | "refine" | "pillage" | "bargain" | "meditate" | "recruit" | "sacrifice" | "refine_two" | "steal" | "opponent_refine"
---@alias CardDropTable table<CardType, integer>
---
---@class Card
---@field type CardType
---@field ops ActionOp[]
---@field priority integer

local Actions = require("data.card.actions")

---@type Card[]
return {
	{
		type = "discover",
		ops = {
			Actions.discover(3),
		},
    priority = 1,
	},
	{
		type = "steal",
		ops = {
			Actions.steal(2),
		},
    priority = -1,
	},
  {
    type = "sacrifice",
    ops = {
      Actions.draft_signature(1),
      Actions.draft_corruption(1),
    },
    priority = 1,
  },
	{
		type = "refine",
		ops = {
			Actions.refine(3),
		},
    priority = -1,
	},
	{
		type = "opponent_refine",
		ops = {
			Actions.opponent_refine(3),
		},
    priority = -1,
	},
	{
		type = "refine_two",
		ops = {
			Actions.refine(3),
			Actions.refine(3),
		},
    priority = -1,
	},
	{
		type = "pillage",
		ops = {
			Actions.loot(1, 1),
			Actions.draft_coin(1),
		},
    priority = 0,
	},
	{
		type = "bargain",
		ops = {
			Actions.draft_coin(1),
			Actions.draft_corruption(1),
		},
    priority = 1,
	},
	{
		type = "meditate",
		ops = {
			Actions.dig_mana(6),
			Actions.draft_corruption(1),
		},
    priority = 1,
	},
	{
		type = "recruit",
		ops = {
			Actions.dig_minion(3),
			Actions.draft_corruption(1),
		},
    priority = 1,
	},
}
