#!/usr/bin/env bash

## Author  : Aditya Shakya (adi1090x), Aina KANTY (@AinaKANTY)
## Mail    : adi1090x@gmail.com, aina.kanty9@gmail.com
## Github  : @adi1090x, @AinaKANTY
## Twitter : @adi1090x, @Aina_KANTY

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
DIR="${DWALL_DIR:-/usr/share/dynamic-wallpaper/images}"

## Default values
ENV=""
STYLE=""
PYWAL=""
RANDOM_MODE=""
SETTER=""
MONITOR=""

## Wordsplit in ZSH
set -o shwordsplit 2>/dev/null

## Strict mode
set -euo pipefail

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
}

## Script Termination
exit_on_signal_SIGINT() {
    printf "${RED}\n\n%s\n\n" "[!] Program Interrupted.\n" >&2
    reset_color
    exit 130
}

exit_on_signal_SIGTERM() {
    printf "${RED}\n\n%s\n\n" "[!] Program Terminated.\n" >&2
    reset_color
    exit 143
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## List available styles
list_styles() {
    if [[ ! -d "$DIR" ]]; then
        printf "${RED}[!] No styles available (directory not found: %s)${WHITE}\n" "$DIR" >&2
        exit 1
    fi

    local styles
    readarray -d "" styles < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\0" 2>/dev/null)

    if [[ ${#styles[@]} -eq 0 ]]; then
        printf "${RED}[!] No styles found in %s${WHITE}\n" "$DIR" >&2
        exit 1
    fi
 
    printf -- "${ORANGE}%s  " "${styles[@]}"
    printf -- "\n${WHITE}"
}

## Remove a style
remove_style() {
    local style="$1"

    if [[ ! -d "$DIR" ]]; then
        printf "${RED}[!] Wallpaper directory not found: ${GREEN}${DIR}${WHITE}\n" >&2
        exit 1
    fi

    local target
    target=$(realpath -m "$DIR/$style")
    local base
    base=$(realpath -m "$DIR")

    if [[ "$target" != "$base/"* ]]; then
        printf "${RED}[!] Invalid style path: ${GREEN}${style}${WHITE}\n" >&2
        exit 1
    fi

    if [[ ! -d "$target" ]]; then
        printf "${RED}[!] Style not found: ${GREEN}${style}${WHITE}\n" >&2
        exit 1
    fi

    printf "${ORANGE}[!] This will permanently delete: ${RED}${target}${WHITE}\n"
    read -r -p "Are you sure? [y/n] " confirm

    if [[ "${confirm,,}" != "y" ]]; then
        printf "${ORANGE}[*] Aborted.${WHITE}\n"
        exit 0
    fi

    if [[ -w "$target" ]]; then
        rm -rf "$target"
    else
        sudo rm -rf "$target"
    fi
    printf "${GREEN}[*] Style '${style}' removed successfully.${WHITE}\n"
}

## Pick a random style
random_style() {
    local styles

    readarray -d "" styles < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\0" 2>/dev/null)

    if [[ ${#styles[@]} -eq 0 ]]; then
        printf "${RED}[!] No styles found in ${DIR}${WHITE}\n" >&2
        exit 1
    fi

    STYLE="${styles[RANDOM % ${#styles[@]}]}"
    printf "${ORANGE}[*] Random style selected: ${MAGENTA}${STYLE}${WHITE}\n"
}

## Usage
usage() {
	clear

    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}

		Dwall V0.4.0 : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x) and forked by Aina KANTY (@AinaKANTY).

		Usage : $(basename "$0") [OPTION...]
		        $(basename "$0") rm <style>

		Options:
		   -h, --help	           Show this help message
		   -p, --pywal	           Use pywal to set wallpaper
		   -s, --style <style>	   Name of the style to apply
		   -S, --setter <setter>   Force a specific wallpaper setter
		   -m, --monitor <name>    Target a specific monitor (ex: DP-1, eDP-1)
		   -l, --list              List available styles
		   -r, --random            Pick a random style

		Subcommands:
		   rm <style>              Remove an installed style

	EOF

    printf "Styles:\n\t${ORANGE}"
    list_styles
}

declare -A SETTER_PRIORITY=(
    # --- WAYLAND ---
    [hyprland]="awww hyprpaper swaybg wpaperd wbg"
    [sway]="swaybg awww wpaperd wbg"
    [cosmic]="cosmic-bg awww swaybg wpaperd wbg"
    [niri]="awww swaybg wpaperd wbg"
    [river]="awww swaybg wpaperd wbg"
    [labwc]="awww swaybg wpaperd wbg"
    [wayfire]="awww swaybg wpaperd wbg"
    [wayland-generic]="swaybg awww wpaperd"

    # --- DESKTOP ENVIRONMENTS ---
    [gnome]="gsettings"
    [kde]="qdbus6 qdbus"
    [xfce]="xfconf-query"
    [budgie]="gsettings"
    [cinnamon]="gsettings"
    [deepin]="gsettings"
    [pantheon]="gsettings"
    [mate]="gsettings"
    [lxqt]="pcmanfm-qt"
    [lxde]="pcmanfm"
    [unity]="gsettings"
    [gnome-flashback]="gsettings"
    [enlightenment]="enlightenment_remote"

    # --- GENERIC X11 ---
    [x11-generic]="feh nitrogen hsetroot xwallpaper"
)

## Detect environment
detect_environment() {
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
    
    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
        local wld
        wld=$(find /run/user/"$(id -u)" -maxdepth 1 -name 'wayland-*' -not -name '*.lock' -printf "%f\n" 2>/dev/null | sort | head -n 1)
        if [[ -n "$wld" ]]; then
            export WAYLAND_DISPLAY="$wld"
        fi
    fi

    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            ENV="hyprland"
        elif [[ -n "${SWAYSOCK:-}" ]]; then
            ENV="sway"
        elif [[ -n "${COSMIC_SESSION:-}" ]]; then # TO BE CHECKED
            ENV="cosmic"
        elif [[ -n "${NIRI_SOCKET:-}" ]]; then
            ENV="niri"
        elif [[ -n "${WAYFIRE_SOCKET:-}" ]]; then
            ENV="wayfire"
        elif pgrep -x river >/dev/null 2>&1; then # TO BE CHECKED: process name
            ENV="river"
        elif pgrep -x labwc >/dev/null 2>&1; then # TO BE CHECKED: process name
            ENV="labwc"
        else
            ENV="wayland-generic"
        fi

    elif [[ "${XDG_SESSION_TYPE:-}" == "x11" || -n "${DISPLAY:-}" ]]; then
        case "${XDG_CURRENT_DESKTOP:-}" in
            *GNOME|*budgie|*Deepin|*Pantheon|*unity*)
                ENV="gnome" ;;
            *KDE|*Plasma*)
                ENV="kde" ;;
            *XFCE*)
                ENV="xfce" ;;
            MATE)
                ENV="mate" ;;
            X-Cinnamon)
                ENV="cinnamon" ;;
            LXDE)
                ENV="lxde" ;;
            ENLIGHTENMENT)
                ENV="enlightenment";;
            *)
                ENV="x11-generic" ;;
        esac

        if [[ "$ENV" == "x11-generic" ]]; then
            case "$(basename "${DESKTOP_SESSION:-}")" in
                gnome|ubuntu|budgie|deepin|pantheon|unity|gnome-flashback|pop|zorin)
                    ENV="gnome" ;;
                plasma|kde-plasma|kde)
                    ENV="kde" ;;
                xfce|xfce4)
                    ENV="xfce" ;;
                mate)
                    ENV="mate" ;;
                cinnamon)
                    ENV="cinnamon" ;;
                lxde)
                    ENV="lxde" ;;
                enlightenment)
                    ENV="enlightenment";;
                *)
                    ENV="x11-generic" ;;
            esac
        fi
    else
        printf "${RED}[!] Error: Environment not supported at this time${WHITE}\n"; exit 1
    fi
    printf "${ORANGE}[*] Detected environment: ${MAGENTA}${ENV}${WHITE}\n"
}

