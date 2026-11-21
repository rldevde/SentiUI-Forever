-- Castbar: shows casting/channeling for player and target below the unit
-- frame. Name/icon/shield when readable; uninterruptible casts get the
-- accent border instead of the cast color.
--
-- The bar lives on UIParent, not on the frame: the unit frames are secure
-- buttons and child Show/Hide/SetPoint calls inherit the combat lockdown -
-- which is exactly when casts happen. Anchoring an unprotected bar TO the
-- frame is allowed; the bar just follows the frame's visibility.
--
-- Fill: the engine duration object via SetTimerDuration when the client
-- gives one, else a per-frame SetValue from the start/end timestamps -
-- and when even those are secret, a static full bar with the spell name.
local _, ns = ...
local S = SentiUI
local L = ns.L
local Plain = ns.Plain

local type = type
local max = math.max
local GetTime = GetTime
local CreateFrame = CreateFrame

local CB = {}
ns.CastBar = CB

local nextID = 0

-- name/icon/ni + timestamps; secret fields go through untouched, the
-- caller never boolean-tests them
local function ReadCast(unit)
	local ok, _, name, icon, st, et, _, _, notInt =
		pcall(UnitCastingInfo, unit)
	if ok and type(name) ~= "nil" then
		return name, icon, st, et, notInt, false
	end
	ok, _, name, icon, st, et, _, notInt = pcall(UnitChannelInfo, unit)
	if ok and type(name) ~= "nil" then
		return name, icon, st, et, notInt, true
	end
end

-- per-frame fill straight off the engine duration object. The getters
-- can hand back secret numbers, which is why the whole body sits inside
-- pcall: StatusBar:SetValue/SetMinMaxValues take the raw values, only
-- arithmetic or comparisons on them would throw. This is also the path
-- that rescues clients where SetTimerDuration accepts the call but the
-- bar never repaints.
local function FillFromDuration(self)
	local d = self.duration
	if not d then return end
	pcall(function()
		local pctFn = d[self.channel and "GetRemainingPercent"
			or "GetElapsedPercent"]
		local ok, pct = pctFn and pcall(pctFn, d)
		if ok and pct then
			self:SetMinMaxValues(0, 1)
			self:SetValue(pct)
			return
		end
		local totFn = d.GetTotalDuration
		local valFn = d[self.channel and "GetRemainingDuration"
			or "GetElapsedDuration"]
		local okT, tot = totFn and pcall(totFn, d)
		if not (okT and tot) then return end
		self:SetMinMaxValues(0, tot)
		local okV, v = valFn and pcall(valFn, d)
		if okV and v then self:SetValue(v) end
	end)
end

-- per-frame fill from the stored timestamps; all arithmetic stays inside
-- pcall so secret times just freeze the fill instead of throwing
local function FillFromTimes(self)
	local st, et = self.startT, self.endT
	if not st or not et then return end
	local ok, dur, rem = pcall(function()
		return (et - st) / 1000, (et / 1000) - GetTime()
	end)
	if not ok or not dur or dur <= 0 then return end
	self:SetMinMaxValues(0, dur)
	self:SetValue(self.channel and max(0, rem) or max(0, dur - rem))
	if ok then
		pcall(self.time.SetFormattedText, self.time, "%.1f", rem or dur)
	end
end

