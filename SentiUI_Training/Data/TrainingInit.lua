local _, ns = ...
-- assembles the player-specific spell list once all Training data
-- files have registered their class tables.
local T = ns.Training

local class = T.ClassData[T.currentClass]
if class then
	T.SpellsByLevel = T.RaceFilter(T.FactionFilter(class.spellsByLevel))
	if class.overriddenGroups then
		T:AddOverriddenSpells(unpack(class.overriddenGroups))
	end
	T.PetAbilityIds = class.petAbilityIds
	T.TomesByLevel = class.tomesByLevel
	T.TomeTaughtSpells = class.tomeTaughtSpells
	T.AddQuestSpells(T.QuestSpells)
end

if T.TomesByLevel then
	for _, tomes in pairs(T.TomesByLevel) do
		for _, tome in ipairs(tomes) do
			if not tome.id then tome.id = tome.itemId end
			if tome.itemId then
				T.TomeIds[tome.itemId] = true
				if tome.family == "Succubus" or tome.family == "Incubus" then
					T.SayaadTomes[tome.itemId] = true
				end
			end
		end
	end
end

if T.buildWeaponTrainerZones then
	T.buildWeaponTrainerZones()
end
