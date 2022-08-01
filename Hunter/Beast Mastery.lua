--------------------------------
-- Beast Mastery
-- Version: 12340  (3.3.5a)
-- Author: Gaisberg
-- Not tested past level 60...
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
        text = "Auto Target",
        enabled = false,
        key = profile.target
    },
    {
        type = "separator"
    },
    {
        type = "label",
        text = "Class Settings"
    },
    {
        type = "separator"
    },
    {
        type = "label",
        text = "Pet Settings"
    }
}

local queue = {
    "On Tick",
    "Pet Logic",
    "Pause Rotation",
    "Auto Target",
    "Auto Attack",
    "Aspect Management",
    "Multi Target",
    "Single Target"
}

local abilities = {
    ["On Tick"] = function()
        profile.on_tick()
    end,
    ["Pause Rotation"] = function()
        if profile.pause_rotation() then
            return true
        end
    end,
    ["Pet Logic"] = function()
        -- Feed Pet
        if not profile.incombat and ni.unit.exists("pet") and ni.pet.happiness() ~= 3 then
            local foodId = 33454 -- hard coded until input has callback
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
        -- Mend Pet
        if ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", ni.spells.mend_pet) then -- hard coded until slider has callback
            return profile.cast(ni.spell.cast, ni.spells.mend_pet)
        end
        if not profile.pause_rotation() then
            if ni.unit.exists("pet") and not ni.unit.is_dead_or_ghost("pet") then
                if ni.unit.target("pet") ~= ni.unit.target("player") and not ni.unit.is_silenced("pet") and
                    not ni.unit.is_pacified("pet") and not ni.unit.is_stunned("pet") and not ni.unit.is_fleeing("pet") then
                    profile.cast(ni.pet.attack, profile.target)
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
        if ni.player.in_melee(profile.target) and #ni.unit.enemies_in_range(profile.target, 10) > 1 and
            ni.player.is_facing(profile.target) then
            if profile.cast(ni.spell.cast, ni.spells.explosive_trap) then
                return true
            end
        end
    end,
    ["Raptor Strike"] = function()
        if not ni.spell.is_current(ni.spells.raptor_strike) and ni.player.in_melee(profile.target) then
            if profile.cast(ni.spell.cast, ni.spells.raptor_strike, profile.target) then
                return true
            end
        end
    end,
    ["Mongoose Bite"] = function()
        if ni.player.in_melee(profile.target) then
            if profile.cast(ni.spell.cast, ni.spells.mongoose_bite, profile.target) then
                return true
            end
        end
    end,
    ["Aspect Management"] = function()
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
    end,
    ["Arcane Shot"] = function()
        if profile.cast(ni.spell.cast, ni.spells.arcane_shot, profile.target) then
            return true
        end
    end,

    ["Multi Target"] = function()
        local enemies = ni.unit.enemies_in_combat_in_range(profile.target, 10)
        if ni.table.length(enemies) > 1 then
            -- Volley
            if ni.table.length(enemies) >= 3 then
                profile.cast(ni.spell.cast_at, ni.spells.volley, {
                    ni.unit.best_damage_location(profile.target, 35, 8, 3, ni.unit.is_in_combat, 3, 35)
                })
                return true
            end
            -- Multi-Shot
            if profile.cast(ni.spell.cast, ni.spells.multishot, profile.target) then
                return true
            end
        end
    end,
    ["Single Target"] = function()
        -- Kill Command
        if ni.unit.exists("pet") and not ni.unit.is_dead_or_ghost("pet") then
            if profile.cast(ni.spell.cast, ni.spells.kill_command, profile.target) then
                return true
            end
        end
        -- Bestial Wrath
        if profile.cast(ni.spell.cast, ni.spells.bestial_wrath) then
            return true
        end
        -- Kill Shot
        if profile.cast(ni.spell.cast, ni.spells.kill_shot) then
            return true
        end
        -- Serpent Sting
        --   if profile.get_setting("serpent") then
        for k in ni.table.pairs(ni.player.enemies_in_combat_in_range(35)) do
            if not ni.unit.debuff(k, ni.spells.serpent_sting) and ni.unit.hp(k) > 15 then
                if profile.cast(ni.spell.cast, ni.spells.serpent_sting, k) then
                    return true
                end
            end
        end
        --   else
        --       if not ni.unit.debuff(profile.target, ni.spells.serpent_sting) and ni.unit.hp(profile.target) > 15 then
        --           if profile.cast(ni.spell.cast, ni.spells.serpent_sting, profile.target) then
        --               return true
        --           end
        --       end
        --   end

        -- Steady Shot
        if not ni.player.is_moving() and profile.cast(ni.spell.cast, ni.spells.steady_shot, profile.target) then
            return true
        end
        -- Arcane Shot
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
