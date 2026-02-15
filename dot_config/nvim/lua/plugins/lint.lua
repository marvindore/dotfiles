vim.pack.add({
	{
		src = "https://github.com/mfussenegger/nvim-lint",
		data = {
			-- Lazy load on buffer events to keep startup clean
			event = { "BufReadPre", "BufNewFile" },

			after = function(_)
				local lint = require("lint")
				lint.linters_by_ft = {
					markdown = { "vale" },
				}

				-- Define the autocommand for triggering the linter
				local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
				vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
					group = lint_augroup,
					callback = function()
						lint.try_lint()
					end,
				})

				-- Cspell On-Demand Keymaps
				local function lint_cspell()
					lint.try_lint({ "cspell" })
				end

				vim.keymap.set("n", "<leader>cll", lint_cspell, { desc = "Cspell Lint On" })
				-- Note: diagnostic.reset clears current diagnostics, it doesn't "disable" the linter
				vim.keymap.set("n", "<leader>cln", vim.diagnostic.reset, { desc = "Cspell Lint Off" })
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
