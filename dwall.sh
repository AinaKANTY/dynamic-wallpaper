#!/usr/bin/env bash

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

## Wordsplit in ZSH
set -o shwordsplit 2>/dev/null

## Reset terminal colors
reset_color() {
	tput sgr0   # reset attributes
	tput op     # reset color
}

## Script Termination
exit_on_signal_SIGINT() {
    printf "${RED}\n\n%s\n\n" "[!] Program Interrupted." >&2
    reset_color
    exit 130
}

exit_on_signal_SIGTERM() {
    printf "${RED}\n\n%s\n\n" "[!] Program Terminated." >&2
    reset_color
    exit 143
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM

## Usage
usage() {
	# clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}
		
		Dwall V2.0.2-pre   : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x) and forked by Aina KANTY (@AinaKANTY)
			
		Usage : $(basename "$0") [-h] [-p] [-s style]

		Options:
		   -h	Show this help message
		   -p	Use pywal to set wallpaper
		   -s	Name of the style to apply
		   
	EOF

    if [[ ! -d "$DIR" ]]; then
        printf "${RED}[!] No styles available (directory not found: %s)${WHITE}\n" "$DIR"
        return
    fi

    readarray -d "" styles < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\0" 2>/dev/null)
	
	printf "${GREEN}""Available styles: ${ORANGE}"
	printf -- "%s  " "${styles[@]}"
	printf -- "\n\n${WHITE}"

    cat <<- EOF
		Examples: 
		$(basename "$0") -s beach        Set wallpaper from 'beach' style
		$(basename "$0") -p -s sahara    Set wallpaper from 'sahara' style using pywal
		
	EOF
}

declare -A SETTER_PRIORITY=(
    # --- WAYLAND ---
    [hyprland]="swww hyprpaper swaybg wpaperd wbg"
    [sway]="swaybg swww wpaperd wbg"
    [cosmic]="cosmic-bg swww swaybg wpaperd wbg"
    [niri]="swww swaybg wpaperd wbg"
    [river]="swww swaybg wpaperd wbg"
    [labwc]="swww swaybg wpaperd wbg"
    [wayfire]="swww swaybg wpaperd wbg"
    [wayland-generic]="swaybg swww wpaperd"
    
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
    if [[ -z "$XDG_RUNTIME_DIR" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
    if [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" ]]; then
        if pgrep -x "Hyprland" >/dev/null; then
            export WAYLAND_DISPLAY="wayland-1"
        elif pgrep -x "sway" >/dev/null; then
            export WAYLAND_DISPLAY="wayland-1"
        fi
    fi
    
    if [[ "$XDG_SESSION_TYPE" == "wayland" || -n "$WAYLAND_DISPLAY" ]]; then
        if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            ENV="hyprland"
        elif [[ -n "$SWAYSOCK" ]]; then
            ENV="sway"
        elif [[ -n "$COSMIC_SESSION" ]]; then # to be checked
            ENV="cosmic"
        elif [[ -n "$NIRI_SOCKET" ]]; then
            ENV="niri"
        elif [[ -n "$WAYFIRE_SOCKET" ]]; then
            ENV="wayfire"
        elif command -v pgrep >/dev/null 2>&1; then
            if pgrep -x river >/dev/null 2>&1; then # process name to be checked
                ENV="river"
            elif pgrep -x labwc >/dev/null 2>&1; then # process name to be checked
                ENV="labwc"
            else
                ENV="wayland-generic"
            fi
        else
            ENV="wayland-generic"
        fi

    elif [[ "$XDG_SESSION_TYPE" == "x11" || -n "$DISPLAY" ]]; then
        case "$XDG_CURRENT_DESKTOP" in
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
            case "$(basename "$DESKTOP_SESSION")" in
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
        echo -e "${RED}[!] Error: Environment not supported at this time${WHITE}"; exit 1
    fi
    echo -e "${ORANGE}[*] Detected environment: ${MAGENTA}${ENV}${WHITE}"
}

## choose wallpaper setter
choose_setter() {
    for wall_setter in ${SETTER_PRIORITY[$ENV]}; do
        if command -v "$wall_setter" > /dev/null 2>&1; then
            SETTER="$wall_setter"
            return
        fi
    done
    echo -e "${RED}[!] No setters found for your environment: ${GREEN}${ENV}${WHITE}" >&2; exit 1
}

## Check valid style
check_style() {
    if [[ -d "$DIR/$1" ]]; then
        echo -e "${BLUE}[*] Using style : ${MAGENTA}$1${WHITE}"
    else
        echo -e "${RED}[!] Invalid style name : ${GREEN}$1${WHITE}" >&2
        local styles
        readarray -t styles < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" 2>/dev/null)
        echo -e "${RED}[!] Available styles are : ${ORANGE}${styles[*]}${WHITE}" >&2
        exit 1
    fi
}

## Get Image
get_img() {
    local target_hour="$1"
    local formats=("png" "jpg" "jpeg" "webp" "gif")
    
    shopt -s nullglob nocaseglob 

    for (( i=0; i<24; i++ )); do
        local h=$(( (target_hour - i + 24) % 24 ))
        
        for fmt in "${formats[@]}"; do
            local files=("$DIR/$STYLE/${h}.${fmt}")
            if [[ ${#files[@]} -gt 0 && -f "${files[0]}" ]]; then
                echo "${files[0]}"
                shopt -u nullglob nocaseglob
                return 0
            fi
        done
    done
    
    shopt -u nullglob nocaseglob
    echo -e "${RED}[!] Error: No image found for style '$STYLE' in $DIR/$STYLE/${WHITE}" >&2
    exit 1
}

## Set wallpaper KDE
set_kde() {
    local safe_img="${1//\'/\\\'}"
    
    "$SETTER" org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
            d.writeConfig('Image', 'file://${safe_img}')
        }
    " || {
        echo -e "${RED}[!] Failed to set KDE wallpaper${WHITE}" >&2; exit 1
    }
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
            set_kde "$img" 
            ;;
        xfce)
            local properties
            properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep "workspace0/last-image")
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
                swww)
                    if ! swww query >/dev/null 2>&1; then
                        swww-daemon &
                        local i=0
                        until swww query >/dev/null 2>&1 || (( i++ >= 10 )); do sleep 0.1; done
                    fi
                    swww img "$img" --transition-type simple --transition-step 90
                    ;;
                hyprpaper) 
                    if ! pgrep -x hyprpaper >/dev/null 2>&1; then
                        echo -e "${ORANGE}[*] Starting hyprpaper daemon...${WHITE}"
                        hyprpaper >/dev/null 2>&1 &
                        
                        local i=0
                        while ! hyprctl hyprpaper list >/dev/null 2>&1 && (( i++ < 20 )); do
                            sleep 0.1
                        done
                    fi
                    hyprctl hyprpaper preload "$img" >/dev/null 2>&1
                    hyprctl hyprpaper wallpaper ",$img" >/dev/null 2>&1
                    ;;
                swaybg)
                    pkill swaybg 2>/dev/null; sleep 0.1
                    swaybg -i "$img" -m fill &
                    ;; 
                wpaperd)
                    if command -v wpaperctl >/dev/null 2>&1; then
                        wpaperctl set-wallpaper "$img"
                    else
                        echo -e "${RED}[!] wpaperctl not found. Unable to change the background.${WHITE}" >&2
                    fi
                    ;;
                wbg) 
                    pkill wbg 2>/dev/null; sleep 0.1; wbg "$img" & 
                    ;;
                feh) 
                    feh --bg-fill "$img" 
                    ;;
                nitrogen) 
                    nitrogen --set-zoom-fill "$img" 
                    ;;
                hsetroot) 
                    hsetroot -fill "$img" 
                    ;;
                xwallpaper) 
                    xwallpaper --zoom "$img" 
                    ;;
                *) 
                    echo -e "${RED}[!] Unknown setter: ${SETTER}${WHITE}" >&2
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
    echo "$1" > "$cfile" || echo -e "${RED}[!] Failed to update cache${WHITE}" >&2
}

