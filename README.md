# dpboom-dotfiles

Portable dotfiles + installer for dpboom's Linux setup.

## What it installs

- **Ollama** + local `uncut` model (Qwen3 8B abliterated, uncensored, multilingual)
- **opencode** config (default model + agent/model-switch keybinds)
- **hyprland** + **kitty** configs
- **steam**, **awww** (Wayland wallpaper daemon)
- **zen-browser** + **modrinth-app** (AUR)
- Your **zen profile** (mods + extensions), restored to `~/.config/zen`

## Usage

```bash
bash setup.sh
```

## Manual notes

- If your GPU isn't detected by Ollama after upgrade, sync CUDA libs:
  `sudo cp -a /usr/local/lib/ollama/. /usr/lib/ollama/ && sudo systemctl restart ollama`
- Import prior opencode sessions with:
  `opencode import opencode/sessions/*.json`
