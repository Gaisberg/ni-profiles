--------------------------------
-- Marksmanship
-- Version: 12340 (3.3.5a)
-- Author: Gaisberg
--------------------------------
local ni = ...
local profile = {}
profile.name = "Marksmanship"

local load_functions = ni.backend.LoadFile(ni.backend.GetBaseFolder() .. "addon\\Rotations\\Misc\\helpers.lua")
load_functions(ni, profile)

local pet_attacking = false

local ui = {
    settingsfile = ni.player.guid() .. "_" .. profile.name .. ".json",
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
        key = "auto_target"
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
        text = "Pet Tank Mode",
        enabled = false,
        key = "pet_tank_mode"
    }
    --  {
    --      type = "separator"
    --  },
    --  {
    --      type = "label",
    --      text = "Pet Settings"
    --  },
    --  {
    --      type = "checkbox",
    --      text = "Mend Pet",
    --      enabled = true,
    --      key = "mend_pet_enabled"
    --  },
    --  {
    --      type = "slider",
    --      text = "",
    --      value = 75,
    --      min = 0,
    --      max = 100,
    --      key = "mend_pet_value",
    --      same_line = true
    --  },
    --  {
    --      type = "checkbox",
    --      text = "Feed Pet with food (ID)",
    --      enabled = true,
    --      key = "feed_pet_enabled"
    --  },
    --  {
    --      type = "input",
    --      text = " ",
    --      value = "0",
    --      key = "feed_pet_value",
    --      same_line = true
    --  }
}

local queue = {
    "On Tick",
    "Pet Logic",
    "Pause Rotation",
    "Auto Target",
    "Aspect Management",
    "Auto Attack",
    "Misdirection",
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
    ["Auto Target"] = function()
        if profile.auto_target() then
            return true
        end
    end,
    ["Pet Logic"] = function()
        -- Feed Pet
        if not profile.incombat and not ni.unit.is_dead_or_ghost("pet") and ni.unit.exists("pet") and ni.pet.happiness() ~= 3 then
            local foodId = 8952 -- hard coded until input has callback
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
        if not ni.unit.is_dead_or_ghost("pet") and ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", ni.spells.mend_pet) then -- hard coded until slider has callback
            return profile.cast(ni.spell.cast, ni.spells.mend_pet)
        end
        if not profile.incombat then
            return true
        end
        if profile.get_setting("pet_tank_mode") then
            if (ni.unit.exists(ni.unit.target("pet")) and ni.unit.threat("pet", ni.unit.target("pet")) >= 2) or not ni.unit.exists(ni.unit.target("pet")) or not ni.pet.is_attack_active() then
                for k, v in ni.table.pairs(ni.player.enemies_in_combat_in_range(35)) do
                    if ni.unit.threat("pet", v.guid) <= 1 then
                        profile.cast(ni.pet.attack, v.guid)
                        break
                    end
                end
            end
        else
            if ni.unit.exists("pet") and not ni.unit.is_dead_or_ghost("pet") then
                if ni.unit.target("pet") ~= ni.unit.target("player") and not ni.unit.is_silenced("pet") and
                    not ni.unit.is_pacified("pet") and not ni.unit.is_stunned("pet") and not ni.unit.is_fleeing("pet") then
                    profile.cast(ni.pet.attack, profile.target)
                end
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
        if not (ni.player.buff(ni.spells.aspect_of_the_dragonhawk) or ni.player.buff(ni.spells.aspect_of_the_viper)) or
            (ni.player.buff(ni.spells.aspect_of_the_viper) and ni.player.power_percent() > 70) then
            if profile.cast(ni.spell.cast, ni.spells.aspect_of_the_dragonhawk) then
                return true
            end
        end
        if not ni.player.buff(ni.spells.aspect_of_the_viper) and ni.player.power_percent() < 10 then
            if profile.cast(ni.spell.cast, ni.spells.aspect_of_the_viper) then
                return true
            end
        end
    end,
    ["Auto Attack"] = function()
        if profile.auto_attack() then
            return true
        end
    end,
    ["Misdirection"] = function()
        if ni.unit.exists("pet") and not ni.unit.is_dead_or_ghost("pet") then
            if profile.cast(ni.spell.cast, ni.spells.misdirection, "pet") then
                return true
            end
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
        -- Kill Shot
        if ni.unit.hp(profile.target) <= 20 and profile.cast(ni.spell.cast, ni.spells.kill_shot, profile.target) then
            return true
        end
        -- Serpent Sting
        for _, v in ni.table.pairs(ni.player.enemies_in_combat_in_range(35)) do
            if not ni.unit.debuff(v.guid, ni.spells.serpent_sting) and ni.unit.hp(v.guid) > 15 then
                if profile.cast(ni.spell.cast, ni.spells.serpent_sting, v.guid) then
                    return true
                end
            end
        end
        -- Chimera Shot
        if profile.cast(ni.spell.cast, ni.spells.chimera_shot, profile.target) then
            return true
        end
        -- Silencing Shot
        if profile.cast(ni.spell.cast, ni.spells.silencing_shot, profile.target) then
            return true
        end
        -- Aimed Shot
        if profile.cast(ni.spell.cast, ni.spells.aimed_shot, profile.target) then
            return true
        end
        -- Steady Shot
        if not ni.player.is_moving() and profile.cast(ni.spell.cast, ni.spells.steady_shot, profile.target) then
            return true
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
