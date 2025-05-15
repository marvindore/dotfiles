--
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local map = function(mode, keys, func, desc)
			vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
		end

		map("n", "gd", vim.lsp.buf.definition, "Go To Definition")
		map("n", "K", function() vim.lsp.buf.hover({ border = "rounded" }) end, "Hover")
		map("n", "gt", vim.lsp.buf.type_definition, "Go to Type Definition")
		map("n", "rn", vim.lsp.buf.rename, "Rename Variable")
		map("n", "gc", vim.lsp.buf.code_action, "Code action")
		map("n", "gD", vim.lsp.buf.declaration, "Go To Declaration")
		map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace")
		map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace")
		map("n", "[d", vim.diagnostic.goto_prev, "Go to prev diagnostic")
		map("n", "]d", vim.diagnostic.goto_next, "Go to next diagnostic")
		map("n", "<LocalLeader>do", vim.diagnostic.open_float, "Diagnostics open float")
		map("n", "<leader>q", vim.diagnostic.setloclist, "Set loc list")
		map("n", "<leader>th", function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end, "[T]oggle Inlay [H]ints")

		local function toggle_diagnostics()
			if vim.g.diagnostics_visible then
				vim.g.diagnostics_visible = false
				vim.diagnostic.enable(false)
			else
				vim.g.diagnostics_visible = true
				vim.diagnostic.enable()
			end
		end

		map("n", "<leader>dh", toggle_diagnostics, "Toggle Diagnostics")

		-- server specific settings
		for _, client in ipairs(vim.lsp.get_clients()) do
			if client.name == "jdtls" then
				map("n", "<leader>dvc", function() require("jdtls").test_class() end, "Java Test Class")
				map("n", "<leader>dvm", function() require("jdtls").test_nearest_method() end, "Java Test Nearest Method")
			end

			if client.name == "ts_ls" then
				client.server_capabilities.documentFormattingProvider = false
			end

			if client.name == "roslyn" then
				local wk = require("which-key")

				wk.add({
					{ "<leader>i", group = "IDE" },
					{ "<leader>it", group = "IDE Test" },
					{ "<leader>ir", group = "IDE Run" },
					{ "<leader>is", group = "IDE Secrets" },
					{ "<leader>ib", group = "IDE Build" },
					{ "<leader>ic", group = "IDE Clean" },
					{ "<leader>id", group = "IDE MSC" },
				})
				map("n", "<leader>itp", function() require("easy-dotnet").test_project() end, "Dotnet test project")
				map("n", "<leader>itd", function() require("easy-dotnet").test_default() end, "Dotnet test default")
				map("n", "<leader>its", function() require("easy-dotnet").test_solution() end, "Dotnet test solution")
				map("n", "<leader>irp", function() require("easy-dotnet").run_project() end, "Dotnet run project")
				map("n", "<leader>irP", function() require("easy-dotnet").run_with_profile(false) end, "Dotnet run profile")
				map("n", "<leader>ird", function() require("easy-dotnet").run_default() end, "Dotnet run default")
				map("n", "<leader>ire", function() require("easy-dotnet").restore() end, "Dotnet restore")
				map("n", "<leader>ise", function() require("easy-dotnet").secrets() end, "Dotnet serets")
				map("n", "<leader>ibp", function() require("easy-dotnet").build() end, "Dotnet build project")
				map("n", "<leader>ibd", function() require("easy-dotnet").build_default() end, "Dotnet build default")
				map("n", "<leader>ibs", function() require("easy-dotnet").build_solution() end, "Dotnet build solution")
				map("n", "<leader>ibq", function() require("easy-dotnet").build_quickfix() end, "Dotnet build quickfix")
				map("n", "<leader>ibQ", function() require("easy-dotnet").build_default_quickfix() end, "Dotnet build default quickfix")
				map("n", "<leader>icp", function() require("easy-dotnet").clean() end, "Dotnet clean project")
				map("n", "<leader>idd", function() require("easy-dotnet").get_debug_dll() end, "Dotnet get debug dll")
				map("n", "<leader>idp", function() require("easy-dotnet").is_dotnet_project() end, "Dotnet is project")

			end
		end -- end server specific settings
	end,
})

local capabilities = {
  workspace = {
    didChangeWatchedFiles = {
      dynamicRegistration = true
    }
  }
}

local success, blink = pcall(require, "blink.cmp")

if success then
	vim.lsp.config("*", {
		capabilities = blink.get_lsp_capabilities(capabilities)
	})
end

vim.lsp.enable("lua_ls")
vim.lsp.enable({"bashls", "yamlls", "dockerls", "jsonls", "lemminx", "sql"})
vim.lsp.enable({ "angularls", "vtsls" }, vim.g.enableJavascript)
vim.lsp.enable("go", vim.g.enableGo)
vim.lsp.enable("pwsh", vim.g.isWindowsOs)
