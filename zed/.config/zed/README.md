# Zed IDE Setup

Zed configured as the same IDE the LazyVim setup in `nvim/.config/nvim` provides: Go and Rust plus the DevOps side (Shell, Docker, YAML, Helm, JSON, TOML, Markdown, Git, Terraform, Ansible), Claude Code as the AI agent, git built in, and a theme that follows Noctalia. Vim mode is on and the space-leader chords follow the Neovim keybind reference wherever Zed has an equivalent action.

Stow with `stow zed` from the repo root. Only `settings.json`, `keymap.json`, `tasks.json` and this README are tracked. `~/.config/zed/themes/` is written by Noctalia (community template `zed`) and stays untracked, the same as the `noctalia` theme files for ghostty and tmux.

File icons come from `zed-noctalia-icons/` at the repo root, a Zed extension rather than a stow package. It needs installing once per machine through **Install Dev Extension**; see its own README.

## File map

| Path | Purpose |
|---|---|
| `settings.json` | Theme, vim mode, panels, extensions, formatters, language server options, Claude Code agent, edit prediction, telemetry. |
| `keymap.json` | Space-leader chords for vim mode, grouped like the Neovim README. |
| `tasks.json` | Global tasks: lazygit, and the linters that have no Zed language server (hadolint, yamllint, actionlint), plus `go test`. |

Fonts follow ghostty: JetBrainsMono Nerd Font with `calt`, `liga` and `ss01`, in the editor and the built-in terminal. Editor text is 16, the UI is 16 on Zed's bundled sans font. Indent guides are on with per-level colouring and a thicker active guide, and `show_whitespaces` is `boundary`, which together make YAML nesting and stray leading spaces visible before a linter runs.

## Tools that must be on PATH

Zed captures its environment from an interactive zsh login shell, so anything `.zshrc` puts on PATH is visible, including the mise shims. Mason's binaries under `~/.local/share/nvim/mason/bin` are not on PATH and Zed does not see them. Zed downloads some servers itself and expects others to be installed:

| Tool | Used for | Provided by |
|---|---|---|
| `gopls` | Go | must be installed (Zed does not download it) |
| `golangci-lint` | Go lint, via the `golangci-lint` extension | mise |
| `rust-analyzer` | Rust | PATH first, otherwise Zed downloads its own |
| `bash-language-server`, `shellcheck`, `shfmt` | Shell | shellcheck and shfmt from mise; the server must be installed |
| `fish_indent` | Fish formatting | the `fish` package |
| `yaml-language-server` | YAML | Zed downloads it |
| `helm_ls` | Helm templates | must be installed |
| `terraform-ls`, `tflint`, `terraform` | Terraform / OpenTofu | must be installed; `~/.local/bin/terraform -> tofu` already exists |
| `ansible-language-server`, `ansible-lint`, `ansible` | Ansible | must be installed |
| `hadolint`, `yamllint`, `actionlint` | tasks in `tasks.json` | yamllint and actionlint from mise; hadolint must be installed |
| `lazygit` | `<space>gg` | pacman |
| `dlv` | Go debugging | must be installed |
| `npx` | Claude Code ACP adapter (`@agentclientprotocol/claude-agent-acp`) | pacman `npm` |

Run `zed: open log` from the command palette to see which servers started and which binaries were not found.

## Mapping from the Neovim setup

| Neovim | Zed |
|---|---|
| Mason-installed servers | Binaries on PATH, or Zed's own downloads |
| `nvim-lint` linters | `golangci-lint`, `tflint`, `markdownlint` extensions run as language servers; `hadolint`, `yamllint`, `actionlint` are tasks |
| `conform.nvim` formatters | `formatter` per language: gopls with organise-imports, rust-analyzer, `shfmt`, `fish_indent`, yaml-language-server, terraform-ls, Prettier for Markdown and JSON |
| gitsigns, lazygit, Snacks git pickers | Built-in git panel, project diff, hunk staging, inline blame; lazygit through a task |
| Octo (GitHub issues and PRs) | No equivalent; `gh` in the terminal |
| `claudecode.nvim` | Claude Code as an ACP agent in the agent panel, docked right |
| Supermaven ghost text | Zed's edit prediction (Zeta), eager mode |
| nvim-dap with delve and codelldb | Built-in debugger, same adapters, `debugger: start` |
| Neotest | gopls test code lens, runnables and tasks |
| `matugen.lua` + base16-nvim | Noctalia's generated theme, selected as "Noctalia Light" |
| Snacks explorer auto-open | `project_panel.starts_open` |
| `marksman` | No Markdown server in Zed |

