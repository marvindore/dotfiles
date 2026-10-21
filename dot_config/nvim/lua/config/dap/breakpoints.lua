--- Debug/DAP helpers
local M = {}

--- Store all breakpoints in a global variable to be persisted in the session
M.store_breakpoints = function()
	-- Require deferred until function execution
	local breakpoints = require("dap.breakpoints")
	local bps = {}
	for buffer_id, buffer_breakpoints in pairs(breakpoints.get()) do
		local filename = vim.api.nvim_buf_get_name(buffer_id)
		bps[filename] = buffer_breakpoints
	end
	vim.g.BREAKPOINTS = bps
end

--- Load existing breakpoints for all open buffers in the session
M.load_breakpoints = function()
	if not vim.g.BREAKPOINTS then
		return
	end

	-- Require deferred until function execution
	local breakpoints = require("dap.breakpoints")
	
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local filename = vim.api.nvim_buf_get_name(buf)
		local buffer_breakpoints = vim.g.BREAKPOINTS[filename]
		if buffer_breakpoints ~= nil then
			for _, bp in pairs(buffer_breakpoints) do
				local line = bp.line
				local opts = {
					condition = bp.condition,
					log_message = bp.logMessage,
					hit_condition = bp.hitCondition,
				}
				breakpoints.set(opts, buf, line)
			end
		end
	end
end

--- Toggle a breakpoint and ensure it is persisted in the session
M.toggle_breakpoint = function()
	require("dap").toggle_breakpoint()
	M.store_breakpoints()
end

--- Create a conditional breakpoint and ensure it is persisted in the session
M.set_conditional_breakpoint = function()
	require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
	M.store_breakpoints()
end

--- Create a log point and ensure it is persisted in the session
M.set_log_point = function()
	require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
	M.store_breakpoints()
end

--- Clear all breakpoints and ensure they are persisted in the session
M.clear_breakpoints = function()
	require("dap").clear_breakpoints()
	M.store_breakpoints()
end

return M