## Choose wallpaper setter
choose_setter() {
    if [[ -n "$SETTER" ]]; then
        if command -v "$SETTER" >/dev/null 2>&1; then
            return
        else
            printf "${RED}[!] Specified setter not found: ${GREEN}${SETTER}${WHITE}\n" >&2
            exit 1
        fi
    fi

    for wall_setter in ${SETTER_PRIORITY[$ENV]}; do
        if command -v "$wall_setter" > /dev/null 2>&1; then
            SETTER="$wall_setter"
            return
        fi
    done
    printf "${RED}[!] No setters found for your environment: ${GREEN}${ENV}${WHITE}\n" >&2; exit 1
}

## Check valid style
check_style() {
    if [[ ! -d "$DIR" ]]; then
        printf "${RED}[!] Wallpaper directory not found: ${GREEN}${DIR}${WHITE}\n" >&2
        exit 1
    fi

    if [[ -d "$DIR/$1" ]]; then
        printf "${BLUE}[*] Using style : ${MAGENTA}$1${WHITE}\n"
    else
        printf "${RED}[!] Invalid style name : ${GREEN}$1${WHITE}\n" >&2
        local styles
        readarray -t styles < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null)
        printf "${RED}[!] Available styles are : ${ORANGE}${styles[*]}${WHITE}\n" >&2
        exit 1
    fi
}

