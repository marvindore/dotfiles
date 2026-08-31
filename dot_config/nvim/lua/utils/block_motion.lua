local M = {}
local last_jump = {}

local function is_blank(line)
	return line:match("^%s*$") ~= nil
end

local function line_text(bufnr, row)
	return vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
end

local function previous_nonblank(bufnr, row)
	for candidate = row, 1, -1 do
		if not is_blank(line_text(bufnr, candidate)) then
			return candidate
		end
	end
end

local function next_nonblank(bufnr, row)
	local last_row = vim.api.nvim_buf_line_count(bufnr)
	for candidate = row, last_row do
		if not is_blank(line_text(bufnr, candidate)) then
			return candidate
		end
	end
end

local function current_nonblank(bufnr, row)
	return previous_nonblank(bufnr, row) or next_nonblank(bufnr, row)
end

local function indentation_bounds(bufnr, row)
	row = current_nonblank(bufnr, row)
	if not row then
		return nil
	end

	local row_indent = vim.fn.indent(row)
	local following_row = next_nonblank(bufnr, row + 1)
	local opens_block = following_row and vim.fn.indent(following_row) > row_indent
	local start_row = row

	if not opens_block then
		for candidate = row - 1, 1, -1 do
			if not is_blank(line_text(bufnr, candidate)) and vim.fn.indent(candidate) < row_indent then
				start_row = candidate
				break
			end
		end
	end

	local start_indent = vim.fn.indent(start_row)
	local end_row = start_row
	local last_row = vim.api.nvim_buf_line_count(bufnr)

	for candidate = start_row + 1, last_row do
		if not is_blank(line_text(bufnr, candidate)) then
			if vim.fn.indent(candidate) <= start_indent then
				break
			end
			end_row = candidate
		end
	end

	return start_row, end_row
end

local function is_toml_header(line)
	local code = line:gsub("%s+#.*$", "")
	return code:match("^%s*%[%[.-%]%]%s*$") ~= nil or code:match("^%s*%[[^%[].-%]%s*$") ~= nil
end

local function toml_bounds(bufnr, row)
	local last_row = vim.api.nvim_buf_line_count(bufnr)
	local start_row

	for candidate = math.min(row, last_row), 1, -1 do
		if is_toml_header(line_text(bufnr, candidate)) then
			start_row = candidate
			break
		end
	end

	if not start_row then
		start_row = next_nonblank(bufnr, 1)
		if not start_row then
			return nil
		end
	end

	local end_row = start_row
	for candidate = start_row + 1, last_row do
		if is_toml_header(line_text(bufnr, candidate)) then
			break
		end
		if not is_blank(line_text(bufnr, candidate)) then
			end_row = candidate
		end
	end

	return start_row, end_row
end

function M.bounds(bufnr, row)
	bufnr = bufnr or 0
	row = row or vim.api.nvim_win_get_cursor(0)[1]

	if vim.bo[bufnr].filetype == "toml" then
		return toml_bounds(bufnr, row)
	end

	return indentation_bounds(bufnr, row)
end

function M.toggle()
	local bufnr = vim.api.nvim_get_current_buf()
	local row = vim.api.nvim_win_get_cursor(0)[1]
	local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
	local previous = last_jump[bufnr]
	local start_row, end_row = M.bounds(bufnr, row)
	if not start_row or start_row == end_row then
		return
	end

	local target_row
	if previous and previous.changedtick == changedtick and previous.to == row then
		target_row = previous.from
	else
		target_row = row == start_row and end_row or start_row
	end

	local target_line = line_text(bufnr, target_row)
	local target_column = target_line:find("%S") or 1

	vim.cmd("normal! m'")
	vim.api.nvim_win_set_cursor(0, { target_row, target_column - 1 })
	last_jump[bufnr] = { from = row, to = target_row, changedtick = changedtick }
end

return M
