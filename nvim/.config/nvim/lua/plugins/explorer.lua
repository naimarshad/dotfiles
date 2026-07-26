return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          -- don't close the sidebar when opening a file or losing focus
          auto_close = false,
          jump = { close = false },
        },
      },
    },
  },
}
