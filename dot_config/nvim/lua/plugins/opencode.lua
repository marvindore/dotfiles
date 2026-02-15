vim.pack.add({
	-- Dependency: snacks.nvim (required for input/picker/terminal integration)
	{
		src = "https://github.com/folke/snacks.nvim",
		data = {
			-- Note: snacks is often used by many plugins; if you've already defined it
			-- in another file, this will simply ensure the options are set.
			after = function(_)
				require("snacks").setup({
					input = {},
					picker = {},
					terminal = {},
				})
			end,
		},
	},

	-- The main OpenCode plugin
	{
		src = "https://github.com/NickvanDyke/opencode.nvim",
		data = {
			-- Trigger loading on these keymaps
			keys = {
				{ lhs = "<leader>oa", mode = { "n", "x" }, desc = "Ask opencode…" },
				{ lhs = "<leader>ox", mode = { "n", "x" }, desc = "Execute opencode action…" },
				{ lhs = "<leader>oo", mode = { "n", "t" }, desc = "Toggle opencode" },
				{ lhs = "go", mode = { "n", "x" }, desc = "Add range to opencode" },
				{ lhs = "goo", mode = { "n" }, desc = "Add line to opencode" },
			},

			after = function(_)
				-- 1. Configuration Options
				vim.g.opencode_opts = {
					-- Your configuration, if any
				}

				-- Required for automatic file reloading when the agent edits code
				vim.o.autoread = true

				local opencode = require("opencode")

				-- 2. Core Keymaps
				vim.keymap.set({ "n", "x" }, "<leader>oa", function()
					opencode.ask("@this: ", { submit = true })
				end, { desc = "Ask opencode…" })

				vim.keymap.set({ "n", "x" }, "<leader>ox", function()
					opencode.select()
				end, { desc = "Execute opencode action…" })

				vim.keymap.set({ "n", "t" }, "<leader>oo", function()
					opencode.toggle()
				end, { desc = "Toggle opencode" })

				-- 3. Operators (The "go" prefix)
				-- Using expr maps for the operator pending mode
				vim.keymap.set({ "n", "x" }, "go", function()
					return opencode.operator("@this ")
				end, { desc = "Add range to opencode", expr = true })

				vim.keymap.set("n", "goo", function()
					return opencode.operator("@this ") .. "_"
				end, { desc = "Add line to opencode", expr = true })

				-- 4. Session Navigation
				vim.keymap.set("n", "<leader>ou", function()
					opencode.command("session.half.page.up")
				end, { desc = "Scroll opencode up" })

				vim.keymap.set("n", "<leader>od", function()
					opencode.command("session.half.page.down")
				end, { desc = "Scroll opencode down" })

				-- 5. Utility Overrides
				vim.keymap.set("n", "+", "<leader>o+", { desc = "Increment under cursor", noremap = true })
				vim.keymap.set(
					"n",
					"<leader>-",
					"<leader>o-",
					{ desc = "Decrement under cursor", unique = true, noremap = true }
				)
			end,
		},
	},
}, {
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
