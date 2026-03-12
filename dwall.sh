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

## Usage
usage() {
	clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}
		
		Dwall V2.0.1-pre   : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x) and forked by Aina KANTY (@AinaKANTY)
			
		Usage : $(basename $0) [-h] [-p] [-s style]

		Options:
		   -h	Show this help message
		   -p	Use pywal to set wallpaper
		   -s	Name of the style to apply
		   
	EOF

	styles=($(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'))
	printf ${GREEN}"Available styles:  "
	printf -- ${ORANGE}'%s  ' "${styles[@]}"
	printf -- '\n\n'${WHITE}

    cat <<- EOF
		Examples: 
		$(basename $0) -s beach        Set wallpaper from 'beach' style
		$(basename $0) -p -s sahara    Set wallpaper from 'sahara' style using pywal
		
	EOF
}

## Prerequisite
Prerequisite() {
    local bin

    case "$SETTER" in
        swww)       bin="swww" ;;
        hyprpaper)  bin="hyprctl" ;;
        swaybg)     bin="swaybg" ;;
        wbg)        bin="wbg" ;;
        wpaperd)    bin="wpaperd" ;;
        gnome)      bin="gsettings" ;;
        kde)        bin="qdbus" ;;
        xfce)       bin="xfconf-query" ;;
        mate)       bin="gsettings" ;;
        cinnamon)   bin="gsettings" ;;
        lxde)       bin="pcmanfm" ;;
        feh)        bin="feh" ;;
        nitrogen)   bin="nitrogen" ;;
        xwallpaper) bin="xwallpaper" ;;
        *)
            echo -e "${RED}[!] ERROR: Unknown setter '${SETTER}'${WHITE}" >&2
            { reset_color; exit 1; }
            ;;
    esac

    type -p "$bin" &>/dev/null || {
        echo -e "${RED}[!] ERROR: Could not find ${GREEN}'${bin}'${RED}, is it installed?${WHITE}" >&2
        { reset_color; exit 1; }
    }
}

## Detect environment
detect_environmement() {
    if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            ENV="hyprland"
        elif [[ -n "$SWAYSOCK" ]]; then
            ENV="sway"
        elif [[ -n "$WAYFIRE_SOCKET" ]]; then
            ENV="wayfire"
        elif [[ -n "$NIRI_SOCKET" ]]; then
            ENV="niri"
        else
            ENV="wayland-generic"
        fi

    elif [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
        case "$XDG_CURRENT_DESKTOP" in
            GNOME|ubuntu:GNOME|Pantheon|Deepin|pop:GNOME|ZORIN|budgie-desktop)
                ENV="gnome" ;;
            KDE)
                ENV="kde" ;;
            XFCE)
                ENV="xfce" ;;
            MATE)
                ENV="mate" ;;
            X-Cinnamon)
                ENV="cinnamon" ;;
            LXDE)
                ENV="lxde" ;;
            *)
                ENV="x11-generic" ;;
        esac
    else
        echo -e "${RED}[!] Error: Environment not supported at this time${WHITE}"; exit 1
    fi

    echo -e "${ORANGE}[*] Detected environment: ${MAGENTA}${ENV}${WHITE}"
}

## Display Info
display_info() {
    local session_name
    case "$ENV" in
        hyprland)        session_name="Hyprland" ;;
        sway)            session_name="Sway" ;;
        wayfire)         session_name="Wayfire" ;;
        niri)            session_name="Niri" ;;
        wayland-generic) session_name="Wayland (generic)" ;;
        *)               session_name="${XDG_CURRENT_DESKTOP:-$ENV}" ;;
    esac

    echo -e "${ORANGE}[*] Setting wallpaper in ${GREEN}${session_name}${ORANGE} session"
    echo -e "${ORANGE}[*] Using setter : ${MAGENTA}${SETTER}${WHITE}"
}

## Get Image
get_img() {
    local search_path="$DIR/$STYLE/$1"
    local formats=("png" "jpg" "jpeg" "webp" "gif")

    for fmt in "${formats[@]}"; do
        if [[ -f "${search_path}.${fmt}" ]]; then
            image="${search_path}.${fmt}"
            FORMAT="$fmt"
            return 0
        fi
    done

    echo -e "${RED}[!] Error: No image found for '$1' in $DIR/$STYLE/${WHITE}"
    echo -e "${RED}[!] Checked formats: ${formats[*]}${WHITE}"
    { reset_color; exit 1; }
}