function CB.Create(f)
	nextID = nextID + 1
	local cb = CreateFrame("StatusBar", "SentiUI_UFCast" .. nextID, UIParent)
	cb:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
	cb:SetMinMaxValues(0, 1)
	cb:SetValue(0)
	cb:SetHeight(14)
	S.Template(cb, "inset")
	cb:SetFrameStrata("MEDIUM")

	cb.icon = cb:CreateTexture(nil, "ARTWORK")
	cb.icon:SetSize(14, 14)
	cb.icon:SetPoint("RIGHT", cb, "LEFT", -2, 0)
	cb.icon:Hide()
	cb.text = ns.Font(cb, 10)
	cb.text:SetPoint("LEFT", cb, "LEFT", 4, 0)
	cb.text:SetPoint("RIGHT", cb, "RIGHT", -32, 0)
	cb.text:SetJustifyH("LEFT")
	cb.text:SetWordWrap(false)
	cb.time = ns.Font(cb, 10)
	cb.time:SetPoint("RIGHT", cb, "RIGHT", -3, 0)
	cb.shield = cb:CreateTexture(nil, "OVERLAY")
	cb.shield:SetSize(10, 10)
	cb.shield:SetPoint("RIGHT", cb, "LEFT", -18, 0)
	cb.shield:Hide()

	cb.anchor = f
	cb:Hide()
	f.Castbar = cb
	return cb
end

local function Paint(cb, notInt)
	local c = S.colors
	if notInt then
		cb:SetStatusBarColor(c.accent2.r, c.accent2.g, c.accent2.b)
		cb.shield:SetTexture("Interface\\Icons\\Spell_Holy_DevotionAura")
		cb.shield:Show()
	else
		cb:SetStatusBarColor(c.accent.r, c.accent.g, c.accent.b)
		cb.shield:Hide()
	end
end

function CB.Update(f)
	local cb = f.Castbar
	if not cb then return end
	local name, icon, st, et, notInt, channel = ReadCast(f.unit)
	if type(name) == "nil" then
		return CB.Stop(f)
	end
	-- sit below the debuff icon row when it is visible, else right under
	-- the frame - the row is an engine container whose icons hang below
	-- the frame, so clear them by row height instead of anchoring to it
	local drop = -3
	if f.Debuffs and f.Debuffs:IsShown() then
		drop = -((f.Debuffs.rowH or 16) + 7)
	end
	cb:ClearAllPoints()
	cb:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, drop)
	cb:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 0, drop)
	pcall(cb.icon.SetTexture, cb.icon, icon)
	cb.icon:SetShown(type(icon) ~= "nil")
	Paint(cb, Plain(notInt) == true)
	pcall(cb.text.SetText, cb.text, name)
	cb.startT, cb.endT, cb.channel = st, et, channel
	cb.duration = nil
	-- preferred: the engine's duration object animates the bar itself
	local durFn = channel and UnitChannelDuration or UnitCastingDuration
	local okD, duration = type(durFn) == "function" and pcall(durFn, f.unit)
	local dir = Enum and Enum.StatusBarTimerDirection
	local interp = Enum and Enum.StatusBarInterpolation
	if okD and duration then
		cb.duration = duration
		-- engine animation is still tried; the per-frame fill below
		-- covers clients where it accepts but never repaints
		if dir and interp and cb.SetTimerDuration then
			pcall(cb.SetTimerDuration, cb, duration, interp.Immediate,
				channel and dir.RemainingTime or dir.ElapsedTime)
		end
	end
	-- start full; the active fill path corrects it, and when times are
	-- secret a full bar with the name still shows
	cb:SetMinMaxValues(0, 1)
	cb:SetValue(1)
	cb.time:SetText("")
	FillFromTimes(cb)
	cb:SetScript("OnUpdate", function(self)
		if self.anchor and not self.anchor:IsShown() then
			self:SetScript("OnUpdate", nil)
			self:Hide()
			return
		end
		if self.duration then
			FillFromDuration(self)
			local okR, rem = pcall(self.duration.GetRemainingDuration,
				self.duration)
			if okR then
				pcall(self.time.SetFormattedText, self.time, "%.1f", rem)
			end
		else
			FillFromTimes(self)
		end
	end)
	cb:SetShown(f:IsShown())
end

function CB.Stop(f)
	local cb = f.Castbar
	if not cb then return end
	cb:SetScript("OnUpdate", nil)
	cb.duration = nil
	cb:Hide()
end
