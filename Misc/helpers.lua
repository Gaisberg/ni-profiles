local ni, profile = ...

profile.pet = {}
profile.enemies = {}
profile.skinnables = {}
profile.lootables = {}
profile.inparty = false
profile.tank = nil
profile.target = nil
profile.pet.attacking = false
profile.lastprint = {
    time = 0,
    text = ""
}

profile.dump = function(o)
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

profile.print = function(text)
    if profile.lastprint.text ~= text and (ni.client.get_time() - profile.lastprint.time > 1) then
        print(text)
        profile.lastprint.text = text
        profile.lastprint.time = ni.client.get_time()
    end
end

profile.cast = function(func, ...)
    local arg1, arg2 = ...
    if func == ni.spell.cast then
        if profile.debug then
            if arg2 then
                profile.print("[DEBUG] Casting " .. arg1.name .. " on " .. ni.unit.name(arg2))
            else
                profile.print("[DEBUG] Casting " .. arg1.name)
            end
        end
        func(arg1.name, arg2)
        return true
    elseif func == ni.pet.attack then
        if profile.debug then
            profile.print("[DEBUG] Pet is attacking " .. ni.unit.name(arg1))
        end
        func(arg1, arg2)
    else
        func(arg1, arg2)
        return true
    end
    return false
end

profile.events = function(event, ...)
    local arg1, arg2 = ...
    if event == "PLAYER_REGEN_DISABLED" then
        profile.incombat = true;
    elseif event == "PLAYER_REGEN_ENABLED" then
        profile.incombat = false;
    end
end

profile.on_tick = function()
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
        if ni.unit.affecting_combat(k) and ni.unit.can_attack("player", k) and not ni.unit.is_dead_or_ghost(k) and
            profile.enemies[k] == nil then
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
    if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then
        profile.inparty = true
    end

    profile.tank = nil
    for i = 1, #ni.members do
        if ni.members[i].istank then
            profile.tank = ni.members[i].guid
            break
        end
    end

    if not ni.unit.exists("target") or UnitIsDeadOrGhost("target") then
        if #profile.enemies > 0 and profile.inparty then
            for k, v in pairs(profile.enemies) do
                if profile.tank ~= nil and ni.unit.threat(profile.tank.guid, v.guid) > 2 then
                    profile.target = v.guid
                end
            end
        end
    else
        profile.target = ni.unit.guid("target")
    end
end
