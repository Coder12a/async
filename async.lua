function extended_api.Async()
	local self = {}
	
	self.pool = {threads = {}, globalstep_threads = {}, task_queue = {}, resting = 200, maxtime = 200, queue_threads = 8, state = "suspended"}
	
	self.create_worker = function(func)
		local thread = coroutine.create(func)
		if not thread or coroutine.status(thread) == "dead" then
			minetest.after(0.3, self.create_worker, func)
			minetest.after(0.5, self.schedule_worker)
			minetest.chat_send_all("Fall")
			return
		end
		table.insert(self.pool.threads, thread)
	end
	
	self.create_globalstep_worker = function(func)
		local thread = coroutine.create(func)
		if not thread or coroutine.status(thread) == "dead" then
			minetest.after(0.3, self.create_globalstep_worker, func)
			minetest.after(0.5, self.schedule_globalstep_worker)
			return
		end
		table.insert(self.pool.globalstep_threads, thread)
	end
	self.run_worker = function(index)
		local thread = self.pool.threads[index]
		if not thread or coroutine.status(thread) == "dead" then
			table.remove(self.pool.threads, index)
			return false
		else
			coroutine.resume(thread)
			minetest.after(0, self.schedule_worker)
			return true
		end
	end

	self.run_globalstep_worker = function(index)
		local thread = self.pool.globalstep_threads[index]
		if not thread or coroutine.status(thread) == "dead" then
			table.remove(self.pool.globalstep_threads, index)
			return false
		else
			coroutine.resume(thread)
			minetest.after(0, self.schedule_globalstep_worker)
			return true
		end
	end

	self.schedule_worker = function()
		self.pool.state = "running"
		for index, value in ipairs(self.pool.threads) do
			minetest.after(self.pool.resting / 1000, self.run_worker, index)
			return true
		end
		self.pool.state = "suspended"
		return false
	end

	self.schedule_globalstep_worker = function()
		for index, value in ipairs(self.pool.globalstep_threads) do
			minetest.after(0, self.run_globalstep_worker, index)
			return true
		end
		return false
	end

	self.priority = function(resting, maxtime)
		self.pool.resting = resting
		self.pool.maxtime = maxtime
	end

	self.iterate = function(from, to, func, callback)
		self.create_worker(function()
			local last_time = minetest.get_us_time() / 1000
			local maxtime = self.pool.maxtime
			for i = from, to do
				local b = func(i)
				if b ~= nil and b == false then
					break
				end
				if minetest.get_us_time() / 1000 > last_time + maxtime then
					coroutine.yield()
					last_time = minetest.get_us_time() / 1000
				end
			end
			if callback then
				callback()
			end
			return
		end)
		self.schedule_worker()
	end

	self.foreach = function(array, func, callback)
		self.create_worker(function()
			local last_time = minetest.get_us_time() / 1000
			local maxtime = self.pool.maxtime
			for k,v in ipairs(array) do
				local b = func(k, v)
				if b ~= nil and b == false then
					break
				end
				if minetest.get_us_time() / 1000 > last_time + maxtime then
					coroutine.yield()
					last_time = minetest.get_us_time() / 1000
				end
			end
			if callback then
				callback()
			end
			return
		end)
		self.schedule_worker()
	end

	self.do_while = function(condition_func, func, callback)
		self.create_worker(function()
			local last_time = minetest.get_us_time() / 1000
			local maxtime = self.pool.maxtime
			while(condition_func()) do
				local c = func()
				if c ~= nil and c ~= condition_func() then
					break
				end
				if minetest.get_us_time() / 1000 > last_time + maxtime then
					coroutine.yield()
					last_time = minetest.get_us_time() / 1000
				end
			end
			if callback then
				callback()
			end
			return
		end)
		self.schedule_worker()
	end

	self.register_globalstep = function(func)
		self.create_globalstep_worker(function()
			local last_time = minetest.get_us_time() / 1000000
			local dtime = last_time
			while(true) do
				dtime = (minetest.get_us_time() / 1000000) - last_time
				func(dtime)
				-- 0.05 seconds
				if minetest.get_us_time() / 1000000 > last_time + 0.05 then
					coroutine.yield()
					last_time = minetest.get_us_time() / 1000000
				end
			end
		end)
		self.schedule_globalstep_worker()
	end

	self.chain_task = function(tasks, callback)
		self.create_worker(function()
			local pass_arg = nil
			local last_time = minetest.get_us_time() / 1000
			local maxtime = self.pool.maxtime
			for index, task_func in pairs(tasks) do
				local p = task_func(pass_arg)
				if p ~= nil then
					pass_arg = p
				end
				if minetest.get_us_time() / 1000 > last_time + maxtime then
					coroutine.yield()
					last_time = minetest.get_us_time() / 1000
				end
			end
			if callback then
				callback(pass_arg)
			end
			return
		end)
		self.schedule_worker()
	end

	self.queue_task = function(func, callback)
		table.insert(self.pool.task_queue, {func = func,callback = callback})
		if self.pool.queue_threads > 0 then
			self.pool.queue_threads = self.pool.queue_threads - 1
			self.create_worker(function()
				local pass_arg = nil
				local last_time = minetest.get_us_time() / 1000
				local maxtime = self.pool.maxtime
				while(true) do
					local task_func = self.pool.task_queue[1]
					table.remove(self.pool.task_queue, 1)
					if task_func and task_func.func then
						pass_arg = nil
						local p = task_func.func()
						if p ~= nil then
							pass_arg = p
						end
						if task_func.callback then
							task_func.callback(pass_arg)
						end
						if minetest.get_us_time() / 1000 > last_time + maxtime then
							coroutine.yield()
							last_time = minetest.get_us_time() / 1000
						end
					else
						self.pool.queue_threads = self.pool.queue_threads + 1
						return
					end
				end
			end)
			self.schedule_worker()
		end
	end

	self.single_task = function(func, callback)
		self.create_worker(function()
			local pass_arg = func()
			if p ~= nil then
				pass_arg = p
			end
			if task_func.callback then
				task_func.callback(pass_arg)
			end
			return
		end)
		self.schedule_worker()
	end
	return self
end
