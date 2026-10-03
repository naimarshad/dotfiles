return {
  'RRethy/base16-nvim',
  priority = 1000,
  config = function()
    -- Italic comments. Wrap base16's setup so every re-apply of the palette
    -- keeps them. Treesitter's @comment is already italic in base16; this
    -- covers plain Comment.
    local b16 = require('base16-colorscheme')
    local setup = b16.setup
    b16.setup = function(...)
      setup(...)
      vim.api.nvim_set_hl(0, 'Comment', { fg = b16.colors.base03, italic = true })
    end

    require('gruvbox_light').setup()
  end,
}
