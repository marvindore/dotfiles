return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	enabled = vim.g.enableCopilot,
	config = function()
		require("copilot").setup({
			suggestion = {
				enabled = true,
				auto_trigger = false,
			},
			panel = { enabled = false },
		})
	end,
}
