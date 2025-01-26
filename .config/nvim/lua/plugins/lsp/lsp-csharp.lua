local utils = require("utils")

return {
	"seblj/roslyn.nvim",
	enabled = utils.enableCsharp,
	dependencies = {
		"williamboman/mason.nvim",
	},
}
