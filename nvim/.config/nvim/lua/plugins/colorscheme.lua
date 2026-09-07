-- The colorscheme is driven by Noctalia through matugen, not set here directly.
-- lua/matugen.lua carries the generated base16 palette and applies it with
-- base16-nvim (installed in lua/plugins/base16.lua); a SIGUSR1 from matugen
-- re-applies it live. LazyVim runs `:colorscheme` itself once after startup and
-- would clobber that palette, so point its colorscheme hook at the same call.
return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        require("matugen").setup()
      end,
    },
  },
}
