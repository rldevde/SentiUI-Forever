local _, ns = ...

-- Export/import of the char table as a copy-paste string, for accounts
-- that live on another PC (same-PC accounts merge via the
-- Tools/SyncAccounts.py script instead). Format:
--   "SAI1:" .. EncodeForPrint(CompressDeflate(Serialize(payload)))
-- payload = { v = 1, exported = <time>, chars = { [key] = char } }
local Transfer = {}
ns.Transfer = Transfer

-- strtrim is a FrameXML global and not guaranteed on this client.
local strtrim = strtrim or function(s)
	return (tostring(s or ""):match("^%s*(.-)%s*$"))
end

local PREFIX = "SAI1:"

local function Lib()
	return _G.SentiAccountInfoLibDeflate
end

-- Builds the export payload from the whole known char table.
local function Payload()
	return {
		v = 1,
		exported = GetServerTime(),
		chars = ns.db and ns.db.chars or {},
	}
end

-- accountLabel (optional): stamped onto chars that carry no account yet,
-- so they group under this label on the receiving side.
function Transfer.Export(accountLabel)
	local lib = Lib()
	if not (lib and lib.CompressDeflate and lib.EncodeForPrint) then
		return nil
	end
	local payload = Payload()
	if accountLabel and accountLabel ~= "" then
		payload.chars = {}
		for key, char in pairs(ns.db.chars) do
			local copy = {}
			for k, v in pairs(char) do
				copy[k] = v
			end
			if not copy.account or copy.account == "" then
				copy.account = accountLabel
			end
			payload.chars[key] = copy
		end
	end
	local ok, text = pcall(ns.Serializer.Serialize, payload)
	if not ok or not text then
		return nil
	end
	return PREFIX .. lib:EncodeForPrint(lib:CompressDeflate(text))
end

local function ValidateChar(char)
	return type(char) == "table" and type(char.name) == "string"
end

-- Merges an export string into the db. Returns count or nil on failure.
-- The own character record is never overwritten.
function Transfer.Import(text)
	local lib = Lib()
	if not (lib and lib.DecodeForPrint and lib.DecompressDeflate) then
		return nil
	end
	text = strtrim(text or "")
	if text:sub(1, #PREFIX) ~= PREFIX then
		return nil
	end
	local raw = lib:DecodeForPrint(text:sub(#PREFIX + 1))
	local serialized = raw and lib:DecompressDeflate(raw)
	local payload = serialized and ns.Serializer.Deserialize(serialized)
	if type(payload) ~= "table" or type(payload.chars) ~= "table" then
		return nil
	end
	local own = ns.Store.OwnKey()
	local count = 0
	for key, char in pairs(payload.chars) do
		if key ~= own and ValidateChar(char) then
			char.imported = true
			ns.db.chars[key] = char
			count = count + 1
		end
	end
	ns:Fire("SAI_CHARS_CHANGED")
	return count
end
