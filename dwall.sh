#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x)
## Mail    : adi1090x@gmail.com
## Github  : @adi1090x
## Twitter : @adi1090x

## Dynamic Wallpaper : Set wallpapers according to current time.
## Created to work better with job schedulers

## ANSI Colors (FG & BG)
RED="$(printf '\033[31m')"        GREEN="$(printf '\033[32m')"
ORANGE="$(printf '\033[33m')"     BLUE="$(printf '\033[34m')"
MAGENTA="$(printf '\033[35m')"    CYAN="$(printf '\033[36m')"
WHITE="$(printf '\033[37m')"      BLACK="$(printf '\033[30m')"
REDBG="$(printf '\033[41m')"      GREENBG="$(printf '\033[42m')"
ORANGEBG="$(printf '\033[43m')"   BLUEBG="$(printf '\033[44m')"
MAGENTABG="$(printf '\033[45m')"  CYANBG="$(printf '\033[46m')"
WHITEBG="$(printf '\033[47m')"    BLACKBG="$(printf '\033[40m')"

## Wallpaper directory
DIR="/usr/share/dynamic-wallpaper/images"
# HOUR=`date +%k`

## Wordsplit in ZSH
set -o shwordsplit 2>/dev/null

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
    return
}

## Script Termination
exit_on_signal_SIGINT() {
    { printf "${RED}\n\n%s\n\n" "[!] Program Interrupted." 2>&1; reset_color; }
    exit 0
}

exit_on_signal_SIGTERM() {
    { printf "${RED}\n\n%s\n\n" "[!] Program Terminated." 2>&1; reset_color; }
    exit 0
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Prerequisite
Prerequisite() { 
    dependencies=($SETTER)
    for dependency in "${dependencies[@]}"; do
        type -p "$dependency" &>/dev/null || {
            echo -e ${RED}"[!] ERROR: Could not find ${GREEN}'${dependency}'${RED}, is it installed?" >&2
            { reset_color; exit 1; }
        }
    done
}

## Usage
usage() {
	clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}
		
		Dwall V3.0   : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x)
			
		Usage : `basename $0` [-h] [-p] [-s style]

		Options:
		   -h	Show this help message
		   -p	Use pywal to set wallpaper
		   -s	Name of the style to apply
		   
	EOF

	styles=(`ls "$DIR"`)
	printf ${GREEN}"Available styles:  "
	printf -- ${ORANGE}'%s  ' "${styles[@]}"
	printf -- '\n\n'${WHITE}

    cat <<- EOF
		Examples: 
		`basename $0` -s beach        Set wallpaper from 'beach' style
		`basename $0` -p -s sahara    Set wallpaper from 'sahara' style using pywal
		
	EOF
}

## Choose wallpaper setter
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

## Display Info
display_info() {
    local session_name="${XDG_CURRENT_DESKTOP:-Wayland}"
    [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && session_name="Hyprland"

    echo -e "${ORANGE}[*] Setting wallpaper in ${GREEN}${session_name}${ORANGE} session"
    echo -e "${ORANGE}[*] Using setter : ${MAGENTA}${SETTER}${WHITE}"
}

## Get Image
get_img() {
    local search_path="$DIR/$STYLE/$1"
    local found_file=$(ls ${search_path}.* 2>/dev/null | head -n 1)

    if [[ -f "$found_file" ]]; then
        image="$found_file"
    else
        echo -e "${RED}[!] Error: No image found for '$1' in $DIR/$STYLE/ (checked .png, .jpg, .webp, .gif)${WHITE}"
        exit 1
    fi
}

# TODO: mettre en valeur les messages
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
        gnome)      SETTER="gnome-settings-daemon";;
        kde)        SETTER="plasma-workspace";;
        xfce)       SETTER="xfdesktop";;
        *)          echo "[!] Unsupported environment: $ENV"; exit 1 ;;
    esac
}

apply_colors() {
    local image="$1"

    if command -v matugen >/dev/null 2>&1; then
        matugen image "$image"
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$image" -n
    fi
}

## Wallpaper Setter
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

## Check valid style
check_style() {
    if [[ -d "$DIR/$1" ]]; then
        echo -e "${BLUE}[*] Using style : ${MAGENTA}$1${WHITE}"
        STYLE="$1"
    else
        echo -e "${RED}[!] Invalid style name : ${GREEN}$1${WHITE}"
        echo -e "${RED}[!] Available styles are : ${YELLOW}$(ls -m "$DIR")${WHITE}"
        exit 1
    fi
}

## Main
main() {
    local h=$((10#$(date +%H)))
    get_img "$h"
    apply_wallpaper "$image"
    reset_color
    exit 0
}

## Get Options
while getopts ":s:hp" opt; do
    case ${opt} in
        p) PYWAL=true ;;
        s) STYLE=$OPTARG ;;
        h) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

## Run
if [[ "$STYLE" ]]; then
    detect_environmement
    choose_setter
    check_style "$STYLE"
    display_info
    Prerequisite
    main
else
    usage
    exit 1
fi