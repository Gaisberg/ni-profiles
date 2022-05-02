--------------------------------
-- Beast Mastery
-- Version: 12340
-- Author: Gaisberg
--------------------------------
local ni = ...
local profile = {}
profile.name = "Beast Mastery"
local load_functions = ni.backend.LoadFile(ni.backend.GetBaseFolder() .. "addon\\Rotations\\Misc\\helpers.lua")
load_functions(ni, profile)

local ui = {
    settingsfile = "Beast Mastery.json",
    {
        type = "label",
        text = "Beast Mastery - for 3.3.5a"
    },
    {
        type = "checkbox",
        text = "Debug",
        enabled = false,
        key = "debug"
    },
    {
        type = "checkbox",
        text = "Auto Skinning",
        enabled = false,
        key = "skinning"
    },
    {
        type = "checkbox",
        text = "Auto Looting",
        enabled = false,
        key = "looting"
    },
    {
        type = "separator"
    },
    {
        type = "label",
        text = "Class Settings"
    },
    {
        type = "checkbox",
        text = "Auto Aspect Management",
        enabled = true,
        key = "aspect"
    },
    {
        type = "separator"
    },
    {
        type = "label",
        text = "Pet Settings"
    },
    {
        type = "input",
        text = "Food ID",
        value = "",
        key = "petfood"
    },
    {
        type = "combobox",
        text = "Attacking Mode",
        key = "pet_mode",
        selected = "Leveling",
        menu = {
            {
                text = "Leveling",
                key = "leveling"
            },
            {
                text = "Assist",
                key = "assist"
            }
        }
    }
}

profile.spells = {
    skinning = {
        name = select(1, ni.spell.info(8617))
    },
    autoshot = {
        name = select(1, ni.spell.info(75))
    },
    raptorstrike = {
        name = select(1, ni.spell.info(2973))
    },
    serpentsting = {
        name = select(1, ni.spell.info(1978))
    },
    aspectofmonkey = {
        name = select(1, ni.spell.info(13163))
    },
    aspectofhawk = {
        name = select(1, ni.spell.info(13165))
    },
    aspectofdragonhawk = {
        name = select(1, ni.spell.info(61847))
    },
    aspectofviper = {
        name = select(1, ni.spell.info(34074))
    },
    arcaneshot = {
        name = select(1, ni.spell.info(3044))
    },
    huntersmark = {
        name = select(1, ni.spell.info(1130))
    },
    mendpet = {
        name = select(1, ni.spell.info(136))
    },
    feedpet = {
        name = select(1, ni.spell.info(6991))
    },
    multishot = {
        name = select(1, ni.spell.info(2643))
    },
    autoattack = {
        name = select(1, ni.spell.info(6603))
    },
    mongoosebite = {
        name = select(1, ni.spell.info(1495))
    },
    explosivetrap = {
        name = select(1, ni.spell.info(13813))
    }
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
    "Mongoose Bite"
}

