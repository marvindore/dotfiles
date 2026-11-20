-- Astro LS. Attaches only in Astro projects, next to vtsls (see lua/utils/ts_server.lua).
local ts = require("utils.ts_server")

return {
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_dir = ts.root_dir("astro"),
	before_init = function(params, config)
		local tsdk = vim.fs.joinpath(config.root_dir, "node_modules", "typescript", "lib")
		if vim.fn.filereadable(tsdk .. "/tsserverlibrary.js") == 1 then
			params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
				typescript = { tsdk = tsdk },
			})
		end
	end,
}
