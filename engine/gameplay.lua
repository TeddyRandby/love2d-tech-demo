local Move = require("data.move")
local Card = require("data.card")
local Effect = require("data.effect")
local Token = require("data.token")

---@alias TokenState "bag" | "active" | "exhausted"

---@class GameplayData
---@field drawn integer
---@field power integer
---@field mana integer
---@field gold integer
---@field lives integer
---@field actions integer
---@field maxlives integer
---@field maxactions integer
---@field TokenTable Token[]
---@field CardTable Card[]
---@field MoveTable Move[]
---@field EffectTable Effect[]
---@field event_handlers table<EffectCause, Effect[]>
---@field token_list Token[]
---@field token_states table<Token, TokenState>
---@field hand Card[]
---@field token_stack Token[][]
---@field token_microops ActionMicroOp[]
---@field choose_impl fun(self:GameplayData)
---@field moves Move[]
---@field class Class
local M = {}

---@return Effect[]
function M:effects()
  ---@type Effect[]
  local tmp = {}

  for _, v in pairs(self.event_handlers) do
    table.append(tmp, v)
  end

  return tmp
end

---@return Token[]
function M:top()
  return self.token_stack[#self.token_stack]
end

---@return Token[]
function M:pop()
  return table.remove(self.token_stack, #self.token_stack)
end

function M:push(e)
  table.insert(self.token_stack, e)
end

---@return Token[]
function M:peek_into(n, tab)
  local peeked = table.sample(self:bag(), n, tab)

  self.token_list = table.filter(self.token_list, function(t)
    return not table.find(peeked, function(ot)
      return ot == t
    end)
  end)

  for _, v in ipairs(peeked) do
    self.token_states[v] = nil
  end

  return peeked
end

---@return Token[]
function M:peek(n)
  return self:peek_into(n)
end

---@return Token[]
function M:pull(n)
  return self:pull_into(n)
end

---@return Token[]
function M:pull_into(n, tab)
  -- Copy each sampled token so that they are unique game objects.
  return table.replacement_sample(self.TokenTable, n, tab, table.copy)
end

function M:opponent()
  return Engine.matchups[self]
end

function M:signature()
  return self.class.signature
end

--- Draw cards at random from the card table. Because the work 'draw' is already taken
--- for drawing tokens from your bag during combat, the word 'fish' is used instead.
--- This is inspired by the french translations of 'draw a card' in other card games.
function M:fish(n, tab)
  -- We copy each sampled element so that they are unique game objects.
  return table.replacement_sample(self.CardTable, n, tab, table.copy)
end

function M:levelup(n)
  local effects = table.flatmap(table.vals(self.event_handlers), function(t)
    return t
  end)

  for _, v in ipairs(self.EffectTable) do
    print(v.type)
  end

  return table.unique_replacement_sample(self.MoveTable, n, {}, self.moves, table.copy),
      table.unique_replacement_sample(self.EffectTable, n, {}, effects, table.copy)
end

function M:hit()
  self.lives = self.lives - 1
end

function M:reset_bag()
  for _, v in ipairs(self.token_list) do
    self.token_states[v] = "bag"
  end

  assert(#self:bag() == #self.token_list)
  assert(#self:active() == 0)
  assert(#self:exhausted() == 0)
end

function M:__tokensin(state)
  ---@type Token[]
  local tmp = {}

  for _, v in ipairs(self.token_list) do
    if self.token_states[v] == state then
      table.insert(tmp, v)
    end
  end

  return tmp
end

function M:bag()
  return self:__tokensin("bag")
end

function M:active()
  return self:__tokensin("active")
end

function M:exhausted()
  return self:__tokensin("exhausted")
end

function M:isempty()
  return table.isempty(self:bag())
end

---@param e EventType
---@param t EventTarget
function M:__fire(e, t)
  local handlers = self.event_handlers[e]

  if handlers then
    for _, h in ipairs(handlers) do
      if h.active then
        if h.should then
          if type(h.should) ~= "function" or h.should(self, t) then
            print("[EFFECT] ", h.cause, h.type .. ": " .. t.type)
            h.effect(self, t)
          end
        end
      end
    end
  end

  -- If the cause doesn't begin with opponent,
  -- Then we fire an opponent event.
  if not e:match("^opponent") then
    self:opponent():__fire("opponent_" .. e, t)
  end
end

function M:choose()
  self:choose_impl()
end

function M:draft(ts)
  for _, v in ipairs(ts) do
    table.insert(self.token_list, v)

    self.token_states[v] = "bag"

    Engine:log_tokenevent("draft", v, self)
  end

  for _, v in ipairs(ts) do
    self:__fire("draft", v)
  end
end

function M:exhaust(ts)
  for _, v in ipairs(ts) do
    self.token_states[v] = "exhausted"
    Engine:log_tokenevent("exhaust", v, self)
  end

  for _, v in ipairs(ts) do
    self:__fire("exhaust", v)
  end
end

function M:activate(ts)
  for _, v in ipairs(ts) do
    assert(self.token_states[v] == "exhausted")
    self.token_states[v] = "active"
    Engine:log_tokenevent("activate", v, self)
  end

  for _, v in ipairs(ts) do
    self:__fire("activate", v)
  end
end

--- Draw n tokens from the bag and move them into the playing field.
function M:draw(n)
  n = n or self.drawn

  local drawn = table.sample(self:bag(), n)

  for _, v in ipairs(drawn) do
    assert(
      self.token_states[v] == "bag",
      "Expected token in bag, found: " .. v.type .. " in " .. self.token_states[v]
    )
    self.token_states[v] = "active"
    Engine:log_tokenevent("draw", v, self)
  end

  for _, v in ipairs(drawn) do
    self:__fire("draw", v)
  end
end

function M:discard(ts)
  for _, v in ipairs(ts) do
    for i, discarded in ipairs(self.token_list) do
      if discarded == v then
        table.remove(self.token_list, i)
        -- Early exit if we find the token
        goto found
      end
    end

    ::found::
    self.token_states[v] = nil
    Engine:log_tokenevent("discard", v, self)
  end

  for _, v in ipairs(ts) do
    self:__fire("discard", v)
  end
end

---@param ts Token[]
---@param to? GameplayData
function M:donate(ts, to)
  to = to or self:opponent()

  for _, donated in ipairs(ts) do
    for i, v in ipairs(self.token_list) do
      if donated == v then
        table.remove(self.token_list, i)
        -- Early exit if we find the token
        goto found
      end
    end

    ::found::
    self.token_states[donated] = nil
    Engine:log_tokenevent("donate", donated, self)
  end

  for _, donated in ipairs(ts) do
    self:__fire("donate", donated)
  end

  to:draft(ts)
end

---@param move Move
function M:doable(move)
  if self.actions <= 0 then
    return false
  end

  if type(move.should) ~= "function" and move.should then
    return Move.cost_is_met(move, self)
  else
    return Move.cost_is_met(move, self) and move.should(self)
  end
end

---@param move Move
function M:domove(move)
  assert(self:doable(move), "Move wasn't doable! " .. move.type)

  self.actions = self.actions - 1
  if move.cost.type == "gold" then
    assert(self.gold >= move.cost.amount)
    self.gold = self.gold - move.cost.amount
  elseif move.cost.type == "manapool" then
    assert(self.mana >= move.cost.amount)
    self.mana = self.mana - move.cost.amount
  else
    local could_pay_with = Move.matches_cost(move, self.token_list, self.token_states)
    assert(#could_pay_with >= move.cost.amount)

    if move.cost.method == "exhaust" then
      self:exhaust(table.take(could_pay_with, move.cost.amount))
    elseif move.cost.method == "draft" then
      self:draft(table.take(could_pay_with, move.cost.amount))
    elseif move.cost.method == "discard" then
      self:discard(table.take(could_pay_with, move.cost.amount))
    elseif move.cost.method == "donate" then
      self:donate(table.take(could_pay_with, move.cost.amount), self:opponent())
    else
      assert(false, "Unhandled move cost pay type: " .. move.cost.method)
    end
  end

  print("[DOMOVE]", self == Engine:player(), move.type)
  move.effect(self)

  -- Log the move event and fire off the handlers.
  Engine:log_moveevent(move, self)

  self:__fire("do", move)
  self:__fire(move.type, move)
end

---@param skill Move | Effect
function M:learn(skill)
  if Move[skill.type] then
    table.insert(self.moves, skill)
  elseif Effect[skill.type] then
    ---@type Effect
    local eff = skill

    Effect.insert(self.event_handlers, eff)
  else
    assert(false, "Unknown skill " .. skill.type)
  end
end

---@param moves? Move[]
function M:domoves(moves)
  moves = moves or self.moves
  for _, move in ipairs(moves) do
    while self:doable(move) do
      self:domove(move)
    end
  end
end

---@param t Token
---@param s? TokenState
function M:useful(t, s)
  local state = self.token_states[t]
  s = s or state

  -- A token we don't have isn't useful
  if not state then
    return false
  end

  -- A token is only useful a we have a move
  -- available which requires it.
  return not not table.find(self.moves, function(move)
    return Move.needs(move, t, s)
  end)
end

---@param card_type CardType
function M:playcardtype(card_type)
  local card = Card[card_type]
  assert(card ~= nil, "Unexpected card type: " .. card_type)
  self:playcard(card)
end

---@param card Card
function M:playcard(card)
  -- assert(#self.token_stack == 0, "Tokenstack was " .. #self.token_stack .. " instead of empty when " .. card.type .. " was played.")
  -- Push an empty table onto the play stack for each card operation we intend to do.
  for _ = 1, #card.ops do
    table.insert(self.token_stack, 1, {})
  end

  local token_microops = table.flatmap(card.ops, function(c)
    return c.microops
  end)

  table.append(self.token_microops, token_microops)

  -- Log this card as played in the event log.
  Engine:log_cardevent(card, self)

  -- TODO: Think through is this a safe way of doing it?
  -- Its not consistent - for tokens, the effects happen *after*
  -- the business of cause takes place.
  self:__fire("play", card)
  self:__fire(card.type, card)

  -- Now we can play
  self:__play()
end

---@param n? integer
function M:play(n)
  n = n or 1

  ---@type Card
  local card = table.remove(self.hand, n)
  assert(card ~= nil, "No card " .. n .. " in hand")

  self:playcard(card)
end

function M:__play()
  while (not table.isempty(self.token_microops)) and (#Engine.scene_buffer == 0) do
    local microop = table.shift(self.token_microops)
    assert(microop ~= nil)

    local t = microop.type

    print("[MICROOP] " .. t)

    if t == "pull" then
      self:pull_into(microop.amount, self:top())
    elseif t == "peek" then
      self:peek_into(microop.amount, self:top())
    elseif t == "opponent_peek" then
      self:opponent():peek_into(microop.amount, self:top())
    elseif t == "signature" then
      for _ = 1, microop.amount do
        table.insert(self:top(), Token.create(self:signature()))
      end
    elseif t == "constant" then
      for _ = 1, microop.amount do
        table.insert(self:top(), table.copy(microop.token))
      end
    elseif t == "filter" then
      local tmp = {}

      for _, v in ipairs(self:pop()) do
        if microop.fun(v) then
          table.insert(tmp, v)
        end
      end

      self:push(tmp)
    elseif t == "choose" then
      self:choose()
    elseif t == "draft" then
      self:draft(self:pop())
    elseif t == "discard" then
      self:discard(self:pop())
    elseif t == "donate" then
      self:donate(self:pop(), self:opponent())
    else
      assert(false, "Unhandled micro op type")
    end
  end
end

---@generic T: { type: string }
---@param srctable T[]
---@param freqtable table<T, integer>
---@return T[]
local function construct_droptable(srctable, freqtable)
  local dt = {}

  for _, v in ipairs(srctable) do
    local freq = freqtable[v.type]
    if freq then
      for _ = 1, freq do
        table.insert(dt, v)
      end
    end
  end

  return dt
end

---@param class Class
---@param choose fun(g: GameplayData)
function M.create(class, choose)
  local instance = table.copy(M)

  return table.merge_over(instance, {
    CardTable = construct_droptable(Engine.CardTypes, class.card_table),
    TokenTable = construct_droptable(Engine.TokenTypes, class.token_table),
    MoveTable = construct_droptable(Engine.MoveTypes, class.move_table),
    EffectTable = construct_droptable(Engine.EffectTypes, class.effect_table),
    mana = 0,
    gold = 0,
    power = 0,
    lives = 0,
    actions = 0,
    maxactions = 5,
    drawn = class.draw,
    maxlives = class.lives,
    hand = {},
    token_list = {},
    token_states = {},
    token_stack = {},
    token_microops = {},
    event_handlers = Effect.table_of(class.effects),
    moves = Move.array_of(class.moves),
    choose_impl = choose,
    class = class,
  })
end

---@param class Class
function M.player(class)
  return M.create(class, function()
    return Engine:transition("choosing")
  end)
end

---@param class Class
---@param behavior Behavior
function M.enemy(class, behavior)
  return M.create(class, function(self)
    local not_chosen, chosen = self:pop(), {}

    for _, o in ipairs(not_chosen) do
      local bhv_bias = behavior.biases[o.type] or 0
      local class_bias = self.class.biases[o.type] or 0

      if type(bhv_bias) == "function" then
        bhv_bias = bhv_bias(self)
      end

      if type(class_bias) == "function" then
        class_bias = class_bias(self)
      end

      local weight = bhv_bias + class_bias

      print("[CHOOSING]", self.class.type, behavior.type, o.type, class_bias, bhv_bias, weight)

      -- THRESHOLD FOR DRAFTING IS 0.5
      if weight >= 0.5 then
        table.insert(chosen, o)
      end
    end

    self:push(table.filter(chosen, not_chosen))
    self:push(not_chosen)
  end)
end

return M
