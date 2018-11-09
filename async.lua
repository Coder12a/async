minetest.async = {}

minetest.async.threads = {}
minetest.async.globalstep_threads = {}
minetest.async.resting = 200
minetest.async.maxtime = 200
minetest.async.state = "suspended"

function minetest.async.create_worker(func)
	local thread = coroutine.create(func)
	table.insert(minetest.async.threads, thread)
end

function minetest.async.create_globalstep_worker(func)
	local thread = coroutine.create(func)
	table.insert(minetest.async.globalstep_threads, thread)
end

function minetest.async.run_worker(index)
	local thread = minetest.async.threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(minetest.async.threads, index)
		minetest.after(0,minetest.async.schedule_worker)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,minetest.async.schedule_worker)
		return true
	end
end

function minetest.async.run_globalstep_worker(index)
	local thread = minetest.async.globalstep_threads[index]
	if thread == nil or coroutine.status(thread) == "dead" then
		table.remove(minetest.async.globalstep_threads, index)
		minetest.after(0,minetest.async.schedule_globalstep_worker)
		return false
	else
		coroutine.resume(thread)
		minetest.after(0,minetest.async.schedule_globalstep_worker)
		return true
	end
end

function minetest.async.schedule_worker()
	minetest.async.state = "running"
	for index,value in ipairs(minetest.async.threads) do
		minetest.after(minetest.async.resting,minetest.async.run_worker,index)
		return true
	end
	minetest.async.state = "suspended"
	return false
end

function minetest.async.schedule_globalstep_worker()
	for index,value in ipairs(minetest.async.globalstep_threads) do
		minetest.after(0,minetest.async.run_globalstep_worker,index)
		return true
	end
	return false
end

function minetest.async.priority(resting,maxtime)
	minetest.async.resting = resting
	minetest.async.maxtime = maxtime
end

function minetest.async.iterate(from,to,func,callback)
	minetest.async.create_worker(function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = minetest.async.maxtime
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
	minetest.async.schedule_worker()
end

function minetest.async.foreach(array, func, callback)
	minetest.async.create_worker(function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = minetest.async.maxtime
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
	minetest.async.schedule_worker()
end

function minetest.async.do_while(condition, func, callback)
	minetest.async.create_worker(function()
		local last_time = minetest.get_us_time() * 1000
		local maxtime = minetest.async.maxtime
		while(condition) do
			local c = func()
			if c and c ~= condition then
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
	minetest.async.schedule_worker()
end

function minetest.async.register_globalstep(func)
	minetest.async.create_globalstep_worker(function()
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
	minetest.async.schedule_globalstep_worker()
end

function minetest.async.queue_task(tasks,callback)
	minetest.async.create_worker(function()
		local pass_arg = {}
		local last_time = minetest.get_us_time() * 1000
		local maxtime = minetest.async.maxtime
		for task_func, index in pairs(tasks) do
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
	minetest.async.schedule_worker()
end