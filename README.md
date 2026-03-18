# Earl Grey - Solarized Light i3 themed config dotfiles

A portable i3 desktop configuration for Linux. Drop it on any machine, run one script, and you're done.

---

## What's included

| Component | Purpose |
|-----------|---------|
| **i3** | Window manager |
| **i3blocks** | Status bar (battery, date, clock) |
| **Alacritty** | Terminal emulator |
| **tmux** | Terminal multiplexer |
| **Vim** | Editor (Solarized Light theme) |
| **Rofi** | Application launcher (Arc-Dark theme) |
| **Nitrogen** | Wallpaper manager |

All components share a **Solarized Light** color palette for visual consistency.

---

## Requirements

```
i3  i3blocks  alacritty  rofi  nitrogen  tmux  vim
xrandr  xscreensaver  brightnessctl  pactl
nm-applet  volumeicon  xclip  python3
```

---

## Install

Two steps — the first needs sudo (run once per machine by an admin), the second does not.

**Step 1 — get the repo onto the machine**

If the target user has git access, they can clone it themselves:
```bash
git clone https://github.com/yourname/dotfiles ~/dotfiles
```

If an admin is copying it on their behalf (e.g. the user has no sudo), make sure to fix ownership after copying or the user won't be able to run the script:
```bash
sudo cp -r /path/to/dotfiles /home/targetuser/dotfiles
sudo chown -R targetuser:targetuser /home/targetuser/dotfiles
```

**Step 2 — install packages (requires sudo, once per machine):**
```bash
sudo ./install-deps.sh
```

**Step 3 — deploy configs (any user, no sudo needed):**
```bash
./setup.sh
```

To preview what `setup.sh` will do without touching anything:
```bash
./setup.sh --dry-run
```

---

## What the installer does

### 1. Dependency check
Scans for all required binaries. If anything is missing it exits immediately and tells you to run `install-deps.sh` — it will never attempt a `sudo` itself.

### 2. Display wizard
Reads your connected outputs via `xrandr` and walks you through:

- Choosing your **primary display**
- Selecting its **resolution** (from detected modes)
- Selecting its **refresh rate**
- Optionally enabling a **secondary display** with the same choices
- If dual: setting the **position** of the secondary relative to the primary (left-of / right-of / above / below)

The i3 config is then automatically patched with the correct output names and `xrandr` command for your hardware. No manual editing.

### 3. Config deployment

Each config is copied to its standard location:

| Source | Destination |
|--------|-------------|
| `alacritty/alacritty.yml` | `~/.config/alacritty/alacritty.yml` |
| `vim/.vimrc` | `~/.vimrc` |
| `vim/colors/` | `~/.vim/colors/` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `i3/config` | `~/.config/i3/config` |
| `i3blocks/config` | `~/.config/i3blocks/config` |
| `rofi/config.rasi` | `~/.config/rofi/config.rasi` |
| `rofi/themes/Arc-Dark.rasi` | `~/.config/rofi/themes/Arc-Dark.rasi` |
| `nitrogen/bg-saved.cfg` | `~/.config/nitrogen/bg-saved.cfg` |
| `nitrogen/nitrogen.cfg` | `~/.config/nitrogen/nitrogen.cfg` |

Nitrogen paths are automatically rewritten to your current home directory.

---

## Key bindings

### i3

| Key | Action |
|-----|--------|
| `Mod + Return` | Open terminal (alacritty + tmux) |
| `Mod + d` | Launch Rofi |
| `Mod + h/j/k/l` | Focus window (vim-style) |
| `Mod + Shift + h/j/k/l` | Move window |
| `Mod + b / v` | Split horizontal / vertical |
| `Mod + f` | Fullscreen toggle |
| `Mod + g / Shift+g` | Increase / decrease inner gaps |
| `Mod + m` | Toggle status bar |
| `Mod + Shift + q` | Kill window |
| `Mod + Shift + r` | Reload i3 |
| `Mod + Shift + c` | Restart i3 |
| `Mod + Shift + e` | Logout |
| `Mod + Up/Down/Left/Right` | Lock screen (xscreensaver) |
| `Mod + p` | Open PDF viewer |
| `Ctrl + Alt + c` | Clean-text utility |
| `XF86AudioRaise/Lower/Mute` | Volume |
| `XF86Brightness Up/Down` | Brightness |

### tmux (prefix: `Ctrl-A`)

| Key | Action |
|-----|--------|
| `prefix + \|` | Split horizontal |
| `prefix + -` | Split vertical |
| `prefix + h/j/k/l` | Navigate panes |
| `prefix + n / p` | Next / previous window |
| `prefix + Tab` | Last pane |
| `prefix + r` | Reload config |
| `Alt + arrows` | Resize pane |
| `v` (copy mode) | Begin selection |
| `y / Enter` (copy mode) | Copy to system clipboard |
| `Ctrl + p` | Paste from system clipboard |

---

## Status bar

The i3blocks bar sits at the bottom and shows:

- Battery percentage
- Full date (`Tuesday, March 10`)
- Time (`14:35`)

---

## After install

1. **Log out** and select i3 from your display manager, or run `i3` from a TTY.
2. **Reload** an existing i3 session with `Mod + Shift + r`.
3. **Set a wallpaper** by opening Nitrogen (`nitrogen`) and pointing it at your pictures folder, or restoring the last saved one: `nitrogen --restore`.

---

## Repository layout

```
dotfiles/
├── alacritty/
│   └── alacritty.yml         # Terminal colors, font, opacity
├── vim/
│   ├── .vimrc                # Vim settings + Solarized Light
│   └── colors/
│       └── solarized.vim
├── tmux/
│   └── .tmux.conf            # tmux bindings, theme, clipboard
├── i3/
│   └── config                # Full i3 config (gaps, bindings, bar)
├── i3blocks/
│   └── config                # Battery, calendar, clock blocks
├── nitrogen/
│   ├── bg-saved.cfg          # Last-used wallpaper (paths rewritten on install)
│   └── nitrogen.cfg          # Nitrogen UI settings
├── rofi/
│   ├── config.rasi           # Launcher settings
│   └── themes/
│       └── Arc-Dark.rasi     # Dark launcher theme
├── install-deps.sh           # Package installer (needs sudo, run once per machine)
├── setup.sh                  # Dotfiles deployer (any user, no sudo)
└── README.md
```
