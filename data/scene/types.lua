---@alias SceneType "main" | "drafting" | "upgrading" | "battling" | "choosing" | "gameover" | "round"

---@class Scene
---@field name SceneType
---@field layout Component[]

local Components = require("data.scene.components")
local Card = require("data.card")
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
function Inputs.PlayerActive()
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
function Inputs.EnemyActive()
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

local PlayerBag = Components.bag(0.01, 0.2, "Player", "bag", Inputs.PlayerBag)
local PlayerActive = Components.bag(0.01, 0.3, "Player", "active", Inputs.PlayerActive)
local PlayerExhausted = Components.bag(0.01, 0.4, "Player", "exhausted", Inputs.PlayerExhausted)

local EnemyBag = Components.bag(-0.41, 0.2, "Enemy", "bag", Inputs.EnemyBag)
local EnemyActive = Components.bag(-0.41, 0.3, "Enemy", "active", Inputs.EnemyActive)
local EnemyExhausted = Components.bag(-0.41, 0.4, "Enemy", "exhausted", Inputs.EnemyExhausted)

local TokenSelector = Components.token_selector(0.5, 0.5)

local PlayerProfile = function()
	local str = Engine.player.class.type
		.. " -- Lives: "
		.. Engine.player.lives
		.. "/"
		.. Engine.player.class.lives
		.. ". Power: "
		.. Engine.player.power
    .. ". Manapool: "
    .. Engine.player.mana
    .. ". Gold: "
    .. Engine.player.gold

	View:text(str, 0.1, 0.01)
end

local EnemyProfile = Components.enemy(-0.2, 0.01)

local NormalMoveWidth, NormalMoveHeight = UI.skill.getNormalizedDim()

local function EffectsComponent(x, y, cb)
	return function()
		local detail = nil

		View:movelist("effects", "Playereffects", x, y, x, 1)

		local thisx = x + UI.width(5)
		local thisy = y + UI.height(11)

		local total = 0

		for _, effects in pairs(Engine.player.event_handlers) do
			for _, effect in ipairs(effects) do
				View:move(effect, thisx, thisy, effect)

				if View:is_hovering(effect) then
					local detailx = thisx + NormalMoveWidth + UI.width(4)
					detail = function()
						View:details(effect.desc, tostring(effect), detailx, thisy)
					end
				end

				-- if cb then
				-- 	View:register(effect, cb(i, effect))
				-- end

				thisx = thisx + NormalMoveWidth + UI.width(2)
				total = total + 1
			end
		end

		while total < 5 do
			View:move(nil, thisx, thisy, "emptyeffect" .. total)

			thisx = thisx + NormalMoveWidth + UI.width(2)
			total = total + 1
		end

		if detail then
			detail()
		end
	end
end

---@param x number
---@param y number
---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function MovesComponent(x, y, cb)
	return function()
		local detail = nil

		View:movelist("moves", "Playermoves", x, y, x, 1)

		local thisx = x + UI.width(5)
		local thisy = y + UI.height(11)
		local total = 0

		for i, move in ipairs(Engine.player.moves) do
			View:move(move, thisx, thisy, move)

			if View:is_hovering(move) then
				local detailx = thisx + NormalMoveWidth + UI.width(4)
				detail = function()
					View:details(Move.describe(move), tostring(move), detailx, thisy)
				end
			end

			if cb then
				View:register(move, cb(i, move))
			end

			thisx = thisx + NormalMoveWidth + UI.width(2)
			total = total + 1
		end

		while total < 5 do
			View:move(nil, thisx, thisy, "emptymove" .. total)

			thisx = thisx + NormalMoveWidth + UI.width(2)
			total = total + 1
		end

		if detail then
			detail()
		end
	end
end

---@param cb? fun(i: integer, move: Move): table<UserEvent, function>
local function PlayerMoves(cb)
	return MovesComponent(0.1, 0.2, cb)
end

local BattleButton = Components.button(0.4, -Card.height(), 0.1, 0.1, "Battle", function()
	Engine:transition("battling")
end)

local History = Components.history(0.01, 0.1)

---@type Scene[]
return {
	{
		name = "main",
		layout = {
			Components.button(0.4, 0.4, 0.1, 0.1, "Play", function()
				Engine:transition("drafting")
			end),
		},
	},
	{
		name = "gameover",
		layout = {
			Components.button(0.4, 0.4, 0.1, 0.1, "Play", function()
				Engine:transition("drafting")
			end),
		},
	},
	{
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
	{
		name = "upgrading",
		layout = {
			EnemyProfile,
			EnemyBag,

			History,

			EffectsComponent(0.01, 0.6),
			MovesComponent(0.01, 0.4, function(i, move)
				return {
					click = function()
						if Engine.player:doable(move) then
							Engine.player:domove(move)
						end
					end,
				}
			end),

			Components.move_selector(-0.01 - UI.skillbox.getNormalizedDim(), 0.4),

			PlayerProfile,
			PlayerBag,
			PlayerHandUp(function(i)
				return {
					dragend = function(x, y)
						-- If we're above the hand play the card
						local _, cardheight = UI.card.getNormalizedDim()
						print("CARDHEIGHT", cardheight, UI.realize_y(-cardheight), y)
						if y > UI.realize_y(-cardheight) then
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
	{
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
	{
		name = "battling",
		layout = {
			EnemyProfile,
			EnemyActive,
			EnemyExhausted,
			EnemyBag,

			History,

			MovesComponent(0.01, 0.6),

			PlayerProfile,
			PlayerBag,
			PlayerActive,
			PlayerExhausted,

			Components.button(
				-0.11 - NormalMoveWidth,
				-NormalMoveHeight,
				NormalMoveWidth,
				NormalMoveHeight,
				"Draw",
				function()
					Engine:begin_round()
					if Engine:current_scene() == "battling" then
						Engine:transition("round")
					end
				end
			),
		},
	},
	{
		name = "round",
		layout = {
			EnemyProfile,
			EnemyActive,
			EnemyExhausted,
			EnemyBag,

			History,

			PlayerProfile,
			PlayerBag,
			PlayerActive,
			PlayerExhausted,
			MovesComponent(0.01, 0.6, function(_, move)
				return {
					click = function(x, y)
						if Engine.player:doable(move) then
							Engine.player:domove(move)
						end
					end,
				}
			end),

			Components.button(
				-0.11 - NormalMoveWidth,
				-NormalMoveHeight,
				NormalMoveWidth,
				NormalMoveHeight,
				"Done",
				function()
					Engine:end_round()

					if Engine:current_scene() == "round" then
						Engine:transition("battling")
					end
				end
			),
		},
	},
}
