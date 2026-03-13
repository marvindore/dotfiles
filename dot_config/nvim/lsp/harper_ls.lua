return {
	cmd = { "harper-ls", "--stdio" },
	filetypes = { "markdown", "text", "gitcommit", "org", "latex" },
	root_markers = { ".git" },
	settings = {
		["harper-ls"] = {
			linters = {
				SentenceCapitalization = false,
				SpellCheck = false,
			},
		},
	},
}
