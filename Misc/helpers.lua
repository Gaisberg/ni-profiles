local ni, profile = ...

profile.pet = {}
profile.enemies = {}
profile.skinnables = {}
profile.lootables = {}
profile.inparty = false
profile.tank = nil
profile.target = nil
profile.pet.attacking = false

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

profile.get_setting = function(name, items)
	for k, v in ipairs(items) do
			if v.type == "entry" and v.key ~= nil and v.key == name then
					return v.value, v.enabled
			end
			if v.type == "dropdown" then
					for k2, v2 in pairs(v.menu) do
							if v2.selected and v2.key ~= nil and v2.key == name then
									return v2.selected
							end
					end
			end
			if v.type == "input" and v.key ~= nil and v.key == name then
					return v.value
			end
	end
end

profile.cast = function(func, ...)
	local arg1, arg2 = ...
	func(arg1, arg2)
	return true
end

profile.events = function(event, ...)
	if event == "PLAYER_REGEN_DISABLED" then
			profile.incombat = true;
	elseif event == "PLAYER_REGEN_ENABLED" then
			profile.incombat = false;
	end
end

profile.on_tick = function()
	profile.debug = false
	if profile.debug then
			profile.debug = true
	end

	profile.enemies = {}
	profile.enemies5y = {}
	profile.skinnables = {}
	profile.lootables = {}
	for k, v in pairs(ni.objects) do
			if type(k) ~= "function" and (type(k) == "string" and type(v) == "table") then
					if UnitAffectingCombat(v.guid) and UnitCanAttack("player", v.guid) and not UnitIsDeadOrGhost(v.guid) and
							profile.enemies[v.guid] == nil then
							tinsert(profile.enemies, v)
							if ni.player.distance(v.guid) < 5 then
									tinsert(profile.enemies5y, v)
							end
					end
					if ni.unit.isskinnable(v.guid) then
							tinsert(profile.skinnables, v)
					end
					if ni.unit.islootable(v.guid) then
							tinsert(profile.lootables, v)
					end
			end
	end

	profile.inparty = false
	if GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0 then
			profile.inparty = true
	end

	profile.tank = nil
	for i = 1, #ni.members do
			if ni.members[i].istank then
					profile.tank = ni.members[i]
					break
			end
	end

	if not ni.unit.exists("target") or UnitIsDeadOrGhost("target") then
			if #profile.enemies > 0 and profile.inparty then
					for k, v in pairs(profile.enemies) do
							if profile.tank ~= nil and ni.unit.threat(profile.tank.guid, v.guid) > 2 then
									profile.target = v
							end
					end
			end
	else
			profile.target = ni.objects["target"]
	end
end