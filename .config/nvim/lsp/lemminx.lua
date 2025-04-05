return {
	cmd = { "lemminx" },
	filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
	root_markers = function(fname)
		return vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
	end,
	single_file_support = true,
}
