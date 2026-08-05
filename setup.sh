#!/bin/bash
set -e
# Portable setup for dpboom's dotfiles — run on any fresh Linux install.
# Installs: Ollama (+ 'uncut' model), opencode configs, hyprland, kitty,
#           steam, awww, zen-browser, modrinth-app, and your zen profile.
# Usage: bash setup.sh

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pacman >/dev/null; then
  echo "Warning: this script targets Arch-based systems. Distro-hop elsewhere at your own risk." >&2
fi

echo "==> Installing base packages (steam, awww)"
if command -v pacman >/dev/null; then
  sudo pacman -S --needed --noconfirm steam awww
fi

echo "==> Installing AUR packages (zen-browser, modrinth-app)"
if command -v yay >/dev/null; then
  yay -S --needed --noconfirm zen-browser-bin modrinth-app-bin
elif command -v paru >/dev/null; then
  paru -S --needed zen-browser-bin modrinth-app-bin
else
  echo "No AUR helper found. Install one (e.g. 'sudo pacman -S --needed yay-git' via pikaur/makepkg) then re-run, or install zen-browser-bin + modrinth-app-bin manually."
fi

echo "==> Installing Ollama"
curl -fsSL https://ollama.com/install.sh | sh

echo "==> Copying opencode configs"
mkdir -p ~/.config/opencode
cp "$DOTFILES/opencode/opencode.json" ~/.config/opencode/
cp "$DOTFILES/opencode/tui.json" ~/.config/opencode/

echo "==> Pulling base model + building local model 'uncut'"
ollama pull richardyoung/qwen3-8b-abliterated:Q4_K_M
ollama create uncut -f "$DOTFILES/opencode/Modelfile.uncut"

echo "==> Copying hyprland + kitty configs"
mkdir -p ~/.config/hypr ~/.config/kitty
cp "$DOTFILES/hypr/hyprland.lua" ~/.config/hypr/
cp "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/

echo "==> Restoring zen profile (mods + extensions)"
if [ -f "$DOTFILES/zen/zen-profile.tar.gz" ]; then
  mkdir -p ~/.config/zen
  tar -xzf "$DOTFILES/zen/zen-profile.tar.gz" -C ~/.config/zen
  echo "    zen profile restored into ~/.config/zen"
else
  echo "    no zen profile archive found — skipping"
fi

echo "==> Importing saved sessions (run manually, interactive):"
echo "    opencode import $DOTFILES/opencode/sessions/*.json"

echo "==> Done. Start opencode and pick 'ollama/uncut'."
echo "    Note: if your GPU isn't detected, update Ollama or re-apply the CUDA lib sync (see README)."
