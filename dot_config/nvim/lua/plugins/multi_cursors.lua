vim.pack.add({
	{
		src = "https://github.com/jake-stewart/multicursor.nvim",
		data = {
			-- Lazy load on your most common multi-cursor triggers
			keys = {
				{ lhs = "<up>", mode = { "n", "v" }, desc = "Add cursor above" },
				{ lhs = "<down>", mode = { "n", "v" }, desc = "Add cursor below" },
				{ lhs = "<leader>nn", mode = { "n", "v" }, desc = "Match word" },
				{ lhs = "<c-q>", mode = { "n", "v" }, desc = "Toggle cursor" },
				{ lhs = "S", mode = { "v" }, desc = "Split visual selection" },
			},

			-- Replicate `branch = "1.0"`
			run = function(p)
				vim.notify("Checking out multicursor.nvim branch 1.0...", vim.log.levels.INFO)
				vim.system({ "git", "checkout", "1.0" }, { cwd = p.spec.path }):wait()
			end,

			after = function(_)
				local mc = require("multicursor-nvim")
				mc.setup()

				local set = vim.keymap.set

				-- Standard Cursors
				set({ "n", "v" }, "<up>", function()
					mc.lineAddCursor(-1)
				end)
				set({ "n", "v" }, "<down>", function()
					mc.lineAddCursor(1)
				end)
				set({ "n", "v" }, "<leader><up>", function()
					mc.lineSkipCursor(-1)
				end)
				set({ "n", "v" }, "<leader><down>", function()
					mc.lineSkipCursor(1)
				end)

				-- Match Word
				set({ "n", "v" }, "<leader>nn", function()
					mc.matchAddCursor(1)
				end)
				set({ "n", "v" }, "<leader>ns", function()
					mc.matchSkipCursor(1)
				end)
				set({ "n", "v" }, "<leader>nN", function()
					mc.matchAddCursor(-1)
				end)
				set({ "n", "v" }, "<leader>nS", function()
					mc.matchSkipCursor(-1)
				end)
				set({ "n", "v" }, "<leader>E", mc.matchAllAddCursors)

				-- Navigation
				set({ "n", "v" }, "<left>", mc.nextCursor)
				set({ "n", "v" }, "<right>", mc.prevCursor)

				-- Mouse & Utilities
				set("n", "<c-leftmouse>", mc.handleMouse)
				set({ "n", "v" }, "<c-q>", mc.toggleCursor)
				set({ "n", "v" }, "<leader><c-q>", mc.duplicateCursors)
				set("n", "<leader>gv", mc.restoreCursors)

				-- The Escape Logic
				set("n", "<esc>", function()
					if not mc.cursorsEnabled() then
						mc.enableCursors()
					elseif mc.hasCursors() then
						mc.clearCursors()
					else
						-- Fallback to default escape behavior
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", true)
					end
				end)

				-- Visual Mode Power Tools
				set("v", "S", mc.splitCursors)
				set("v", "I", mc.insertVisual)
				set("v", "A", mc.appendVisual)
				set("v", "M", mc.matchCursors)

				-- Jumplist
				set({ "v", "n" }, "<c-i>", mc.jumpForward)
				set({ "v", "n" }, "<c-o>", mc.jumpBackward)

				-- Highlights
				local hl = vim.api.nvim_set_hl
				hl(0, "MultiCursorCursor", { link = "Cursor" })
				hl(0, "MultiCursorVisual", { link = "Visual" })
				hl(0, "MultiCursorSign", { link = "SignColumn" })
				hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
				hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
				hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
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
