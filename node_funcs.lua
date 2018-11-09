local function on_construct_override(pos)
	local lpos = pos
	local pos1 = {x=lpos.x-1,y=lpos.y-1,z=lpos.z-1}
	local pos2 = {x=lpos.x+1,y=lpos.y+1,z=lpos.z+1}
	
	local vm = minetest.get_voxel_manip()
	
	local emin, emax = vm:read_from_map(pos1, pos2)
	local a = VoxelArea:new{
        MinEdge = emin,
        MaxEdge = emax
    }
	
	local nx = lpos.x
	local ny = lpos.y
	local nz = lpos.z
	
	local n1x = pos1.x
	local n1y = pos1.y
	local n1z = pos1.z
	
	local n2x = pos2.x
	local n2y = pos2.y
	local n2z = pos2.z
	
    local data = vm:get_data()
	
	local m_vi = a:index(nx, ny, nz)
	local myname = minetest.get_name_from_content_id(data[m_vi])
	
	for z = n1z, n2z do
		for y = n1y, n2y do
			for x = n1x, n2x do
				if x ~= nx or y ~= ny or z ~= nz then
					local vi = a:index(x, y, z)
					local name = minetest.get_name_from_content_id(data[vi])
					local node = minetest.registered_nodes[name]
					if node.on_construct_node_near_by then
						node.on_construct_node_near_by({x=x,y=y,z=z},lpos,myname)
					end
				end
			end
		end
    end
end

local function on_construct_override2(pos)
	local lpos = pos
	local pos1 = {x=lpos.x-1,y=lpos.y-1,z=lpos.z-1}
	local pos2 = {x=lpos.x+1,y=lpos.y+1,z=lpos.z+1}
	
	local vm = minetest.get_voxel_manip()
	
	local emin, emax = vm:read_from_map(pos1, pos2)
	local a = VoxelArea:new{
        MinEdge = emin,
        MaxEdge = emax
    }
	
	local nx = lpos.x
	local ny = lpos.y
	local nz = lpos.z
	
	local n1x = pos1.x
	local n1y = pos1.y
	local n1z = pos1.z
	
	local n2x = pos2.x
	local n2y = pos2.y
	local n2z = pos2.z
	
    local data = vm:get_data()
	
	local m_vi = a:index(nx, ny, nz)
	local myname = minetest.get_name_from_content_id(data[m_vi])
	
	for z = n1z, n2z do
		for y = n1y, n2y do
			for x = n1x, n2x do
				local vi = a:index(x, y, z)
				local name = minetest.get_name_from_content_id(data[vi])
				local node = minetest.registered_nodes[name]
				if x ~= nx or y ~= ny or z ~= nz then
					if node.on_construct_node_near_by then
						node.on_construct_node_near_by({x=x,y=y,z=z},lpos,myname)
					end
				else
					node.exa_old_on_construct(lpos)
				end
			end
		end
    end
end
-- End

local function on_destruct_override(pos)
	local lpos = pos
	local pos1 = {x=lpos.x-1,y=lpos.y-1,z=lpos.z-1}
	local pos2 = {x=lpos.x+1,y=lpos.y+1,z=lpos.z+1}
	
	local vm = minetest.get_voxel_manip()
	
	local emin, emax = vm:read_from_map(pos1, pos2)
	local a = VoxelArea:new{
        MinEdge = emin,
        MaxEdge = emax
    }
	
	local nx = lpos.x
	local ny = lpos.y
	local nz = lpos.z
	
	local n1x = pos1.x
	local n1y = pos1.y
	local n1z = pos1.z
	
	local n2x = pos2.x
	local n2y = pos2.y
	local n2z = pos2.z
	
    local data = vm:get_data()
	
	local m_vi = a:index(nx, ny, nz)
	local myname = minetest.get_name_from_content_id(data[m_vi])
	
	for z = n1z, n2z do
		for y = n1y, n2y do
			for x = n1x, n2x do
				if x ~= nx or y ~= ny or z ~= nz then
					local vi = a:index(x, y, z)
					local name = minetest.get_name_from_content_id(data[vi])
					local node = minetest.registered_nodes[name]
					if node.on_destruct_node_near_by then
						node.on_destruct_node_near_by({x=x,y=y,z=z},lpos,myname)
					end
				end
			end
		end
    end
end

local function on_destruct_override2(pos)
	local lpos = pos
	local pos1 = {x=lpos.x-1,y=lpos.y-1,z=lpos.z-1}
	local pos2 = {x=lpos.x+1,y=lpos.y+1,z=lpos.z+1}
	
	local vm = minetest.get_voxel_manip()
	
	local emin, emax = vm:read_from_map(pos1, pos2)
	local a = VoxelArea:new{
        MinEdge = emin,
        MaxEdge = emax
    }
	
	local nx = lpos.x
	local ny = lpos.y
	local nz = lpos.z
	
	local n1x = pos1.x
	local n1y = pos1.y
	local n1z = pos1.z
	
	local n2x = pos2.x
	local n2y = pos2.y
	local n2z = pos2.z
	
    local data = vm:get_data()
	
	local m_vi = a:index(nx, ny, nz)
	local myname = minetest.get_name_from_content_id(data[m_vi])
	
	for z = n1z, n2z do
		for y = n1y, n2y do
			for x = n1x, n2x do
				local vi = a:index(x, y, z)
				local name = minetest.get_name_from_content_id(data[vi])
				local node = minetest.registered_nodes[name]
				if x ~= nx or y ~= ny or z ~= nz then
					if node.on_destruct_node_near_by then
						node.on_destruct_node_near_by({x=x,y=y,z=z},lpos,myname)
					end
				else
					node.exa_old_on_destruct(lpos)
				end
			end
		end
    end
end
-- End

minetest.after(0, 
function()
	for n, d in pairs(minetest.registered_nodes) do
	local cn = {}
	for k,v in pairs(minetest.registered_nodes[n]) do cn[k] = v end
		-- on_construct_node_near_by(pos,other_pos,name)
		local on_con = cn.on_construct
		if on_con then
			cn.exa_old_on_construct = on_con
			on_con = on_construct_override2
		else
			on_con = on_construct_override
		end
		cn.on_construct = on_con
		-- on_destruct_node_near_by(pos,other_pos,name)
		local on_dis = cn.on_destruct
		if on_dis then
			cn.exa_old_on_destruct = on_dis
			on_dis = on_destruct_override2
		else
			on_dis = on_destruct_override
		end
		cn.on_destruct = on_dis
		minetest.register_node(":"..n,cn)
	end
end)