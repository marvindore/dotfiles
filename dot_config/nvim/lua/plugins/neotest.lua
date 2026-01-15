return {
	"nvim-neotest/neotest",
	keys = {
		{ "<leader>tt", "<cmd>lua require('neotest').summary.toggle()<CR>", desc = "Toggle Neotest" },
	},
	dependencies = {
		"nvim-neotest/nvim-nio",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-plenary",
		"nvim-neotest/neotest-go",
		"haydenmeade/neotest-jest",
		"Issafalcon/neotest-dotnet",
		-- "Decodetalkers/csharpls-extended-lsp.nvim",
		"stevanmilic/neotest-scala",
		"rouge8/neotest-rust",
		-- "mrcjkb/neotest-haskell",
		"nvim-neotest/neotest-vim-test",
		"vim-test/vim-test",
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
				require("neotest-dotnet")({
					dap = {
						args = { justMyCode = false },
						adapter_name = "netcoredbg",
					},
				}),
				require("neotest-scala"),
				-- require "neotest-haskell",
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
					ignore_file_types = { "python", "vim", "lua", "cs", "rust", "scala" }, --, "haskell"
				}),
			},
		})
	end,
}
