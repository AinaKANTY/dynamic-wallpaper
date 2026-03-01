#!/usr/bin/env bash

## Dynamic Wallpaper : Set wallpapers according to current time.
## This script removes all files, including systemd timers and cache.

## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"        GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"     BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"    CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"      NC="$(printf '\033[0m')"

# Path
DES="/usr/share"
BIN="/usr/bin/dwall"
CACHE="$HOME/.cache/dwall_current"

## Stop and disable systemd timer
cleanup_systemd() {
    if systemctl --user list-timers | grep -q "dwall"; then
        echo -e "${ORANGE}[*] Stopping and disabling systemd timer...${NC}"
        systemctl --user disable --now dwall@*.timer 2>/dev/null
        rm -f "$HOME/.config/systemd/user/dwall@.timer"
        rm -f "$HOME/.config/systemd/user/dwall@.service"
        systemctl --user daemon-reload
    fi
}

## Delete files
rmdir_dw() {
    echo -e "${ORANGE}[*] Uninstalling Dynamic Wallpaper files...${NC}"
    
    # Remove binary link
    if [[ -L "$BIN" ]]; then
        sudo rm "$BIN"
    fi

    # Remove share directory
    if [[ -d "$DES/dynamic-wallpaper" ]]; then
        sudo rm -rf "$DES/dynamic-wallpaper"
    fi
    
    # Remove cache file
    if [[ -f "$CACHE" ]]; then
        rm "$CACHE"
    fi
}

## Final message
finish() {
    echo -e "${GREEN}[*] Uninstalled Successfully.${NC}"
}

## Uninstall execution
cleanup_systemd
rmdir_dw
finish