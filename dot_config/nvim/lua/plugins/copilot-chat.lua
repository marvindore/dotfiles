vim.pack.add({
	-- Dependencies
	"https://github.com/nvim-lua/plenary.nvim",

	-- CopilotChat
	{
		src = "https://github.com/CopilotC-Nvim/CopilotChat.nvim",
		version = "canary",
		data = {
			cmd = {
				"CopilotChat",
				"CopilotChatToggle",
				"CopilotChatVisual",
				"CopilotChatInline",
				"CopilotChatBuffer",
			},
			after = function(_)
				local chat = require("CopilotChat")
				local select = require("CopilotChat.select")

				local prompts = {
					-- Code related prompts
					Explain = "Please explain how the following code works.",
					Review = "Please review the following code and provide suggestions for improvement.",
					Tests = "Please explain how the selected code works, then generate unit tests for it.",
					Refactor = "Please refactor the following code to improve its clarity and readability.",
					FixCode = "Please fix the following code to make it work as intended.",
					FixError = "Please explain the error in the following text and provide a solution.",
					BetterNamings = "Please provide better names for the following variables and functions.",
					Documentation = "Please provide documentation for the following code.",
					SwaggerApiDocs = "Please provide documentation for the following API using Swagger.",
					SwaggerJsDocs = "Please write JSDoc for the following API using Swagger.",
					-- Text related prompts
					Summarize = "Please summarize the following text.",
					Spelling = "Please correct any grammar and spelling errors in the following text.",
					Wording = "Please improve the grammar and wording of the following text.",
					Concise = "Please rewrite the following text to make it more concise.",
				}

				local opts = {
					question_header = "## User ",
					answer_header = "## Copilot ",
					error_header = "## Error ",
					separator = " ",
					prompts = prompts,
					auto_follow_cursor = false,
					show_help = false,
					selection = select.unnamed,
					mappings = {
						complete = {
							detail = "Use @<Tab> or /<Tab> for options.",
							insert = "<Tab>",
						},
						close = {
							normal = "q",
							insert = "<C-c>",
						},
						reset = {
							normal = "<C-l>",
							insert = "<C-l>",
						},
						submit_prompt = {
							normal = "<CR>",
							insert = "<C-CR>",
						},
						accept_diff = {
							normal = "<C-y>",
							insert = "<C-y>",
						},
						yank_diff = {
							normal = "gmy",
						},
						show_diff = {
							normal = "gmd",
						},
						show_system_prompt = {
							normal = "gmp",
						},
						show_user_selection = {
							normal = "gms",
						},
					},
				}

				opts.prompts.Commit = {
					prompt = "Write commit message for the change with commitizen convention",
					selection = select.gitdiff,
				}
				opts.prompts.CommitStaged = {
					prompt = "Write commit message for the change with commitizen convention",
					selection = function(source)
						return select.gitdiff(source, true)
					end,
				}

				chat.setup(opts)

				vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
					chat.ask(args.args, { selection = select.visual })
				end, { nargs = "*", range = true })

				vim.api.nvim_create_user_command("CopilotChatInline", function(args)
					chat.ask(args.args, {
						selection = select.visual,
						window = {
							layout = "float",
							relative = "cursor",
							width = 1,
							height = 0.4,
							row = 1,
						},
					})
				end, { nargs = "*", range = true })

				vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
					chat.ask(args.args, { selection = select.buffer })
				end, { nargs = "*", range = true })

				vim.api.nvim_create_autocmd("BufEnter", {
					pattern = "copilot-*",
					callback = function()
						vim.opt_local.relativenumber = true
						vim.opt_local.number = true
						if vim.bo.filetype == "copilot-chat" then
							vim.bo.filetype = "markdown"
						end
					end,
				})

				require("which-key").add({
					{ "gm",  group = "Copilot Chat" },
					{ "gmd", desc = "Show diff" },
					{ "gmp", desc = "System prompt" },
					{ "gms", desc = "Show selection" },
					{ "gmy", desc = "Yank diff" },
				})
			end,
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
