#!/usr/bin/env bash
set -euo pipefail

# Arch Linux installer for this dotfiles repo.
# - Installs required packages (pacman + AUR)
# - Copies configs and system files from ./Dots
# - Copies wallpapers if present
# - Applies NVIDIA + Niri tuning (mkinitcpio/modprobe/grub)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="$REPO_DIR/Dots"

if [[ ! -d "$DOTS_DIR" ]]; then
  echo "Error: Dots directory not found at: $DOTS_DIR"
  exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
  echo "Error: This script is only for Arch Linux."
  exit 1
fi

if [[ "$EUID" -eq 0 ]]; then
  echo "Run this script as regular user, not as root."
  exit 1
fi

PACMAN_PACKAGES=(
  niri
  egl-wayland
  rofi
  yazi
  nautilus
  zoxide
  fzf
  swaybg
  swayidle
  waybar
  xdg-desktop-portal
  xdg-desktop-portal-gnome
  power-profiles-daemon
  bluez
  bluez-utils
  blueman
  swaync
  hyprlock
  brightnessctl
  cliphist
  polkit-gnome
  zsh
  eza
  exiftool
  grim
  imagemagick
  wl-clipboard
  discord
  loupe
  evince
  7zip
  nvidia-open
  nvidia-utils
  libva-nvidia-driver
  mesa
  pipewire
  pipewire-audio
  pipewire-alsa
  pipewire-pulse
  wireplumber
  pavucontrol
  gpart
  dosfstools
  exfatprogs
  ntfs-3g
  cups
  hplip
  xdg-user-dirs
  fastfetch
  nerd-fonts
  git
  base-devel
  rsync
)

OPTIONAL_PACMAN_PACKAGES=(
  lib32-nvidia-utils
)

AUR_PACKAGES=(
  iwgtk
  nwg-look
  nwg-displays
  ttf-ms-fonts
  ly
  quickshell
  file-roller
)

log() {
  printf "\n==> %s\n" "$1"
}

install_yay_if_missing() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  log "yay not found, installing yay"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT

  git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
  (
    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
  )
}

resolve_exfat_conflict() {
  # exfatprogs and exfat-utils conflict; we install exfatprogs — remove the other first.
  if pacman -Q exfat-utils &>/dev/null; then
    log "Removing exfat-utils (conflicts with exfatprogs)"
    sudo pacman -Rns --noconfirm exfat-utils
  fi
}

install_packages() {
  resolve_exfat_conflict
  log "Installing official packages via pacman"
  sudo pacman -Syu --noconfirm --needed "${PACMAN_PACKAGES[@]}"

  for pkg in "${OPTIONAL_PACMAN_PACKAGES[@]}"; do
    if ! sudo pacman -S --noconfirm --needed "$pkg"; then
      echo "Warning: optional package '$pkg' was skipped (likely disabled multilib)."
    fi
  done

  install_yay_if_missing

  log "Installing AUR packages via yay"
  yay -S --noconfirm --needed "${AUR_PACKAGES[@]}"
}

copy_user_configs() {
  log "Copying user configs to \$HOME"
  mkdir -p "$HOME/.config"

  if [[ -d "$DOTS_DIR/.config" ]]; then
    rsync -a "$DOTS_DIR/.config/" "$HOME/.config/"
  fi

  # Copy any Pictures assets from repo (including wallpapers).
  if [[ -d "$DOTS_DIR/Pictures" ]]; then
    mkdir -p "$HOME/Pictures"
    rsync -a "$DOTS_DIR/Pictures/" "$HOME/Pictures/"
  fi
}

copy_system_files() {
  log "Copying system files (/etc, /usr/share/themes)"

  if [[ -d "$DOTS_DIR/etc" ]]; then
    sudo rsync -a "$DOTS_DIR/etc/" "/etc/"
  fi

  if [[ -d "$DOTS_DIR/usr/share/themes" ]]; then
    sudo mkdir -p /usr/share/themes
    sudo rsync -a "$DOTS_DIR/usr/share/themes/" "/usr/share/themes/"
  fi
}

set_permissions() {
  log "Setting executable permissions for helper scripts"

  if [[ -d "$HOME/.config/hypr/scripts" ]]; then
    chmod +x "$HOME/.config/hypr/scripts/"*.sh || true
  fi

  if [[ -d "$HOME/.config/niri/scripts" ]]; then
    chmod +x "$HOME/.config/niri/scripts/"*.sh || true
  fi
}

configure_nvidia() {
  log "Configuring NVIDIA for Niri (modprobe + mkinitcpio + grub)"

  sudo install -d /etc/modprobe.d
  echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

  if [[ -f /etc/mkinitcpio.conf ]]; then
    if rg -n '^MODULES=' /etc/mkinitcpio.conf >/dev/null; then
      sudo sed -i 's/^MODULES=.*/MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
    else
      echo 'MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)' | sudo tee -a /etc/mkinitcpio.conf >/dev/null
    fi
    sudo mkinitcpio -P
  fi

  if [[ -f /etc/default/grub ]]; then
    if ! rg -n 'nvidia-drm\.modeset=1' /etc/default/grub >/dev/null; then
      sudo sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
    fi
    if command -v grub-mkconfig >/dev/null 2>&1; then
      sudo grub-mkconfig -o /boot/grub/grub.cfg
    fi
  fi
}

configure_user_session() {
  log "Configuring user session defaults"
  xdg-user-dirs-update || true
}

configure_hiddify_if_present() {
  if [[ -f /usr/lib/hiddify/HiddifyCli ]]; then
    log "Applying capabilities for HiddifyCli"
    sudo setcap 'cap_net_admin,cap_net_bind_service,cap_net_raw=+eip' /usr/lib/hiddify/HiddifyCli || true
  fi
}

enable_services() {
  log "Enabling recommended system services"
  sudo systemctl enable --now bluetooth.service || true
  sudo systemctl enable --now power-profiles-daemon.service || true
  sudo systemctl enable --now cups.service || true
  sudo systemctl enable --now ly.service || true

  # PipeWire stack.
  sudo systemctl enable --now pipewire-pulse.socket wireplumber.service || true
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service || true
  systemctl --user enable --now pipewire.service || true
}

print_done() {
  cat <<'EOF'

Done.

Recommended next steps:
1) Log out and choose Niri in your display manager.
2) Ensure wallpapers exist in:
   ~/Pictures/Wallpapers
3) Reboot to apply NVIDIA initramfs + kernel params.
4) For printing setup:
   hp-setup -i
5) Firefox caret blinking fix:
   set accessibility.browsewithcaret_shortcut.enabled=false
   set accessibility.browsewithcaret=false in about:config
EOF
}

main() {
  install_packages
  copy_user_configs
  copy_system_files
  set_permissions
  configure_nvidia
  configure_user_session
  configure_hiddify_if_present
  enable_services
  print_done
}

main "$@"
