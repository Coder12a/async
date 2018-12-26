modpath = minetest.get_modpath("extended_api")

extended_api = {}

dofile(string.format("%s/node_funcs.lua", modpath))
dofile(string.format("%s/async.lua", modpath))
dofile(string.format("%s/register.lua", modpath))
