-- Generic per-project .env loader.
--
-- Why this exists: neotest-python has no `env` option and spawns its runner as a
-- child process, so the only project-agnostic way to hand env vars to test runs
-- AND to DAP/debugpy sessions is via `vim.env` (child processes inherit it).
-- Walking up from the current file to the nearest `.env` makes it work in
-- monorepos without any per-project Lua config.

local helpers = require("utils.dap_helpers")

local M = {}

-- Absolute path of the last .env we applied; guards against redundant reloads
-- when DirChanged/BufEnter fire repeatedly inside the same project.
M._last_path = nil
-- Keys we set on vim.env, kept for potential future cleanup on project switch.
M._applied = {}

-- Parse a .env file into a { KEY = value } table, or nil if the file is missing.
-- Splits on the first `=` so `=` in URLs/credentials survives; strips a leading
-- `export ` and matching surrounding quotes. Blank lines and `#` comments skip.
function M.parse(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local env = {}
	for raw in file:lines() do
		local line = vim.trim(raw)
		if line ~= "" and line:sub(1, 1) ~= "#" then
			line = line:gsub("^export%s+", "")
			local key, value = line:match("^([^=]+)=(.*)$")
			if key then
				key = vim.trim(key)
				value = vim.trim(value)
				value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
				env[key] = value
			end
		end
	end
	file:close()
	return env
end

-- Absolute path of the nearest .env walking up from start_dir (default: cwd), or nil.
-- Used where a single path is required (e.g. dap-python's `envFile` field).
function M.find(start_dir)
	local dir = start_dir or vim.fn.getcwd()
	local _, matches = helpers.find_upward(dir, ".env")
	return matches[1]
end

-- All .env files from start_dir up to (and including) the repo root, nearest
-- first. A monorepo can have an unrelated nested .env (e.g. a subproject's own
-- service credentials) that would otherwise shadow the root .env entirely if
-- only the first match were used.
function M.find_all(start_dir)
	local dir = start_dir or vim.fn.getcwd()
	local paths = {}
	while dir and dir ~= "" do
		local candidate = dir .. "/.env"
		if helpers.file_exists(candidate) then
			table.insert(paths, candidate)
		end
		if vim.fn.isdirectory(dir .. "/.git") == 1 then
			break
		end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then
			break
		end
		dir = parent
	end
	return paths
end

-- Find every .env from the buffer up to the repo root and merge them into
-- vim.env (nearer files win on key conflicts). No-op if the resolved set of
-- paths is unchanged since the last load (pass { force = true } to override).
function M.load(opts)
	opts = opts or {}
	local start_dir = vim.fn.expand("%:p:h")
	if start_dir == "" then
		start_dir = vim.fn.getcwd()
	end

	local paths = M.find_all(start_dir)
	if #paths == 0 then
		if opts.force then
			vim.notify("dotenv: no .env found", vim.log.levels.DEBUG)
		end
		return
	end

	local cache_key = table.concat(paths, "|")
	if cache_key == M._last_path and not opts.force then
		return
	end

	-- Merge root-most first so nearer-to-buffer files win on conflicting keys.
	local merged = {}
	for i = #paths, 1, -1 do
		local env = M.parse(paths[i])
		if env then
			for key, value in pairs(env) do
				merged[key] = value
			end
		end
	end

	local count = 0
	for key, value in pairs(merged) do
		vim.env[key] = value
		M._applied[key] = true
		count = count + 1
	end
	M._last_path = cache_key

	vim.notify(
		("dotenv: loaded %d vars from %d file(s): %s"):format(count, #paths, table.concat(paths, ", ")),
		vim.log.levels.INFO
	)
end

-- Install auto-load autocmds and the :DotenvReload command. Call once at startup.
function M.setup()
	local group = vim.api.nvim_create_augroup("Dotenv", { clear = true })

	-- VimEnter/DirChanged cover the common case; BufEnter *.py makes monorepo
	-- per-subdir .env files load when hopping between packages. The _last_path
	-- guard keeps BufEnter cheap (no reparse while inside the same project).
	vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
		group = group,
		callback = function()
			M.load()
		end,
	})
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		pattern = "*.py",
		callback = function()
			M.load()
		end,
	})

	vim.api.nvim_create_user_command("DotenvReload", function()
		M.load({ force = true })
	end, { desc = "Reload the nearest .env into vim.env" })
end

return M
