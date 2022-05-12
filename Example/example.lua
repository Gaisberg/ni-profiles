--------------------------------
-- Example
-- Version: 12340
-- Author: Gaisberg
--------------------------------
local ni = ...
local profile = {}
profile.name = "Example"
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
        text = "Example checkbox",
        enabled = true,
        key = "example_checkbox"
    },
    {
        type = "input",
        text = "Example input",
        value = "",
        key = "example_input"
    },
    {
        type = "combobox",
        text = "Example combobox",
        key = "example_combobox",
        selected = "Example 1",
        menu = {
            {
                text = "Example 1",
                key = "example_1"
            },
            {
                text = "Example 1",
                key = "example_2"
            }
        }
    }
}

profile.spells = {
    skinning = select(1, ni.spell.info(8617)),
    autoattack = select(1, ni.spell.info(6603)),
    autoshot = select(1, ni.spell.info(75))
}

local queue = {
    "On Tick",
    "Looting",
    "Skinning",
    "Pause Rotation",
    "Auto Target",
    "Auto Attack"
}

local abilities = {
    ["On Tick"] = function()
        profile.on_tick()
    end,
    ["Looting"] = function()
        profile.looting()
    end,
    ["Skinning"] = function()
        profile.skinning()
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
    ["Auto Attack"] = function()
        if profile.auto_attack() then
            return true
        end
    end
}

ni.profile.new(profile.name, queue, abilities, ui, profile.events)
