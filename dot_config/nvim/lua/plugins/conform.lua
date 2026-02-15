vim.pack.add({
	{
		src = "https://github.com/stevearc/conform.nvim",
		data = {
			-- Lazy load when opening or creating a new buffer
			event = { "BufReadPre", "BufNewFile" },

			after = function(_)
				require("conform").setup({
					formatters_by_ft = {
						cs = { "csharpier" },
						html = { "prettierd", "prettier", stop_after_first = true },
						lua = { "stylua" },
						-- Conform will run multiple formatters sequentially
						python = { "isort", "black" },
						-- You can customize some of the format options for the filetype
						rust = { "rustfmt", lsp_format = "fallback" },
						-- Conform will run the first available formatter
						javascript = { "prettierd", "prettier", stop_after_first = true },
						javascriptreact = { "prettierd", "prettier", stop_after_first = true },
						typescript = { "prettierd", "prettier", stop_after_first = true },
						typescriptreact = { "prettierd", "prettier", stop_after_first = true },
					},
				})
			end,
		},
	},
}, {
	-- Hand the data over to lze for lazy-loading
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
