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
    settingsfile = profile.name .. ".json",
    {
        type = "label",
        text = profile.name .. " - for 3.3.5a"
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
        type = "checkbox",
        text = "Auto Target",
        enabled = false,
        key = "target"
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
        type = "checkbox",
        text = "Multi-Dot Serpent Sting",
        enabled = true,
        key = "serpent"
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

local queue = {
    "On Tick",
    "Looting",
    "Skinning",
    "Feed Pet",
    "Mend Pet",
    "Pause Rotation",
    "Auto Target",
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
        if profile.looting() then
            return true
        end
    end,
    ["Skinning"] = function()
        if profile.skinning() then
            return true
        end
    end,
    ["Feed Pet"] = function()
        if not profile.incombat and ni.unit.exists("pet") and ni.pet.happiness() ~= 3 then
            local foodId = profile.get_setting("petfood")
            if foodId ~= 0 and ni.item.is_present(foodId) and not ni.unit.buff("pet", 1539) then
                local name = ni.item.info(foodId)
                if (name ~= nil) then
                    if profile.cast(ni.spell.cast, ni.spells.feed_pet, "pet") then
                        if profile.cast(ni.client.run_text, string.format("/use %s", name)) then
                            return true
                        end
                    end
                end
            end
        end
    end,
    ["Mend Pet"] = function()
        if ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", ni.spells.mend_pet) then
            return profile.cast(ni.spell.cast, ni.spells.mend_pet)
        end
    end,
    ["Pause Rotation"] = function()
        if profile.pause_rotation() then
            return true
        end
    end,
    ["Pet Logic"] = function()
        if ni.unit.exists("pet") then
            if ni.unit.guid(ni.unit.target("pet")) ~= profile.pet.target or not profile.incombat or
                not ni.unit.exists("pettarget") then
                profile.pet.attacking = false
            end
            if profile.get_setting("pet_mode") == "Assist" and ni.unit.target("pet") ~= ni.unit.target("player") and
                not ni.unit.is_dead_or_ghost("target") and not profile.pet.attacking and not ni.unit.is_silenced("pet") and
                not ni.unit.is_pacified("pet") and not ni.unit.is_stunned("pet") and not ni.unit.is_fleeing("pet") then
                profile.cast(ni.pet.attack, "target")
                profile.pet.attacking = true
            end
            if profile.get_setting("pet_mode") == "Leveling" then
                if not profile.pet.attacking then
                    for k in ni.table.pairs(ni.player.enemies_in_combat_in_range(40)) do
                        if ni.unit.target(k) == "player" or ni.unit.threat("pet", k) < 3 or
                            (not ni.pet.is_attack_active() and profile.incombat) then
                            if profile.cast(ni.pet.attack, k) then
                                profile.pet.attacking = true
                                profile.pet.target = k
                                break
                            end
                        end
                    end
                end
            end
        end
    end,
    ["Auto Target"] = function()
        if profile.auto_target() then
            return true
        end
    end,
    ["Auto Attack"] = function()
        if profile.auto_attack() then
            return true
        end
    end,
    ["Explosive Trap"] = function()
        if ni.player.in_melee("target") and #ni.unit.enemies_in_combat_in_range("target", 10) > 1 and
            ni.player.is_facing("target") then
            if profile.cast(ni.spell.cast, ni.spells.explosive_trap) then
                return true
            end
        end
    end,
    ["Raptor Strike"] = function()
        if not ni.spell.is_current(ni.spells.raptor_strike) and ni.player.in_melee("target") then
            if profile.cast(ni.spell.cast, ni.spells.raptor_strike, "target") then
                return true
            end
        end
    end,
    ["Mongoose Bite"] = function()
        if ni.player.in_melee("target") then
            if profile.cast(ni.spell.cast, ni.spells.mongoose_bite, "target") then
                return true
            end
        end
    end,
    ["Serpent Sting"] = function()
        if profile.get_setting("serpent") then
            for k in ni.table.pairs(ni.player.enemies_in_combat_in_range(35)) do
                if not ni.unit.debuff(k, ni.spells.serpent_sting) and ni.unit.hp(k) > 15 then
                    if profile.cast(ni.spell.cast, ni.spells.serpent_sting, k) then
                        return true
                    end
                end
            end
        else
            if not ni.unit.debuff("target", ni.spells.serpent_sting) and ni.unit.hp("target") > 15 then
                if profile.cast(ni.spell.cast, ni.spells.serpent_sting, "target") then
                    return true
                end
            end
        end
    end,
    ["Aspect Management"] = function()
        if profile.get_setting("aspect") then
            if ni.player.level() < 10 and not ni.player.buff(ni.spells.aspect_of_the_monkey) then
                if profile.cast(ni.spell.cast, ni.spells.aspect_of_the_monkey) then
                    return true
                end
            end
            --    if ni.spell.available(ni.spells.aspectofdragonhawk) then
            --       if not (ni.player.buff(ni.spells.aspectofdragonhawk) or ni.player.buff(ni.spells.aspectofviper)) or
            --           (ni.player.buff(ni.spells.aspectofviper) and ni.player.power() > 70) then
            --           if profile.cast(ni.spell.cast, ni.spells.aspectofdragonhawk) then
            --               if profile.debug then
            --                   print("[debug] Casting " .. ni.spells.aspectofdragonhawk)
            --               end
            --               return true
            --           end
            --       end
            --   end
            if not (ni.player.buff(ni.spells.aspect_of_the_hawk) or ni.player.buff(ni.spells.aspect_of_the_viper)) or
                (ni.player.buff(ni.spells.aspect_of_the_viper) and ni.player.power_percent() > 70) then
                if profile.cast(ni.spell.cast, ni.spells.aspect_of_the_hawk) then
                    return true
                end
            end
            if not ni.player.buff(ni.spells.aspect_of_the_viper) and ni.player.power_percent() < 10 then
                if profile.cast(ni.spell.cast, ni.spells.aspect_of_the_viper) then
                    return true
                end
            end
        end
    end,
    ["Arcane Shot"] = function()
        if profile.cast(ni.spell.cast, ni.spells.arcane_shot, "target") then
            return true
        end
    end,
    ["Multi Shot"] = function()
        if profile.cast(ni.spell.cast, ni.spells.multishot, "target") then
            return true
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
