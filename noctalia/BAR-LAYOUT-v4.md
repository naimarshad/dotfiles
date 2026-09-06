# Noctalia v4 bar layouts — reference for the v5 rebuild

Recovered from the v4 `settings.json` before the `noctalia/.config/noctalia/` tree was
removed in the v4 -> v5 migration. Noctalia 5 keeps its config at
`~/.local/state/noctalia/settings.toml` and is configured through the GUI, so this file
is the record of what each output's bar held — rebuild from it, then encrypt the result
into `noctalia/settings.sops.toml`.

All credential fields (`token`, `username`, `icsUrl`, `kubeconfigPath`, ...) were empty in
the source: they were entered at runtime into the gitignored per-plugin settings, so
nothing here is sensitive. They must be re-entered in v5 via
`noctalia msg settings-open-plugin <author/plugin>`.

Widget ids are v4 names. Core widgets carry over; `plugin:` entries depend on each
plugin having a v5 port — `next-meeting` in particular is unverified, see [[CLAUDE.md]].

---

## HDMI-A-1  ·  home desk, primary ultrawide

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsOpacity`=1 |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `compactShowAlbumArt`=true, `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `panelShowVisualizer`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true |

**center** — empty

**right** (16)

| # | widget | non-default settings |
|---|---|---|
| 1 | `plugin:next-meeting` | — |
| 2 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=["You have 1 notification", "Cachy-Update", "KDE Connect"] |
| 3 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 4 | `plugin:ip-monitor` | — |
| 5 | `plugin:network-indicator` | — |
| 6 | `plugin:tailscale` | — |
| 7 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 8 | `plugin:screen-recorder` | — |
| 9 | `plugin:screenshot` | — |
| 10 | `plugin:privacy-indicator` | — |
| 11 | `plugin:mini-docker` | — |
| 12 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-hover", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 13 | `Clock` | `clockColor`="secondary", `customFont`="Inter", `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 14 | `plugin:kubectl-ctx` | — |
| 15 | `plugin:github-feed` | — |
| 16 | `ControlCenter` | `colorizeSystemIcon`="error", `icon`="noctalia" |

---

## DP-3  ·  office dock, P34w-20 (alternates with DP-5)

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket", `iconColor`="tertiary" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `fontWeight`="bold", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsO... |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true |

**center** — empty

**right** (16)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=[] |
| 2 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 3 | `plugin:ip-monitor` | — |
| 4 | `plugin:network-indicator` | — |
| 5 | `plugin:tailscale` | — |
| 6 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 7 | `plugin:screen-recorder` | — |
| 8 | `plugin:screenshot` | — |
| 9 | `plugin:privacy-indicator` | — |
| 10 | `plugin:mini-docker` | — |
| 11 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-hover", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 12 | `Clock` | `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 13 | `plugin:kde-connect` | — |
| 14 | `ControlCenter` | `icon`="noctalia" |
| 15 | `plugin:github-feed` | — |
| 16 | `plugin:kubectl-ctx` | — |

---

## DP-5  ·  office dock, P34w-20 (alternates with DP-3)

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket", `iconColor`="tertiary" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsOpacity`=1 |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `compactShowAlbumArt`=true, `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `panelShowVisualizer`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true |

**center** — empty

**right** (16)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=[] |
| 2 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 3 | `plugin:ip-monitor` | — |
| 4 | `plugin:network-indicator` | — |
| 5 | `plugin:tailscale` | — |
| 6 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 7 | `plugin:screen-recorder` | — |
| 8 | `plugin:screenshot` | — |
| 9 | `plugin:privacy-indicator` | — |
| 10 | `plugin:mini-docker` | — |
| 11 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-hover", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 12 | `plugin:ramadan-iftar` | — |
| 13 | `Clock` | `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 14 | `plugin:github-feed` | — |
| 15 | `ControlCenter` | `icon`="noctalia" |
| 16 | `plugin:kubectl-ctx` | — |

---

## DP-6  ·  secondary

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket", `iconColor`="tertiary" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsOpacity`=1 |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true |

**center** — empty

