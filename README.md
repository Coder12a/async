# extended_api
mod for minetest

This mod adds more functions and features to the minetest api.

extended_api
===========

extended_api is a minetest mod that extends the current minetest api.
It adds two new node events and contains async functions.

Usage Async
===========
1. create a async pool.
```lua
pool = minetest.Async.create_async_pool()
```
2. set the priority of the async pool to high.
```lua
minetest.Async.priority(pool,50,500)
```
3. iterate from 1 to 50 and log the value i.
```lua
minetest.Async.iterate(pool,1,50,function(i)
	minetest.log(i)
end)
```
4. run throught each element in a table.
```lua
local array = {"start","text2","text3","text4","text5","end"}
minetest.Async.foreach(pool,array, function(k,v)
	minetest.log(v)
end)
```
5. async do while loop.
```lua
local c = 50
minetest.Async.do_while(pool,function() return c>0 end, function()
	minetest.log(c)
	c = c - 1
end)
```
6. register a async globalstep. this one spams the chat with the word spam.
```lua
minetest.Async.register_globalstep(pool,function(dtime) 
	minetest.chat_send_all("spam")
end)
```
7. chain task runs a group of functions from a table.
```lua
minetest.Async.chain_task(pool,{
	function(args)
	args.count = 1
	minetest.log(args.count)
	return args
	end,
	function(args)
	args.count = args.count + 1
	minetest.log(args.count)
	return args
	end}
)
```
8. adds a single function to the task queue. This is a sort of waiting list.
```lua
	minetest.Async.queue_task(pool,function() 
		minetest.log("Hello World!")
	end)
```
Usage Node
===========
1. this covers both functions. I made this for a way to awake node timers without abms.
```lua
minetest.register_node("default:stone", {
	description = "Stone",
	tiles = {"default_stone.png"},
	groups = {cracky = 3, stone = 1},
	drop = 'default:cobble',
	legacy_mineral = true,
	sounds = default.node_sound_stone_defaults(),
	on_construct_node_near_by = function(pos,other_pos,name)
		if name == "tnt:tnt" then
			minetest.chat_send_all("Do not place tnt near me thank you!")
		end
	end,
	on_destruct_node_near_by = function(pos,other_pos,name)
		if name == "default:dirt" then
			minetest.chat_send_all("I hate dirt too!")
		end
	end,
})
```