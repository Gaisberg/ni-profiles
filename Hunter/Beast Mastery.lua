--------------------------------
-- Beast Mastery
-- Version: 12340
-- Author: Gaisberg
--------------------------------

local ni = ...
local profile = {}
profile.name = "Beast Mastery"
load_functions = ni.backend.LoadFile(ni.backend.GetBaseFolder().."addon\\Rotations\\Misc\\helpers.lua")
load_functions(ni, profile)

local items = {
	settingsfile = "Beast Mastery.json",
	{
			type = "title",
			text = "|cffb4eb34 Beast Mastery - |cff888888 for 3.3.5a"
	},
	{
			type = "entry",
			text = "Debug",
			tooltip = "Print debug messages",
			enabled = false,
			key = "debug"
	},
	{
			type = "entry",
			text = "\124T" .. select(3, GetSpellInfo(8617)) .. ":20:20\124t |cffFFFFFF" .. GetSpellInfo(8617) .. "|r",
			tooltip = "Auto skin",
			enabled = true,
			key = "skinning"
	},
	{
			type = "entry",
			text = "\124T" .. select(10, GetItemInfo(21841)) .. ":26:26\124t Looting",
			tooltip = "Auto loot",
			enabled = true,
			key = "looting"
	},
	{
			type = "separator"
	},
	{
			type = "title",
			text = "Class Settings"
	},
	{
			type = "entry",
			text = "\124T" .. select(3, GetSpellInfo(34074)) .. ":26:26\124t Aspect Management",
			tooltip = "Will handle aspect changes",
			enabled = true,
			key = "aspect"
	},
	{
			type = "separator"
	},
	{
			type = "title",
			text = "Pet Mode"
	},
	{
			type = "dropdown",
			menu = {
					{
							text = "Leveling",
							selected = true,
							key = "leveling"
					},
					{
							text = "Assist",
							selected = false,
							key = "assist"
					}
			}
	},
	{
			type = "entry",
			text = "\124T" .. select(10, GetItemInfo(2672)) .. ":26:26\124t Pet Food",
			tooltip = "Food for pet to use",
			value = "",
			key = "petfood"
	}
}

local spells = {
    skinning = GetSpellInfo(8617),
    autoshot = GetSpellInfo(75),
    raptorstrike = GetSpellInfo(2973),
    serpentsting = GetSpellInfo(1978),
    aspectofmonkey = GetSpellInfo(13163),
    aspectofhawk = GetSpellInfo(13165),
    aspectofviper = GetSpellInfo(34074),
    arcaneshot = GetSpellInfo(3044),
    huntersmark = GetSpellInfo(1130),
    mendpet = GetSpellInfo(136),
    feedpet = GetSpellInfo(6991),
    multishot = GetSpellInfo(2643),
    autoattack = GetSpellInfo(6603),
    mongoosebite = GetSpellInfo(1495),
		explosivetrap = GetSpellInfo(13813)
}

local queue = {
    "On Tick",
    "Looting",
    "Skinning",
    "Feed Pet",
    "Mend Pet",
    "Pause Rotation",
    "Pet Logic",
    "Aspect Management",
    "Auto Attack",
		"Explosive Trap",
    "Multi Shot",
    "Serpent Sting",
    "Arcane Shot",
		"Raptor Strike",
    "Mongoose Bite",
    "Hunters Mark",
}

