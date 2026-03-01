#!/usr/bin/env bash

## Dynamic Wallpaper : Diagnostic and test script

## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"        GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"     BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"    CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"      BLACK="$(printf '\033[30m')"

## Wallpaper directory (Current directory for testing)
DIR="`pwd`/images"
HOUR=$((10#$(date +%H)))

## Wordsplit in ZSH
set -o shwordsplit 2>/dev/null

## Reset terminal colors
reset_color() {
    tput sgr0
    tput op
    return
}

## Script Termination
exit_on_signal_SIGINT() {
    { printf "${RED}\n\n%s\n\n" "[!] Test Interrupted." 2>&1; reset_color; }
    exit 0
}

trap exit_on_signal_SIGINT SIGINT

## Detect environment
detect_environmement() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            ENV="hyprland"
        elif [[ -n "$SWAYSOCK" ]]; then
            ENV="sway"
        else
            ENV="wayland-uknow"
        fi
    elif [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
        case "$XDG_CURRENT_DESKTOP" in
            GNOME)  ENV="gnome";;
            KDE)    ENV="kde";;
            XFCE)   ENV="xfce";;
            *)      ENV="x11-uknow";;
        esac
    else
        echo -e "${RED}[!] Error: Environment not supported at this time${WHITE}"; exit 1
    fi
    echo -e "${ORANGE}[*] Detected environment: ${MAGENTA}${ENV}${WHITE}"
}

## Choose setter
choose_setter() {
    case "$ENV" in
        hyprland)
            if command -v swww >/dev/null 2>&1; then
                SETTER="swww"
            elif command -v hyprpaper >/dev/null 2>&1; then
                SETTER="hyprpaper"
            elif command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            else
                echo "[!] No setters found for Hyprland"; exit 1
            fi
            ;;
        sway)
            if command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            else
                echo "[!] No setters found for sway"; exit 1
            fi
            ;;
        gnome)  SETTER="gnome";;
        kde)    SETTER="kde";;
        xfce)   SETTER="xfce";;
        *)      echo "[!] Unsupported environment: $ENV"; exit 1 ;;
    esac
    echo -e "${ORANGE}[*] Using setter: ${MAGENTA}${SETTER}${WHITE}"
}

## Prerequisite
Prerequisite() {
    dependencies=($SETTER)
    echo -e "${ORANGE}[*] Checking dependencies...${WHITE}"
    for dependency in "${dependencies[@]}"; do
        type -p "$dependency" &>/dev/null || {
            echo -e ${RED}"[!] ERROR: Could not find ${GREEN}'${dependency}'${RED}, is it installed?" >&2
            { reset_color; exit 1; }
        }
    done
    echo -e "${GREEN}[+] Dependencies found.${WHITE}"
}

## Apply colors
apply_colors() {
    local image="$1"
    if command -v matugen >/dev/null 2>&1; then
        matugen image "$image"
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$image" -n
    fi
}

## Apply wallpaper
apply_wallpaper() {
    local image="$1"
    case "$SETTER" in
        hyprpaper)
            hyprctl hyprpaper preload "$image"
            hyprctl hyprpaper wallpaper ",$image"
            ;;
        swww)
            if ! swww query >/dev/null 2>&1; then
                swww init && sleep 0.5
            fi
            swww img "$image"
            ;;
        swaybg)
            swaybg -i "$image" -m fill
            ;;
        gnome)
            gsettings set org.gnome.desktop.background picture-uri "file://$image"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$image"
            ;;
        kde)
            plasma-apply-wallpaperimage "$image"
            ;;
        xfce)
            xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$image"
            ;;
    esac
    apply_colors "$image"
}

## Usage
usage() {
    clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}

		Dwall Test Script

		Usage : `basename $0` [-h] [-s style]

		Options:
		   -h	Show this help message
		   -s	Name of the style to apply

	EOF

    if [[ -d "$DIR" ]]; then
        styles=(`ls "$DIR"`)
        printf ${GREEN}"Available styles:  "
        printf -- ${ORANGE}'%s  ' "${styles[@]}"
        printf -- '\n\n'${WHITE}
    fi
}

## Get Image
get_img() {
    local search_path="$DIR/$STYLE/$1"
    local found_file=$(ls ${search_path}.* 2>/dev/null | head -n 1)
    if [[ -f "$found_file" ]]; then
        image="$found_file"
    else
        echo -e "${RED}[!] Error: Image '$1' not found in $DIR/$STYLE/${WHITE}"
        exit 1
    fi
}

## Check valid style
check_style() {
    if [[ -d "$DIR/$1" ]]; then
        echo -e "${BLUE}[*] Testing style : ${MAGENTA}$1${WHITE}"
        STYLE="$1"
    else
        echo -e "${RED}[!] Invalid style name : ${GREEN}$1${WHITE}"
        exit 1
    fi
}

## Main
main() {
    get_img "$HOUR"
    apply_wallpaper "$image"
    echo -e "${GREEN}[V] Test completed successfully.${WHITE}"
    reset_color
    exit 0
}

## Get Options
while getopts ":s:h" opt; do
    case ${opt} in
        s) STYLE=$OPTARG ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

## Run
detect_environmement
choose_setter
Prerequisite
if [[ "$STYLE" ]]; then
    check_style "$STYLE"
    main
else
    usage
    exit 1
fi