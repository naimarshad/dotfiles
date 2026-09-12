# Neovim IDE Setup

This is a [LazyVim](https://www.lazyvim.org/) config, run as a full IDE on `machine/workforce` rather than a plain text editor. It replaces VS Code for daily work: Go and Rust development, plus the DevOps/IaC side (Shell, Docker, YAML, Helm, JSON, TOML, Markdown, Git), with Claude Code and Supermaven wired in for AI assistance, and a colorscheme that follows the desktop theme (Noctalia) live.

The next section is the brief: what's here and why. Everything after "Keybind reference" is the lookup table for daily use.

## File map

| Path | Purpose |
|---|---|
| `init.lua` | Bootstraps `lazy.nvim` and LazyVim. Stock, untouched. |
| `lazyvim.json` | Which LazyVim extras are enabled, and the pinned extras schema version. |
| `lua/config/options.lua` | `vim.opt`/`vim.g` overrides: light background, `confirm = true`, Supermaven display mode. |
| `lua/config/keymaps.lua` | Keymaps added on top of LazyVim's defaults. Currently just `<C-p>`. |
| `lua/config/autocmds.lua` | Autocommands added on top of LazyVim's defaults. Currently just auto-opening the file explorer. |
| `lua/config/lazy.lua` | `lazy.nvim` setup, including the `concurrency = 10` throttle (see below). |
| `lua/plugins/*.lua` | Custom plugin specs, one concern per file (see "Custom, non-stock pieces"). |
| `lua/matugen.lua` | Bridge that turns Noctalia's generated base16 palette into a live `base16-nvim` colorscheme. |

## Enabled extras

From `lazyvim.json`, grouped by what they're for:

| Group | Extras |
|---|---|
| Languages | Go, Rust, Docker, YAML, Helm, JSON, TOML, Markdown, Git, Terraform, Ansible |
| AI | `ai.claudecode` (Claude Code), `ai.supermaven` (ghost-text completion) |
| Editor | `editor.outline` (symbol outline), `editor.snacks_explorer` (file tree sidebar), `editor.snacks_picker` (fuzzy finder for files/grep/buffers/git/LSP symbols/etc.) |
| Debug / test | `dap.core` (nvim-dap + UI), `test.core` (Neotest) |
| Coding | `coding.yanky` (yank history and ring) |
| Util | `util.octo` (GitHub issues/PRs from inside Neovim), `util.mini-hipatterns` (highlights hex colors and Tailwind classes inline) |

## Custom, non-stock pieces

These aren't part of any LazyVim extra, they're hand-written in `lua/plugins/`:

- **`shell.lua`**: bash/fish support. LazyVim has no `lang.bash` extra, so this wires up `bashls` (LSP), `shfmt` (format, sh/bash/fish), and `shellcheck` (lint) by hand.
- **`lint.lua`**: adds `yamllint` on top of `yamlls`' schema validation, and `actionlint` scoped to the `yaml.github` filetype (which LazyVim's YAML extra already assigns to anything under `.github/workflows/`).
- **`explorer.lua`**: keeps the Snacks file explorer sidebar open when you open a file or move focus elsewhere, instead of auto-closing.
- **`claude.lua`**: docks the Claude Code terminal on the right at 30% width and focuses it after sending; everything else about `ai.claudecode` is the extra's own defaults.
- **`colorscheme.lua`** + **`base16.lua`** + **`matugen.lua`**: point LazyVim's colorscheme hook at `matugen.lua`, which reads the palette Noctalia generates and applies it through `base16-nvim`. A `SIGUSR1` from matugen re-applies it live, so changing the desktop theme recolors Neovim without a restart.
- **`lua/config/options.lua`**: forces `vim.opt.background = "light"` to match the Noctalia light palette, and sets `vim.g.ai_cmp = false` so Supermaven shows as inline ghost text (Copilot-style) instead of riding inside the completion menu.
- **`lua/config/autocmds.lua`**: auto-opens the file explorer sidebar on startup, skipping special buffers (git commit messages, diffs, empty stdin).
- **`lua/config/keymaps.lua`**: adds `<C-p>` as a VS Code-style quick-open, on top of everything LazyVim already binds.

