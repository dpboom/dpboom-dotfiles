# dpboom-dotfiles

Full machine-rebuilder for dpboom's Arch setup. Clone on a fresh install, run once, done.

## What it does

- Installs **every package** — official (`pkglist.txt`, 60) + AUR (`pkglist-aur.txt`, 12) via yay
- Steam, awww (wallpaper daemon), zen-browser, modrinth-app, yazi, btop, cava, neofetch, nnn, hyprland, kitty, and more
- **Ollama** + local `uncut` model (Qwen3 8B abliterated, uncensored, multilingual)
- **opencode** config (default model + agent/model-switch keybinds) + saved sessions
- All `~/.config` dotfiles (hypr, kitty, btop, cava, neofetch, nnn, yay, tetris-cli)
- **Wallpapers** → `~/walls`
- **zen profile** with your mods + extensions → `~/.config/zen`

## Usage

```bash
bash setup.sh
```

## Prerequisites

- Arch booted with internet, `sudo` configured
- `[multilib]` enabled in `/etc/pacman.conf` (steam needs it)

## Manual notes

- GPU not detected by Ollama after upgrade? Sync CUDA libs:
  `sudo cp -a /usr/local/lib/ollama/. /usr/lib/ollama/ && sudo systemctl restart ollama`
- Import prior opencode sessions:
  `opencode import opencode/sessions/*.json`
- Refresh the package lists for future hops:
  `comm -23 <(pacman -Qqe | sort) <(pacman -Qqm | sort) > pkglist.txt && pacman -Qqm | grep -v -- "-debug$" | sort > pkglist-aur.txt`
