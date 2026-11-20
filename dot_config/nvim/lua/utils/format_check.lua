-- "Not formatted" warning. No format-on-save: conform runs a dry run on read/write and
-- puts one WARN diagnostic on line 1 when the conform formatters would change the buffer.
-- Toggle with :FormatCheckToggle or vim.g.format_check = false.
local M = {}

local ns = vim.api.nvim_create_namespace("format_check")
local MAX_BYTES = 1024 * 1024
local DEBOUNCE_MS = 300
local timers = {} ---@type table<integer, uv.uv_timer_t>

---@param bufnr integer
---@return boolean
local function looks_like_template(bufnr)
	if vim.api.nvim_buf_get_name(bufnr):match("%.tmpl$") then
		return true
	end
	for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)) do
		if line:find("{{", 1, true) then
			return true
		end
	end
	return false
end

---@param bufnr integer
---@return boolean
local function should_check(bufnr)
	if vim.g.format_check == false or not vim.api.nvim_buf_is_loaded(bufnr) then
		return false
	end
	if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
		return false
	end
	local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr))
	if size > MAX_BYTES then
		return false
	end
	return not looks_like_template(bufnr)
end

---@param bufnr integer
---@return string[]
local function formatter_names(bufnr)
	local formatters = require("conform").list_formatters_to_run(bufnr)
	return vim.tbl_map(function(f)
		return f.name
	end, formatters)
end

---@param bufnr integer
function M.clear(bufnr)
	if vim.api.nvim_buf_is_loaded(bufnr) then
		vim.diagnostic.reset(ns, bufnr)
	end
end

---@param bufnr integer
---@param names string[]
local function warn(bufnr, names)
	vim.diagnostic.set(ns, bufnr, {
		{
			lnum = 0,
			col = 0,
			severity = vim.diagnostic.severity.WARN,
			source = "format_check",
			message = ("Not formatted (%s). Run <leader>F."):format(table.concat(names, ", ")),
		},
	})
end

---@param bufnr integer
function M.check(bufnr)
	if not should_check(bufnr) then
		return M.clear(bufnr)
	end
	local names = formatter_names(bufnr)
	if #names == 0 then
		return M.clear(bufnr)
	end
	require("conform").format(
		{ bufnr = bufnr, dry_run = true, lsp_format = "never", async = true, quiet = true },
		function(err, did_edit)
			if err or not did_edit then
				return M.clear(bufnr)
			end
			warn(bufnr, names)
		end
	)
end

---@param bufnr integer
local function schedule_check(bufnr)
	local timer = timers[bufnr] or vim.uv.new_timer()
	timers[bufnr] = timer
	timer:stop()
	timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
		M.check(bufnr)
	end))
end

---@param bufnr integer
local function forget(bufnr)
	local timer = timers[bufnr]
	if timer then
		timer:stop()
		timer:close()
		timers[bufnr] = nil
	end
end

local function toggle()
	vim.g.format_check = vim.g.format_check == false
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.g.format_check then
			schedule_check(bufnr)
		else
			M.clear(bufnr)
		end
	end
	vim.notify("Format check: " .. (vim.g.format_check and "on" or "off"))
end

function M.setup()
	local group = vim.api.nvim_create_augroup("format_check", { clear = true })
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		group = group,
		callback = function(args)
			schedule_check(args.buf)
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			forget(args.buf)
		end,
	})
	vim.api.nvim_create_user_command("FormatCheckToggle", toggle, { desc = "Toggle the 'not formatted' warning" })

	-- conform loads on BufReadPre, so the current buffer already passed BufReadPost.
	schedule_check(vim.api.nvim_get_current_buf())
end

return M