One operational note from `lua/config/lazy.lua`: a large `:Lazy sync` opens many concurrent git fetches, which has flooded the home router's DNS resolver before (`Could not resolve host: github.com`). `concurrency = 10` keeps that from happening; if you ever see that error mid-sync, just re-run `:Lazy sync`, it converges.

## Language and IaC tooling

| Filetype | LSP | Format | Lint | Debug / test | Notes |
|---|---|---|---|---|---|
| Go | `gopls` | `goimports`, `gofumpt` | `golangci-lint` | `delve` via `nvim-dap-go`; `neotest-golang` | |
| Rust | `rust-analyzer` via `rustaceanvim` | rust-analyzer itself | rust-analyzer itself | `codelldb` | `rustaceanvim` disables the plain `rust_analyzer` lspconfig server and manages it directly; formatting and code actions come from `:RustLsp` commands, there's no separate conform/lint entry |
| Shell (bash/sh) | `bashls` | `shfmt` | `shellcheck` | | custom, `shell.lua` |
| Fish | none | `fish_indent` | none | | custom, `shell.lua` |
| Docker | `dockerls`, `docker_compose_language_service` | | `hadolint` | | |
| YAML | `yamlls` + SchemaStore | `yamlls` (built in) | `yamllint` | | `yamllint` is the custom addition in `lint.lua` |
| YAML, GitHub Actions | (same, `yaml.github` ft) | | `actionlint` | | only fires under `.github/workflows/` |
| Helm | `helm_ls` | | | | root-detected by `Chart.yaml` |
| JSON | `jsonls` + SchemaStore | built in | | | |
| TOML | `taplo` | | | | |
| Markdown | `marksman` | `prettier`, `markdownlint-cli2`, `markdown-toc` | `markdownlint-cli2` | | live preview via `<leader>cp`; rendered checkboxes/headings via `render-markdown.nvim` |
| Git commit/rebase/ignore files | treesitter + completion only | | | | no LSP, just better highlighting and `cmp-git` completion |
| Terraform / OpenTofu | `terraform-ls` | `terraform_fmt` | `tflint`, `terraform_validate` | | root-detected by `.terraform`; see the OpenTofu note below |
| Ansible | `ansible-language-server` | | `ansible-lint` | | `<leader>ta` runs the current playbook/role, scoped to the `yaml.ansible` filetype (confirmed below) |

Run `:LspInfo` in any buffer to confirm which server actually attached, and `:Mason` to see everything installed and its update status.

> [!note] OpenTofu vs Terraform binary
> `terraform-ls`, `terraform_fmt`, and `terraform_validate` all shell out to a binary literally named `terraform`. This machine only has `tofu` (via mise), no real Hashicorp Terraform, which showed up as `Error running terraform: ENOENT` the first time a `.tf` file was formatted. Fixed with a symlink: `~/.local/bin/terraform -> ~/.local/share/mise/installs/opentofu/latest/tofu` (`~/.local/bin` is already on `PATH`). Points at mise's `latest` OpenTofu install rather than a pinned version, so a `mise upgrade` keeps working without re-linking. This is a machine-level fix (not part of this dotfiles repo), so it needs redoing on any other machine that has `tofu` but not `terraform` on `PATH`.

The `<leader>ta` collision between Neotest ("Attach to Test", global) and `nvim-ansible` ("Run Playbook/Role", scoped to `ft = "yaml.ansible"`) is real but resolved in Ansible's favor: confirmed with `:verbose map <leader>ta` in a `yaml.ansible` buffer, the buffer-local Ansible mapping wins there, Neotest's stays active everywhere else.

## Keybind reference