## Get Image
get_img() {
    local target_hour="$1"
    local formats=("png" "jpg" "jpeg" "webp" "gif")

    for (( i=0; i<24; i++ )); do
        local h=$(( (target_hour - i + 24) % 24 ))

        for fmt in "${formats[@]}"; do
            local img="$DIR/$STYLE/${h}.${fmt}"
            if [[ -f "$img" ]]; then
                echo "$img"
                return 0
            fi
        done
    done

    printf "${RED}[!] Error: No image found for style '$STYLE' in $DIR/$STYLE/${WHITE}\n" >&2
    exit 1
}

## Set wallpaper KDE
set_kde() {
    local safe_img="${1//\'/\\\'}"
    local target_screen="${2:-}"

    "$SETTER" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            if ('${target_screen}' !== '' && d.screen != '${target_screen}') continue;
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
            d.writeConfig('Image', 'file://${safe_img}')
        }
    " || {
        printf "${RED}[!] Failed to set KDE wallpaper${WHITE}\n" >&2; exit 1
    }
}

validate_monitor() {
    [[ -z "$MONITOR" ]] && return 0

    case "$ENV" in
        hyprland)
            if command -v jq >/dev/null 2>&1; then
                if ! hyprctl monitors -j | jq -e '.[] | select(.name == "'"$MONITOR"'")' >/dev/null 2>&1; then
                    printf "${RED}[!] Monitor '%s' not found${WHITE}\n" "$MONITOR" >&2
                    exit 1
                fi
            else
                if ! hyprctl monitors -j | grep -q "\"name\": \"$MONITOR\""; then
                    printf "${RED}[!] Monitor '%s' not found${WHITE}\n" "$MONITOR" >&2
                    exit 1
                fi
            fi
            ;;
        *)
            printf "${ORANGE}[!] Warning: --monitor not natively supported for %s, applying globally.${WHITE}\n" "$ENV" >&2
            ;;
    esac
}