## Keybind reference

Leader is Space in vim normal mode. Stock Zed vim mode already provides `gd`, `gD`, `gy`, `g shift-i` (implementation), `g r r` (references), `K`, `gc`, `]c` / `[c` and `ctrl-p`.

### Files, explorer, outline

| Keys | Action |
|---|---|
| `<space><space>` / `<space>ff` / `<space>fr` | File finder (recent files are ranked first) |
| `<space>fb` / `<space>,` | Open tabs switcher |
| `<space>e` | Toggle project panel |
| `<space>cs` | Toggle outline panel |
| `<space>ft` | Toggle terminal panel |
| `<space>:` | Command palette |

### Search

| Keys | Action |
|---|---|
| `<space>/` / `<space>sg` | Project search |
| `<space>ss` | Buffer symbols |
| `<space>sS` | Project symbols |
| `<space>sd` / `<space>xx` | Diagnostics view |

### LSP and diagnostics

| Keys | Action |
|---|---|
| `<space>ca` | Code actions (normal and visual) |
| `<space>cr` | Rename |
| `<space>cf` | Format (normal and visual) |
| `<space>cc` | Toggle code lens |
| `<space>uh` | Toggle inlay hints |
| `<space>cd` | Hover (includes the diagnostic under the cursor) |
| `]d` / `[d` | Next / previous diagnostic |

### Git

| Keys | Action |
|---|---|
| `<space>gg` | lazygit in the terminal panel |
| `<space>gs` | Toggle git panel |
| `<space>gd` | Project diff |
| `<space>gb` | Toggle inline blame |
| `<space>ghb` | Blame the buffer |
| `<space>ghs` / `<space>ghu` | Stage / unstage hunk and move to the next |
| `<space>ghr` | Restore hunk |
| `<space>ghp` | Toggle the diff for the hunk under the cursor |
| `<space>ghd` | Expand all diff hunks in the buffer |
| `]h` / `[h` | Next / previous hunk |

Commit, push, pull, fetch, branch switching and stash live in the git panel and its own default keys (`ctrl-enter` to commit, `ctrl-g up` / `ctrl-g down` to push / pull).

### Debugging

| Keys | Action |
|---|---|
| `<space>db` | Toggle breakpoint |
| `<space>dc` | Start a debug session |
| `<space>dr` | Rerun the last session |
| `<space>di` / `<space>do` / `<space>dO` | Step into / over / out |
| `<space>dt` | Stop |

### Tasks and tests

| Keys | Action |
|---|---|
| `<space>tt` | Spawn a task (runnables for the current file, then `tasks.json`) |
| `<space>tl` | Rerun the last task |

### AI: Claude Code

| Keys | Action |
|---|---|
| `<space>ac` | Toggle the agent panel |
| `<space>an` | New Claude Code thread |
| `<space>ab` | Add the selection to the thread (normal) |
| `<space>as` | Add the selection to the thread (visual) |
| `<space>ar` | Review the agent's diff |
| `<space>aa` / `<space>ad` | Keep / reject the hunk under the cursor |

Edit prediction: `tab` accepts in eager mode, `alt-l` also accepts, `alt-k` accepts the next word, `escape` dismisses.

### Windows and Markdown

| Keys | Action |
|---|---|
| `ctrl-h/j/k/l` | Move between panes |
| `<space>-` / `<space>\|` | Split below / right |
| `<space>wm` | Zoom the current pane |
| `<space>cp` | Markdown preview to the side (Markdown files only) |
