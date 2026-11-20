if not vim.g.enableRust then
	return
end

-- rustaceanvim handles Rust LSP and DAP setup for Rust buffers.
vim.pack.add({
	{
		src = "https://github.com/mrcjkb/rustaceanvim",
		name = "rustaceanvim",
		data = {
			-- Optional: Pin to the v6.x major release tag
			run = function(p)
				vim.notify("Updating rustaceanvim...", vim.log.levels.INFO)
				-- If you want to strictly pin it to a v6 tag later, you can use:
				-- vim.system({ "git", "checkout", "tags/v6.0.0" }, { cwd = p.spec.path }):wait()
			end,
		},
	},
})

-- ==========================================
-- LAZY PLUGINS (via lze)
-- ==========================================

vim.pack.add({
	-- crates.nvim
	{
		src = "https://github.com/saecki/crates.nvim",
		data = {
			-- Lazy load only for Cargo.toml
			event = { "BufRead Cargo.toml" },

			after = function(_)
				require("crates").setup({
					lsp = {
						enabled = true,
						on_attach = function(client, bufnr) end,
						actions = true,
						completion = true,
						hover = true,
					},
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
