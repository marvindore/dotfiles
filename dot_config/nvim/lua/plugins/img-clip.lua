vim.pack.add({
  {
    src = "https://github.com/hakonharnes/img-clip.nvim.git",
    cmds = {"PasteImage"},
    keys = {
      { mode = "n", lhs = "<leader>p", rhs = "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard"}
    },
    data = {}
  }
}, {
	-- Standard lze loading hook
	load = function(p)
		local spec = p.spec.data or {}
		spec.name = p.spec.name
		require("lze").load(spec)
	end,
})
