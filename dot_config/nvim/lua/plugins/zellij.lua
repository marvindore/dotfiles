-- ==========================================
-- Zellij Navigation & Terminal Management
-- Replaces: toggleterm.nvim
-- ==========================================

-- 1. Custom Floating Terminal Keymaps (Native Neovim -> Zellij)
-- Note: <C-\> is handled entirely by Zellij via config.kdl, so it is omitted here!

-- Lazygit via Zellij Floating Pane
vim.keymap.set("n", "<leader>gg", function()
	-- The '-c' flag closes the pane automatically the moment lazygit exits
	vim.fn.system("zellij action run --floating -c -- lazygit")
end, { desc = "Lazygit (Zellij)" })

-- Explicitly open a *new* floating terminal (if you need multiple floating panes at once)
-- vim.keymap.set("n", [[<c-\>]], function()
-- 	vim.fn.system("zellij action new-pane --floating")
-- end, { desc = "New Floating Terminal (Zellij)" })

-- Explicitly open a *new* tiled terminal on the side
vim.keymap.set("n", [[<c-\>]], function()
	vim.fn.system("zellij action new-pane --direction right")
end, { desc = "New Side Terminal (Zellij)" })

-- 2. Zellij Navigation Plugin (Lazy Loaded)
vim.pack.add({
	{
		src = "https://github.com/swaits/zellij-nav.nvim",
		data = {
			-- Lazy load on the first navigation keypress
			keys = {
				{ lhs = "<C-h>", rhs = "<cmd>ZellijNavigateLeft<cr>", mode = "n", desc = "Switch window left" },
				{ lhs = "<C-j>", rhs = "<cmd>ZellijNavigateDown<cr>", mode = "n", desc = "Switch window down" },
				{ lhs = "<C-k>", rhs = "<cmd>ZellijNavigateUp<cr>", mode = "n", desc = "Switch window up" },
				{ lhs = "<C-l>", rhs = "<cmd>ZellijNavigateRight<cr>", mode = "n", desc = "Switch window right" },
				{ lhs = "<C-right>", rhs = "<cmd>ZellijNavigateRightTab<cr>", mode = "n", desc = "Switch tab right" },
				{ lhs = "<C-left>", rhs = "<cmd>ZellijNavigateLeftTab<cr>", mode = "n", desc = "Switch tab left" },
			},
			after = function(_)
				require("zellij-nav").setup({})
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


-- -- Toggle the floating pane (Minimize/Restore)
-- vim.keymap.set("n", [[<c-\>]], function()
-- 	vim.fn.system("zellij action toggle-floating-panes")
-- end, { desc = "Toggle Floating Terminal (Zellij)" })
--
-- keybinds {
--     shared_except "locked" {
--         // Intercept Ctrl+\ to minimize/restore floating panes
--         bind "Ctrl \\" { ToggleFloatingPanes; }
--     }
-- }
