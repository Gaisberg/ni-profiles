--------------------------------
-- Generic Helper
-- Version: 12340  (3.3.5a)
-- Author: Gaisberg
-- Not tested past level 60...
--------------------------------
local ni = ...
local profile = {}
profile.name = "Helper"

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
    }
}

local queue = {
    "On Tick",
    "Looting",
    "Skinning"
}

local abilities = {
    ["On Tick"] = function()
        profile.on_tick()
    end,
    ["Looting"] = function()
        if profile.get_setting("looting") then
            if not profile.incombat and not ni.player.is_looting() and not ni.player.is_moving() then
                for k in ni.table.pairs(ni.player.lootable_in_range(2)) do
                    if profile.cast(ni.player.interact, k) then
                        return true
                    end
                end
            end
        end
    end,
    ["Skinning"] = function()
        if profile.get_setting("skinning") then
            if not profile.incombat and not ni.player.is_moving() and not ni.player.is_casting() then
                for k in ni.table.pairs(ni.player.skinnable_in_range(3)) do
                    if not ni.player.is_looting() and profile.cast(ni.spell.cast, ni.spells.skinning, k) then
                        return true
                    end
                end
            end
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
