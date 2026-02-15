-- Eagerly add rustaceanvim to the path (it handles its own lazy-loading internally)
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
	-- 1. rust.vim
	{
		src = "https://github.com/rust-lang/rust.vim",
		data = {
			-- Lazy load only when a Rust file is opened
			ft = "rust",
		},
	},
	-- 2. crates.nvim
	{
		src = "https://github.com/saecki/crates.nvim",
		data = {
			-- Lazy load only when a TOML file (like Cargo.toml) is opened
			ft = "toml",

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
