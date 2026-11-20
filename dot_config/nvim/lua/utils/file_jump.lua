-- Move through the jumplist one file at a time ([j / ]j), like <C-o>/<C-i> but
-- skipping jumps inside the same file. Skips unlisted and special buffers.
local M = {}

local CTRL_O = "\15"
local CTRL_I = "\t"

---@param bufnr integer
---@return boolean
local function is_file_buf(bufnr)
	return vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted and vim.bo[bufnr].buftype == ""
end

-- Last index of the run of entries in the same buffer as jumps[i], i.e. where that file was left.
---@param jumps table[]
---@param i integer
---@return integer
local function run_end(jumps, i)
	while jumps[i + 1] and jumps[i + 1].bufnr == jumps[i].bufnr do
		i = i + 1
	end
	return i
end

-- Returns the 1-based jumplist index of the count-th different file in direction step.
-- Back finds the newest entry of that file directly; forward needs run_end() for it.
---@param jumps table[]
---@param from integer 1-based index of the current position
---@param step integer -1 = back, 1 = forward
---@param count integer
---@return integer?
local function find_target(jumps, from, step, count)
	local last = vim.api.nvim_get_current_buf()
	local stop = step < 0 and 1 or #jumps
	for i = from + step, stop, step do
		local bufnr = jumps[i].bufnr
		if bufnr ~= last and is_file_buf(bufnr) then
			count = count - 1
			last = bufnr
			if count == 0 then
				return step < 0 and i or run_end(jumps, i)
			end
		end
	end
end

---@param step integer -1 = back, 1 = forward
local function jump(step)
	local jumps, pos = unpack(vim.fn.getjumplist())
	local from = pos + 1 -- getjumplist() pos is 0-based
	local target = find_target(jumps, from, step, vim.v.count1)
	if not target then
		vim.notify("No " .. (step < 0 and "previous" or "next") .. " file in jumplist", vim.log.levels.INFO)
		return
	end
	local key = step < 0 and CTRL_O or CTRL_I
	vim.cmd("normal! " .. math.abs(from - target) .. key)
end

function M.back()
	jump(-1)
end

function M.forward()
	jump(1)
end

return M
