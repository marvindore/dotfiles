return {
	"nvim-neotest/neotest",
	-- Either ensure neotest itself is not lazily skipped in headless:
	--lazy = false,
	keys = {
		{ "<leader>tt", "<cmd>lua require('neotest').summary.toggle()<CR>", desc = "Toggle Neotest" },
	},
	dependencies = {
		"nvim-neotest/nvim-nio",
		"antoinemadec/FixCursorHold.nvim",

		-- Python
		{ "nvim-neotest/neotest-python", module = "neotest-python" },

		-- Plenary tests
		{ "nvim-neotest/neotest-plenary", module = "neotest-plenary" },

		-- Go
		{ "nvim-neotest/neotest-go", module = "neotest-go" },

		-- Jest
		{ "haydenmeade/neotest-jest", module = "neotest-jest" },

		-- .NET
		{ "nsidorenco/neotest-vstest", module = "neotest-vstest" },

		-- Scala
		{ "stevanmilic/neotest-scala", module = "neotest-scala" },

		-- Rust
		{ "rouge8/neotest-rust", module = "neotest-rust" },

		-- vim-test bridge (the one failing in headless)
		{ "nvim-neotest/neotest-vim-test", module = "neotest-vim-test" },

		-- required by neotest-vim-test, has no module so make it available anyway
		{ "vim-test/vim-test", lazy = false },
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-python")({
					dap = { justMyCode = false },
					python = function()
						local venv = os.getenv("VIRTUAL_ENV")
						if venv and vim.fn.executable(venv .. "/bin/python") == 1 then
							return venv .. "/bin/python"
						end
						local cwd = vim.fn.getcwd()
						if vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
							return cwd .. "/.venv/bin/python"
						elseif vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
							return cwd .. "/venv/bin/python"
						end
						return vim.g.homeDir .. "/.local/share/mise/shims/python3"
					end,
					pytest_discover_instances = true,
				}),

				require("neotest-rust"),
				-- require("neotest-dotnet")({
				--   dap = {
				--     args = { justMyCode = false },
				--     adapter_name = "netcoredbg",
				--   },
				-- }),
				require("neotest-vstest"),
				require("neotest-scala"),

				require("neotest-jest")({
					jestCommand = "npm test --",
					jestConfigFile = "custom.jest.config.ts",
					env = { CI = true },
					cwd = function()
						return vim.fn.getcwd()
					end,
				}),

				require("neotest-go"),
				require("neotest-plenary"),

				require("neotest-vim-test")({
					-- You're already ignoring some types here so other native adapters handle them
					ignore_file_types = { "python", "vim", "lua", "cs", "rust", "scala" },
				}),
			},
		})
	end,
}