## Wallpaper Setter
apply_wallpaper() {
    local img="$1"

    case "$ENV" in
        gnome)
            gsettings set org.gnome.desktop.background picture-uri "file://$img"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
            gsettings set org.gnome.desktop.screensaver picture-uri "file://$img"
            ;;
        kde)
            set_kde "$img" "$MONITOR"
            ;;
        xfce)
            local properties
            properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "workspace0/last-image" || true)
            
            if [[ -z "$properties" ]]; then
                printf "${RED}[!] xfce: no wallpaper properties found via xfconf-query${WHITE}\n" >&2
                exit 1
            fi
            
            if [[ -n "$MONITOR" ]]; then
                properties=$(echo "$properties" | grep -i "$MONITOR" || true)
                if [[ -z "$properties" ]]; then
                    printf "${RED}[!] xfce: Monitor '%s' not found in configuration.${WHITE}\n" "$MONITOR" >&2
                    exit 1
                fi
            fi
            
            for prop in $properties; do
                xfconf-query -c xfce4-desktop -p "$prop" -s "$img"
            done
            ;;
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri "file://$img"
            ;;
        mate)
            gsettings set org.mate.background picture-filename "$img"
            ;;
        lxqt)
            pcmanfm-qt -w "$img"
            ;;
        lxde)
            pcmanfm --set-wallpaper "$img"
            ;;
        enlightenment)
            enlightenment_remote -desktop-bg-add 0 0 0 0 "$img"
            ;;
        *)
            case "$SETTER" in
                awww)
                    if ! awww query >/dev/null 2>&1; then
                        awww-daemon &

                        local i=0
                        until awww query >/dev/null 2>&1; do
                            (( i++ >= 10 )) && { printf "${RED}[!] awww-daemon failed to start${WHITE}\n" >&2; exit 1; }
                            sleep 0.1
                        done
                    fi

                    if [[ -n "$MONITOR" ]]; then
                        awww img "$img" -o "$MONITOR" --transition-type simple --transition-step 90
                    else
                        awww img "$img" --transition-type simple --transition-step 90
                    fi
                    ;;
                hyprpaper)
                    if hyprctl hyprpaper preload "$img" 2>&1 | grep -q "invalid hyprpaper request"; then
                        if [[ -n "$MONITOR" ]]; then
                            if ! hyprctl hyprpaper wallpaper "$MONITOR,$img"; then
                                printf "${RED}[!] Failed to set wallpaper on %s${WHITE}\n" "$MONITOR" >&2
                                exit 1
                            fi
                        else
                            if ! hyprctl hyprpaper wallpaper ",$img"; then
                                printf "${RED}[!] Failed to set wallpaper${WHITE}\n" >&2
                                exit 1
                            fi
                        fi
                    else
                        if [[ -n "$MONITOR" ]]; then
                            if ! hyprctl hyprpaper wallpaper "$MONITOR,$img"; then
                                printf "${RED}[!] Failed to set wallpaper on %s${WHITE}\n" "$MONITOR" >&2
                                exit 1
                            fi
                        else
                            if ! hyprctl hyprpaper wallpaper ",$img"; then
                                printf "${RED}[!] Failed to set wallpaper${WHITE}\n" >&2
                                exit 1
                            fi
                        fi
                        hyprctl hyprpaper unload unused >/dev/null 2>&1 || true
                    fi
                    ;;
                swaybg)
                    if [[ "$ENV" == "sway" ]]; then
                        local target="${MONITOR:-*}"
                        swaymsg output "$target" bg "$img" fill >/dev/null 2>&1
                    else
                        pkill swaybg 2>/dev/null || true

                        local i=0
                        while pgrep -x swaybg >/dev/null 2>&1; do
                            (( i++ >= 20 )) && { printf "${RED}[!] swaybg failed to stop${WHITE}\n" >&2; exit 1; }
                            sleep 0.05
                        done

                        swaybg -i "$img" -m fill &

                        i=0
                        while ! pgrep -x swaybg >/dev/null 2>&1; do
                            (( i++ >= 20 )) && { printf "${RED}[!] swaybg failed to start${WHITE}\n" >&2; exit 1; }
                            sleep 0.05
                        done
                    fi
                    ;;
                wpaperd)
                    if command -v wpaperctl >/dev/null 2>&1; then
                        wpaperctl set-wallpaper "$img"
                    else
                        printf "${RED}[!] wpaperctl not found. Unable to change the background.${WHITE}\n" >&2
                        exit 1
                    fi
                    ;;
                wbg)
                    pkill wbg 2>/dev/null || true
                    
                    local i=0
                    while pgrep -x wbg >/dev/null 2>&1; do
                        (( i++ >= 20 )) && { printf "${RED}[!] wbg failed to stop${WHITE}\n" >&2; exit 1; }
                        sleep 0.05
                    done
                    
                    wbg "$img" &
                    
                    i=0
                    while ! pgrep -x wbg >/dev/null 2>&1; do
                        (( i++ >= 20 )) && { printf "${RED}[!] wbg failed to start${WHITE}\n" >&2; exit 1; }
                        sleep 0.05
                    done
                    ;;
                feh)
                    feh --bg-fill "$img"
                    ;;
                nitrogen)
                    if [[ -n "$MONITOR" ]]; then
                        nitrogen --set-zoom-fill "$img" --head="$MONITOR"
                    else
                        nitrogen --set-zoom-fill "$img"
                    fi
                    ;;
                hsetroot)
                    hsetroot -fill "$img"
                    ;;
                xwallpaper)
                    if [[ -n "$MONITOR" ]]; then
                        xwallpaper --output "$MONITOR" --zoom "$img"
                    else
                        xwallpaper --zoom "$img"
                    fi
                    ;;
                *)
                    printf "${RED}[!] Unknown setter: ${SETTER}${WHITE}\n" >&2
                    exit 1
                    ;;
            esac
            ;;
    esac

    update_cache "$img"
    apply_colors "$img"
}

