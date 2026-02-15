vim.api.nvim_create_user_command("PackHealth", function()
	-- 1. Define where vim.pack stores your plugins natively
	local data_dir = vim.fn.stdpath("data") .. "/site/pack/core"
	local opt_dir = data_dir .. "/opt"
	local start_dir = data_dir .. "/start"

	-- 2. Helper to scan directories
	local function get_plugins(dir)
		local p = {}
		if vim.fn.isdirectory(dir) == 1 then
			local paths = vim.fn.glob(dir .. "/*", false, true)
			for _, path in ipairs(paths) do
				table.insert(p, vim.fn.fnamemodify(path, ":t"))
			end
		end
		table.sort(p)
		return p
	end

	local opt_plugins = get_plugins(opt_dir)
	local start_plugins = get_plugins(start_dir)
	local rtp = vim.o.runtimepath

	-- 3. Build the Report UI
	local lines = {
		"📦 Native PackHealth Report",
		"===========================",
		"",
		"🚀 EAGER PLUGINS (Loaded on Startup):",
		"-------------------------------------"
	}

	for _, p in ipairs(start_plugins) do
		table.insert(lines, "  [✓] " .. p)
	end

	table.insert(lines, "")
	table.insert(lines, "💤 LAZY PLUGINS (lze / opt):")
	table.insert(lines, "-------------------------------------")

	local loaded_count = 0
	local pending_count = 0

	for _, p in ipairs(opt_plugins) do
		-- If the plugin's folder name is in the runtimepath, it has been triggered
		if string.find(rtp, p, 1, true) then
			table.insert(lines, "  [🟢] " .. p .. " (Active)")
			loaded_count = loaded_count + 1
		else
			table.insert(lines, "  [💤] " .. p .. " (Pending Trigger)")
			pending_count = pending_count + 1
		end
	end

	table.insert(lines, "")
	table.insert(lines, "📊 SUMMARY:")
	table.insert(lines, "  Eager:           " .. #start_plugins)
	table.insert(lines, "  Lazy (Active):   " .. loaded_count)
	table.insert(lines, "  Lazy (Pending):  " .. pending_count)
	table.insert(lines, "  Total Installed: " .. (#start_plugins + #opt_plugins))

	-- 4. Create the Scratch Buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	
	-- 5. Open in a split window
	vim.cmd("vsplit")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)
	
	-- 6. Lock the buffer and apply basic syntax highlighting
	vim.bo[buf].modifiable = false
	vim.bo[buf].filetype = "packhealth"
	
	vim.cmd([[
		syntax match PackHealthLoaded /\[✓\]\|\[🟢\]/ containedin=ALL
		syntax match PackHealthPending /\[💤\]/ containedin=ALL
		syntax match PackHealthTitle /📦 Native PackHealth Report/ containedin=ALL
		highlight default link PackHealthLoaded String
		highlight default link PackHealthPending Comment
		highlight default link PackHealthTitle Title
	]])

end, { desc = "Show Native Plugin Health and Lazy Status" })
