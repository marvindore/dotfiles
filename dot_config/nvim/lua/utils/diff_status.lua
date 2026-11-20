-- Helpers for :diffthis (not diffview):
--   * winbar status: "✓ IDENTICAL" or "≠ N hunks · first change L:C" (shown via settings.lua winbar)
--   * ]x / [x: jump to the next/previous changed characters (inline:char), for long minified lines
--   * :DiffPretty: diff formatted temp copies of the two diffed buffers
local M = {}

local status = {} ---@type table<integer, { text: string, hl: string }>
local pending = false

-- diffopt flags that vim.text.diff() also understands, so "identical" matches what is highlighted.
local DIFFOPT_TO_TEXT_DIFF = {
	iwhite = "ignore_whitespace_change",
	iwhiteall = "ignore_whitespace",
	iwhiteeol = "ignore_whitespace_change_at_eol",
	iblank = "ignore_blank_lines",
}

local PRETTIER = { "prettierd", "prettier" }

---@param tab? integer
---@return integer[]
local function diff_windows(tab)
	return vim.tbl_filter(function(win)
		return vim.wo[win].diff
	end, vim.api.nvim_tabpage_list_wins(tab or 0))
end

---@return table
local function text_diff_opts()
	local opts = { result_type = "indices", algorithm = "histogram" }
	for _, flag in ipairs(vim.opt.diffopt:get()) do
		local key = DIFFOPT_TO_TEXT_DIFF[flag]
		if key then
			opts[key] = true
		end
	end
	return opts
end

-- 1-based byte column of the first difference between two lines.
---@param a string
---@param b string
---@return integer
local function first_diff_col(a, b)
	local n = math.min(#a, #b)
	local chunk = 4096
	local i = 1
	while i <= n and a:sub(i, i + chunk - 1) == b:sub(i, i + chunk - 1) do
		i = i + chunk
	end
	while i <= n and a:byte(i) == b:byte(i) do
		i = i + 1
	end
	return i
end

---@param lines string[]
---@return string
local function as_text(lines)
	return table.concat(lines, "\n") .. "\n"
end

---@param buf_a integer
---@param buf_b integer
---@return integer[][] hunks { start_a, count_a, start_b, count_b }
local function compute_hunks(buf_a, buf_b)
	local a = vim.api.nvim_buf_get_lines(buf_a, 0, -1, false)
	local b = vim.api.nvim_buf_get_lines(buf_b, 0, -1, false)
	return vim.text.diff(as_text(a), as_text(b), text_diff_opts()) --[[@as integer[][] ]]
end

---@param bufnr integer
---@param other integer
---@param lnum integer
---@param other_lnum integer
---@return string
local function first_change(bufnr, other, lnum, other_lnum)
	local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
	local other_line = vim.api.nvim_buf_get_lines(other, other_lnum - 1, other_lnum, false)[1] or ""
	return ("%d:%d"):format(lnum, first_diff_col(line, other_line))
end

---@param buf_a integer
---@param buf_b integer
local function set_status(buf_a, buf_b)
	local hunks = compute_hunks(buf_a, buf_b)
	if #hunks == 0 then
		status[buf_a] = { text = "✓ IDENTICAL", hl = "DiagnosticOk" }
		status[buf_b] = status[buf_a]
		return
	end
	local h = hunks[1]
	local summary = ("≠ %d hunk%s · first change "):format(#hunks, #hunks == 1 and "" or "s")
	local la, lb = math.max(h[1], 1), math.max(h[3], 1)
	status[buf_a] = { text = summary .. first_change(buf_a, buf_b, la, lb), hl = "DiagnosticWarn" }
	status[buf_b] = { text = summary .. first_change(buf_b, buf_a, lb, la), hl = "DiagnosticWarn" }
end

local function refresh()
	pending = false
	local wins = diff_windows()
	if #wins < 2 then
		return vim.cmd.redrawstatus({ bang = true })
	end
	local buf_a, buf_b = vim.api.nvim_win_get_buf(wins[1]), vim.api.nvim_win_get_buf(wins[2])
	if buf_a ~= buf_b then
		set_status(buf_a, buf_b)
	end
	vim.cmd.redrawstatus({ bang = true })
end

-- DiffUpdated fires on every change in diff mode; coalesce into one refresh per tick.
local function schedule_refresh()
	if pending then
		return
	end
	pending = true
	vim.schedule(refresh)
end

-- Winbar component. Called per window at render time through %{%...%}.
---@return string
function M.winbar()
	local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
	if not (vim.api.nvim_win_is_valid(win) and vim.wo[win].diff) then
		return ""
	end
	local s = status[vim.api.nvim_win_get_buf(win)]
	if not s then
		return ""
	end
	return ("%%#%s# %s %%*"):format(s.hl, s.text)
end

----------------------------------------------------------------------
-- ]x / [x: changed-character navigation
----------------------------------------------------------------------

-- diff_hlID() per column is far too slow on a 1 MB minified line, so diff the line against
-- its partner line ourselves, token by token (word runs / single punctuation chars).
local starts_cache = {} ---@type table<string, integer[]>

---@param line string
---@return string[] tokens, integer[] byte start of each token
local function tokenize(line)
	local tokens, cols = {}, {}
	for col, tok in line:gmatch("()([%w_]*[^%w_]?)") do
		if tok ~= "" then
			tokens[#tokens + 1], cols[#cols + 1] = tok, col
		end
	end
	return tokens, cols
end

-- Partner line in the other buffer for lnum, or nil when lnum is an added line.
---@param hunks integer[][]
---@param lnum integer
---@return integer?
local function map_line(hunks, lnum)
	local delta = 0
	for _, h in ipairs(hunks) do
		local before = lnum < h[1] or (h[2] == 0 and lnum == h[1])
		if before then
			break
		end
		if lnum < h[1] + h[2] then
			local offset = lnum - h[1]
			return offset < h[4] and h[3] + offset or nil
		end
		delta = h[3] + h[4] - h[1] - h[2]
	end
	return lnum + delta
end

local MAX_CHAR_DIFF = 200000

---@param s string
---@return string one byte per line, for vim.text.diff
local function bytes_as_lines(s)
	return (s:gsub(".", "%0\n"))
end

-- Changed-run starts (1-based) inside a and b compared byte by byte.
---@param a string
---@param b string
---@return integer[]
local function char_change_starts(a, b)
	if #a + #b > MAX_CHAR_DIFF then
		return { 1 }
	end
	local hunks = vim.text.diff(bytes_as_lines(a), bytes_as_lines(b), { result_type = "indices" }) --[[@as integer[][] ]]
	return vim.tbl_map(function(h)
		return h[2] == 0 and h[1] + 1 or h[1]
	end, hunks)
end

-- Byte range [first, last] covered by tokens i .. i+count-1.
---@param cols integer[]
---@param line string
---@param i integer
---@param count integer
---@return integer, integer
local function token_span(cols, line, i, count)
	local first = cols[i] or #line + 1
	local next_col = cols[i + count] or #line + 1
	return first, next_col - 1
end

-- Token diff first (fast on 1 MB lines), then a byte diff inside each changed token range, so a
-- change inside one long word (base64, hashes, long strings) is found at its exact column.
---@param line string
---@param other_line string
---@return integer[]
local function token_change_starts(line, other_line)
	local toks, cols = tokenize(line)
	local other_toks, other_cols = tokenize(other_line)
	local hunks = vim.text.diff(as_text(toks), as_text(other_toks), { result_type = "indices" }) --[[@as integer[][] ]]
	local starts = {}
	for _, h in ipairs(hunks) do
		local a_first, a_last = token_span(cols, line, h[2] == 0 and h[1] + 1 or h[1], h[2])
		local b_first, b_last = token_span(other_cols, other_line, h[4] == 0 and h[3] + 1 or h[3], h[4])
		for _, offset in ipairs(char_change_starts(line:sub(a_first, a_last), other_line:sub(b_first, b_last))) do
			starts[#starts + 1] = math.min(a_first + offset - 1, math.max(#line, 1))
		end
	end
	return starts
end

---@param win integer
---@return integer? other diff window in this tab
local function partner_window(win)
	for _, w in ipairs(diff_windows()) do
		if w ~= win then
			return w
		end
	end
end

-- Start columns (1-based bytes) of each changed run on lnum in the current window.
---@param lnum integer
---@return integer[]
local function change_starts(lnum)
	local other_win = partner_window(vim.api.nvim_get_current_win())
	if not other_win then
		return {}
	end
	local buf, other = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_buf(other_win)
	local key = table.concat({ buf, other, lnum, vim.b[buf].changedtick, vim.b[other].changedtick }, ":")
	if starts_cache[key] then
		return starts_cache[key]
	end
	local other_lnum = map_line(compute_hunks(buf, other), lnum)
	local line = vim.fn.getline(lnum)
	local starts = other_lnum and token_change_starts(line, vim.fn.getbufline(other, other_lnum)[1] or "") or { 1 }
	starts_cache = { [key] = starts }
	return starts
end

---@param starts integer[]
---@param col integer cursor column, 1-based
---@param step integer
---@return integer?
local function pick_start(starts, col, step)
	local first, last = 1, #starts
	if step < 0 then
		first, last = #starts, 1
	end
	for i = first, last, step do
		if (step > 0 and starts[i] > col) or (step < 0 and starts[i] < col) then
			return starts[i]
		end
	end
end

---@param lnum integer
---@param col integer 1-based
local function goto_col(lnum, col)
	vim.api.nvim_win_set_cursor(0, { lnum, col - 1 })
	if not vim.wo.wrap then
		local half = math.floor(vim.api.nvim_win_get_width(0) / 2)
		vim.fn.winrestview({ leftcol = math.max(col - half, 0) })
	end
end

-- Next/previous changed characters on this line; at the line end, go to the next hunk (]c/[c).
---@param step integer 1 = next, -1 = previous
local function jump_change(step)
	if not vim.wo.diff then
		return vim.notify("Not in diff mode", vim.log.levels.INFO)
	end
	local lnum, col = vim.fn.line("."), vim.fn.col(".")
	local target = pick_start(change_starts(lnum), col, step)
	if target then
		return goto_col(lnum, target)
	end
	vim.cmd("normal! " .. (step > 0 and "]c" or "[c"))
	if vim.fn.line(".") == lnum then
		return vim.notify("No more changes", vim.log.levels.INFO)
	end
	local starts = change_starts(vim.fn.line("."))
	goto_col(vim.fn.line("."), starts[step > 0 and 1 or #starts] or 1)
end

----------------------------------------------------------------------
-- :DiffPretty
----------------------------------------------------------------------

---@return integer[]? two source buffers
local function pretty_sources()
	local wins = diff_windows()
	if #wins ~= 2 then
		wins = vim.tbl_filter(function(w)
			return vim.bo[vim.api.nvim_win_get_buf(w)].buftype == ""
		end, vim.api.nvim_tabpage_list_wins(0))
	end
	if #wins ~= 2 then
		return nil
	end
	return { vim.api.nvim_win_get_buf(wins[1]), vim.api.nvim_win_get_buf(wins[2]) }
end

---@param src integer
---@return string temp path with src's extension (formatters pick the parser from it)
local function temp_path(src)
	local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(src), ":e")
	return vim.fn.tempname() .. (ext ~= "" and "." .. ext or "")
end

-- conform formatters for src's filetype, else prettier (json, css, ...).
---@param conform table
---@param src integer
---@return string[] names, boolean stop_after_first
local function formatter_names(conform, src)
	local names = vim.tbl_map(function(f)
		return f.name
	end, conform.list_formatters_to_run(src))
	if #names > 0 then
		return names, false
	end
	local available = vim.tbl_filter(function(name)
		return conform.get_formatter_info(name, src).available
	end, PRETTIER)
	return available, true
end

-- Format src's text in a hidden scratch buffer with no filetype, so treesitter and LSP do not
-- process the huge one-line -> many-line edit (that took seconds on a 1 MB minified file).
---@param src integer
---@return string[] lines
local function pretty_lines(src)
	local lines = vim.api.nvim_buf_get_lines(src, 0, -1, false)
	local ok, conform = pcall(require, "conform")
	if not ok then
		vim.notify("DiffPretty: conform is not loaded", vim.log.levels.WARN)
		return lines
	end
	-- Not a "nofile" scratch buffer: conform passes no file name for those, and prettier then
	-- cannot infer the parser.
	local scratch = vim.api.nvim_create_buf(false, false)
	vim.bo[scratch].swapfile = false
	vim.api.nvim_buf_set_name(scratch, temp_path(src))
	vim.api.nvim_buf_set_lines(scratch, 0, -1, false, lines)
	local names, stop_after_first = formatter_names(conform, src)
	local opts = { bufnr = scratch, formatters = names, stop_after_first = stop_after_first }
	if not conform.format(vim.tbl_extend("force", opts, { async = false, lsp_format = "never", timeout_ms = 10000 })) then
		vim.notify("DiffPretty: no formatter ran for " .. vim.bo[src].filetype, vim.log.levels.WARN)
	end
	lines = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
	vim.api.nvim_buf_delete(scratch, { force = true })
	return lines
end

-- Open a formatted copy of src as a temp file in the current window and diff it.
---@param src integer
local function open_pretty_copy(src)
	local path = temp_path(src)
	vim.fn.writefile(pretty_lines(src), path)
	vim.cmd.edit(vim.fn.fnameescape(path))
	vim.bo.bufhidden = "wipe"
	vim.cmd.diffthis()
end

local function diff_pretty()
	local sources = pretty_sources()
	if not sources then
		return vim.notify("DiffPretty: need exactly two diff (or file) windows in this tab", vim.log.levels.WARN)
	end
	vim.cmd.tabnew()
	open_pretty_copy(sources[1])
	vim.cmd.vsplit()
	open_pretty_copy(sources[2])
end

function M.setup()
	local group = vim.api.nvim_create_augroup("diff_status", { clear = true })
	vim.api.nvim_create_autocmd("OptionSet", { group = group, pattern = "diff", callback = schedule_refresh })
	vim.api.nvim_create_autocmd({ "DiffUpdated", "TabEnter" }, { group = group, callback = schedule_refresh })
	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			status[args.buf] = nil
		end,
	})

	vim.keymap.set("n", "]x", function()
		jump_change(1)
	end, { desc = "Next changed characters (diff)" })
	vim.keymap.set("n", "[x", function()
		jump_change(-1)
	end, { desc = "Previous changed characters (diff)" })
	vim.api.nvim_create_user_command("DiffPretty", diff_pretty, { desc = "Diff formatted copies of the two diffed files" })
end

return M