local abilities = {
    ["On Tick"] = function()
        profile.on_tick()
    end,
    ["Looting"] = function()
        if select(2, profile.get_setting("looting", items)) then
            local freeslots = 0
            if not profile.incombat and not ni.player.islooting() and not ni.player.ismoving() then
                for k, v in pairs(profile.lootables) do
                    for i = 0, 3 do
                        freeslots = freeslots + #GetContainerFreeSlots(i)
                    end
                    if freeslots ~= 0 and ni.player.distance(v.guid) < 2 then
                        if profile.cast(ni.player.interact, v.guid) then
                            if profile.debug then
                                print("[debug] Looting")
                            end
                            return true
                        end
                    end
                end
            end
        end
    end,
    ["Skinning"] = function()
        if select(2, profile.get_setting("skinning", items)) then
            if not profile.incombat and not ni.player.ismoving() and not ni.player.ischanneling() then
                for k, v in pairs(profile.skinnables) do
                    if ni.player.distance(v.guid) < 3 then
                        if ni.spell.available(spells.skinning) then
                            if profile.cast(ni.spell.cast, spells.skinning, v.guid) then
                                if profile.debug then
                                    print("[debug] Skinning")
                                end
                                return true
                            end
                        end
                    end
                end
            end
        end
    end,
    ["Feed Pet"] = function()
        if not profile.incombat and ni.unit.exists("pet") and ni.spell.available(spells.feedpet) and
            ni.spell.valid("pet", 6991, false, true, true) then
            local happiness = GetPetHappiness()
            local foodId = profile.get_setting("petfood", items)
            if happiness ~= 3 and foodId ~= 0 and ni.player.hasitem(foodId) and not ni.unit.buff("pet", 1539) then
                local name = GetItemInfo(foodId)
                if (name ~= nil) then
                    if profile.cast(ni.spell.cast, spells.feedpet) then
                        if profile.cast(ni.player.runtext, string.format("/use %s", name)) then
                            if profile.debug then
                                print("[debug] Feeding pet")
                            end
                        end
                    end
                end
            end
        end
    end,
    ["Mend Pet"] = function()
        if ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", spells.mendpet) and
            not UnitIsDeadOrGhost("pet") and ni.spell.available(spells.mendpet) then
            if profile.cast(ni.spell.cast, spells.mendpet) then
                if profile.debug then
                    print("[debug] Casting " .. spells.mendpet)
                end
                return true
            end
        end
    end,
    ["Pause Rotation"] = function()
        if IsMounted() or UnitIsDeadOrGhost("player") or UnitUsingVehicle("player") or UnitInVehicle("player") or
            not profile.incombat or ni.player.ischanneling() or ni.player.iscasting() 
						or ni.player.buff("drink") or ni.player.buff("food") then
            return true;
        end
    end,
    ["Pet Logic"] = function()
        if ni.unit.exists("pet") then
            if profile.get_setting("assist", items) and not UnitIsDeadOrGhost(profile.target.guid) and ni.objects["pet"]:target() ~=
                ni.objects["player"]:target() then
                profile.cast(PetAttack, ni.objects["player"]:target())
            end
            if profile.get_setting("leveling", items) then
                if ni.objects["pet"].guid == ni.objects["pettarget"]:target() or not profile.incombat or
                    not ni.unit.exists("pettarget") then
                    profile.pet.attacking = false
                end
                if not profile.pet.attacking then
                    for k, v in pairs(profile.enemies) do
                        if v:target() == ni.objects["pet"].guid or v:target() == ni.objects["player"].guid then
                            if not ni.unit.exists(ni.objects["pet"]:target()) then
                                profile.cast(PetAttack, profile.target)
                                profile.pet.attacking = true
                                break
                            end
                            if not profile.pet.attacking and ni.unit.threat(ni.objects["pet"].guid, v.guid) < 3 then
                                profile.cast(PetAttack, v.guid)
                                profile.pet.attacking = true
                                break
                            end
                        end
                    end
                end
                -- profile.cast(PetAttack, ni.objects["player"]:target())
            end
        end
    end,
    ["Auto Attack"] = function()
        ni.player.target(profile.target.guid)
        if ni.unit.exists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target") and
            UnitAffectingCombat("player") and not IsCurrentSpell(spells.autoshot) and
            not ni.player.ismoving() and not ni.player.inmelee(profile.target.guid) then
            if profile.cast(ni.spell.cast, spells.autoshot, profile.target.guid) then
                if profile.debug then
                    print("[debug] Casting " .. spells.autoshot)
                end
                return true
            end
        end
    end,
    ["Explosive Trap"] = function()
        if ni.spell.available(spells.explosivetrap) and
            ni.player.inmelee(profile.target.guid) and ni.player.isfacing(profile.target.guid) and
            #ni.unit.enemiesinrange(profile.target.guid, 10) > 1 then
            if profile.cast(ni.spell.cast, spells.explosivetrap) then
                if profile.debug then
                    print("[debug] Casting " .. spells.explosivetrap)
                end
            end
        end
    end,
    ["Raptor Strike"] = function()
        if ni.spell.available(spells.raptorstrike) and
            ni.spell.valid(profile.target.guid, spells.raptorstrike) and
            ni.player.inmelee(profile.target.guid) and not IsCurrentSpell(spells.raptorstrike) then
            if profile.cast(ni.spell.cast, spells.raptorstrike, profile.target.guid) then
                if profile.debug then
                    print("[debug] Casting " .. spells.raptorstrike)
                end
                return true
            end
        end
    end,
    ["Mongoose Bite"] = function()
        if ni.spell.available(spells.mongoosebite) and
            ni.spell.valid(profile.target.guid, spells.mongoosebite) and
            ni.player.inmelee(profile.target.guid) and not IsCurrentSpell(spells.mongoosebite) then
            if profile.cast(ni.spell.cast, spells.mongoosebite, profile.target.guid) then
                if profile.debug then
                    print("[debug] Casting " .. spells.mongoosebite)
                end
                return true
            end
        end
    end,
    ["Serpent Sting"] = function()
        for k, v in pairs(profile.enemies) do
            if ni.spell.available(spells.serpentsting) and
                ni.spell.valid(v.guid, spells.serpentsting, true, true) then
                if not ni.unit.debuff(v.guid, spells.serpentsting) and ni.unit.ttd(v.guid) > 5 then
                    if profile.cast(ni.spell.cast, spells.serpentsting, v.guid) then
                        if profile.debug then
                            print("[debug] Casting " .. spells.serpentsting)
                        end
                        return true
                    end
                end
            end
        end
    end,
    ["Aspect Management"] = function()
        if select(2, profile.get_setting("aspect", items)) then
            if ni.spell.available(spells.aspectofmonkey) then
                if UnitLevel("player") < 10 and not ni.player.buff(spells.aspectofmonkey) then
                    if profile.cast(ni.spell.cast, spells.aspectofmonkey) then
                        if profile.debug then
                            print("[debug] Casting " .. spells.aspectofmonkey)
                        end
                        return true
                    end
                end
            end
            if ni.spell.available(spells.aspectofhawk) then
                if not (ni.player.buff(spells.aspectofhawk) or
                    ni.player.buff(spells.aspectofviper)) or
                    (ni.player.buff(spells.aspectofviper) and ni.player.power() > 70) then
                    if profile.cast(ni.spell.cast, spells.aspectofhawk) then
                        if profile.debug then
                            print("[debug] Casting " .. spells.aspectofhawk)
                        end
                        return true
                    end
                end
            end
            if ni.spell.available(spells.aspectofviper) then
                if not ni.player.buff(spells.aspectofviper) and ni.player.power() < 5 then
                    if profile.cast(ni.spell.cast, spells.aspectofviper) then
                        if profile.debug then
                            print("[debug] Casting " .. spells.aspectofviper)
                        end
                        return true
                    end
                end
            end
        end
    end,
    ["Arcane Shot"] = function()
        if ni.spell.available(spells.arcaneshot) and
            ni.spell.valid(profile.target.guid, spells.arcaneshot, true, true) then
            if profile.cast(ni.spell.cast, spells.arcaneshot, profile.target.guid) then
                if profile.debug then
                    print("[debug] Casting " .. spells.arcaneshot)
                end
                return true
            end
        end
    end,
    ["Hunters Mark"] = function()
        if ni.spell.available(spells.huntersmark) and
            ni.spell.valid(profile.target, spells.huntersmark, true, true) then
            if ni.unit.isboss(profile.target) and not ni.unit.debuff(profile.target, spells.huntersmark) then
                if profile.cast(ni.spell.cast, spells.huntersmark, profile.target.guid) then
                    if profile.debug then
                        print("[debug] Casting " .. spells.huntersmark)
                    end
                    return true
                end
            end
        end
    end,
    ["Multi Shot"] = function()
        if #ni.unit.enemiesinrange(profile.target.guid, 10) > 1 then
            if ni.spell.available(spells.multishot) and
                ni.spell.valid(profile.target.guid, spells.multishot, true, true) and
                not IsCurrentSpell(spells.multishot) then
                if profile.cast(ni.spell.cast, spells.multishot, profile.target.guid) then
                    if profile.debug then
                        print("[debug] Casting " .. spells.multishot)
                    end
                    return true
                end
            end
        end
    end
}

local function on_load()
    ni.GUI.AddFrame(profile.name, items);
    ni.combatlog.registerhandler(profile.name, profile.events);
end

local function on_unload()
    ni.GUI.DestroyFrame(profile.name);
    ni.combatlog.unregisterhandler(profile.name);
end

ni.bootstrap.profile(profile.name, queue, abilities, on_load, on_unload)