## Choose wallpaper setter
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
                echo "[!] No setters found for Hyprland (tried: swww, hyprpaper, swaybg)"; exit 1
            fi
            ;;
        sway)
            if command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            elif command -v swww >/dev/null 2>&1; then
                SETTER="swww"
            elif command -v wpaperd >/dev/null 2>&1; then
                SETTER="wpaperd"
            else
                echo "[!] No setters found for Sway (tried: swaybg, swww, wpaperd)"; exit 1
            fi
            ;;
        wayfire)
            if command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            elif command -v wbg >/dev/null 2>&1; then
                SETTER="wbg"
            elif command -v wpaperd >/dev/null 2>&1; then
                SETTER="wpaperd"
            else
                echo "[!] No setters found for Wayfire (tried: swaybg, wbg, wpaperd)"; exit 1
            fi
            ;;
        niri)
            if command -v swww >/dev/null 2>&1; then
                SETTER="swww"
            elif command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            elif command -v wpaperd >/dev/null 2>&1; then
                SETTER="wpaperd"
            else
                echo "[!] No setters found for Niri (tried: swww, swaybg, wpaperd)"; exit 1
            fi
            ;;
        wayland-generic)
            if command -v swww >/dev/null 2>&1; then
                SETTER="swww"
            elif command -v swaybg >/dev/null 2>&1; then
                SETTER="swaybg"
            elif command -v wpaperd >/dev/null 2>&1; then
                    SETTER="wpaperd"
            else
                echo "[!] No setters found for generic Wayland (tried: swww, swaybg, wpaperd)"; exit 1
            fi
            ;;
        gnome)      SETTER="gnome" ;;
        kde)        SETTER="kde" ;;
        xfce)       SETTER="xfce" ;;
        mate)       SETTER="mate" ;;
        cinnamon)   SETTER="cinnamon" ;;
        lxde)       SETTER="lxde" ;;
        x11-generic)
            if command -v feh >/dev/null 2>&1; then
                SETTER="feh"
            elif command -v nitrogen >/dev/null 2>&1; then
                SETTER="nitrogen"
            elif command -v xwallpaper >/dev/null 2>&1; then
                SETTER="xwallpaper"
            else
                echo "[!] No setters found for generic X11 (tried: feh, nitrogen, xwallpaper)"; exit 1
            fi
            ;;
        *)
            echo "[!] Unsupported environment: $ENV"; exit 1 ;;
    esac
}

## Apply colors from image
apply_colors() {
    local image="$1"

    if [[ -n "$PYWAL" ]]; then
        if command -v wal >/dev/null 2>&1; then
            wal -i "$image" -n
        else
            echo -e "${RED}[!] pywal (wal) is not installed, skipping color generation${WHITE}"
        fi
    elif command -v matugen >/dev/null 2>&1; then
        matugen image "$image"
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$image" -n
    fi
}

## Set wallpaper KDE
set_kde() {
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
            d.writeConfig('Image', 'file://$1')
        }
    "
}

## Update wallpaper cache
update_cache() {
    local cfile="$HOME/.cache/dwall_current"
    local cdir
    cdir="$(dirname "$cfile")"

    [[ ! -d "$cdir" ]] && mkdir -p "$cdir"
    echo "$1" > "$cfile"
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
                swww-daemon &
                sleep 0.5
            fi
            swww img "$image"
            ;;
        swaybg)
            pkill swaybg 2>/dev/null; sleep 0.1
            swaybg -i "$image" -m fill &
            ;;
        wbg)
            pkill wbg 2>/dev/null; sleep 0.1
            wbg "$image" &
            ;;
        wpaperd)
            local wpconf="$HOME/.config/wpaperd/wallpaper.toml"
            local wpdir
            wpdir="$(dirname "$wpconf")"

            [[ ! -d "$wpdir" ]] && mkdir -p "$wpdir"

            cat > "$wpconf" <<- TOML
				[[outputs]]
				name = "*"
				path = "$image"
				mode = "fill"
			TOML

            if pgrep -x wpaperd >/dev/null 2>&1; then
                killall -SIGHUP wpaperd
            else
                wpaperd &
            fi
            ;;
        gnome)
            gsettings set org.gnome.desktop.background picture-uri "file://$image"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$image"
            gsettings set org.gnome.desktop.screensaver picture-uri "file://$image"
            ;;
        kde)
            set_kde "$image"
            ;;
        xfce)
            local screen monitor
            screen="$(xrandr --listactivemonitors 2>/dev/null | awk -F ' ' 'END {print $1}' | tr -d :)"
            monitor="$(xrandr --listactivemonitors 2>/dev/null | awk -F ' ' 'END {print $2}' | tr -d '*+')"
            xfconf-query -c xfce4-desktop \
                -p "/backdrop/screen${screen:-0}/monitor${monitor:-0}/workspace0/last-image" \
                -s "$image"
            ;;
        mate)
            gsettings set org.mate.background picture-filename "$image"
            ;;
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri "file://$image"
            ;;
        lxde)
            pcmanfm --set-wallpaper "$image"
            ;;
        feh)
            feh --bg-fill "$image"
            ;;
        nitrogen)
            nitrogen --set-zoom-fill "$image"
            ;;
        xwallpaper)
            xwallpaper --zoom "$image"
            ;;
    esac

    update_cache "$image"
    apply_colors "$image"
}

## Check valid style
check_style() {
    if [[ -d "$DIR/$1" ]]; then
        echo -e "${BLUE}[*] Using style : ${MAGENTA}$1${WHITE}"
        STYLE="$1"
    else
        echo -e "${RED}[!] Invalid style name : ${GREEN}$1${WHITE}"
        echo -e "${RED}[!] Available styles are : ${ORANGE}$(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | tr '\n' ' ')${WHITE}"
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
        \?) echo -e ${RED}"[!] Unknown option, run ${GREEN}`basename $0` -h"; { reset_color; exit 1; } ;;
        :)  echo -e ${RED}"[!] Invalid: ${GREEN}-${OPTARG}${RED} requires an argument."; { reset_color; exit 1; } ;;
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