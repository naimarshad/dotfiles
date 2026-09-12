# Noctalia Icons

A Zed icon theme whose glyphs are drawn in the Noctalia light palette, so the project panel and tabs match the rest of the desktop theme. Hand-drawn line art rather than a port of an existing icon set, because the point is the palette.

This is a Zed extension directory, **not a stow package**. Do not `stow` it. The Zed config that selects it lives in the `zed` package (`zed/.config/zed/settings.json`, key `icon_theme`).

## Installing

Zed has no way to install an unpublished extension from a path in settings, so this is a one-time manual step per machine:

1. Open Zed, then the Extensions view (`ctrl-shift-x`, or `zed: extensions` from the command palette).
2. Click **Install Dev Extension**.
3. Select `~/dotfiles/zed-noctalia-icons`.

`settings.json` already sets `"icon_theme": "Noctalia Icons"`, so the icons appear as soon as the extension loads. Before that, Zed silently falls back to its own icon theme, which is why a fresh machine shows default icons until step 3 is done.

There is no build step. Icon themes need no Rust and no compilation, so editing a file here and reloading Zed is enough.

## Layout

| Path | Purpose |
|---|---|
| `extension.toml` | Extension manifest. `schema_version = 1`. |
| `icon_themes/noctalia.json` | The icon theme: filename and suffix mappings, and the icon list. |
| `icons/*.svg` | 28 glyphs, 16x16 viewBox, 1.25 stroke, round caps and joins. |

## Palette

Taken from the Noctalia Light theme Noctalia generates at `~/.config/zed/themes/noctalia.json`, which is the same palette `nvim/.config/nvim/lua/matugen.lua` carries for Neovim.

| Colour | Used for |
|---|---|
| `#1f52ad` bright blue | Go |
| `#c84053` red | Rust, Ansible, Git |
| `#6f894e` green | Shell, images |
| `#527e1b` leaf green | Fish, Helm |
| `#1b3e7e` deep blue | YAML, Lua |
| `#4d699b` blue | Docker |
| `#77713f` olive | TOML, Terraform, KDL, config |
| `#ad9e1f` gold | JSON, secrets and keys |
| `#545464` foreground | Markdown, text |
| `#918661` dim | Folders, archives, licences, the default file |
| `#8a8980` muted | Chevrons |

The colours are written into each SVG, so this is a hand-maintained copy of the palette, exactly like `lua/matugen.lua` is for Neovim. Noctalia has no icon template, so **a desktop theme change does not update these icons**. Re-colouring means editing the SVGs. That is the known cost of the approach.

The set is drawn for a light background and `appearance` is declared `light`. On Noctalia Dark the darker glyphs (deep blue, foreground, dim) would lose contrast.

## Coverage

Exact filenames are matched before extensions, so `Chart.yaml`, `go.mod`, `docker-compose.yml`, `.zshrc`, `.sops.yaml` and `LICENSE` get their own icons rather than the generic YAML or shell one. Anything unmapped falls back to Zed's own icon theme for that type, so partial coverage degrades quietly instead of showing blanks.

Mapped groups: Go, Rust, shell, fish, YAML, JSON, TOML, KDL, Lua, Markdown, Docker, Helm, Terraform and OpenTofu, Ansible, git metadata, secrets and keys, images, archives, config and unit files, licences, plain text. Folders get a generic pair plus a git-marked pair for `.git` and `.github`.

## Editing

Keep the shared grammar so the set stays coherent: `viewBox="0 0 16 16"`, `fill="none"`, `stroke-width="1.25"`, round caps and joins, glyphs filling roughly 12 of the 16 units. Solid dots are `fill` plus `stroke="none"` on that one element.

After editing, re-check the theme file and the icon paths:

```sh
cd ~/dotfiles/zed-noctalia-icons
jq -e . icon_themes/noctalia.json
for p in $(jq -r '[.themes[].file_icons[].path] | .[]' icon_themes/noctalia.json); do test -f "$p" || echo "missing $p"; done
```

Zed reloads a dev extension on restart. Bump `version` in `extension.toml` when the set changes meaningfully, so it is obvious which revision a machine has.
