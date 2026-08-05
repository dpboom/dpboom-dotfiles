#!/bin/bash
set -e
# dpboom's universal setup — rebuilds the full machine on any Linux distro.
# Auto-detects the package manager (pacman/apt/dnf/zypper) and the GPU vendor
# (nvidia/amd/intel) and installs the matching drivers. Works on any hardware.
#
# WARNING: this folder deletes itself when done (the ~/walls copy is kept).
# Everything lands in ~/walls except configs (-> ~/.config) and models (-> ~/models).
# Usage: ./setup.sh
#   Want the Qwen backup model too?  WITH_SWAN=1 ./setup.sh
#   (kiwi is pinned to Q4_K_S — the only quant of the abliterated build available)
#
# Prerequisites:
#   - Linux with internet, sudo configured for your user
#   - On Arch: [multilib] repo enabled in /etc/pacman.conf (for steam)

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
WALLS="$HOME/walls"
MODELS="$HOME/models"

# ---------------- detection ----------------
detect_pm() {
  if command -v pacman >/dev/null; then echo pacman
  elif command -v apt-get >/dev/null; then echo apt
  elif command -v dnf >/dev/null; then echo dnf
  elif command -v zypper >/dev/null; then echo zypper
  else echo none; fi
}
PM="$(detect_pm)"
[ "$PM" = none ] && { echo "Unsupported distro (no pacman/apt/dnf/zypper)." >&2; exit 1; }
echo "==> Package manager: $PM"

detect_gpu() {
  command -v lspci >/dev/null || return
  V="$(lspci | grep -iE 'vga|3d|display' || true)"
  case "$V" in
    *NVIDIA*) echo nvidia ;;
    *"Advanced Micro Devices"*|*AMD*|*ATI*) echo amd ;;
    *Intel*) echo intel ;;
    *) echo unknown ;;
  esac
}
GPU="$(detect_gpu)"
echo "==> GPU vendor: ${GPU:-unknown}"

install_one() {
  case "$PM" in
    pacman) sudo pacman -S --needed --noconfirm "$1" ;;
    apt)    sudo apt-get install -y "$1" ;;
    dnf)    sudo dnf install -y "$1" ;;
    zypper) sudo zypper --non-interactive install "$1" ;;
  esac
}

install_list() {
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    install_one "$p" >/dev/null 2>&1 || echo "    skipped: $p"
  done < "$1"
}

# ---------------- ~/walls: create, wipe, copy the kit ----------------
if [ "$(readlink -f "$DOTFILES")" != "$(readlink -f "$WALLS")" ]; then
  echo "==> Preparing ~/walls"
  mkdir -p "$WALLS"
  find "$WALLS" -mindepth 1 -delete
  cp -a "$DOTFILES"/. "$WALLS"/
  rm -rf "$WALLS"/config "$WALLS"/.git
fi

# ---------------- packages ----------------
echo "==> Installing packages"
case "$PM" in
  pacman) install_list "$DOTFILES/pkglist.txt" ;;
  apt)    install_list "$DOTFILES/pkglist-apt.txt" ;;
  dnf)    install_list "$DOTFILES/pkglist-dnf.txt" ;;
  zypper) echo "    no dedicated list for zypper; trying apt equivalents"
          install_list "$DOTFILES/pkglist-apt.txt" ;;
esac

# ---------------- GPU drivers ----------------
echo "==> GPU drivers ($GPU)"
case "$GPU:$PM" in
  nvidia:pacman) install_one nvidia-open; install_one libva-nvidia-driver ;;
  nvidia:apt)    install_one nvidia-driver ;;
  nvidia:dnf)    echo "    note: on Fedora use rpmfusion: sudo dnf install akmod-nvidia" ;;
  amd:pacman)    install_one vulkan-radeon; install_one libva-mesa-driver; install_one mesa ;;
  amd:apt|amd:dnf) install_one mesa-vulkan-drivers; install_one libva-mesa-driver ;;
  intel:pacman)  install_one intel-media-driver; install_one vulkan-intel ;;
  intel:apt)     install_one intel-media-va-driver; install_one libva2 ;;
  intel:dnf)     install_one intel-media-driver; install_one libva ;;
  *) echo "    no driver install (unknown/unset GPU)" ;;
esac

