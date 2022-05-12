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
    skinning = select(1, ni.spell.info(8617)),
    autoshot = select(1, ni.spell.info(75)),
    raptorstrike = select(1, ni.spell.info(2973)),
    serpentsting = select(1, ni.spell.info(1978)),
    aspectofmonkey = select(1, ni.spell.info(13163)),
    aspectofhawk = select(1, ni.spell.info(13165)),
    aspectofdragonhawk = select(1, ni.spell.info(61847)),
    aspectofviper = select(1, ni.spell.info(34074)),
    arcaneshot = select(1, ni.spell.info(3044)),
    huntersmark = select(1, ni.spell.info(1130)),
    mendpet = select(1, ni.spell.info(136)),
    feedpet = select(1, ni.spell.info(6991)),
    multishot = select(1, ni.spell.info(2643)),
    autoattack = select(1, ni.spell.info(6603)),
    mongoosebite = select(1, ni.spell.info(1495)),
    explosivetrap = select(1, ni.spell.info(13813))
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
                    if profile.cast(ni.spell.cast, profile.spells.feedpet, "pet") then
                        if profile.cast(ni.client.run_text, string.format("/use %s", name)) then return true end
                    end
                end
            end
        end
    end,
    ["Mend Pet"] = function()
        if ni.unit.hp("pet") < 70 and not ni.unit.buff("pet", profile.spells.mendpet) then
            return profile.cast(ni.spell.cast, profile.spells.mendpet)
        end
    end,
    ["Pause Rotation"] = function()
        if profile.pause_rotation() then
            return true
        end
    end,
    ["Pet Logic"] = function()
        if ni.unit.exists("pet") then
            if ni.pet.guid() == ni.unit.guid(ni.unit.target("pettarget")) or not profile.incombat or
                not ni.unit.exists("pettarget") then
                profile.pet.attacking = false
            end
            if profile.get_setting("pet_mode") == "Assist" and ni.unit.target("pet") ~= ni.unit.target("player") and
                not ni.unit.is_dead_or_ghost("target") and not profile.pet.attacking and
                not ni.unit.is_silenced("pet") and not ni.unit.is_pacified("pet") and not ni.unit.is_stunned("pet") and
                not ni.unit.is_fleeing("pet") then
                profile.cast(ni.pet.attack, "target")
                profile.pet.attacking = true
                return true
            end
            if profile.get_setting("pet_mode") == "Leveling" then
                if not profile.pet.attacking then
                    for k, v in ni.table.pairs(profile.enemies) do
                        if ni.unit.guid(ni.unit.target(v)) ~= ni.pet.guid() and ni.unit.target(v) == "player" or
                            ni.unit.guid(ni.unit.target(v)) == ni.unit.guid("player") then
                            --  if not ni.unit.exists(ni.unit.target("pettarget")) then
                            if profile.cast(ni.pet.attack, v) then
                                profile.pet.attacking = true
                              --   break
                                return true
                            end
                            --  end
                           --  if not profile.pet.attacking and ni.unit.threat(ni.pet.guid(), v) < 3 then
                           --      if profile.cast(ni.pet.attack, v) then
                           --          profile.pet.attacking = true
                           --          break
                           --          -- return true
                           --      end
                           --  end
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
        if ni.player.in_melee("target") and ni.player.is_facing("target") and
            #ni.unit.enemies_in_range("target", 10) > 1 then
            if profile.cast(ni.spell.cast, profile.spells.explosivetrap) then
                return true
            end
        end
    end,
    ["Raptor Strike"] = function()
        if not ni.spell.is_current(profile.spells.raptorstrike) and ni.player.in_melee("target") then
            if profile.cast(ni.spell.cast, profile.spells.raptorstrike, "target") then
                return true
            end
        end
    end,
    ["Mongoose Bite"] = function()
        if ni.player.in_melee("target") then
            if profile.cast(ni.spell.cast, profile.spells.mongoosebite, "target") then
                return true
            end
        end
    end,
    ["Serpent Sting"] = function()
        for k, v in ni.table.pairs(profile.enemies) do
            if not ni.unit.debuff(v, profile.spells.serpentsting) and ni.unit.hp(v) > 15 then
                if profile.cast(ni.spell.cast, profile.spells.serpentsting, v) then
                    return true
                end
            end
        end
    end,
    ["Aspect Management"] = function()
        if profile.get_setting("aspect") then
            if ni.player.level() < 10 and not ni.player.buff(profile.spells.aspectofmonkey) then
                if profile.cast(ni.spell.cast, profile.spells.aspectofmonkey) then
                    return true
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
            if not (ni.player.buff(profile.spells.aspectofhawk) or ni.player.buff(profile.spells.aspectofviper)) or
                (ni.player.buff(profile.spells.aspectofviper) and ni.player.power_percent() > 70) then
                if profile.cast(ni.spell.cast, profile.spells.aspectofhawk) then
                    return true
                end
            end
            if not ni.player.buff(profile.spells.aspectofviper) and ni.player.power_percent() < 10 then
                if profile.cast(ni.spell.cast, profile.spells.aspectofviper) then
                    return true
                end
            end
        end
    end,
    ["Arcane Shot"] = function()
        if profile.cast(ni.spell.cast, profile.spells.arcaneshot, "target") then
            return true
        end
    end,
    ["Multi Shot"] = function()
        if profile.cast(ni.spell.cast, profile.spells.multishot, "target") then
            return true
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
