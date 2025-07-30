---@alias ClassType "ooze"

---@class Class
---@field type ClassType
---@field battle_stats BattleStats
---@field token_table TokenDropTable
---@field card_table CardDropTable
---@field signature TokenType
---@field moves MoveType[]
---@field effects EffectType[]
---@field oppeffects EffectType[]

---@type Class[]
local M = {
  {
    type = "ooze",
    signature = "ooze",
    battle_stats = { draw = 3, lives = 3 },
    token_table = {
      ooze = 3,
      coin = 1,
      bomb = 1,
      mana = 2,
      skeleton = 1,
      corruption = 1,
    },
    card_table = {
      sacrifice = 1,
      discover = 1,
      refine = 1,
      pillage = 1,
      bargain = 1,
      meditate = 1,
      recruit = 1,
    },
    moves = {
      "minion_attack",
    },
    effects = {
      "bomb_explode",
      "corruption_hit",
      "draft_coin_draft_ooze",
      "ooze_exhaust_donate",
      "ooze_draft_opponent_does_too",
    },
    oppeffects = {
      "ooze_opponent_draw_donate",
    },
 },
}

return M
