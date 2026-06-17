-- lua/plugins/easydotnet.lua

if not vim.g.enableCsharp then
	return
end

local dotnet_spec = {
	name = "easy-dotnet.nvim",
	
	-- TRIGGERS: Loads automatically on C# files
	ft = { "cs", "razor", "cshtml", "csproj", "fsproj", "sln" },

	-- THE FIX: We use native Neovim commands to synchronously load the 'opt' 
	-- directories into memory the exact millisecond you press the keymap.
	load = function()
		vim.cmd("packadd plenary.nvim")
		vim.cmd("packadd snacks.nvim")
		vim.cmd("packadd easy-dotnet.nvim")
	end,

	-- CONFIG: Runs safely after packadd succeeds
	after = function()
		local status, dotnet = pcall(require, "easy-dotnet")
		if not status then 
			vim.notify("easy-dotnet failed to load!", vim.log.levels.ERROR)
			return 
		end

		local function get_secret_path(secret_guid)
			local home = vim.fn.expand("~")
			if vim.fn.has("win32") == 1 then
				return home .. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\" .. secret_guid .. "\\secrets.json"
			else
				return home .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
			end
		end

		dotnet.setup({
			lsp = { enabled = false },
			picker = "snacks",
			secrets = { path = get_secret_path },
			csproj_mappings = true,
			fsproj_mappings = true,
			test_runner = {
				viewmode = "float",
				enable_buffer_test_execution = true,
				noBuild = true,
			},
			terminal = function(path, action, args)
				local commands = {
					run = "dotnet run --project " .. path,
					test = "dotnet test " .. path,
					restore = "dotnet restore " .. path,
					build = "dotnet build " .. path,
				}
				local command = (commands[action] or "dotnet build") .. (args or "")
				if vim.fn.has("win32") == 1 then command = command .. "\r" end
				vim.cmd("vsplit | term " .. command)
			end,
		})

		vim.api.nvim_create_user_command("Secrets", function()
			dotnet.secrets()
		end, {})
	end,

	-- KEYMAPS: Pressing these tells 'lze' to fire the 'load' and 'after' functions above
	keys = {
		{ "<leader>idd", function()
			-- Read environmentVariables from the first Project profile in launchSettings.json,
			-- mirroring what Rider does automatically, so ASPNETCORE_ENVIRONMENT etc. are set.
			local function get_launch_settings_env()
				local found = vim.fn.findfile("Properties/launchSettings.json", vim.fn.getcwd() .. "/**3")
				if found == "" then return {} end
				local ok, lines = pcall(vim.fn.readfile, found)
				if not ok then return {} end
				local ok2, json = pcall(vim.fn.json_decode, table.concat(lines, "\n"))
				if not ok2 or not json.profiles then return {} end
				for _, profile in pairs(json.profiles) do
					if profile.commandName == "Project" and profile.environmentVariables then
						return profile.environmentVariables
					end
				end
				return {}
			end

			local dap_ok, dap = pcall(require, "dap")
			if dap_ok then
				local env = get_launch_settings_env()
				if not vim.tbl_isempty(env) then
					local original_run = dap.run
					dap.run = function(config, opts)
						config.env = vim.tbl_extend("keep", env, config.env or {})
						dap.run = original_run
						original_run(config, opts)
					end
				end
			end

			coroutine.wrap(function() require("easy-dotnet").debug_default() end)()
		end, desc = "Dotnet Debug" },
		{ "<leader>itp", function() require("easy-dotnet").test() end, desc = "Dotnet Test (Picker)" },
		{ "<leader>irr", function() require("easy-dotnet").run() end, desc = "Dotnet Run" },
		{ "<leader>ibb", function() require("easy-dotnet").build() end, desc = "Dotnet Build" },
		{ "<leader>ise", function() require("easy-dotnet").secrets() end, desc = "Dotnet Secrets" },
	},
}

-- Register the spec with your global package wrapper
vim.pack.add({
	{
		src = "https://github.com/GustavEikaas/easy-dotnet.nvim",
		data = dotnet_spec,
	}
}, {
	load = function(p)
		local spec = p.spec.data
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
