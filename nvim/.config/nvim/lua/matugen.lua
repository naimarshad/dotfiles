 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#f2ecbc',
    base01 = '#e5ddb0',
    base02 = '#e0d6a1',
    base03 = '#918661',
    base04 = '#8a8980',
    base05 = '#545464',
    base06 = '#545464',
    base07 = '#545464',
    base08 = '#c84053',
    base09 = '#4d699b',
    base0A = '#77713f',
    base0B = '#6f894e',
    base0C = '#1b3e7e',
    base0D = '#527e1b',
    base0E = '#7e741b',
    base0F = '#ad9e1f',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#545464',          bg = '#f2ecbc' })
  hi('TelescopeBorder',         { fg = '#918661',             bg = '#f2ecbc' })
  hi('TelescopePromptNormal',   { fg = '#545464',          bg = '#f2ecbc' })
  hi('TelescopePromptBorder',   { fg = '#918661',             bg = '#f2ecbc' })
  hi('TelescopePromptPrefix',   { fg = '#6f894e',             bg = '#f2ecbc' })
  hi('TelescopePromptCounter',  { fg = '#8a8980',  bg = '#f2ecbc' })
  hi('TelescopePromptTitle',    { fg = '#f2ecbc',             bg = '#6f894e' })
  hi('TelescopePreviewTitle',   { fg = '#f2ecbc',             bg = '#77713f' })
  hi('TelescopeResultsTitle',   { fg = '#f2ecbc',             bg = '#4d699b' })
  hi('TelescopeSelection',      { fg = '#545464',          bg = '#e0d6a1' })
  hi('TelescopeSelectionCaret', { fg = '#6f894e',             bg = '#e0d6a1' })
  hi('TelescopeMatching',       { fg = '#6f894e',             bold = true })
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
