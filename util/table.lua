---@generic T
---@generic X
---@param src T[]
---@param n integer
---@param dst? T[]
---@param f? fun(in: T): X
---@return T[]
function table.replacement_sample(src, n, dst, f)
	dst = dst or {}

	if f then
		for _ = 1, n do
			local idx = math.random(1, #src)
			table.insert(dst, f(src[idx]))
		end
	else
		for _ = 1, n do
			local idx = math.random(1, #src)
			table.insert(dst, src[idx])
		end
	end

	return dst
end

---@generic T
---@generic X
---@param src T[]
---@param n integer
---@param dst? T[]
---@param f? fun(in: T): X
---@return T[]
function table.sample(src, n, dst, f)
	dst = dst or {}

	if f then
		for _ = 1, n do
			local idx = math.random(1, #src)
		table.insert(dst, f(table.remove(src, idx)))
		end
	else
		for _ = 1, n do
			local idx = math.random(1, #src)
		table.insert(dst, table.remove(src, idx))
		end
	end

	return dst
end

---@generic T
---@generic X
---@param f fun(in: T): X
---@param t T[]
---@return X[]
function table.map(t, f)
	local tmp = {}

	for _, v in ipairs(t) do
		table.insert(tmp, f(v))
	end

	return tmp
end

---@generic T
---@param f fun(in: T): boolean
---@param t T[]
---@return T[]
function table.filter(t, f)
	local tmp = {}

	for _, v in ipairs(t) do
    if f(v) then
      table.insert(tmp, v)
    end
	end

	return tmp
end

---@generic T: table
---@param t T
---@return T
function table.copy(t)
	local tmp = {}

	for k, v in pairs(t) do
		tmp[k] = v
	end

	return tmp
end

---@generic T
---@param t T[]
---@return T?
function table.pop(t)
  return table.remove(t, #t)
end
