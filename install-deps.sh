#!/usr/bin/env bash
# install-deps.sh — install system packages required by the dotfiles
# Must be run by a user with sudo privileges, once per machine.
# Usage: sudo ./install-deps.sh

set -uo pipefail

RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'; BLD='\033[1m'; RST='\033[0m'

ok()     { printf "${GRN}ok${RST}  %s\n" "$*"; }
warn()   { printf "${YLW}!!${RST}  %s\n" "$*"; }
die()    { printf "${RED}ERR${RST} %s\n" "$*" >&2; exit 1; }
header() { printf "\n${BLD}━━━ %s ━━━${RST}\n" "$*"; }

if [[ "$EUID" -ne 0 ]]; then
    die "Run as root or with sudo: sudo ./install-deps.sh"
fi

PACKAGES=(
    i3
    i3blocks
    alacritty
    rofi
    nitrogen
    tmux
    vim
    x11-xserver-utils   # xrandr
    xscreensaver
    brightnessctl
    pulseaudio-utils    # pactl
    network-manager-gnome  # nm-applet
    volumeicon-alsa
    xclip
    python3
)

header "Installing dependencies"

echo "Updating package lists..."
if ! apt-get update -qq 2>/dev/null; then
    warn "apt-get update had errors (possibly a broken third-party repo on this machine)."
    warn "Continuing anyway — core packages should still install fine."
fi

FAILED=()
for pkg in "${PACKAGES[@]}"; do
    if apt-get install -y "$pkg" >/dev/null; then
        ok "$pkg"
    else
        warn "Failed: $pkg"
        FAILED+=("$pkg")
    fi
done

header "Done"

if [[ ${#FAILED[@]} -gt 0 ]]; then
    warn "The following packages could not be installed: ${FAILED[*]}"
    warn "Check package names for your distro and install manually."
else
    ok "All packages installed — any user can now run ./setup.sh"
fi
echo ""
