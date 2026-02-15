vim.pack.add({
	-- 1. Eagerly load the standard dependencies
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-treesitter/nvim-treesitter",
	"https://github.com/j-hui/fidget.nvim",

	-- 2. Lazy-load render-markdown based on filetype
	{
		src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
		data = {
			ft = { "markdown", "codecompanion" },
			after = function(_)
				require("render-markdown").setup({})
			end,
		},
	},

	-- 3. Lazy-load CodeCompanion
	{
		src = "https://github.com/olimorris/codecompanion.nvim",
		data = {
			-- Load the plugin when you run any of these commands
			cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd" },
			keys = {
				{ lhs = "<leader>aa", rhs = "<cmd>CodeCompanionChat Toggle<CR>", mode = "n", desc = "CodeCompanion Toggle" },
				{ lhs = "<leader>ax", rhs = "<cmd>CodeCompanionActions<cr>", mode = "n",  desc = "CodeCompanion Actions" },
				{ lhs = "<leader>ac", rhs = "<cmd>CodeCompanionCmd<cr>", mode = "n",  desc = "CodeCompanion Command" },
			},
			after = function(_)
				-- Define the opts table locally
				local opts = {
					log_level = "DEBUG",
					display = {
						action_palette = {
							width = 95,
							height = 10,
							prompt = "Prompt ",
							provider = "snacks",
							opts = {
								show_default_actions = true,
								show_default_prompt_library = true,
								title = "CodeCompanion actions",
							},
						},
					},
					adapters = {
						opts = { allow_insecure = true },
					},
				}

				-- DEFINE THE ADAPTER INLINE
				local litellm_adapter = function()
					return require("codecompanion.adapters").extend("openai_compatible", {
						name = "LiteLLM",
						env = {
							url = "http://127.0.0.1:4000",
							api_key = "litellm",
							chat_url = "/v1/chat/completions",
						},
						schema = {
							model = {
								default = "gemini/gemini-3-pro-preview",
							},
							num_ctx = {
								default = 32000,
							},
						},
					})
				end

				-- ASSIGN STRATEGIES
				opts.strategies = {
					chat = {
						adapter = litellm_adapter,
						slash_commands = {
							["buffer"] = { opts = { provider = "snacks" } },
							["file"] = { opts = { provider = "snacks" } },
						},
					},
					inline = { adapter = litellm_adapter },
					agent = { adapter = litellm_adapter },
				}

				-- Initialize the plugin
				require("codecompanion").setup(opts)

				-- FIDGET INTEGRATION
				local progress = require("fidget.progress")
				local handles = {}
				local group = vim.api.nvim_create_augroup("CodeCompanionFidget", {})

				vim.api.nvim_create_autocmd("User", {
					pattern = "CodeCompanionRequestStarted",
					group = group,
					callback = function(e)
						handles[e.data.id] = progress.handle.create({
							title = "CodeCompanion",
							message = "Thinking... ",
							lsp_client = { name = e.data.adapter.formatted_name },
						})
					end,
				})

				vim.api.nvim_create_autocmd("User", {
					pattern = "CodeCompanionRequestFinished",
					group = group,
					callback = function(e)
						local h = handles[e.data.id]
						if h then
							h.message = e.data.status == "success" and "Done" or "Failed"
							h:finish()
							handles[e.data.id] = nil
						end
					end,
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

-- -- CodeCompanion
-- if vim.g.enableCodeCompanion then
-- 	wk.add({
-- 		{ "<leader>a", group = "CodeCompanion" },
-- 	})
-- end
