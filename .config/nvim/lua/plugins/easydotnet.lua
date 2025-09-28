return {
	"GustavEikaas/easy-dotnet.nvim",
	dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
  enabled = vim.g.enableCsharp,
	config = function()
		local function get_secret_path(secret_guid)
			local path = ""
			local home_dir = vim.fn.expand("~")
			if require("easy-dotnet.extensions").isWindows() then
				local secret_path = home_dir
					.. "\\AppData\\Roaming\\Microsoft\\UserSecrets\\"
					.. secret_guid
					.. "\\secrets.json"
				path = secret_path
			else
				local secret_path = home_dir .. "/.microsoft/usersecrets/" .. secret_guid .. "/secrets.json"
				path = secret_path
			end
			return path
		end

		local dotnet = require("easy-dotnet")
		-- Options are not required
		dotnet.setup({
			--Optional function to return the path for the dotnet sdk (e.g C:/ProgramFiles/dotnet/sdk/8.0.0)
			get_sdk_path = require("easy-dotnet.extensions").isWindows() and vim.fn.expand("~") .. "" or vim.fn.expand("~") .. "/.asdf/shims/dotnet",
			---@type TestRunnerOptions
			test_runner = {
				---@type "split" | "float" | "buf"
				viewmode = "split",
				noBuild = true,
				noRestore = true,
			},
			---@param action "test" | "restore" | "build" | "run"
			terminal = function(path, action)
				local commands = {
					run = function()
						return "dotnet run --project " .. path
					end,
					test = function()
						return "dotnet test " .. path
					end,
					restore = function()
						return "dotnet restore " .. path
					end,
					build = function()
						return "dotnet build " .. path
					end,
				}
				local command = commands[action]() .. "\r"
				vim.cmd("vsplit")
				vim.cmd("term " .. command)
			end,
			secrets = {
				path = get_secret_path,
			},
			csproj_mappings = true,
			fsproj_mappings = true,
			auto_bootstrap_namespace = {
				--block_scoped, file_scoped
				type = "block_scoped",
				enabled = true,
			},
			-- choose which picker to use with the plugin
			-- possible values are "telescope" | "fzf" | "snacks" | "basic"
			-- if no picker is specified, the plugin will determine
			-- the available one automatically with this priority:
			-- telescope -> fzf -> snacks ->  basic
			picker = "snacks",
		})

		-- Example command
		vim.api.nvim_create_user_command("Secrets", function()
			dotnet.secrets()
		end, {})

		-- Example keybinding
		vim.keymap.set("n", "<C-p>", function()
			dotnet.run_project()
		end)
	end,
}
