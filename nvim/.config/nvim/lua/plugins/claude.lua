-- Claude Code terminal tweaks. The `ai.claudecode` extra already installs
-- coder/claudecode.nvim and its <leader>a… keymaps; this only adjusts the
-- terminal placement/behaviour. Delete this file to fall back to defaults.
--
-- NOTE: leave `terminal_cmd` unset while `claude` is on your PATH. If you use
-- the local (non-PATH) install, uncomment the line below.
return {
  {
    "coder/claudecode.nvim",
    opts = {
      -- terminal_cmd = "~/.claude/local/claude",
      focus_after_send = true,
      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        provider = "snacks",
      },
    },
  },
}
