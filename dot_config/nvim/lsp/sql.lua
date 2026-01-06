return {
	cmd = {
		vim.g.isWindowsOs and vim.g.neovim_home .. "/mason/packages/sqls/sqls.exe"
			or vim.g.neovim_home .. "/mason/bin/sqls",
		"--config",
		vim.g.homeDir .. "/.config/sqls.yml",
	},
  filetypes = { "sql", "mysql" }
}
