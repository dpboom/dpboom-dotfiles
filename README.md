# dpboom-dotfiles

Full machine-rebuilder for dpboom's Arch setup. Clone, run once, done.

## Layout

- **Repo root = the kit** — `setup.sh`, `pkglist.txt`, `pkglist-aur.txt`, `Modelfile.uncut`, `sessions/`, `zen-profile.tar.gz`, wallpapers. Deployed into `~/walls`.
- **`config/`** — the files you edit (hypr, kitty, opencode, btop, cava, neofetch, yay, tetris-cli). Deployed to `~/.config`.

## What it does

- Installs every package you added — official (`pkglist.txt`, 45) + AUR (`pkglist-aur.txt`, 12) via yay
- Steam, awww (wallpaper daemon), zen-browser, modrinth-app, yazi, btop, cava, neofetch, hyprland, kitty, and more
- **Ollama** + local `uncut` model (Qwen3 8B abliterated, uncensored, multilingual)
- **opencode** config + saved sessions
- **Wallpapers** + setup kit → `~/walls`
- **zen profile** with mods + extensions → `~/.config/zen`

## Usage

```bash
./setup.sh
```

`setup.sh` creates `~/walls` if missing (wipes any old content), copies the kit there, deploys configs, installs everything, then **deletes the folder it ran from**. Re-runs are safe: running `~/walls/setup.sh` skips the wipe.

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
