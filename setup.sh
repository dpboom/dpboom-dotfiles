#!/bin/bash
set -e
# Portable setup for dpboom's dotfiles — rebuilds the full machine on a fresh Arch install.
# WARNING: this folder deletes itself when done. Copy anything you want to keep first.
# Installs: every package from pkglist.txt (official) + pkglist-aur.txt (AUR),
#           Ollama ('uncut' model), opencode, hyprland, kitty, yazi, zen, walls.
# Usage: ./setup.sh
#
# Prerequisites (fresh install):
#   - Arch booted with internet
#   - sudo configured for your user
#   - [multilib] repo enabled in /etc/pacman.conf (needed for steam)

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if ! command -v pacman >/dev/null; then
  echo "This script targets Arch-based systems. Exiting." >&2
  exit 1
fi

echo "==> Installing all packages from pkglist.txt ($(wc -l < "$DOTFILES/pkglist.txt") official)"
sudo pacman -S --needed --noconfirm $(cat "$DOTFILES/pkglist.txt")

echo "==> Ensuring AUR helper (yay)"
if ! command -v yay >/dev/null; then
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
  (cd /tmp/yay-bin && makepkg -si --noconfirm)
fi

echo "==> Installing AUR packages ($(wc -l < "$DOTFILES/pkglist-aur.txt"))"
yay -S --needed --noconfirm $(cat "$DOTFILES/pkglist-aur.txt")

echo "==> Copying dotfiles configs (~/.config)"
mkdir -p ~/.config/hypr ~/.config/kitty ~/.config/opencode
cp "$DOTFILES/hypr/hyprland.lua" ~/.config/hypr/
cp "$DOTFILES/kitty/kitty.conf" ~/.config/kitty/
cp "$DOTFILES/opencode/opencode.json" ~/.config/opencode/
cp "$DOTFILES/opencode/tui.json" ~/.config/opencode/
for d in "$DOTFILES"/config/*/; do
  cp -r "$d" ~/.config/
done

echo "==> Copying wallpapers"
mkdir -p ~/walls
cp "$DOTFILES"/walls/* ~/walls/ 2>/dev/null || true

echo "==> Restoring zen profile (mods + extensions)"
if [ -f "$DOTFILES/zen/zen-profile.tar.gz" ]; then
  mkdir -p ~/.config/zen
  tar -xzf "$DOTFILES/zen/zen-profile.tar.gz" -C ~/.config/zen
fi

echo "==> Starting Ollama + building local model 'uncut'"
sudo systemctl enable --now ollama
ollama pull richardyoung/qwen3-8b-abliterated:Q4_K_M
ollama create uncut -f "$DOTFILES/opencode/Modelfile.uncut"

echo "==> Importing saved sessions (run manually, interactive):"
echo "    opencode import $DOTFILES/opencode/sessions/*.json"

echo "==> Done. Reboot, then start opencode and pick 'ollama/uncut'."
echo "    Note: if your GPU isn't detected by Ollama after upgrade, sync CUDA libs:"
echo "    sudo cp -a /usr/local/lib/ollama/. /usr/lib/ollama/ && sudo systemctl restart ollama"

echo "==> Deleting setup folder ($DOTFILES)"
rm -rf /tmp/yay-bin
( sleep 3 && rm -rf "$DOTFILES" ) &
echo "    done — it will be gone in a few seconds."
