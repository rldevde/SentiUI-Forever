-- ForeverBlackListed JSON encode/decode.
-- WoW cannot write files, so export/import works through a copy/paste popup.
-- The encoder handles the subset we emit (tables, strings, numbers, bools);
-- the decoder is a small recursive-descent parser that accepts any valid JSON.
local _, ns = ...
local FBL = ns.FBL

local type, pairs, tostring, tonumber = type, pairs, tostring, tonumber
local sub, byte, find, format = string.sub, string.byte, string.find, string.format
local concat, sort, tinsert = table.concat, table.sort, table.insert
local floor = math.floor

-- encoder ---------------------------------------------------------------------
local escapes = {
	['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b', ['\f'] = '\\f',
	['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t',
}
local function escStr(s)
	-- Nicht-ASCII als \uXXXX ausgeben: EditBox-Copy/Paste verliert
	-- Bytes >127 (werden zu ?), der Decoder baut \uXXXX wieder
	-- korrekt zu UTF-8 zurueck. Export ist damit reines ASCII.
	local out, i, n = {}, 1, #s
	while i <= n do
		local b = byte(s, i)
		local esc = escapes[sub(s, i, i)]
		if esc then
			out[#out + 1] = esc
			i = i + 1
		elseif b < 0x80 then
			out[#out + 1] = sub(s, i, i)
			i = i + 1
		else
			local cp, len
			if b < 0xE0 then cp, len = b - 0xC0, 2
			elseif b < 0xF0 then cp, len = b - 0xE0, 3
			elseif b < 0xF8 then cp, len = b - 0xF0, 4
			else cp, len = b, 1 end
			for j = 2, len do
				local cb = i + j - 1 <= n and byte(s, i + j - 1) or 0x80
				cp = cp * 0x40 + cb - 0x80
			end
			if cp < 0x10000 then
				out[#out + 1] = format('\\u%04x', cp)
			else -- Astralebene -> Surrogatpaar
				local a = cp - 0x10000
				out[#out + 1] = format('\\u%04x\\u%04x',
					0xD800 + floor(a / 0x400), 0xDC00 + a % 0x400)
			end
			i = i + len
		end
	end
	return '"' .. concat(out) .. '"'
end

local function isArray(t)
	return t[1] ~= nil
end

local function encodeValue(v, buf, ind, lvl)
	local tv = type(v)
	if tv == "string" then
		tinsert(buf, escStr(v))
	elseif tv == "number" then
		if v ~= v or v == math.huge or v == -math.huge then
			tinsert(buf, "null")
		elseif floor(v) == v then
			tinsert(buf, format("%d", v))
		else
			tinsert(buf, tostring(v))
		end
	elseif tv == "boolean" then
		tinsert(buf, v and "true" or "false")
	elseif tv == "table" then
		local pad = ind and string.rep(ind, lvl + 1) or ""
		local padEnd = ind and string.rep(ind, lvl) or ""
		local nl = ind and "\n" or ""
		local sep = ind and ": " or ":"
		if isArray(v) then
			if #v == 0 then
				tinsert(buf, "[]")
				return
			end
			tinsert(buf, "[" .. nl)
			for i = 1, #v do
				tinsert(buf, pad)
				encodeValue(v[i], buf, ind, lvl + 1)
				tinsert(buf, i < #v and ",\n" or nl)
			end
			tinsert(buf, padEnd .. "]")
		else
			local keys = {}
			for k in pairs(v) do
				if type(k) == "string" then tinsert(keys, k) end
			end
			if #keys == 0 then
				tinsert(buf, "{}")
				return
			end
			sort(keys)
			tinsert(buf, "{" .. nl)
			for i, k in ipairs(keys) do
				tinsert(buf, pad)
				tinsert(buf, escStr(k))
				tinsert(buf, sep)
				encodeValue(v[k], buf, ind, lvl + 1)
				tinsert(buf, i < #keys and ",\n" or nl)
			end
			tinsert(buf, padEnd .. "}")
		end
	end
end

function FBL.JsonEncode(v, pretty)
	local buf = {}
	encodeValue(v, buf, pretty and "  " or nil, 0)
	return concat(buf)
end

-- decoder ---------------------------------------------------------------------
local function decodeError(str, pos, msg)
	return format("%s (near offset %d)", msg or "parse error", pos)
end

function FBL.JsonDecode(str)
	if type(str) ~= "string" then return nil, "not a string" end
	str = str:gsub("^\239\187\191", "") -- UTF-8 BOM from files saved by Windows tools
	local pos, len = 1, #str

	local function skipWs()
		while pos <= len do
			local c = byte(str, pos)
			if c == 32 or c == 9 or c == 10 or c == 13 then pos = pos + 1 else break end
		end
	end

	local parseValue -- forward

	local function parseString()
		-- assumes str:sub(pos,pos) == '"'
		pos = pos + 1
		local out = {}
		while pos <= len do
			local c = sub(str, pos, pos)
			if c == '"' then
				pos = pos + 1
				return concat(out)
			elseif c == "\\" then
				local e = sub(str, pos + 1, pos + 1)
				if e == '"' or e == "\\" or e == "/" then
					tinsert(out, e)
					pos = pos + 2
				elseif e == "b" then tinsert(out, "\b") pos = pos + 2
				elseif e == "f" then tinsert(out, "\f") pos = pos + 2
				elseif e == "n" then tinsert(out, "\n") pos = pos + 2
				elseif e == "r" then tinsert(out, "\r") pos = pos + 2
				elseif e == "t" then tinsert(out, "\t") pos = pos + 2
				elseif e == "u" then
					local hex = sub(str, pos + 2, pos + 5)
					local cp = tonumber(hex, 16)
					if not cp then return nil, decodeError(str, pos, "bad \\u escape") end
					pos = pos + 6
					-- UTF-8 encode the code point (surrogates included for BMP pairs)
					if cp >= 0xD800 and cp <= 0xDBFF then
						local hex2 = sub(str, pos + 2, pos + 5)
						local lo = sub(str, pos, pos + 1) == "\\u" and tonumber(hex2, 16) or nil
						if lo and lo >= 0xDC00 and lo <= 0xDFFF then
							cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00)
							pos = pos + 6
						end
					end
					if cp < 0x80 then
						tinsert(out, string.char(cp))
					elseif cp < 0x800 then
						tinsert(out, string.char(0xC0 + floor(cp / 0x40), 0x80 + cp % 0x40))
					elseif cp < 0x10000 then
						tinsert(out, string.char(0xE0 + floor(cp / 0x1000), 0x80 + floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40))
					else
						tinsert(out, string.char(0xF0 + floor(cp / 0x40000), 0x80 + floor(cp / 0x1000) % 0x40, 0x80 + floor(cp / 0x40) % 0x40, 0x80 + cp % 0x40))
					end
				else
					return nil, decodeError(str, pos, "bad escape")
				end
			else
				tinsert(out, c)
				pos = pos + 1
			end
		end
		return nil, decodeError(str, pos, "unterminated string")
	end

	local function parseNumber()
		local s = pos
		if sub(str, pos, pos) == "-" then pos = pos + 1 end
		while pos <= len and find(sub(str, pos, pos), "[%d%.eE%+%-]") do pos = pos + 1 end
		local n = tonumber(sub(str, s, pos - 1))
		if not n then return nil, decodeError(str, s, "bad number") end
		return n
	end

	local function parseObject()
		pos = pos + 1 -- skip {
		local obj = {}
		skipWs()
		if sub(str, pos, pos) == "}" then pos = pos + 1 return obj end
		while pos <= len do
			skipWs()
			if sub(str, pos, pos) ~= '"' then return nil, decodeError(str, pos, "expected key string") end
			local key, err = parseString()
			if key == nil then return nil, err end
			skipWs()
			if sub(str, pos, pos) ~= ":" then return nil, decodeError(str, pos, "expected ':'") end
			pos = pos + 1
			skipWs()
			local val
			val, err = parseValue()
			if err then return nil, err end
			obj[key] = val
			skipWs()
			local c = sub(str, pos, pos)
			if c == "," then pos = pos + 1
			elseif c == "}" then pos = pos + 1 return obj
			else return nil, decodeError(str, pos, "expected ',' or '}'") end
		end
		return nil, decodeError(str, pos, "unterminated object")
	end

	local function parseArray()
		pos = pos + 1 -- skip [
		local arr = {}
		skipWs()
		if sub(str, pos, pos) == "]" then pos = pos + 1 return arr end
		while pos <= len do
			skipWs()
			local val, err = parseValue()
			if err then return nil, err end
			tinsert(arr, val)
			skipWs()
			local c = sub(str, pos, pos)
			if c == "," then pos = pos + 1
			elseif c == "]" then pos = pos + 1 return arr
			else return nil, decodeError(str, pos, "expected ',' or ']'") end
		end
		return nil, decodeError(str, pos, "unterminated array")
	end

	parseValue = function()
		skipWs()
		local c = sub(str, pos, pos)
		if c == "{" then return parseObject() end
		if c == "[" then return parseArray() end
		if c == '"' then return parseString() end
		if c == "t" then
			if sub(str, pos, pos + 3) == "true" then pos = pos + 4 return true end
		elseif c == "f" then
			if sub(str, pos, pos + 4) == "false" then pos = pos + 5 return false end
		elseif c == "n" then
			if sub(str, pos, pos + 3) == "null" then pos = pos + 4 return nil end
		end
		if c == "-" or (c and find(c, "%d")) then return parseNumber() end
		return nil, decodeError(str, pos, "unexpected character")
	end

	local val, err = parseValue()
	if err then return nil, err end
	skipWs()
	if pos <= len then return nil, decodeError(str, pos, "trailing data") end
	return val
end
