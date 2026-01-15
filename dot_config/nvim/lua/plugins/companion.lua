return {
	"olimorris/codecompanion.nvim",
	enabled = vim.g.enableCodeCompanion,
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
		strategies = {
			chat = {
				adapter = "copilot",
				model = "gpt-4.1",
			},
		},
		opts = {
			log_level = "DEBUG",
		},
		-- Moved display settings here to consolidate config
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
	-- Update signature to accept opts
	config = function(_, opts)
		require("codecompanion").setup(opts)

		-- Fidget integration remains here
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
