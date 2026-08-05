# dpboom-dotfiles

Full machine-rebuilder for dpboom's Arch setup. Clone on a fresh install, run once, done.

## What it does

- Installs **every package you added** — official (`pkglist.txt`, 45) + AUR (`pkglist-aur.txt`, 12) via yay
- Steam, awww (wallpaper daemon), zen-browser, modrinth-app, yazi, btop, cava, neofetch, hyprland, kitty, and more
- **Ollama** + local `uncut` model (Qwen3 8B abliterated, uncensored, multilingual)
- **opencode** config (default model + agent/model-switch keybinds) + saved sessions
- All `~/.config` dotfiles (hypr, kitty, btop, cava, neofetch, yay, tetris-cli)
- **Wallpapers** → `~/walls`
- **zen profile** with your mods + extensions → `~/.config/zen`

## Usage

```bash
./setup.sh
```

**The setup folder deletes itself when done.** Everything lands in place: configs → `~/.config`, wallpapers → `~/walls`, zen profile → `~/.config/zen`. Nothing left behind.

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
