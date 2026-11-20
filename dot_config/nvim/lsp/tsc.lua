-- TypeScript 7 native language server (`tsc --lsp`). Needs typescript >= 7.
-- Selection and fallback to vtsls: lua/utils/ts_server.lua
local ts = require("utils.ts_server")

return {
	cmd = function(dispatchers, config)
		local root = (config or {}).root_dir or vim.fn.getcwd()
		return vim.lsp.rpc.start({ ts.lsp_bin(root) or "tsc", "--lsp", "--stdio" }, dispatchers)
	end,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "typescript.tsx" },
	root_dir = ts.root_dir("tsc"),
	settings = {
		["js/ts"] = {
			inlayHints = {
				parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
		},
	},
}
