-- 1. Fast exit if JavaScript/TypeScript is disabled globally
if not vim.g.enableJavascript then
	return
end

-- 2. Register with the native package manager and lze
vim.pack.add({
	{
		src = "https://github.com/yioneko/nvim-vtsls",
		data = {
			-- Lazy load only when you open a JS, TS, or Vue file
			ft = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"astro",
			},

			-- Catch requests from lspconfig trying to setup vtsls
			on_require = { "vtsls" },
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
