minetest.Async = {}

function minetest.Async.create_async_pool()
	local pool = {threads = {},globalstep_threads = {},resting = 200,maxtime = 200,state = "suspended"}
	return pool
end

function minetest.Async.create_worker(pool,func)
	local thread = coroutine.create(func)
	table.insert(pool.threads, thread)
end

function minetest.Async.create_globalstep_worker(pool,func)
	local thread = coroutine.create(func)
	table.insert(pool.globalstep_threads, thread)
end

function minetest.Async.run_worker(pool,index)
	local thread = pool.threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(pool.threads, index)
		minetest.after(0,minetest.Async.schedule_worker,pool)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,minetest.Async.schedule_worker,pool)
		return true
	end
end

function minetest.Async.run_globalstep_worker(pool,index)
	local thread = pool.globalstep_threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(pool.globalstep_threads, index)
		minetest.after(0,minetest.Async.schedule_globalstep_worker,pool)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,minetest.Async.schedule_globalstep_worker,pool)
		return true
	end
end

function minetest.Async.schedule_worker(pool)
	pool.state = "running"
	for index,value in ipairs(pool.threads) do
		minetest.after(pool.resting / 1000,minetest.Async.run_worker,pool,index)
		return true
	end
	pool.state = "suspended"
	return false
end

function minetest.Async.schedule_globalstep_worker(pool)
	for index,value in ipairs(pool.globalstep_threads) do
		minetest.after(0,minetest.Async.run_globalstep_worker,pool,index)
		return true
	end
	return false
end

function minetest.Async.priority(pool,resting,maxtime)
	pool.resting = resting
	pool.maxtime = maxtime
end

function minetest.Async.iterate(pool,from,to,func,callback)
	minetest.Async.create_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		for i = from, to do
			func(i)
			if minetest.get_us_time() * 1000 > last_time + maxtime then
				coroutine.yield()
				last_time = minetest.get_us_time() * 1000
			end
		end
		if callback then
			callback()
		end
	end)
	minetest.Async.schedule_worker(pool)
end

function minetest.Async.foreach(pool,array, func, callback)
	minetest.Async.create_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		for k,v in ipairs(array) do
			func(k,v)
			if minetest.get_us_time() * 1000 > last_time + maxtime then
				coroutine.yield()
				last_time = minetest.get_us_time() * 1000
			end
		end
		if callback then
			callback()
		end
	end)
	minetest.Async.schedule_worker(pool)
end

function minetest.Async.do_while(pool,condition_func, func, callback)
	minetest.Async.create_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		while(condition_func()) do
			local c = func()
			if c and c ~= condition_func() then
				break
			end
			if minetest.get_us_time() * 1000 > last_time + maxtime then
				coroutine.yield()
				last_time = minetest.get_us_time() * 1000
			end
		end
		if callback then
			callback()
		end
	end)
	minetest.Async.schedule_worker(pool)
end

function minetest.Async.register_globalstep(pool,func)
	minetest.Async.create_globalstep_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local dtime = last_time
		while(true) do
			local c = func(dtime)
			if c and c == false then
				break
			end
			dtime = minetest.get_us_time() * 1000
			-- 0.05 seconds
			if minetest.get_us_time() * 1000 > last_time + 50 then
				coroutine.yield()
				local last_time = minetest.get_us_time() * 1000
			end
		end
	end)
	minetest.Async.schedule_globalstep_worker(pool)
end

function minetest.Async.queue_task(pool,tasks,callback)
	minetest.Async.create_worker(pool,function()
		local pass_arg = {}
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		for index, task_func in pairs(tasks) do
			local p = task_func(pass_arg)
			if p then
				pass_arg = p
			end
			if minetest.get_us_time() * 1000 > last_time + maxtime then
				coroutine.yield()
				last_time = minetest.get_us_time() * 1000
			end
		end
		if callback then
			callback(pass_arg)
		end
	end)
	minetest.Async.schedule_worker(pool)
end