## Update wallpaper cache
update_cache() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dwall"
    local cfile="$cache_dir/current"
    
    [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"
    echo "$1" > "$cfile" || printf "${RED}[!] Failed to update cache${WHITE}\n" >&2
}

## Apply colors from image
apply_colors() {
    local image="$1"

    if [[ -n "$PYWAL" ]]; then
        if command -v wal >/dev/null 2>&1; then
            wal -i "$image" -n
        else
            printf "${RED}[!] pywal (wal) is not installed, but -p was passed.${WHITE}\n" >&2
        fi
    elif command -v matugen >/dev/null 2>&1; then
        matugen image "$image"
    else
        printf "${ORANGE}[*] No color generator (matugen/pywal) found.${WHITE}\n"
    fi
}

## Display Info
display_info() {
    local session_name
    case "$ENV" in
        # --- WAYLAND ---
        hyprland)        session_name="Hyprland" ;;
        sway)            session_name="Sway" ;;
        cosmic)          session_name="Cosmic" ;;
        niri)            session_name="Niri" ;;
        river)           session_name="River" ;;
        labwc)           session_name="Labwc" ;;
        wayfire)         session_name="Wayfire" ;;
        wayland-generic) session_name="Wayland (generic)" ;;
        # --- DESKTOP ENVIRONMENTS ---
        gnome)           session_name="GNOME" ;;
        kde)             session_name="KDE Plasma" ;;
        xfce)            session_name="XFCE" ;;
        budgie)          session_name="Budgie" ;;
        cinnamon)        session_name="Cinnamon" ;;
        deepin)          session_name="Deepin" ;;
        pantheon)        session_name="Pantheon" ;;
        mate)            session_name="MATE" ;;
        lxqt)            session_name="LXQt" ;;
        lxde)            session_name="LXDE" ;;
        unity)           session_name="Unity" ;;
        gnome-flashback) session_name="GNOME Flashback" ;;
        enlightenment)   session_name="Enlightenment" ;;
        # --- GENERIC X11 ---
        x11-generic)     session_name="X11 (generic)" ;;
        *)               session_name="$ENV" ;;
    esac

    printf "${ORANGE}[*] Setting wallpaper in ${GREEN}${session_name}${ORANGE} session${WHITE}\n"
    printf "${ORANGE}[*] Using setter : ${MAGENTA}${SETTER}${WHITE}\n"
    if [[ -n "$MONITOR" ]]; then
        printf "${ORANGE}[*] Target Monitor : ${MAGENTA}${MONITOR}${WHITE}\n"
    fi
}

## Main
main() {
    local h=$((10#$(date +%H)))
    local current_image

    current_image=$(get_img "$h") || exit 1

    apply_wallpaper "$current_image"

    reset_color
    exit 0
}

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

## Handle subcommands
if [[ "$1" == "rm" ]]; then
    if [[ -z "${2:-}" ]]; then
        printf "${RED}[!] Usage: $(basename "$0") rm <style>${WHITE}\n" >&2
        exit 1
    fi
    remove_style "$2"
    exit 0
fi

## Get Options
parsed=$(getopt -o "hplrm:s:S:" --long "help,pywal,list,random,monitor:,style:,setter:" -n "$(basename "$0")" -- "$@") || {
    printf "${RED}[!] Run ${GREEN}$(basename "$0") --help${RED} for usage.${WHITE}\n" >&2
    exit 1
}

eval set -- "$parsed"

while true; do
    case "$1" in
        -h|--help)     usage; exit 0 ;;
        -p|--pywal)    PYWAL=true; shift ;;
        -l|--list)     list_styles; exit 0 ;;
        -r|--random)   RANDOM_MODE=true; shift ;;
        -s|--style)    STYLE="$2"; shift 2 ;;
        -S|--setter)   SETTER="$2"; shift 2 ;;
        -m|--monitor)  MONITOR="$2"; shift 2 ;;
        --) shift; break ;;
        *) break ;;
    esac
done

## Run
if [[ -n "$RANDOM_MODE" && -z "$STYLE" ]]; then
    random_style
fi

if [[ -n "$STYLE" ]]; then
    detect_environment
    choose_setter
    check_style "$STYLE"
    validate_monitor
    display_info
    main
else
    usage
    exit 1
fi