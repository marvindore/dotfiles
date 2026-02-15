-- 1. Eagerly add non-Lua dependencies and standard helpers
vim.pack.add({
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/antoinemadec/FixCursorHold.nvim",
	"https://github.com/vim-test/vim-test",
})

-- 2. Define Neotest and all its adapters lazily
vim.pack.add({
	-- Wrap each adapter to tell lze to wait for the require() call
	{ src = "https://github.com/nvim-neotest/neotest-python", data = { on_require = { "neotest-python" } } },
	{ src = "https://github.com/nvim-neotest/neotest-plenary", data = { on_require = { "neotest-plenary" } } },
	{ src = "https://github.com/nvim-neotest/neotest-go", data = { on_require = { "neotest-go" } } },
	{ src = "https://github.com/haydenmeade/neotest-jest", data = { on_require = { "neotest-jest" } } },
	{ src = "https://github.com/nsidorenco/neotest-vstest", data = { on_require = { "neotest-vstest" } } },
	{ src = "https://github.com/stevanmilic/neotest-scala", data = { on_require = { "neotest-scala" } } },
	{ src = "https://github.com/rouge8/neotest-rust", data = { on_require = { "neotest-rust" } } },
	{ src = "https://github.com/nvim-neotest/neotest-vim-test", data = { on_require = { "neotest-vim-test" } } },

	{
		src = "https://github.com/nvim-neotest/neotest",
		data = {
			-- Lazy load Neotest itself on your toggle keymap
			keys = {
				{
					lhs = "<leader>tt",
					rhs = "<cmd>lua require('neotest').summary.toggle()<CR>",
					mode = { "n" },
					desc = "Toggle Neotest",
				},

				{ lhs = "<leader>tr", rhs = ':lua require("neotest").run.run()<CR>', mode = "n", desc =  "Test run under cursor" },
				{
					lhs = "<leader>tf",
					rhs = ':lua require("neotest").run.run(vim.fn.expand("%"))<CR>',
					mode = "n",
					desc = "Test run file",
				},
				{ lhs = "<leader>td", rhs = ':lua require("neotest").run.run({strategy = "dap"})<CR>', mode = "n", desc =  "Test debug" },
				{ lhs = "<leader>ts", rhs = ':lua require("neotest").run.stop()<CR>', mode = "n", desc =  "Test stop" },
				{ lhs = "<leader>ta", rhs = ':lua require("neotest").run.attach()<CR>', mode = "n", desc =  "Test attach" },
				{ lhs = "<leader>tt", rhs = ':lua require("neotest").summary.toggle()<CR>', mode = "n", desc =  "Test toggle summary" },
				{ lhs = "<leader>to", rhs = ':lua require("neotest").output.open()<CR>', mode = "n", desc =  "Test toggle summary output" },
				{
					lhs = "<leader>tpp",
					rhs = ':lua require("neotest").output_panel.toggle()<CR>',
					mode = "n",
					desc = "Test toggle output panel",
				},
				{ lhs = "<leader>tpc", rhs = "Neotest output_panel clear<cr>", mode = "n", desc =  "Test output clear" },
				{ lhs = "<leader>tw", rhs = ':lua require("neotest").watch.toggle()<CR>', mode = "n", desc =  "Test toggle watch" },
			},

			after = function(_)
				-- When you hit <leader>tt, Neotest wakes up.
				-- Then it runs this setup block.
				-- When it hits these require() calls, `lze` intercepts them
				-- and instantly wakes up the adapters you defined above!
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
							ignore_file_types = { "python", "vim", "lua", "cs", "rust", "scala" },
						}),
					},
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
