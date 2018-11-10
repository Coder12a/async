extended_api.Async = {}

function extended_api.Async.create_async_pool()
	local pool = {threads = {},globalstep_threads = {},task_queue = {},resting = 200,maxtime = 200,queue_threads = 8,state = "suspended"}
	return pool
end

function extended_api.Async.create_worker(pool,func)
	local thread = coroutine.create(func)
	table.insert(pool.threads, thread)
end

function extended_api.Async.create_globalstep_worker(pool,func)
	local thread = coroutine.create(func)
	table.insert(pool.globalstep_threads, thread)
end

function extended_api.Async.run_worker(pool,index)
	local thread = pool.threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(pool.threads, index)
		minetest.after(0,extended_api.Async.schedule_worker,pool)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,extended_api.Async.schedule_worker,pool)
		return true
	end
end

function extended_api.Async.run_globalstep_worker(pool,index)
	local thread = pool.globalstep_threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(pool.globalstep_threads, index)
		minetest.after(0,extended_api.Async.schedule_globalstep_worker,pool)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,extended_api.Async.schedule_globalstep_worker,pool)
		return true
	end
end

function extended_api.Async.schedule_worker(pool)
	pool.state = "running"
	for index,value in ipairs(pool.threads) do
		minetest.after(pool.resting / 1000,extended_api.Async.run_worker,pool,index)
		return true
	end
	pool.state = "suspended"
	return false
end

function extended_api.Async.schedule_globalstep_worker(pool)
	for index,value in ipairs(pool.globalstep_threads) do
		minetest.after(0,extended_api.Async.run_globalstep_worker,pool,index)
		return true
	end
	return false
end

function extended_api.Async.priority(pool,resting,maxtime)
	pool.resting = resting
	pool.maxtime = maxtime
end

function extended_api.Async.iterate(pool,from,to,func,callback)
	extended_api.Async.create_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		for i = from, to do
			local b = func(i)
			if b and b == false then
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
	extended_api.Async.schedule_worker(pool)
end

function extended_api.Async.foreach(pool,array, func, callback)
	extended_api.Async.create_worker(pool,function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = pool.maxtime
		for k,v in ipairs(array) do
			local b = func(k,v)
			if b and b == false then
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
	extended_api.Async.schedule_worker(pool)
end

function extended_api.Async.do_while(pool,condition_func, func, callback)
	extended_api.Async.create_worker(pool,function()
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
	extended_api.Async.schedule_worker(pool)
end

function extended_api.Async.register_globalstep(pool,func)
	extended_api.Async.create_globalstep_worker(pool,function()
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
	extended_api.Async.schedule_globalstep_worker(pool)
end

function extended_api.Async.chain_task(pool,tasks,callback)
	extended_api.Async.create_worker(pool,function()
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
	extended_api.Async.schedule_worker(pool)
end

function extended_api.Async.queue_task(pool,func,callback)
	table.insert(pool.task_queue,{func = func,callback = callback})
	if pool.queue_threads > 0 then
		pool.queue_threads = pool.queue_threads - 1
		extended_api.Async.create_worker(pool,function()
			local pass_arg = {}
			local last_time = minetest.get_us_time() * 1000
			local maxtime = pool.maxtime
			while(true) do
				local task_func = pool.task_queue[1]
				if task_func and task_func.func then
					table.remove(pool.task_queue,1)
					pass_arg = {}
					local p = task_func.func(pass_arg)
					if p then
						pass_arg = p
					end
					if task_func.callback then
						task_func.callback(pass_arg)
					end
					if minetest.get_us_time() * 1000 > last_time + maxtime then
						coroutine.yield()
						last_time = minetest.get_us_time() * 1000
					end
				else
					pool.queue_threads = pool.queue_threads + 1
					break
				end
			end
		end)
		extended_api.Async.schedule_worker(pool)
	end
end