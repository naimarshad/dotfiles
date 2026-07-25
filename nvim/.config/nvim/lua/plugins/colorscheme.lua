-- Catppuccin, flavour "latte" (light) to match a light KDE Plasma theme.
-- Switch flavour to "macchiato" | "frappe" | "mocha" for a dark theme.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "latte",
      transparent_background = false,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        telescope = true,
        which_key = true,
        treesitter = true,
        indent_blankline = { enabled = true },
        mini = { enabled = true },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-latte" },
  },
}
