-- 1. Fast exit if C# is disabled globally
if not vim.g.enableCsharp then
	return
end

-- 2. Define the spec for lze
local roslyn_spec = {
	name = "roslyn.nvim",
	
	-- Lazy load only when you open a C# or Razor file
	ft = { "cs", "razor" },

	-- THE FIX PART 1: Bring the plugin into memory
	load = function()
		vim.cmd("packadd roslyn.nvim")
	end,

after = function(_)
				-- 1. Check for installation BEFORE trying to setup/start the LSP
				local registry = require("mason-registry")
				if not registry.is_installed("roslyn") then
					vim.notify("Installing Roslyn via Mason... Please restart Neovim after it finishes.", vim.log.levels.INFO)
					vim.cmd("MasonInstall roslyn")
					return -- Prevent the crash by aborting setup until installed
				end

				-- 2. Configure the Roslyn plugin
				require("roslyn").setup({
					filewatching = "auto",
				})

				-- Configure language-server settings through Neovim's native LSP API.
				vim.lsp.config("roslyn", {
					settings = {
						["csharp|inlay_hints"] = {
							csharp_enable_inlay_hints_for_implicit_object_creation = true,
							csharp_enable_inlay_hints_for_implicit_variable_types = true,
							csharp_enable_inlay_hints_for_lambda_parameter_types = true,
							csharp_enable_inlay_hints_for_types = true,
							dotnet_enable_inlay_hints_for_indexer_parameters = true,
							dotnet_enable_inlay_hints_for_literal_parameters = true,
							dotnet_enable_inlay_hints_for_object_creation_parameters = true,
							dotnet_enable_inlay_hints_for_other_parameters = true,
							dotnet_enable_inlay_hints_for_parameters = true,
							dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
							dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
						},
						["csharp|code_lens"] = {
							dotnet_enable_references_code_lens = true,
							dotnet_enable_tests_code_lens = true,
						},
						["csharp|completion"] = {
							dotnet_show_completion_items_from_unimported_namespaces = true,
							dotnet_show_name_completion_suggestions = true,
						},
						["csharp|background_analysis"] = {
							background_analysis_dotnet_compiler_diagnostics_scope = "fullSolution",
							background_analysis_dotnet_analyzers_diagnostics_scope = "fullSolution",
						},
						["csharp|symbol_search"] = {
							dotnet_search_reference_assemblies = true,
						},
					},
				})

				-- Re-trigger FileType so the server attaches to the CURRENT buffer
				vim.cmd("doautocmd FileType " .. vim.bo.filetype)
			end,
}

-- 3. Register with the native package manager and lze
vim.pack.add({
	{
		src = "https://github.com/seblyng/roslyn.nvim",
		data = roslyn_spec,
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
