extended_api.p_loop = {}
extended_api.step = {}

local wield_list = {}
local wield_switch_list = {}

minetest.register_globalstep(function(dtime)
	local a1 = extended_api.p_loop
	local a2 = extended_api.step
	local count1 = #a1
	for _, player in pairs(minetest.get_connected_players()) do
		for i=1, count1 do
			a1[i](dtime, _, player)
		end
	end
	local count2 = #a2
	for i=1, count2 do
		a2[i](dtime)
	end
end)

function extended_api.register_playerloop(func)
	table.insert(extended_api.p_loop, func)
end

function extended_api.register_step(func)
	table.insert(extended_api.step, func)
end

function extended_api.register_on_wield(itemname, func)
	if wield_list[itemname] then
		local old = wield_list[itemname]
		wield_list[itemname] = function(item, itemname, player)
			func(item, itemname, player)
			old(item, itemname, player)
		end
	else
		wield_list[itemname] = func
	end
end

function extended_api.register_on_wield_switch(itemname, func)
	if wield_switch_list[itemname] then
		local old = wield_switch_list[itemname]
		wield_switch_list[itemname] = function(item, itemname, player)
			func(item, itemname, player)
			old(item, itemname, player)
		end
	else
		wield_switch_list[itemname] = func
	end
end

local wield_timer = 0
local wield_limit = 0.2
local players = {}

local function create_wield_step()
	extended_api.register_playerloop(function(dtime, _, player)
		if wield_timer < wield_limit then
			return
		end
		
		local item = player:get_wielded_item()
		local item_name = item:get_name()
		local pname = player:get_player_name()
		local ply = players[pname]
		if not ply then
			players[pname] = item
			local wlf = wield_list[item_name]
			if wlf then
				wlf(item, item_name, player)
			end
		elseif ply:get_name() ~= item_name then
			local old = ply:get_name()
			players[pname] = item
			local wlf = wield_switch_list[old]
			
			if wlf then
				wlf(item, old, player)
			end
			
			wlf = wield_list[item_name]
			if wlf then
				wlf(item, item_name, player)
			end
		end
	end)
	
	extended_api.register_step(function(dtime) 
		if wield_timer < wield_limit then
			wield_timer = wield_timer + dtime
			return
		else
			wield_timer = 0
		end
	end)
end

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

create_wield_step()
