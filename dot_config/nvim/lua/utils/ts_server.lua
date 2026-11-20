-- TypeScript server selection (like WebStorm: the project's TypeScript version decides).
-- tsc (TS 7 native LSP): the project's own typescript is >= 7.
-- vtsls: everything else, and always for Angular, Astro and tsserver plugins.
-- vim.g.tsLsp: "auto" (default) | "tsc" (also use a global TS 7 for older projects) | "vtsls".
local M = {}

local lsp_bin_cache = {} ---@type table<string, string|false>
local servers_cache = {} ---@type table<string, { set: table<string, boolean>, fallback_reason: string|nil }>
local global_roots ---@type string[]|nil

local LOCKFILES = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }

---@param bin string
---@return boolean
local function supports_lsp(bin)
	if vim.fn.executable(bin) ~= 1 then
		return false
	end
	local out = vim.system({ bin, "--version" }, { text = true }):wait()
	local version = vim.version.parse(out.stdout or "")
	return out.code == 0 and version ~= nil and version.major >= 7
end

---@param path string
---@return boolean
local function exists(path)
	return vim.uv.fs_stat(path) ~= nil
end

---@param bufnr integer
---@return string
function M.root(bufnr)
	return vim.fs.root(bufnr, { LOCKFILES, { "tsconfig.json", "jsconfig.json", "package.json" }, { ".git" } })
		or vim.fn.getcwd()
end

--- TS 7 `tsc`/`tsgo` candidates: the project's node_modules/.bin, plus PATH when tsLsp = "tsc".
---@param root string
---@return string[]
local function lsp_bin_candidates(root)
	local bins = {}
	for _, name in ipairs({ "tsc", "tsgo" }) do
		table.insert(bins, vim.fs.joinpath(root, "node_modules", ".bin", name))
	end
	if vim.g.tsLsp == "tsc" then
		vim.list_extend(bins, { "tsc", "tsgo" })
	end
	return bins
end

--- First candidate that supports `--lsp` (TypeScript >= 7). Cached per root.
---@param root string
---@return string|nil
function M.lsp_bin(root)
	if lsp_bin_cache[root] ~= nil then
		return lsp_bin_cache[root] or nil
	end
	for _, bin in ipairs(lsp_bin_candidates(root)) do
		if supports_lsp(bin) then
			lsp_bin_cache[root] = bin
			return bin
		end
	end
	lsp_bin_cache[root] = false
	return nil
end

--- Global node_modules dirs (pnpm, npm). Computed once per session.
---@return string[]
function M.global_roots()
	if global_roots then
		return global_roots
	end
	global_roots = {}
	for _, pm in ipairs({ "pnpm", "npm" }) do
		if vim.fn.executable(pm) == 1 then
			local out = vim.system({ pm, "root", "-g" }, { text = true }):wait()
			local dir = vim.trim(out.stdout or "")
			if out.code == 0 and dir ~= "" then
				table.insert(global_roots, dir)
			end
		end
	end
	return global_roots
end

--- First existing `<dir>/<rel>` in the project node_modules, then the global ones.
---@param root string
---@param rel string
---@return string|nil
function M.find_module(root, rel)
	local candidates = { vim.fs.joinpath(root, "node_modules", rel) }
	for _, dir in ipairs(M.global_roots()) do
		table.insert(candidates, vim.fs.joinpath(dir, rel))
	end
	for _, path in ipairs(candidates) do
		if exists(path) then
			return path
		end
	end
	return nil
end

---@param root string
---@return boolean
function M.is_angular(root)
	if exists(root .. "/angular.json") or exists(root .. "/nx.json") then
		return true
	end
	local f = io.open(root .. "/package.json", "r")
	if not f then
		return false
	end
	local content = f:read("*a"):lower()
	f:close()
	return content:find("@angular/core", 1, true) ~= nil
end

---@param root string
---@return boolean
local function is_astro(root)
	return #vim.fn.glob(root .. "/astro.config.*", false, true) > 0
end

---@param root string
---@return boolean
local function uses_tsserver_plugins(root)
	return exists(vim.fs.joinpath(root, "node_modules", "typescript-plugin-css-modules"))
end

--- Servers for this project. Second value is a reason when tsc was wanted but not used.
---@param root string
---@return string[] servers
---@return string|nil fallback_reason
local function pick_servers(root)
	if M.is_angular(root) then
		return { "vtsls", "angularls", "eslint" }
	end
	if is_astro(root) then
		return { "vtsls", "astro", "eslint" }
	end
	if vim.g.tsLsp == "vtsls" or uses_tsserver_plugins(root) then
		return { "vtsls", "eslint" }
	end
	if M.lsp_bin(root) then
		return { "tsc", "eslint" }
	end
	-- Only warn when the global TS 7 was asked for; older projects use vtsls on purpose.
	if vim.g.tsLsp == "tsc" then
		return { "vtsls", "eslint" }, "vim.g.tsLsp = \"tsc\" but no TypeScript 7 `tsc` found (pnpm add -g typescript@7); using vtsls"
	end
	return { "vtsls", "eslint" }
end

--- True if `name` must attach in the project at `root`. Used by the root_dir of
--- lsp/tsc.lua, lsp/vtsls.lua, lsp/angularls.lua, lsp/astro.lua. Cached per root.
---@param root string
---@param name string
---@return boolean
function M.wants(root, name)
	local entry = servers_cache[root]
	if not entry then
		local servers, fallback_reason = pick_servers(root)
		entry = { set = {}, fallback_reason = fallback_reason }
		for _, s in ipairs(servers) do
			entry.set[s] = true
		end
		servers_cache[root] = entry
	end
	-- Warn once, and only when a TS server is asked for (not for e.g. angularls on html).
	if name == "vtsls" and entry.fallback_reason then
		vim.notify(entry.fallback_reason, vim.log.levels.WARN, { title = "TypeScript LSP" })
		entry.fallback_reason = nil
	end
	return entry.set[name] == true
end

--- root_dir function for a TS-family server: attach only when this project wants it.
---@param name string
---@return fun(bufnr: integer, on_dir: fun(root: string))
function M.root_dir(name)
	return function(bufnr, on_dir)
		local root = M.root(bufnr)
		if M.wants(root, name) then
			on_dir(root)
		end
	end
end

return M
