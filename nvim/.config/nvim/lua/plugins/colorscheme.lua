-- ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- load before other plugins so colors are set first
    opts = {
      flavour = "macchiato",
      transparent_background = false,
      term_colors = true, -- makes your terminal inside nvim match the theme
      dim_inactive = {
        enabled = true, -- dims inactive splits — nice for split pane work
        shade = "dark",
        percentage = 0.15,
      },
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
      },
      default_integrations = true,
      auto_integrations = true, -- lazy.nvim auto-detects installed plugins
      integrations = {
        telescope = { enabled = true },
        gitsigns = true,
        which_key = true,
        treesitter = true,
        indent_blankline = { enabled = true },
        mini = { enabled = true },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin-macchiato")
    end,
  },
}