Leader is **Space**, local leader is **`\`** (both LazyVim defaults, unchanged here). This section covers what's actually bound in this config, it skips plain Vim motions and the huge stock LazyVim set that isn't relevant to IaC/backend work; see [LazyVim's own keymap reference](https://www.lazyvim.org/keymaps) for the full stock list.

### Files, explorer, and outline

| Keys | Action |
|---|---|
| `<C-p>` | Quick-open files (custom, `keymaps.lua`) |
| `<leader>e` / `<leader>fe` | Toggle file explorer (root dir) |
| `<leader>E` / `<leader>fE` | Toggle file explorer (cwd) |
| `<leader>cs` | Toggle symbol outline (this repo repoints it from Trouble's symbol view to `outline.nvim`) |

### Search (Snacks picker)

The picker backend is Snacks (`editor.snacks_picker`), the same engine already running the file explorer, terminal, and dashboard. Most useful for IaC work: `<leader>sg` to grep a variable/task/resource name across a whole Terraform module or Ansible role tree, `<leader>ss`/`<leader>sS` to jump between symbols in a large values.yaml or main.tf.

| Keys | Action |
|---|---|
| `<leader><space>` | Find files (root dir), same as `<leader>ff` |
| `<leader>ff` / `<leader>fF` | Find files (root dir / cwd) |
| `<leader>fg` | Find files (git-tracked only) |
| `<leader>fr` / `<leader>fR` | Recent files (all / cwd) |
| `<leader>fb` / `<leader>fB` | Buffers (open / all incl. hidden) |
| `<leader>fc` | Find a config file |
| `<leader>fp` | Projects |
| `<leader>/` / `<leader>sg` | Grep (root dir) |
| `<leader>sG` | Grep (cwd) |
| `<leader>sw` / `<leader>sW` | Grep word or visual selection (root dir / cwd) |
| `<leader>sb` | Grep current buffer's lines |
| `<leader>sB` | Grep across open buffers |
| `<leader>ss` | LSP document symbols |
| `<leader>sS` | LSP workspace symbols |
| `<leader>sd` / `<leader>sD` | Diagnostics (workspace / buffer) |
| `<leader>st` / `<leader>sT` | TODO comments (all / TODO+FIX+FIXME) |
| `<leader>sh` | Help pages |
| `<leader>sk` | Keymaps |
| `<leader>,` / `<leader>:` | Buffers / command history |
| `<leader>n` | Notification history |

This also changes `gd`/`gr`/`gI`/`gy` (the LSP navigation keys below): they now open through a Snacks picker list instead of jumping straight there, same keys, picker-backed results.

### LSP (works in any attached buffer)

| Keys | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gI` | Go to implementation |
| `gy` | Go to type definition |
| `gr` | List references |
| `K` | Hover docs |
| `gK` | Signature help |
| `<leader>ca` | Code action (normal + visual) |
| `<leader>cA` | Source action |
| `<leader>cr` | Rename symbol |
| `<leader>cR` | Rename file (and update imports, if the server supports it) |
| `<leader>cc` | Run codelens |
| `<leader>cC` | Refresh codelens |
| `<leader>cl` | LSP info picker |
| `<leader>cm` | Open Mason |
| `]]` / `[[` | Next/prev reference to symbol under cursor |

### Diagnostics

| Keys | Action |
|---|---|
| `<leader>cd` | Line diagnostics (float) |
| `]d` / `[d` | Next/prev diagnostic |
| `]e` / `[e` | Next/prev error |
| `]w` / `[w` | Next/prev warning |
| `<leader>xx` | Toggle Trouble (all diagnostics) |
| `<leader>xX` | Toggle Trouble (current buffer only) |
| `<leader>cS` | Trouble: LSP references/definitions |
| `<leader>xt` / `<leader>xT` | Trouble: TODOs / TODO+FIX+FIXME |

### Formatting and linting

| Keys | Action |
|---|---|
| `<leader>cf` | Format buffer (normal + visual) |
| `<leader>uf` / `<leader>uF` | Toggle format-on-save (buffer / global) |

Linters run automatically via `nvim-lint` on the events it's configured for (save, insert-leave); there's no manual "run linter" keybind, check `:LspInfo` and the diagnostics list above.

### Git

