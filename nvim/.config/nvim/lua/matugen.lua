 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#fbf1c7',
    base01 = '#ebdbb2',
    base02 = '#e7d3a2',
    base03 = '#98896f',
    base04 = '#7c6f64',
    base05 = '#3c3836',
    base06 = '#3c3836',
    base07 = '#3c3836',
    base08 = '#cc241d',
    base09 = '#458588',
    base0A = '#d79921',
    base0B = '#98971a',
    base0C = '#1b7a7e',
    base0D = '#838216',
    base0E = '#855e14',
    base0F = '#b17e1b',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#3c3836',          bg = '#fbf1c7' })
  hi('TelescopeBorder',         { fg = '#98896f',             bg = '#fbf1c7' })
  hi('TelescopePromptNormal',   { fg = '#3c3836',          bg = '#fbf1c7' })
  hi('TelescopePromptBorder',   { fg = '#98896f',             bg = '#fbf1c7' })
  hi('TelescopePromptPrefix',   { fg = '#98971a',             bg = '#fbf1c7' })
  hi('TelescopePromptCounter',  { fg = '#7c6f64',  bg = '#fbf1c7' })
  hi('TelescopePromptTitle',    { fg = '#fbf1c7',             bg = '#98971a' })
  hi('TelescopePreviewTitle',   { fg = '#fbf1c7',             bg = '#d79921' })
  hi('TelescopeResultsTitle',   { fg = '#fbf1c7',             bg = '#458588' })
  hi('TelescopeSelection',      { fg = '#3c3836',          bg = '#e7d3a2' })
  hi('TelescopeSelectionCaret', { fg = '#98971a',             bg = '#e7d3a2' })
  hi('TelescopeMatching',       { fg = '#98971a',             bold = true })
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
