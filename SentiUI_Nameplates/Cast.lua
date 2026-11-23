-- Cast bar driver per plate. Spellcast events flip the bar on/off. The
-- fill is driven per frame straight off the engine duration object from
-- UnitCastingDuration/UnitChannelDuration - its getters may return
-- secret numbers, and StatusBar accepts those raw; only Lua arithmetic
-- on them throws. SetTimerDuration is tried on top so clients that do
-- animate it still can. With no duration object the start/end
-- timestamps take over, and when even those are secret the bar shows
-- the spell name as a static full bar.
local _, ns = ...
local S = SentiUI

local Cast = {}
ns.Cast = Cast

local ACC = S.colors.accent

local function plain(v)
	if S.IsSecret(v) then return nil end
	return v
end

local CAST_EVENTS = {
	"UNIT_SPELLCAST_START", "UNIT_SPELLCAST_STOP", "UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_DELAYED",
	"UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_INTERRUPTIBLE",
	"UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
	"UNIT_SPELLCAST_EMPOWER_START", "UNIT_SPELLCAST_EMPOWER_UPDATE",
	"UNIT_SPELLCAST_EMPOWER_STOP",
}

-- per-frame fill from the stored timestamps; arithmetic stays in pcall so
-- secret times just freeze the fill instead of throwing
local function FillFromTimes(self)
	local st, et = self.startT, self.endT
	if not st or not et then return end
	local ok, dur, rem = pcall(function()
		return (et - st) / 1000, (et / 1000) - GetTime()
	end)
	if not ok or not dur or dur <= 0 then return end
	self:SetMinMaxValues(0, dur)
	self:SetValue(self.channel and math.max(0, rem)
		or math.max(0, dur - rem))
	if self.timeText then
		pcall(self.timeText.SetFormattedText, self.timeText,
			"%.1f", math.max(0, rem))
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
		-- the remaining-time text works on either fill path and reads
		-- the same duration object the fill does
		local t = self.timeText
		if t then
			local remFn = d.GetRemainingDuration
			local okR, rem = remFn and pcall(remFn, d)
			if okR and rem then
				pcall(t.SetFormattedText, t, "%.1f", rem)
			end
		end
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

function Cast.Refresh(p)
	local db = ns.Cfg()
	if not db.castBar or not p.unit or p.friendly then
		return Cast.Stop(p)
	end
	-- display text is the 2nd return, like the game's own cast bar; the
	-- type() check alone decides (a secret name is still non-nil)
	local okC, _, name, texture, st, et, _, _, ni =
		pcall(UnitCastingInfo, p.unit)
	local channel = false
	if not okC or type(name) == "nil" then
		okC, _, name, texture, st, et, _, ni = pcall(UnitChannelInfo, p.unit)
		channel = okC and type(name) ~= "nil"
	end
	if type(name) == "nil" then return Cast.Stop(p) end
	p.castBox:Show()
	if p.castIcon:IsShown() then
		pcall(p.castIcon.SetTexture, p.castIcon, texture)
	end
	pcall(p.castText.SetText, p.castText, name)
	if p.castTime then p.castTime:SetText("") end
	-- non-interruptible reads darker + carries the shield badge so you
	-- see at a glance not to waste the kick
	local niCast = plain(ni) == true
	if niCast then
		p.cast:SetStatusBarColor(0.45, 0.45, 0.50)
	else
		p.cast:SetStatusBarColor(ACC.r, ACC.g, ACC.b)
	end
	if p.castShield then p.castShield:SetShown(niCast) end
	p.cast.startT, p.cast.endT, p.cast.channel = st, et, channel
	-- preferred: the engine's duration object drives the bar. The
	-- per-frame fill reads its getters every frame (secret-safe raw
	-- values), so the bar moves even where SetTimerDuration accepts the
	-- duration yet never repaints.
	local durFn = channel and UnitChannelDuration or UnitCastingDuration
	local ok, duration = type(durFn) == "function" and pcall(durFn, p.unit)
	local dir = Enum and Enum.StatusBarTimerDirection
	local interp = Enum and Enum.StatusBarInterpolation
	p.cast.duration = nil
	if ok and duration then
		p.cast.duration = duration
		if dir and interp and p.cast.SetTimerDuration then
			pcall(p.cast.SetTimerDuration, p.cast, duration,
				interp.Immediate,
				channel and dir.RemainingTime or dir.ElapsedTime)
		end
		-- start full; the duration fill corrects it on the same tick
		p.cast:SetMinMaxValues(0, 1)
		p.cast:SetValue(1)
		FillFromDuration(p.cast)
		p.cast:SetScript("OnUpdate", FillFromDuration)
	else
		-- start full; readable times take over per frame, secret times
		-- leave a full bar with the spell name up for the cast
		p.cast:SetMinMaxValues(0, 1)
		p.cast:SetValue(1)
		FillFromTimes(p.cast)
		p.cast:SetScript("OnUpdate", FillFromTimes)
	end
end

function Cast.Stop(p)
	p.cast:SetScript("OnUpdate", nil)
	p.cast.duration = nil
	p.castBox:Hide()
end

-- shared event frame: one registration fans out to the plate on that unit
function Cast.Register()
	for _, ev in ipairs(CAST_EVENTS) do
		S.RegisterEvent(ev, function(_, unit)
			local p = unit and ns.Manager.byUnit[unit]
			if p then Cast.Refresh(p) end
		end)
	end
end
