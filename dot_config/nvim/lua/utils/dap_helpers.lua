local M = {}

function M.file_exists(path)
	local st = vim.loop.fs_stat(path)
	return st and st.type == "file"
end

function M.resolve_first_existing(paths)
	for _, p in ipairs(paths) do
		if M.file_exists(p) then return p end
	end
end

function M.find_upward(start_dir, glob)
	local dir = start_dir
	while dir and dir ~= "" do
		local matches = vim.fn.glob(dir .. "/" .. glob, true, true)
		if matches and #matches > 0 then return dir, matches end
		local parent = vim.fn.fnamemodify(dir, ":h")
		if parent == dir then break end
		dir = parent
	end
	return start_dir, {}
end

function M.detect_project_root()
	local cwd = vim.fn.getcwd()
	local dir, csprojs = M.find_upward(cwd, "*.csproj")
	if #csprojs > 0 then return dir, csprojs[1] end
	local sdir, slns = M.find_upward(cwd, "*.sln")
	if #slns > 0 then return sdir, slns[1] end
	return cwd, nil
end

function M.pick_with_fzf(items, prompt, on_choice)
	local ok, fzf = pcall(require, "fzf-lua")
	if not ok then return false end
	fzf.fzf_exec(items, {
		prompt = (prompt or "Select > ") .. " ",
		actions = {
			["default"] = function(selected)
				on_choice(selected and selected[1] or nil)
			end,
			["esc"] = function() on_choice(nil) end,
			["ctrl-c"] = function() on_choice(nil) end,
		},
	})
	return true
end

function M.is_runnable_dll(dll)
	if not dll or dll == "" then return false end
	if dll:match("[/\\]Tests[/\\]") or dll:match("Tests") then return false end
	local runtimeconfig = dll:gsub("%.dll$", ".runtimeconfig.json")
	return M.file_exists(runtimeconfig)
end

function M.list_candidate_dlls(project_root)
	local globs = {
		project_root .. "/**/bin/Debug*/net*/*.dll",
		project_root .. "/**/bin/Release*/net*/*.dll",
	}
	local out, seen = {}, {}
	for _, pat in ipairs(globs) do
		local matches = vim.fn.glob(pat, true, true) or {}
		for _, f in ipairs(matches) do
			if not f:match("/ref/") and not f:match("\\ref\\") and 
			   not f:match("%.vshost%.dll$") and not f:match("%.deps%.dll$") and 
			   not f:match("[/\\]testhost[%.]dll$") and M.is_runnable_dll(f) then
				if not seen[f] then
					table.insert(out, f)
					seen[f] = true
				end
			end
		end
	end
	table.sort(out, function(a, b)
		local sa, sb = vim.loop.fs_stat(a), vim.loop.fs_stat(b)
		return (sa and sa.mtime.sec or 0) > (sb and sb.mtime.sec or 0)
	end)
	return out
end

return M
