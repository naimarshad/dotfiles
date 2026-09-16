-- Colours come from Noctalia, not from a colorscheme plugin. Noctalia's nvim
-- template renders lua/matugen.lua with a base16 palette for the active scheme
-- (currently Gruvbox Light) and sends SIGUSR1 on every re-render, which
-- matugen.lua catches to re-apply itself. So changing the Noctalia scheme
-- re-themes running editors too; never hand-edit matugen.lua.
return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        -- base16-nvim does not set 'background' itself, and plugins that pick
        -- light/dark variants of their own highlights read it.
        vim.o.background = "light"
        require("matugen").setup()
      end,
    },
  },
}
