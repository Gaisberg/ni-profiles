local ni, profile = ...

profile.pet = {}
profile.enemies = {}
profile.skinnables = {}
profile.lootables = {}
profile.blocked_spells = {}
profile.inparty = false
profile.tank = nil
profile.target = nil
profile.pet.attacking = false
profile.casting_history = nil

function profile.dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. profile.dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function profile.get_setting(key)
    return ni.profile[profile.name].get_setting(key)
end

function profile.print(text)
    print(text)
end

function profile.cast(func, ...)
    local arg1, arg2 = ...
    if func == ni.spell.cast or func == ni.spell.cast_on or func == ni.spell.cast_at then

        local spell, target = ...

        if spell == 0 or not spell then
            return false
        end

        for _, v in ni.table.pairs(profile.blocked_spells) do
            if spell == v.id then
                return false
            end
        end
        if not ni.spell.available(spell) then
            return false
        end

        if func == ni.spell.cast_at then
            func(spell, target[1], target[2], target[3])
            return true
        end

        local valid_whitelist = {
            34026
        }

        if target and spell ~= ni.spells.skinning then
            if ni.spell.valid(spell, target, true, true) or ni.table.contains_value(valid_whitelist, spell) then
                func(spell, target)
                return true
            end
        else
            func(spell)
            return true
        end

        return false
    elseif func == ni.pet.attack then
        func(arg1, arg2)
        if profile.debug then
            -- profile.print("[DEBUG] Pet is attacking " .. ni.unit.name(arg1))
        end
        return true
    elseif func == ni.player.start_attack then
        func(arg1)
        if profile.debug then
            profile.print("[DEBUG] Auto attacking " .. ni.unit.name(arg1))
        end
    else
        func(arg1, arg2)
        return true
    end
    return false
end

function profile.events(event, ...)
    local arg1, arg2 = ...
    --  if event == "PLAYER_REGEN_DISABLED" then
    --      profile.incombat = true;
    --  elseif event == "PLAYER_REGEN_ENABLED" then
    --      profile.incombat = false;
    if event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        ni.table.insert(profile.blocked_spells, {
            id = ni.backend.GetSpellID(arg2),
            time = ni.client.get_time()
        })
    end
    if event == "PET_ATTACK_START" then
        profile.pet.attacking = true
    end
    if event == "PET_ATTACK_STOP" then
        profile.pet.attacking = false
    end

    --  if event == "PLAYER_ENTERING_WORLD" then
    --    --  Scan for our "PM" window
    --    for i = 3, NUM_CHAT_WINDOWS do
    --       --  Fix the ChatFrame.oldAlpha problem here
    --       local cframe = _G["ChatFrame" .. i];
    --       cframe.oldAlpha = cframe.oldAlpha or 0;

    --       --  Check if this window is named "PM" and only has the two whisper types registered (order of the function returns doesn't matter)
    --       if GetChatWindowInfo(i) == "History" then
    --             --      If so, stop here
    --             return;
    --       end
    --    end

    --    local HistoryFrame = FCF_OpenNewWindow("History"); --        There's no "PM" window, so we'll create one
    --    ChatFrame_RemoveAllMessageGroups(HistoryFrame); --        Remove the default group registrations
    --    profile.casting_history = HistoryFrame
    -- end
end

function profile.on_tick()
   --  ni.objects.update()
    profile.debug = profile.get_setting("debug") or false

    profile.skinnables = {}
    profile.lootables = {}

    profile.incombat = ni.player.is_in_combat()
    profile.inparty = false
    if ni.group.size() > 0 then
        profile.inparty = true
    end

    profile.tank = nil
    for i = 1, #ni.members do
        if ni.members[i].istank then
            profile.tank = ni.members[i].guid
            break
        end
    end

    for k, v in ni.table.pairs(profile.blocked_spells) do
        if ni.client.get_time() - v.time > 1 then
            profile.blocked_spells[k] = nil
        end
    end
end

function profile.pause_rotation()
    if ni.player.is_mounted() or ni.player.is_dead_or_ghost() or not profile.incombat or ni.player.is_channeling() or
        ni.player.is_casting() or ni.player.buff("drink") or ni.player.buff("food") or ni.player.is_silenced() or
        ni.player.is_pacified() then
        return true;
    end
end

function profile.auto_target()
    local target = "target"
    if profile.get_setting("target") then
        if not ni.unit.exists(target) or ni.unit.is_dead_or_ghost(target) then
            for k in ni.table.pairs(ni.player.enemies_in_combat_in_range(35)) do
                target = k
                break
            end
            ni.player.target(target)
        end
    end
end

function profile.auto_attack()
    if ni.unit.exists("target") and (not ni.spell.is_current(ni.spells.auto_shot) or
        (ni.player.in_melee("target") and not ni.spell.is_current(ni.spells.auto_attack))) then
        ni.player.start_attack("target")
        return true
    end
end