| Keys | Action |
|---|---|
| `<leader>gg` / `<leader>gG` | Lazygit (root dir / cwd) |
| `<leader>gb` | Git blame line |
| `<leader>gB` | Browse to line/selection on remote |
| `<leader>gl` / `<leader>gL` | Git log (root dir / cwd) |
| `]h` / `[h` | Next/prev git hunk |
| `<leader>ghs` / `<leader>ghr` | Stage / reset hunk |
| `<leader>ghS` / `<leader>ghR` | Stage / reset whole buffer |
| `<leader>ghp` | Preview hunk inline |
| `<leader>ghb` / `<leader>ghB` | Blame line / blame buffer |
| `<leader>ghd` | Diff current buffer against index |
| `<leader>gi` / `<leader>gI` | Octo: list / search issues |
| `<leader>gp` / `<leader>gP` | Octo: list / search PRs |
| `<leader>gd` / `<leader>gD` | Snacks picker: git diff hunks (cwd / vs `origin`) |
| `<leader>gs` / `<leader>gS` | Snacks picker: git status / git stash |

Octo explicitly disables Snacks' own `<leader>gi`/`<leader>gI`/`<leader>gp`/`<leader>gP` (its GitHub issue/PR pickers) in favor of Octo's, so there's no real collision between the two extras, just be aware Octo wins those four keys.

### Debugging (DAP)

| Keys | Action |
|---|---|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dc` | Continue / start |
| `<leader>da` | Run with args |
| `<leader>di` / `<leader>do` / `<leader>dO` | Step into / out / over |
| `<leader>dt` | Terminate session |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Evaluate expression (normal + visual) |
| `<leader>dr` | Toggle REPL |
| `<leader>dw` | Hover widgets |

Requires a debug adapter for the language: `delve` for Go, `codelldb` for Rust, both installed automatically by their language extras.

### Testing (Neotest)

| Keys | Action |
|---|---|
| `<leader>tt` | Run current file |
| `<leader>tr` | Run nearest test |
| `<leader>tT` | Run all test files |
| `<leader>tl` | Re-run last |
| `<leader>ts` | Toggle summary panel |
| `<leader>to` | Show output of last run |
| `<leader>td` | Debug nearest test (via DAP) |
| `<leader>ta` | Attach to a running test; in a `yaml.ansible` buffer this is shadowed by `nvim-ansible`'s buffer-local mapping instead, which runs the current playbook/role (see the Terraform/Ansible note above) |

### AI: Claude Code

| Keys | Action |
|---|---|
| `<leader>ac` | Toggle the Claude Code terminal |
| `<leader>af` | Focus it |
| `<leader>ar` | Resume last session |
| `<leader>aC` | Continue last session |
| `<leader>ab` | Add current buffer to context |
| `<leader>as` | Send visual selection (or add current file, in the explorer) |
| `<leader>aa` / `<leader>ad` | Accept / deny a proposed diff |

### AI: Supermaven

Suggestions show as inline ghost text (not in the completion menu, since `vim.g.ai_cmp = false`). Accept/dismiss go through the same keys as normal completion acceptance (`<Tab>`/whatever `blink.cmp` is bound to), there's no separate Supermaven-only keybind in this config.

### Yank/paste history

| Keys | Action |
|---|---|
| `<leader>p` | Open yank history picker |
| `y` / `p` / `P` | Yank / put after / put before (yanky-wrapped, same muscle memory as stock Vim) |
| `[y` / `]y` | Cycle backward/forward through yank history |

### Windows, tabs, terminal

| Keys | Action |
|---|---|
| `<C-h/j/k/l>` | Move between windows |
| `<leader>-` / `<leader>\|` | Split below / right |
| `<leader>wm` | Zoom current window |
| `<C-/>` | Focus a floating terminal (root dir) |
| `<leader>ft` / `<leader>fT` | Open floating terminal (root dir / cwd) |
| `<leader><tab><tab>` | New tab |

## Theming

Covered in the repo's top-level `CLAUDE.md` under "Neovim IDE setup (done)", short version: the colorscheme is generated by Noctalia and applied live through `matugen.lua` + `base16-nvim`, not set as a static `colorscheme` name here.
