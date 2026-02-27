-- 1. Fast exit if C# is disabled globally
if not vim.g.enableCsharp then
	return
end

-- 2. Register with the native package manager and lze
vim.pack.add({
	{
		src = "https://github.com/seblyng/roslyn.nvim",
		data = {
			-- Lazy load only when you open a C# or Razor file
			ft = { "cs", "razor" },

			after = function(_)
				require("roslyn").setup({
					cmd = {
						"dotnet",
						vim.fs.joinpath(
							vim.g.mason_root,
							"packages/roslyn/libexec/Microsoft.CodeAnalysis.LanguageServer.dll"
						),
						"--logLevel",
						"Information",
						"--extensionLogDirectory",
						vim.fs.joinpath(vim.uv.os_tmpdir(), "roslyn_ls/logs"),
						"--stdio",
					},
					on_attach = function(client, bufnr)
						-- Install roslyn after plugin loads if missing
						local registry = require("mason-registry")
						if not registry.is_installed("roslyn") then
							vim.cmd("MasonInstall roslyn")
						end

						-- Let client know we got this
						client.server_capabilities = vim.tbl_deep_extend("force", client.server_capabilities, {
							semanticTokensProvider = { full = true },
						})

						-- Save the original request method
						local original_request = client.request

						-- Override the client's request method
						client.request = function(method, params, handler, ctx, config)
							if method == "textDocument/semanticTokens/full" then
								-- Modify the request to a range request covering the entire document
								local target_bufnr = vim.uri_to_bufnr(params.textDocument.uri)

								if not vim.api.nvim_buf_is_loaded(target_bufnr) then
									vim.notify(
										"[LSP] Buffer not loaded for URI: " .. params.textDocument.uri,
										vim.log.levels.WARN
									)
									return original_request(method, params, handler, ctx, config)
								end

								local line_count = vim.api.nvim_buf_line_count(target_bufnr)
								local last_line = vim.api.nvim_buf_get_lines(
									target_bufnr,
									line_count - 1,
									line_count,
									true
								)[1] or ""
								local end_character = #last_line

								local range = {
									start = { line = 0, character = 0 },
									["end"] = { line = line_count - 1, character = end_character },
								}

								local new_params = {
									textDocument = params.textDocument,
									range = range,
								}

								-- Send the modified range request
								return original_request(
									"textDocument/semanticTokens/range",
									new_params,
									handler,
									ctx,
									config
								)
							end

							-- Call the original request method for all other methods
							return original_request(method, params, handler, ctx, config)
						end
					end,
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
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