local abilities = {
    ["On Tick"] = function()
        profile.on_tick()
    end,
    ["Looting"] = function()
        --   if profile.get_setting("looting") then
        --       local freeslots = 0
        --       if not profile.incombat and not ni.player.is_looting() and not ni.player.is_moving() then
        --           for k, v in ni.table.pairs(profile.lootables) do
        --               for i = 0, 3 do
        --                   freeslots = freeslots + #GetContainerFreeSlots(i)
        --               end
        --               if freeslots ~= 0 and ni.player.distance(v) < 2 then
        --                   if profile.cast(ni.player.interact, v) then
        --                       return true
        --                   end
        --               end
        --           end
        --       end
        --   end
    end,
    ["Skinning"] = function()
        --   if profile.get_setting("skinning") then
        --       if not profile.incombat and not ni.player.is_moving() and not ni.player.is_channeling() then
        --           for k, v in ni.table.pairs(profile.skinnables) do
        --               if ni.player.distance(v) < 3 then
        --                   if ni.spell.available(profile.spells.skinning.name) then
        --                       if profile.cast(ni.spell.cast, profile.spells.skinning.name, v) then
        --                           return true
        --                       end
        --                   end
        --               end
        --           end
        --       end
        --   end
    end,
    ["Feed Pet"] = function()
        if not profile.incombat and ni.unit.exists("pet") and ni.spell.available(profile.spells.feedpet.name) and
            ni.spell.valid(6991, "pet", false, true, true) then
            local happiness = ni.pet.happiness()
            local foodId = profile.get_setting("petfood")
            if happiness ~= 3 and foodId ~= 0 and ni.item.is_present(foodId) and not ni.unit.buff("pet", 1539) then
                local name = ni.item.info(foodId)
                if (name ~= nil) then
                    if profile.cast(ni.spell.cast, profile.spells.feedpet) then
                        if profile.cast(ni.client.run_text, string.format("/use %s", name)) then
                        end
                    end
                end
            end
        end
    end,
    ["Mend Pet"] = function()
        if ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", profile.spells.mendpet.name) and
            not ni.unit.is_dead_or_ghost("pet") and ni.spell.available(profile.spells.mendpet.name) then
            if profile.cast(ni.spell.cast, profile.spells.mendpet) then
                return true
            end
        end
    end,
    ["Pause Rotation"] = function()
        if ni.player.mounted() or ni.player.is_dead_or_ghost() or not profile.incombat or ni.player.is_channeling() or
            ni.player.is_casting() or ni.player.buff("drink") or ni.player.buff("food") then
            return true;
        end
    end,
    ["Pet Logic"] = function()
        if ni.unit.exists("pet") then
            if profile.get_setting("pet_mode") == "Assist" and not ni.unit.is_dead_or_ghost(profile.target) and
                ni.unit.target("pet") ~= ni.unit.target("player") then
                profile.cast(ni.pet.attack, profile.target)
                return true
            end
            if profile.get_setting("pet_mode") == "Leveling" and not profile.inparty then
                if ni.pet.guid() == ni.unit.guid(ni.unit.target("pettarget")) or not profile.incombat or
                    not ni.unit.exists("pettarget") then
                    profile.pet.attacking = false
                end
                if not profile.pet.attacking then
                    for k, v in ni.table.pairs(profile.enemies) do
                        if ni.unit.target(v) == ni.pet.guid() or ni.unit.target(v) == ni.unit.guid("player") then
                            if not ni.unit.exists(ni.unit.target("pettarget")) then
                                if profile.cast(ni.pet.attack, profile.target) then
                                    profile.pet.attacking = true
                                    return true
                                end
                            end
                            if not profile.pet.attacking and ni.unit.threat(ni.pet.guid(), v) < 3 then
                                if profile.cast(ni.pet.attack, v) then
                                    profile.pet.attacking = true
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end,
    ["Auto Attack"] = function()
        if ni.unit.exists(profile.target) and not ni.spell.is_current(profile.spells.autoshot.name) and
            not ni.player.is_moving() and not ni.player.in_melee(profile.target) and
            ni.spell.valid(profile.spells.autoshot.name, profile.target, true, true) then
            if profile.cast(StartAttack, profile.target) then
                return true
            end
        end
    end,
    ["Explosive Trap"] = function()
        if ni.spell.available(profile.spells.explosivetrap.name) and ni.player.in_melee(profile.target) and
            ni.player.is_facing(profile.target) and #ni.unit.enemies_in_range(profile.target, 10) > 1 then
            if profile.cast(ni.spell.cast, profile.spells.explosivetrap) then
                return true
            end
        end
    end,
    ["Raptor Strike"] = function()
        if ni.spell.available(profile.spells.raptorstrike.name) and
            ni.spell.valid(profile.spells.raptorstrike.name, profile.target, true) and
            ni.player.in_melee(profile.target) and not ni.spell.is_current(profile.spells.raptorstrike.name) then
            if profile.cast(ni.spell.cast, profile.spells.raptorstrike, profile.target) then
                return true
            end
        end
    end,
    ["Mongoose Bite"] = function()
        if ni.spell.available(profile.spells.mongoosebite.name) and
            ni.spell.valid(profile.spells.mongoosebite.name, profile.target, true) and
            ni.player.in_melee(profile.target) then
            if profile.cast(ni.spell.cast, profile.spells.mongoosebite, profile.target) then
                return true
            end
        end
    end,
    ["Serpent Sting"] = function()
        for k, v in ni.table.pairs(profile.enemies) do
            if ni.spell.available(profile.spells.serpentsting.name) and
                ni.spell.valid(profile.spells.serpentsting.name, v, true, true) then
                if not ni.unit.debuff(v, profile.spells.serpentsting.name) and ni.unit.hp(v) > 15 then
                    if profile.cast(ni.spell.cast, profile.spells.serpentsting, v) then
                        return true
                    end
                end
            end
        end
    end,
    ["Aspect Management"] = function()
        if profile.get_setting("aspect") then
            if ni.spell.available(profile.spells.aspectofmonkey.name) then
                if ni.player.level() < 10 and not ni.player.buff(profile.spells.aspectofmonkey.name) then
                    if profile.cast(ni.spell.cast, profile.spells.aspectofmonkey) then
                        return true
                    end
                end
            end
            --    if ni.spell.available(profile.spells.aspectofdragonhawk) then
            --       if not (ni.player.buff(profile.spells.aspectofdragonhawk) or ni.player.buff(profile.spells.aspectofviper)) or
            --           (ni.player.buff(profile.spells.aspectofviper) and ni.player.power() > 70) then
            --           if profile.cast(ni.spell.cast, profile.spells.aspectofdragonhawk) then
            --               if profile.debug then
            --                   print("[debug] Casting " .. profile.spells.aspectofdragonhawk)
            --               end
            --               return true
            --           end
            --       end
            --   end
            if ni.spell.available(profile.spells.aspectofhawk.name) and
                not (ni.player.buff(profile.spells.aspectofhawk.name) or
                    ni.player.buff(profile.spells.aspectofviper.name)) or
                (ni.player.buff(profile.spells.aspectofviper.name) and ni.player.power_percent() > 70) then
                if profile.cast(ni.spell.cast, profile.spells.aspectofhawk) then
                    return true
                end
            end
            if ni.spell.available(profile.spells.aspectofviper.name) then
                if not ni.player.buff(profile.spells.aspectofviper.name) and ni.player.power_percent() < 10 then
                    if profile.cast(ni.spell.cast, profile.spells.aspectofviper) then
                        return true
                    end
                end
            end
        end
    end,
    ["Arcane Shot"] = function()
        if ni.spell.available(profile.spells.arcaneshot.name) and
            ni.spell.valid(profile.spells.arcaneshot.name, profile.target, true, true) then
            if profile.cast(ni.spell.cast, profile.spells.arcaneshot, profile.target) then
                return true
            end
        end
    end,
    ["Multi Shot"] = function()
        if ni.spell.available(profile.spells.multishot.name) and
            ni.spell.valid(profile.spells.multishot.name, profile.target, true, true) and
            not ni.spell.is_current(profile.spells.multishot.name) and not ni.player.is_moving() then
            if profile.cast(ni.spell.cast, profile.spells.multishot, profile.target) then
                return true
            end
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
