if vim.g.enableJava then
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "java",
		callback = function(args)
			require("config.jdtls_setup").setup({})
		end,
	})
end
