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
			if #src == 0 then
				return dst
			end
			local idx = math.random(1, #src)
			table.insert(dst, f(src[idx]))
		end
	else
		for _ = 1, n do
			if #src == 0 then
				return dst
			end
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
			if #src == 0 then
				return dst
			end
			local idx = math.random(1, #src)
			table.insert(dst, f(table.remove(src, idx)))
		end
	else
		for _ = 1, n do
			if #src == 0 then
				return dst
			end
			local idx = math.random(1, #src)
			table.insert(dst, table.remove(src, idx))
		end
	end

	return dst
end

---@generic T
---@generic X
---@param f fun(in: T, i?: integer): X
---@param t T[]
---@return X[]
function table.map(t, f)
	local tmp = {}

	for i, v in ipairs(t) do
		table.insert(tmp, f(v, i))
	end

	return tmp
end

---@generic T
---@generic X
---@param f fun(in: T): X[]
---@param t T[]
---@return X[]
function table.flatmap(t, f)
	local tmp = {}

	for _, x in ipairs(t) do
		for _, v in ipairs(f(x)) do
			table.insert(tmp, v)
		end
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

---@generic T
---@param t T[]
---@return T?
function table.shift(t)
	return table.remove(t, 1)
end

---@generic T
---@param t T[]
---@return boolean
function table.isempty(t)
	return #t == 0
end

---@generic K
---@generic V
---@param t table<K, V>
---@return K[]
function table.keys(t)
	local tmp = {}

	for k in pairs(t) do
		table.insert(k)
	end

	return tmp
end

---@generic K
---@generic V
---@param t table<K, V>
---@return V[]
function table.vals(t)
	local tmp = {}

	for _, v in pairs(t) do
		table.insert(v)
	end

	return tmp
end

---@generic T
---@param f fun(in: T): boolean
---@param t T[]
---@return T?
function table.find(t, f)
	for _, v in ipairs(t) do
		if f(v) then
			return v
		end
	end
end

---@generic T
---@param f fun(in: T): boolean
---@param t T[]
---@return integer
function table.count(t, f)
	local count = 0

	for _, v in ipairs(t) do
		if f(v) then
			count = count + 1
		end
	end

	return count
end