**right** (16)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=[] |
| 2 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 3 | `plugin:ip-monitor` | — |
| 4 | `plugin:network-indicator` | — |
| 5 | `plugin:tailscale` | — |
| 6 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 7 | `plugin:screen-recorder` | — |
| 8 | `plugin:screenshot` | — |
| 9 | `plugin:privacy-indicator` | — |
| 10 | `plugin:mini-docker` | — |
| 11 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-hover", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 12 | `plugin:ramadan-iftar` | — |
| 13 | `Clock` | `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 14 | `ControlCenter` | `icon`="noctalia" |
| 15 | `plugin:github-feed` | — |
| 16 | `plugin:kubectl-ctx` | — |

---

## DP-1  ·  home desk, MSI MP275QPG — the layout that was nearly lost. (It was rotated vertical under v4; it is landscape now, see outputs.kdl.)

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket", `iconColor`="tertiary" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `fontWeight`="bold", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsO... |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true, `showText`=true |

**center** — empty

**right** (16)

| # | widget | non-default settings |
|---|---|---|
| 1 | `plugin:next-meeting` | — |
| 2 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=[] |
| 3 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 4 | `plugin:ip-monitor` | — |
| 5 | `plugin:network-indicator` | — |
| 6 | `plugin:tailscale` | — |
| 7 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 8 | `plugin:screen-recorder` | — |
| 9 | `plugin:screenshot` | — |
| 10 | `plugin:privacy-indicator` | — |
| 11 | `plugin:mini-docker` | — |
| 12 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-hover", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 13 | `Clock` | `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 14 | `plugin:kubectl-ctx` | — |
| 15 | `plugin:github-feed` | — |
| 16 | `ControlCenter` | `icon`="noctalia" |

---

## eDP-1  ·  laptop panel

`enabled = true`

**left** (7)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Launcher` | `icon`="rocket", `iconColor`="tertiary" |
| 2 | `Workspace` | `characterCount`=2, `emptyColor`="secondary", `enableScrollWheel`=true, `focusedColor`="primary", `groupedBorderOpacity`=1, `iconScale`=0.8, `labelMode`="index", `occupiedColor`="secondary", `pillSize`=0.6, `showBadge`=true, `showLabelsOnlyWhenOccupied`=true, `unfocusedIconsOpacity`=1 |
| 3 | `SystemMonitor` | `compactMode`=true, `diskPath`="/", `showCpuTemp`=true, `showCpuUsage`=true, `showMemoryUsage`=true, `useMonospaceFont`=true |
| 4 | `plugin:notes-scratchpad` | — |
| 5 | `plugin:pomodoro` | — |
| 6 | `MediaMini` | `compactShowAlbumArt`=true, `hideMode`="hidden", `maxWidth`=145, `panelShowAlbumArt`=true, `panelShowVisualizer`=true, `scrollingMode`="hover", `showAlbumArt`=true, `showArtistFirst`=true, `showProgressRing`=true, `visualizerType`="linear" |
| 7 | `ActiveWindow` | `hideMode`="hidden", `maxWidth`=145, `scrollingMode`="hover", `showIcon`=true |

**center** — empty

**right** (15)

| # | widget | non-default settings |
|---|---|---|
| 1 | `Tray` | `blacklist`=[], `drawerEnabled`=true, `pinned`=[] |
| 2 | `NotificationHistory` | `showUnreadBadge`=true, `unreadBadgeColor`="primary" |
| 3 | `plugin:ip-monitor` | — |
| 4 | `plugin:network-indicator` | — |
| 5 | `plugin:tailscale` | — |
| 6 | `Volume` | `displayMode`="onhover", `middleClickCommand`="pwvucontrol || pavucontrol" |
| 7 | `plugin:screen-recorder` | — |
| 8 | `plugin:screenshot` | — |
| 9 | `plugin:privacy-indicator` | — |
| 10 | `plugin:mini-docker` | — |
| 11 | `Battery` | `deviceNativePath`="__default__", `displayMode`="icon-always", `hideIfNotDetected`=true, `showPowerProfiles`=true |
| 12 | `Clock` | `formatHorizontal`="HH:mm ddd, MMM dd", `formatVertical`="HH mm - dd MM", `tooltipFormat`="HH:mm ddd, MMM dd" |
| 13 | `plugin:kubectl-ctx` | — |
| 14 | `plugin:github-feed` | — |
| 15 | `ControlCenter` | `icon`="noctalia" |

---
