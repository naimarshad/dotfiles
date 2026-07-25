-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- AI completion display mode (used by the ai.supermaven extra):
--   false = Supermaven shows as inline ghost text (Copilot-style)
--   true  = Supermaven suggestions ride inside the blink.cmp menu
vim.g.ai_cmp = false

-- Ask for confirmation instead of erroring on unsaved changes / :q etc.
vim.opt.confirm = true

-- Light theme (catppuccin latte), to match a light KDE Plasma setup.
vim.opt.background = "light"
