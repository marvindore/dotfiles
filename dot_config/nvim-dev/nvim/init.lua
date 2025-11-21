-- DO NOT change the paths and don't remove the colorscheme
local root = vim.fn.fnamemodify("./.lazy-dev", ":p")

-- set stdpaths to use .lazy-dev
for _, name in ipairs({ "config", "data", "state", "cache" }) do
	vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

-- bootstrap lazy
local lazypath = root .. "/plugins/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.runtimepath:prepend(lazypath)

local rest_repo = "https://github.com/rest-nvim/rest.nvim.git"
local rest_path = root .. "/tmp/rest.nvim"
vim.fn.mkdir(root .. "/tmp", "p")

if not vim.loop.fs_stat(rest_path) then
	vim.fn.system({ "git", "clone", "--filter=blob:none", rest_repo, rest_path })
end

-- install plugins
local plugins = {

  ---
  ---
  --- Envioronment plugin setup below
  ---
  ---

	"folke/tokyonight.nvim",
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true },
			picker = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"mfussenegger/nvim-dap",
		cmd = "DapContinue",
		dependencies = {
			"theHamsta/nvim-dap-virtual-text",
			"jbyuki/one-small-step-for-vimkind",
			{ "igorlfs/nvim-dap-view", opts = {} },
		},
		config = function()
			--https://alpha2phi.medium.com/neovim-dap-enhanced-ebc730ff498b
			local dap = require("dap")
			local configurations = dap.configurations
			local adapters = dap.adapters

			-- Debug js/ts
			--https://www.youtube.com/watch?v=Ul_WPhS2bis&ab_channel=LazarNikolov
			-- Lua one step mankind plugin
			adapters.nlua = function(callback, config)
				callback({ type = "server", host = config.host or "127.0.0.1", port = 5677 }) --8086
			end

			adapters.local_lua = {
				type = "executable",
				command = "node",
				args = {
					vim.g.homeDir .. "/projects/local-lua-debugger-vscode/extension/debugAdapter.js",
				},
				enrich_config = function(config, on_config)
					if not config["extensionPath"] then
						local c = vim.deepcopy(config)
						-- 💀 If this is missing or wrong you'll see
						-- "module 'lldebugger' not found" errors in the dap-repl when trying to launch a debug session
						c.extensionPath = vim.g.homeDir .. "/projects/local-lua-debugger-vscode/"
						on_config(c)
					else
						on_config(config)
					end
				end,
			}

			local lua_port = 5677
			configurations.lua = {
				{
					name = "Current file (local-lua-dbg, lua)",
					type = "local_lua",
					request = "launch",
					cwd = "${workspaceFolder}",
					program = {
						lua = "lua5.1",
						file = "${file}",
					},
					args = {},
				},
				{
					type = "nlua",
					request = "attach",
					port = lua_port,
					name = "Attach to running Neovim instance",
				},
				{
					type = "nlua",
					request = "attach",
					name = "New instance (dotfiles)",
					port = lua_port,
					start_neovim = {
						cwd = vim.g.homeDir .. "/dotfiles",
						fname = "vim/.config/nvim/init.lua",
					},
				},
				{
					type = "nlua",
					request = "attach",
					name = "New instance (crate/crate)",
					port = lua_port,
					start_neovim = {
						cwd = vim.g.homeDir .. "/dev/crate/crate",
						fname = "server/src/test/java/io/crate/planner/PlannerTest.java",
					},
				},
				{
					type = "nlua",
					request = "attach",
					name = "New instance (neovim/neovim)",
					port = lua_port,
					start_neovim = {
						cwd = vim.g.homeDir .. "/dev/neovim/neovim",
						fname = "src/nvim/main.c",
					},
				},
				{
					type = "nlua",
					request = "attach",
					name = "Attach",
					port = function()
						return assert(tonumber(vim.fn.input("Port: ")), "Port is required")
					end,
				},
			}
		end,
		keys = {
			{
				"<leader>dO",
				function()
					require("dap").step_out()
				end,
				desc = "Step Out",
			},
			{
				"<leader>do",
				function()
					require("dap").step_over()
				end,
				desc = "Step Over",
			},
		},
	}, -- end dap
	-- add any other plugins here
}
require("lazy").setup(plugins, {
	root = root .. "/plugins",
})

vim.cmd.colorscheme("tokyonight")
-- add anything else here
