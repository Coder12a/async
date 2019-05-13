async
===========

async mod is a library pack.
It adds two new node events and contains async functions.

Usage Async
===========
1. create a async instance.
```lua
async = async.Async()
```
2. set the priority of the async pool to high.
```lua
async.priority(50, 500)
```
3. iterate from 1 to 50 and log the value i.
```lua
async.iterate(1, 50, function(i)
	minetest.log(i)
end)
```
4. run throught each element in a table.
```lua
local array = {"start", "text2", "text3", "text4", "text5", "end"}
async.foreach(array, function(k,v)
	minetest.log(v)
end)
```
5. async do while loop.
```lua
local c = 50
async.do_while(function() return c>0 end, function()
	minetest.log(c)
	c = c - 1
end)
```
6. register a async globalstep. this one spams the chat with the word spam.
```lua
async.register_globalstep(function(dtime) 
	minetest.chat_send_all("spam")
end)
```
7. chain task runs a group of functions from a table.
```lua
async.chain_task({
	function(args)
		args.count = 1
		minetest.log(args.count)
		return args
	end,
	function(args)
		args.count = args.count + 1
		minetest.log(args.count)
		return args
end})
```
8. adds a single function to the task queue. This is a sort of waiting list.
```lua
async.queue_task(function() 
	minetest.log("Hello World!")
end)
```
9. Same as queue_task but the task does not go into a queue.
```lua
async.single_task(function() 
	minetest.log("Hello World!")
end)
```
