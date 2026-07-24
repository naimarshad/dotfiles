-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- VSCode muscle-memory: Ctrl+P quick-open (snacks picker is LazyVim's default).
vim.keymap.set("n", "<C-p>", function()
  Snacks.picker.files()
end, { desc = "Find Files (quick open)" })
