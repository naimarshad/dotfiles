 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#eff1f5',
    base01 = '#ccd0da',
    base02 = '#c0c5d1',
    base03 = '#838aa7',
    base04 = '#6c6f85',
    base05 = '#4c4f69',
    base06 = '#4c4f69',
    base07 = '#4c4f69',
    base08 = '#d20f39',
    base09 = '#40a02b',
    base0A = '#fe640b',
    base0B = '#8839ef',
    base0C = '#2d7e1b',
    base0D = '#440b8e',
    base0E = '#983801',
    base0F = '#cb4b01',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#4c4f69',          bg = '#eff1f5' })
  hi('TelescopeBorder',         { fg = '#838aa7',             bg = '#eff1f5' })
  hi('TelescopePromptNormal',   { fg = '#4c4f69',          bg = '#eff1f5' })
  hi('TelescopePromptBorder',   { fg = '#838aa7',             bg = '#eff1f5' })
  hi('TelescopePromptPrefix',   { fg = '#8839ef',             bg = '#eff1f5' })
  hi('TelescopePromptCounter',  { fg = '#6c6f85',  bg = '#eff1f5' })
  hi('TelescopePromptTitle',    { fg = '#eff1f5',             bg = '#8839ef' })
  hi('TelescopePreviewTitle',   { fg = '#eff1f5',             bg = '#fe640b' })
  hi('TelescopeResultsTitle',   { fg = '#eff1f5',             bg = '#40a02b' })
  hi('TelescopeSelection',      { fg = '#4c4f69',          bg = '#c0c5d1' })
  hi('TelescopeSelectionCaret', { fg = '#8839ef',             bg = '#c0c5d1' })
  hi('TelescopeMatching',       { fg = '#8839ef',             bold = true })
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