# ---------------- AUR (Arch only) ----------------
if [ "$PM" = pacman ]; then
  echo "==> Ensuring AUR helper (yay)"
  if ! command -v yay >/dev/null; then
    sudo pacman -S --needed --noconfirm base-devel git
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
  fi
  echo "==> Installing AUR packages ($(wc -l < "$DOTFILES/pkglist-aur.txt"))"
  yay -S --needed --noconfirm $(cat "$DOTFILES/pkglist-aur.txt")
else
  echo "==> Skipping AUR-only apps. Optional flatpaks:"
  echo "    flatpak install flathub io.github.zen_browser.zen"
  echo "    flatpak install flathub com.modrinth.ModrinthApp"
fi

# ---------------- configs ----------------
echo "==> Copying configs to ~/.config"
for d in "$DOTFILES"/config/*/; do
  case "$(basename "$d")" in zsh) continue ;; esac
  cp -a "$d" ~/.config/
done

# ---------------- zsh ----------------
echo "==> Setting up zsh"
if [ ! -d ~/.oh-my-zsh ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone -q --depth=1 https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone -q --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi
cp "$DOTFILES/config/zsh/.zshrc" ~/.zshrc
[ -x /usr/bin/zsh ] && sudo chsh -s /usr/bin/zsh "$USER" || sudo chsh -s /bin/zsh "$USER"

# ---------------- zen profile ----------------
echo "==> Restoring zen profile (mods + extensions)"
if [ -f "$DOTFILES/zen-profile.tar.gz" ]; then
  mkdir -p ~/.config/zen
  tar -xzf "$DOTFILES/zen-profile.tar.gz" -C ~/.config/zen
fi

# ---------------- Ollama + models ----------------
echo "==> Starting Ollama"
if command -v systemctl >/dev/null; then
  sudo systemctl enable --now ollama || echo "    (systemd enable failed; will run 'ollama serve' manually)"
else
  (ollama serve >/dev/null 2>&1 &) || true
fi
sleep 2

echo "==> Building model 'kiwi' (GLM-Z1-9B-0414 abliterated, Q4_K_S)"
mkdir -p "$MODELS"
GGUF="$MODELS/glm-z1-9b-0414-abliterated-q4_k_s-imat.gguf"
GGUF_URL="https://huggingface.co/irmma/GLM-Z1-9B-0414-abliterated-Q4_K_S-GGUF/resolve/main/glm-z1-9b-0414-abliterated-q4_k_s-imat.gguf"
if [ ! -s "$GGUF" ]; then
  echo "    downloading $GGUF_URL (resumable)..."
  curl -L -C - -o "$GGUF" "$GGUF_URL"
fi
# Single source of truth: the repo Modelfile.kiwi (GLM template, stops, caps).
sed "s|^FROM .*|FROM ./glm-z1-9b-0414-abliterated-q4_k_s-imat.gguf|" "$DOTFILES/Modelfile.kiwi" > "$MODELS/Modelfile.kiwi"
ollama create kiwi -f "$MODELS/Modelfile.kiwi"

if [ "${WITH_SWAN:-0}" = 1 ]; then
  echo "==> Building backup model 'swan' (Qwen3-8B abliterated)"
  ollama pull richardyoung/qwen3-8b-abliterated:Q4_K_M
  ollama create swan -f "$DOTFILES/Modelfile.swan"
fi

# ---------------- opencode ----------------
echo "==> Ensuring opencode"
if ! command -v opencode >/dev/null; then
  case "$PM" in
    pacman) install_one opencode || true ;;
    *) echo "    installing via official script..."
       curl -fsSL https://opencode.ai/install | bash || echo "    install opencode manually" ;;
  esac
fi

# ---------------- done ----------------
echo "==> Done. Reboot, then pick your local model in any app:"
echo "      kiwi  (GLM-Z1-9B-0414 abliterated)  — primary"
[ "${WITH_SWAN:-0}" = 1 ] && echo "      swan  (Qwen3-8B abliterated)   — backup"
echo "    Import saved sessions:  opencode import $DOTFILES/sessions/*.json"
echo "    If Ollama misses your GPU:  sudo cp -a /usr/local/lib/ollama/. /usr/lib/ollama/  &&  sudo systemctl restart ollama"

if [ "$(readlink -f "$DOTFILES")" != "$(readlink -f "$WALLS")" ]; then
  echo "==> Deleting setup folder ($DOTFILES)"
  rm -rf /tmp/yay-bin
  ( sleep 3 && rm -rf "$DOTFILES" ) &
  echo "    done — it will be gone in a few seconds."
fi
