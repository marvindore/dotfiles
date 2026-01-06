local function get_typescript_lib()
	-- get the project root
	local root = vim.fs.find({ "package.json", "tsconfig.json", ".git" }, { upward = true })[1]
	if not root then
		return nil
	end
	root = vim.fs.dirname(root)
	local tsdk = root .. "/node_modules/typescript/lib"
	-- check if tsserverlibrary.js exists
	if vim.fn.filereadable(tsdk .. "/tsserverlibrary.js") == 1 then
		return tsdk
	end
	return nil
end

return {
	cmd = { vim.fn.stdpath("data") .. "/mason/bin/astro-ls", "--stdio" },
	filetypes = { "astro" },
	root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
	init_options = {
		typescript = {
			tsdk = get_typescript_lib(),
		},
	},
}
