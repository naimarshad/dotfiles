 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#fdf6e3',
    base01 = '#eee8d5',
    base02 = '#e8e0c6',
    base03 = '#998e6e',
    base04 = '#738587',
    base05 = '#657b83',
    base06 = '#657b83',
    base07 = '#657b83',
    base08 = '#dc322f',
    base09 = '#cb4b16',
    base0A = '#d33682',
    base0B = '#a37a00',
    base0C = '#8a330f',
    base0D = '#997300',
    base0E = '#7e1b4b',
    base0F = '#ad1f64',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#657b83',          bg = '#fdf6e3' })
  hi('TelescopeBorder',         { fg = '#998e6e',             bg = '#fdf6e3' })
  hi('TelescopePromptNormal',   { fg = '#657b83',          bg = '#fdf6e3' })
  hi('TelescopePromptBorder',   { fg = '#998e6e',             bg = '#fdf6e3' })
  hi('TelescopePromptPrefix',   { fg = '#a37a00',             bg = '#fdf6e3' })
  hi('TelescopePromptCounter',  { fg = '#738587',  bg = '#fdf6e3' })
  hi('TelescopePromptTitle',    { fg = '#fdf6e3',             bg = '#a37a00' })
  hi('TelescopePreviewTitle',   { fg = '#fdf6e3',             bg = '#d33682' })
  hi('TelescopeResultsTitle',   { fg = '#fdf6e3',             bg = '#cb4b16' })
  hi('TelescopeSelection',      { fg = '#657b83',          bg = '#e8e0c6' })
  hi('TelescopeSelectionCaret', { fg = '#a37a00',             bg = '#e8e0c6' })
  hi('TelescopeMatching',       { fg = '#a37a00',             bold = true })
end

-- Register a signal handler for SIGUSR1 (matugen updates).
-- The handler re-requires this module, which re-runs the code below, so the
-- previous handle is stopped first; otherwise handlers double on every signal.
if _G.__matugen_signal then
  _G.__matugen_signal:stop()
  _G.__matugen_signal:close()
end

local signal = vim.uv.new_signal()
_G.__matugen_signal = signal
signal:start(
  'sigusr1',
  vim.schedule_wrap(function()
    package.loaded['matugen'] = nil
    require('matugen').setup()
  end)
)

return M
