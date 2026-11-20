-- vtsls: fallback TS server for projects that need tsserver (see lua/utils/ts_server.lua).
-- tsdk and typescript-plugin-css-modules are resolved per project root in before_init,
-- so no shell calls run when the config loads.
local ts = require("utils.ts_server")

local function global_plugins(root)
	local location = ts.find_module(root, "typescript-plugin-css-modules")
	if not location then
		return {}
	end
	return {
		{
			name = "typescript-plugin-css-modules",
			location = location,
			enableForWorkspaceTypeScriptVersions = true,
		},
	}
end

return {
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/vtsls", "--stdio" },

	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"typescript.tsx",
		"astro",
	},

	root_dir = ts.root_dir("vtsls"),

	before_init = function(params, config)
		local root = config.root_dir or vim.fn.getcwd()
		local tsdk = ts.find_module(root, "typescript/lib")
		params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
			typescript = { tsdk = tsdk },
		})
		config.settings.vtsls.tsserver.globalPlugins = global_plugins(root)
	end,

	settings = {
		vtsls = {
			tsserver = {
				globalPlugins = {},
			},
		},

		typescript = {
			preferences = {
				importModuleSpecifier = "non-relative",
				quoteStyle = "single",
			},
			inlayHints = {
				includeInlayParameterNameHints = "literals",
				includeInlayVariableTypeHints = true,
			},
		},

		javascript = {
			inlayHints = {
				includeInlayParameterNameHints = "literals",
				includeInlayVariableTypeHints = true,
			},
		},
	},
}
