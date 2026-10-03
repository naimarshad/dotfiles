-- The colorscheme is not set here directly. lua/gruvbox_light.lua carries the
-- base16 Gruvbox Light palette and applies it with base16-nvim (installed in
-- lua/plugins/base16.lua). LazyVim runs `:colorscheme` itself once after startup
-- and would clobber that palette, so point its colorscheme hook at the same call.
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("gruvbox_light").setup()
      end,
    },
  },
}
