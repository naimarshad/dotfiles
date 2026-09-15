return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    opts = {
      -- contrast "" is the standard gruvbox dark background (#282828), which is
      -- what Ghostty's "Gruvbox Dark" theme uses. "hard" would be #1d2021.
      contrast = "",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
