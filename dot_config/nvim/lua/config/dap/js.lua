-- JS/TS debugging with vscode-js-debug from Mason (js-debug-adapter).
-- .vscode/launch.json configs that use type "pwa-node" / "node" also work through these adapters.
local M = {}

local JS_FILETYPES = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

local function adapter_cmd()
	return require("config.dap.helpers").resolve_first_existing({
		vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter",
		vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter.cmd",
	}) or "js-debug-adapter"
end

local function default_configurations()
	return {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file (node)",
			program = "${file}",
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
		{
			type = "pwa-node",
			request = "attach",
			name = "Attach to process",
			processId = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
			sourceMaps = true,
			skipFiles = { "<node_internals>/**", "**/node_modules/**" },
		},
	}
end

function M.setup(dap)
	local server = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = { command = adapter_cmd(), args = { "${port}" } },
	}
	dap.adapters["pwa-node"] = server
	dap.adapters["node"] = server

	for _, ft in ipairs(JS_FILETYPES) do
		dap.configurations[ft] = dap.configurations[ft] or default_configurations()
	end
end

return M
