return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"j-hui/fidget.nvim",
		{
			"MeanderingProgrammer/render-markdown.nvim",
			ft = { "markdown", "codecompanion" },
		},
	},
	opts = {
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
	},
	config = function(_, opts)
		-- 1. DEFINE THE ADAPTER INLINE
		local litellm_adapter = function()
			return require("codecompanion.adapters").extend("openai_compatible", {
				-- Name to appear in status bar
				name = "LiteLLM",

				env = {
					url = "http://127.0.0.1:4000",
					api_key = "litellm", -- key for litellm, by default codecompanion looks for the OPEN_API_KEY
					chat_url = "/v1/chat/completions",
				},
				schema = {
					model = {
						default = "gemini/gemini-3-pro-preview", -- match model to litellm config
					},
					-- Force the model to generate full code
					num_ctx = {
						default = 32000, -- Ensure we have enough room for full files
					},
				},
				-- 				handlers = {
				-- 					-- This function injects our rule into the messages sent to LiteLLM
				-- 					form_messages = function(self, messages, adapter)
				-- 						local no_lazy_prompt = [[
				-- IMPORTANT: When asked to write or fix code, you MUST output the FULL content of the file or function.
				-- DO NOT use abbreviations like "// ...existing code..." or "# ...rest of file".
				-- The user's interface requires the full code to render a diff. If you use abbreviations, the diff will fail.
				-- ]]
				-- 						-- Prepend our rule to the very first system message
				-- 						if messages[1].role == "system" then
				-- 							messages[1].content = messages[1].content .. "\n\n" .. no_lazy_prompt
				-- 						else
				-- 							table.insert(messages, 1, { role = "system", content = no_lazy_prompt })
				-- 						end
				--
				-- 						return messages
				-- 					end,
				-- 				},
			})
		end

		-- 2. ASSIGN STRATEGIES
		opts.strategies = {
			chat = {
				adapter = litellm_adapter,
				-- Enable built-in slash commands
				slash_commands = {
					["buffer"] = {
						opts = {
							provider = "snacks",
						},
					},
					["file"] = {
						opts = {
							provider = "snacks",
						},
					},
				},
			},
			inline = {
				adapter = litellm_adapter,
			},
			-- Enable Agents (Tools)
			-- This allows you to use @tools in the chat
			agent = {
				adapter = litellm_adapter,
			},
		}

		-- GLOBAL ADAPTER OPTIONS
		-- This tells CodeCompanion that "litellm" (our custom adapter) supports vision
		opts.adapters = {
			opts = {
				allow_insecure = true, -- Often needed for local http
			},
		}

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
}
