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
    if func == ni.spell.cast then

        local spell, target = ...
        for k, v in ni.table.pairs(profile.blocked_spells) do
            if spell == v.name then
                return false
            end
        end
        if not ni.spell.available(spell) then
            return false
        end

        if target and spell ~= profile.spells.skinning then
            if not ni.spell.valid(spell, target, true, true) then
                return false
            end
        end

        func(spell, target)
        if profile.debug then
            if target then
                profile.print("[DEBUG] Casting " .. spell .. " on " .. ni.unit.name(target))
            else
                profile.print("[DEBUG] Casting " .. spell)
            end
        end
        return true
    elseif func == ni.pet.attack then
        func(arg1, arg2)
        if profile.debug then
            -- profile.print("[DEBUG] Pet is attacking " .. ni.unit.name(arg1))
        end
        return true
    elseif func == StartAttack then
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
    if event == "PLAYER_REGEN_DISABLED" then
        profile.incombat = true;
    elseif event == "PLAYER_REGEN_ENABLED" then
        profile.incombat = false;
    elseif event == "UNIT_SPELLCAST_SENT" and arg1 == "player" then
        for k, v in ni.table.pairs(profile.spells) do
            if v == arg2 then
                ni.table.insert(profile.blocked_spells, {
                    name = v,
                    time = ni.client.get_time()
                })
                break
            end
        end
    end
end

function profile.on_tick()
    ni.objects.update()
    profile.debug = false
    if profile.get_setting("debug") then
        profile.debug = true
    end

    profile.enemies = {}
    profile.enemies5y = {}
    profile.skinnables = {}
    profile.lootables = {}
    for k, v in ni.table.pairs(ni.objects) do
        if ni.unit.affecting_combat(k) and ni.unit.can_attack("player", k) and not ni.unit.is_dead_or_ghost(k) then
            ni.table.insert(profile.enemies, v.guid)
            if ni.player.distance(v.guid) < 5 then
                ni.table.insert(profile.enemies5y, v.guid)
            end
        end
        if ni.unit.is_skinnable(k) then
            ni.table.insert(profile.skinnables, v.guid)
        end
        if ni.unit.is_lootable(k) then
            ni.table.insert(profile.lootables, v.guid)
        end
    end

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
        if ni.client.get_time() - v.time > 0.2 then
            profile.blocked_spells[k] = nil
        end
    end
end

function profile.looting()
    if profile.get_setting("looting") then
        if not profile.incombat and not ni.player.is_looting() and not ni.player.is_moving() then
            for k, v in ni.table.pairs(profile.lootables) do
                if ni.player.distance(v) < 3 then
                    return profile.cast(ni.player.interact, v)
                end
            end
        end
    end
end

function profile.skinning()
    if profile.get_setting("skinning") then
        if not profile.incombat and not ni.player.is_moving() and not ni.player.is_casting() then
            for k, v in ni.table.pairs(profile.skinnables) do
                if ni.player.distance(v) < 3 then
                    if profile.cast(ni.spell.cast, profile.spells.skinning, v) then
                        return true
                    end
                end
            end
        end
    end
end

function profile.pause_rotation()
    if ni.player.mounted() or ni.player.is_dead_or_ghost() or not profile.incombat or ni.player.is_channeling() or
        ni.player.is_casting() or ni.player.buff("drink") or ni.player.buff("food") then
        --   ni.player.is_silenced() or ni.player.is_pacified() or ni.player.is_stunned() or ni.player.is_fleeing() then
        return true;
    end
end

function profile.auto_target()
    local target = "target"
    if profile.get_setting("target") then
        if not ni.unit.exists("target") or ni.unit.is_dead_or_ghost("target") then
            for k, v in ni.table.pairs(profile.enemies) do
                target = v
                break
            end
        end
        ni.player.target(target)
    end
end

function profile.auto_attack()
    if ni.unit.exists(profile.target) and not ni.spell.is_current(profile.spells.autoshot) or
        ni.spell.is_current(profile.spells.autoattack) then
        ni.player.target(profile.target)
        return profile.cast(ni.player.start_attack, profile.target)
    end
end