## Apply colors from image
# Priority: pywal (if -p flag) > matugen > wal
apply_colors() {
    local image="$1"

    if [[ -n "$PYWAL" ]]; then
        if command -v wal >/dev/null 2>&1; then
            wal -i "$image" -n
        else
            echo -e "${RED}[!] pywal (wal) is not installed, skipping color generation.${WHITE}" >&2
        fi
    elif command -v matugen >/dev/null 2>&1; then
        matugen image "$image"
    elif command -v wal >/dev/null 2>&1; then
        wal -i "$image" -n
    else
        echo -e "${ORANGE}[*] No color generator (matugen/pywal) found.${WHITE}"
    fi
}

## Display Info
display_info() {
    local session_name
    case "$ENV" in
        hyprland)        session_name="Hyprland" ;;
        sway)            session_name="Sway" ;;
        cosmic)          session_name="Cosmic" ;;
        niri)            session_name="Niri" ;;
        river)           session_name="River" ;;
        labwc)           session_name="Labwc" ;;
        wayfire)         session_name="Wayfire" ;;
        wayland-generic) session_name="Wayland (generic)" ;;
        *)               session_name="${XDG_CURRENT_DESKTOP:-$ENV}" ;;
    esac

    echo -e "${ORANGE}[*] Setting wallpaper in ${GREEN}${session_name}${ORANGE} session${WHITE}"
    echo -e "${ORANGE}[*] Using setter : ${MAGENTA}${SETTER}${WHITE}"
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

## Get Options
while getopts ":s:hp" opt; do
    case ${opt} in
        p) PYWAL=true ;;
        s) STYLE=$OPTARG ;;
        h) usage; exit 0 ;;
        \?) echo -e "${RED}[!] Unknown option, run ${GREEN}$(basename "$0") -h"; exit 1 ;;
        :)  echo -e "${RED}[!] Invalid: ${GREEN}-${OPTARG}${RED} requires an argument."; exit 1 ;;
        *) usage; exit 1 ;;
    esac
done

## Run
if [[ "$STYLE" ]]; then
    detect_environment
    choose_setter
    check_style "$STYLE"
    display_info
    main
else
    usage
    exit 1
fi