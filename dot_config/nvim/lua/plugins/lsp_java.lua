-- 1. Fast exit if Java is disabled globally
if not vim.g.enableJava then
	return
end

-- 2. Register with the native package manager and lze
vim.pack.add({
	{
		src = "https://github.com/mfussenegger/nvim-jdtls",
		data = {
			-- Lazy load only when you open a Java file
			ft = { "java" },

			-- nvim-jdtls does not use a standard global setup() function.
			-- You will call `require('jdtls').start_or_attach(config)`
			-- inside your `~/.config/nvim/ftplugin/java.lua` file instead.
		},
	},
}, {
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = spec.name or p.spec.name
		require("lze").load(spec)
	end,
})
