#!/usr/bin/env bash

set -euo pipefail

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
RESET="$(printf '\033[0m')"

## Wallpaper directory
DIR="${DWALL_DIR:-/usr/share/dynamic-wallpaper/images}"

declare -A CTX=(
    [env]=""
    [style]=""
    [setter]=""
    [monitor]=""
    [pywal]=""
    [random_mode]=""
)



## ---------------------------------------------------------------------------
## Terminal / Signal helpers
## ---------------------------------------------------------------------------

reset_color() {
    if [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" ]]; then
        printf "%s" "$RESET"
    fi
}

cleanup_lock() {
    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-$(id -u).lock"
    [[ -f "$lock_file" ]] && rm -f "$lock_file"
}

exit_on_signal_SIGINT() {
    printf "${RED}\n\n%s\n\n" "[!] Program Interrupted.\n" >&2
    reset_color
    cleanup_lock
    exit 130
}

exit_on_signal_SIGTERM() {
    printf "${RED}\n\n%s\n\n" "[!] Program Terminated.\n" >&2
    reset_color
    cleanup_lock
    exit 143
}

trap exit_on_signal_SIGINT SIGINT
trap exit_on_signal_SIGTERM SIGTERM
trap cleanup_lock EXIT

## ---------------------------------------------------------------------------
## Style management
## ---------------------------------------------------------------------------

get_styles() {
    local -n _styles_ref="$1"
    if [[ ! -d "$DIR" ]]; then
        printf "${RED}[!] Wallpaper directory not found: %s${WHITE}\n" "$DIR" >&2
        exit 1
    fi
    readarray -d "" _styles_ref < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\0" 2>/dev/null)
    if [[ ${#_styles_ref[@]} -eq 0 ]]; then
        printf "${RED}[!] No styles found in %s${WHITE}\n" "$DIR" >&2
        exit 1
    fi
}

list_styles() {
    local styles
    get_styles styles
    printf -- "${ORANGE}%s  " "${styles[@]}"
    printf -- "\n${WHITE}"
}

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

    if [[ ! -t 0 ]]; then
        printf "${RED}[!] remove_style requires an interactive terminal (stdin is not a tty).${WHITE}\n" >&2
        exit 1
    fi

    read -r -p "Are you sure? [y/n] " confirm

    if [[ "${confirm,,}" != "y" ]]; then
        printf "${ORANGE}[*] Aborted.${WHITE}\n"
        exit 0
    fi

    if [[ -w "$target" ]]; then
        rm -rf "$target"
        printf "${GREEN}[*] Style '${style}' removed successfully.${WHITE}\n"
    else
        printf "${ORANGE}[!] Directory requires elevated privileges to delete.${WHITE}\n"
        printf "${ORANGE}[!] Please run: sudo %s rm %s${WHITE}\n" "$0" "$style"
        exit 1
    fi
}

random_style() {
    local styles
    get_styles styles
    CTX[style]="${styles[RANDOM % ${#styles[@]}]}"
    printf "${ORANGE}[*] Random style selected: ${MAGENTA}${CTX[style]}${WHITE}\n"
}

check_style() {
    local style="$1"
    if [[ -d "$DIR/$style" ]]; then
        printf "${BLUE}[*] Using style : ${MAGENTA}${style}${WHITE}\n"
    else
        printf "${RED}[!] Invalid style name : ${GREEN}${style}${WHITE}\n" >&2
        local styles
        get_styles styles
        printf "${RED}[!] Available styles are : ${ORANGE}${styles[*]}${WHITE}\n" >&2
        exit 1
    fi
}

## ---------------------------------------------------------------------------
## Usage
## ---------------------------------------------------------------------------

usage() {
    clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}

		Dwall V0.4.2 : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x) and forked by Aina KANTY (@AinaKANTY).

		Usage : $(basename "$0") [OPTION...]
		        $(basename "$0") rm <style>

		Options:
		   -h, --help	           Show this help message
		   -p, --pywal	           Use pywal to set wallpaper
		   -s, --style <style>	   Name of the style to apply
		   -S, --setter <setter>   Force a specific wallpaper setter
		   -m, --monitor <n>    Target a specific monitor (ex: DP-1, eDP-1)
		   -l, --list              List available styles
		   -r, --random            Pick a random style

		Subcommands:
		   rm <style>              Remove an installed style

	EOF

    printf "Styles:\n\t${ORANGE}"
    list_styles
}

## ---------------------------------------------------------------------------
## Environment detection
## ---------------------------------------------------------------------------

declare -A SETTER_PRIORITY=(
    # --- WAYLAND ---
    [hyprland]="hyprpaper awww swaybg wbg"
    [sway]="swaybg awww wbg"
    [cosmic]="awww swaybg wbg"
    [niri]="awww swaybg wbg"
    [river]="awww swaybg wbg"
    [labwc]="awww swaybg wbg"
    [wayfire]="awww swaybg wbg"
    [wayland-generic]="swaybg awww"

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

detect_environment() {
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
        for sock in "wayland-0" "wayland-1"; do
            if [[ -S "${XDG_RUNTIME_DIR}/$sock" ]]; then
                export WAYLAND_DISPLAY="$sock"
                break
            fi
        done
        
        if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
            local wld
            wld=$(find /run/user/"$(id -u)" -maxdepth 1 -name 'wayland-[0-9]*' -not -name '*.lock' -printf "%T@ %f\n" 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2 || true)
            if [[ -n "$wld" ]]; then
                export WAYLAND_DISPLAY="$wld"
            fi
        fi
    fi

    local env=""

    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            env="hyprland"
        elif [[ -n "${SWAYSOCK:-}" ]]; then
            env="sway"
        elif [[ -n "${COSMIC_SESSION:-}" ]]; then
            env="cosmic"
        elif [[ -n "${NIRI_SOCKET:-}" ]]; then
            env="niri"
        elif [[ -n "${WAYFIRE_SOCKET:-}" ]]; then
            env="wayfire"
        elif pgrep -x river >/dev/null 2>&1; then
            env="river"
        elif pgrep -x labwc >/dev/null 2>&1; then
            env="labwc"
        else
            env="wayland-generic"
        fi

    elif [[ "${XDG_SESSION_TYPE:-}" == "x11" || -n "${DISPLAY:-}" ]]; then
        case "${XDG_CURRENT_DESKTOP:-}" in
            *GNOME|*budgie|*Deepin|*Pantheon|*unity*)
                env="gnome" ;;
            *KDE|*Plasma*)
                env="kde" ;;
            *XFCE*)
                env="xfce" ;;
            MATE)
                env="mate" ;;
            X-Cinnamon)
                env="cinnamon" ;;
            LXDE)
                env="lxde" ;;
            ENLIGHTENMENT)
                env="enlightenment";;
            *)
                env="x11-generic" ;;
        esac

        if [[ "$env" == "x11-generic" ]]; then
            case "$(basename "${DESKTOP_SESSION:-}")" in
                gnome|ubuntu|budgie|deepin|pantheon|unity|gnome-flashback|pop|zorin)
                    env="gnome" ;;
                plasma|kde-plasma|kde)
                    env="kde" ;;
                xfce|xfce4)
                    env="xfce" ;;
                mate)
                    env="mate" ;;
                cinnamon)
                    env="cinnamon" ;;
                lxde)
                    env="lxde" ;;
                enlightenment)
                    env="enlightenment";;
                *)
                    env="x11-generic" ;;
            esac
        fi
    else
        env="unknown"
        printf "${ORANGE}[!] Warning: Environment not recognized. You may need to use --setter (-S)${WHITE}\n" >&2
    fi

    CTX[env]="$env"
    printf "${ORANGE}[*] Detected environment: ${MAGENTA}${CTX[env]}${WHITE}\n"
}

choose_setter() {
    if [[ -n "${CTX[setter]}" ]]; then
        if command -v "${CTX[setter]}" >/dev/null 2>&1; then
            return
        else
            printf "${RED}[!] Specified setter not found: ${GREEN}${CTX[setter]}${WHITE}\n" >&2
            exit 1
        fi
    fi

    if [[ -z "${CTX[env]}" ]]; then
        printf "${RED}[!] Internal error: environment not detected before choose_setter()${WHITE}\n" >&2
        exit 1
    fi

    local wall_setter
    for wall_setter in ${SETTER_PRIORITY[${CTX[env]}]:-}; do
        if command -v "$wall_setter" >/dev/null 2>&1; then
            CTX[setter]="$wall_setter"
            return
        fi
    done
    printf "${RED}[!] No setters found for your environment: ${GREEN}${CTX[env]}${WHITE}\n" >&2
    exit 1
}

## ---------------------------------------------------------------------------
## Monitor validation
## ---------------------------------------------------------------------------

validate_monitor() {
    [[ -z "${CTX[monitor]}" ]] && return 0

    case "${CTX[env]}" in
        hyprland)
            if command -v jq >/dev/null 2>&1; then
                if ! hyprctl monitors -j | jq -e --arg m "${CTX[monitor]}" '.[] | select(.name == $m)' >/dev/null 2>&1; then
                    printf "${RED}[!] Monitor '%s' not found${WHITE}\n" "${CTX[monitor]}" >&2
                    exit 1
                fi
            else
                if ! hyprctl monitors -j | grep -Eq "\"name\":[[:space:]]*\"${CTX[monitor]}\""; then
                    printf "${RED}[!] Monitor '%s' not found${WHITE}\n" "${CTX[monitor]}" >&2
                    exit 1
                fi
            fi
            ;;
        kde)
            local kde_screens
            if command -v jq >/dev/null 2>&1; then
                readarray -t kde_screens < <(
                    "${CTX[setter]}" org.kde.plasmashell /PlasmaShell \
                        org.kde.PlasmaShell.evaluateScript \
                        "print(JSON.stringify(desktops().map(function(d){return d.screen;})))" \
                        2>/dev/null | jq -r '.[]' 2>/dev/null || true
                )
            fi
            if [[ ${#kde_screens[@]} -gt 0 ]]; then
                local found=0
                local s
                for s in "${kde_screens[@]}"; do
                    [[ "$s" == "${CTX[monitor]}" ]] && { found=1; break; }
                done
                if [[ $found -eq 0 ]]; then
                    printf "${RED}[!] Monitor '%s' not found in KDE desktops${WHITE}\n" "${CTX[monitor]}" >&2
                    exit 1
                fi
            else
                printf "${ORANGE}[!] Warning: could not verify monitor '%s' for KDE, proceeding.${WHITE}\n" "${CTX[monitor]}" >&2
            fi
            ;;
        xfce)
            local xfce_props
            if xfce_props=$(xfconf-query -c xfce4-desktop -l 2>/dev/null); then
                if ! printf '%s\n' "$xfce_props" | grep -qi "${CTX[monitor]}"; then
                    printf "${RED}[!] Monitor '%s' not found in XFCE configuration.${WHITE}\n" "${CTX[monitor]}" >&2
                    exit 1
                fi
            else
                printf "${ORANGE}[!] Warning: could not verify monitor '%s' for XFCE, proceeding.${WHITE}\n" "${CTX[monitor]}" >&2
            fi
            ;;
        *)
            printf "${ORANGE}[!] Warning: --monitor not natively supported for %s, applying globally.${WHITE}\n" "${CTX[env]}" >&2
            ;;
    esac
}

## ---------------------------------------------------------------------------
## Image resolution
## ---------------------------------------------------------------------------

get_img() {
    local target_hour="$1"
    local formats=("png" "jpg" "jpeg" "webp" "gif")
    local h i

    if ! find "$DIR/${CTX[style]}" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        printf "${RED}[!] Error: Style directory '%s' is empty or missing.${WHITE}\n" "${CTX[style]}" >&2
        exit 1
    fi

    for (( i=0; i<24; i++ )); do
        h=$(( (target_hour - i + 24) % 24 ))

        for fmt in "${formats[@]}"; do
            local img="$DIR/${CTX[style]}/${h}.${fmt}"
            if [[ -f "$img" ]]; then
                printf '%s\n' "$img"
                return 0
            fi
        done
    done

    printf "${RED}[!] Error: No image found for style '%s' in %s/%s/${WHITE}\n" \
        "${CTX[style]}" "$DIR" "${CTX[style]}" >&2
    exit 1
}

## ---------------------------------------------------------------------------
## Setter implementations
## ---------------------------------------------------------------------------

_setter_gsettings() {
    local img="$1"
    local schema

    case "${CTX[env]}" in
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri "file://$img"
            gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$img"
            ;;
        mate)
            gsettings set org.mate.background picture-filename "$img"
            ;;
        *)
            ## gnome, budgie, deepin, pantheon, unity, gnome-flashback
            gsettings set org.gnome.desktop.background picture-uri "file://$img"
            gsettings set org.gnome.desktop.background picture-uri-dark "file://$img"
            gsettings set org.gnome.desktop.screensaver picture-uri "file://$img"
            ;;
    esac
}

_setter_qdbus() {
    local img="$1"
    local monitor="${CTX[monitor]:-}"

    DWALL_KDE_IMG="$img" DWALL_KDE_MONITOR="$monitor" \
        "${CTX[setter]}" org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.evaluateScript "
        var imgPath = env('DWALL_KDE_IMG');
        var targetMonitor = env('DWALL_KDE_MONITOR');
        var allDesktops = desktops();
        for (var i = 0; i < allDesktops.length; i++) {
            var d = allDesktops[i];
            if (targetMonitor !== '' && d.screen != targetMonitor) continue;
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
            d.writeConfig('Image', 'file://' + imgPath)
        }
    " || {
        printf "${RED}[!] Failed to set KDE wallpaper${WHITE}\n" >&2
        exit 1
    }
}

_setter_xfconf_query() {
    local img="$1"
    local properties

    if ! properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null); then
        printf "${RED}[!] xfce: xfconf-query failed (is XFCE running?)${WHITE}\n" >&2
        exit 1
    fi
    properties=$(printf '%s\n' "$properties" | grep "workspace0/last-image" || true)

    if [[ -z "$properties" ]]; then
        printf "${RED}[!] xfce: no wallpaper properties found via xfconf-query${WHITE}\n" >&2
        exit 1
    fi

    if [[ -n "${CTX[monitor]}" ]]; then
        properties=$(printf '%s\n' "$properties" | grep -i "${CTX[monitor]}" || true)
        if [[ -z "$properties" ]]; then
            printf "${RED}[!] xfce: Monitor '%s' not found in configuration.${WHITE}\n" "${CTX[monitor]}" >&2
            exit 1
        fi
    fi

    local prop_list
    readarray -t prop_list <<< "$properties"
    local prop
    for prop in "${prop_list[@]}"; do
        [[ -z "$prop" ]] && continue
        xfconf-query -c xfce4-desktop -p "$prop" -s "$img"
    done
}

_setter_awww() {
    local img="$1"

    if ! awww query >/dev/null 2>&1; then
        awww-daemon 2>/tmp/dwall-awww-daemon.log >/dev/null & disown

        local i=0
        until awww query >/dev/null 2>&1; do
            if (( i >= 10 )); then
                printf "${RED}[!] awww-daemon failed to start${WHITE}\n" >&2
                exit 1
            fi
            (( i++ )) || true
            sleep 0.1
        done
    fi

    if [[ -n "${CTX[monitor]}" ]]; then
        awww img -o "${CTX[monitor]}" "$img" --transition-type simple --transition-step 90
    else
        awww img "$img" --transition-type simple --transition-step 90
    fi
}

_setter_hyprpaper() {
    local img="$1"

    if [[ -n "${CTX[monitor]:-}" ]]; then
        if ! hyprctl hyprpaper wallpaper "${CTX[monitor]},${img}"; then
            printf "${RED}[!] Failed to set wallpaper on ${CTX[monitor]}${WHITE}\n" >&2
            exit 1
        fi
    else
        local monitors
        if command -v jq >/dev/null 2>&1; then
            readarray -t monitors < <(hyprctl monitors -j | jq -r '.[].name' 2>/dev/null)
        else
            readarray -t monitors < <(hyprctl monitors | awk '/^Monitor/ {print $2}')
        fi

        if [[ ${#monitors[@]} -eq 0 ]]; then
            printf "${RED}[!] No monitors detected by hyprctl${WHITE}\n" >&2
            exit 1
        fi

        for mon in "${monitors[@]}"; do
            [[ -z "$mon" ]] && continue
            if ! hyprctl hyprpaper wallpaper "${mon},${img}"; then
                printf "${RED}[!] Failed to set wallpaper on monitor: %s${WHITE}\n" "$mon" >&2
            fi
        done
    fi
}

_setter_swaybg() {
    local img="$1"
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-swaybg.pid"

    if [[ "${CTX[env]}" == "sway" ]]; then
        local target="${CTX[monitor]:-*}"
        swaymsg output "$target" bg "$img" fill >/dev/null 2>&1
    else
        if [[ -f "$pid_file" ]]; then
            local old_pid; old_pid=$(cat "$pid_file")
            if kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid" 2>/dev/null || true
            fi
        fi

        swaybg -i "$img" -m fill >/dev/null 2>&1 &
        local new_pid=$!
        disown "$new_pid"
        echo "$new_pid" > "$pid_file"
    fi
}

_setter_wpaperctl() {
    printf "${RED}[!] wpaperd is not supported as a dwall setter.\n" >&2
    printf "    wpaperctl cannot accept a specific image path at runtime.\n" >&2
    printf "    Use --setter swaybg, --setter awww, or --setter wbg instead.${WHITE}\n" >&2
    exit 1
}

_setter_wbg() {
    local img="$1"
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-wbg.pid"

    if [[ -f "$pid_file" ]]; then
        local old_pid; old_pid=$(cat "$pid_file")
        if kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null || true
        fi
    fi

    wbg "$img" >/dev/null 2>&1 &
    local new_pid=$!
    disown "$new_pid"
    echo "$new_pid" > "$pid_file"
}

_setter_feh() {
    feh --bg-fill "$1"
}

_setter_nitrogen() {
    local img="$1"
    if [[ -n "${CTX[monitor]}" ]]; then
        nitrogen --set-zoom-fill "$img" --head="${CTX[monitor]}"
    else
        nitrogen --set-zoom-fill "$img"
    fi
}

_setter_hsetroot() {
    hsetroot -fill "$1"
}

_setter_xwallpaper() {
    local img="$1"
    if [[ -n "${CTX[monitor]}" ]]; then
        xwallpaper --output "${CTX[monitor]}" --zoom "$img"
    else
        xwallpaper --zoom "$img"
    fi
}

_setter_pcmanfm_qt() {
    pcmanfm-qt -w "$1"
}

_setter_pcmanfm() {
    pcmanfm --set-wallpaper "$1"
}

_setter_enlightenment_remote() {
    enlightenment_remote -desktop-bg-add 0 0 0 0 "$1"
}

_setter_cosmic_bg() {
    printf "${ORANGE}[!] cosmic-bg runtime wallpaper change not yet supported.${WHITE}\n" >&2
    exit 1
}

apply_wallpaper() {
    local img="$1"

    case "${CTX[setter]}" in
        gsettings)           _setter_gsettings "$img" ;;
        qdbus6|qdbus)        _setter_qdbus "$img" ;;
        xfconf-query)        _setter_xfconf_query "$img" ;;
        awww)                _setter_awww "$img" ;;
        hyprpaper)           _setter_hyprpaper "$img" ;;
        swaybg)              _setter_swaybg "$img" ;;
        wpaperd)             _setter_wpaperctl "$img" ;;
        wbg)                 _setter_wbg "$img" ;;
        feh)                 _setter_feh "$img" ;;
        nitrogen)            _setter_nitrogen "$img" ;;
        hsetroot)            _setter_hsetroot "$img" ;;
        xwallpaper)          _setter_xwallpaper "$img" ;;
        pcmanfm-qt)          _setter_pcmanfm_qt "$img" ;;
        pcmanfm)             _setter_pcmanfm "$img" ;;
        enlightenment_remote) _setter_enlightenment_remote "$img" ;;
        cosmic-bg)           _setter_cosmic_bg "$img" ;;
        *)
            printf "${RED}[!] Unknown setter: %s${WHITE}\n" "${CTX[setter]}" >&2
            exit 1
            ;;
    esac

    update_cache "$img"
    apply_colors "$img"
}

## ---------------------------------------------------------------------------
## Cache & colors
## ---------------------------------------------------------------------------

update_cache() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dwall"
    local cfile="$cache_dir/current"

    [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"
    echo "$1" > "$cfile" || printf "${RED}[!] Failed to update cache${WHITE}\n" >&2
}

apply_colors() {
    local image="$1"

    if [[ -n "${CTX[pywal]}" ]]; then
        if command -v wal >/dev/null 2>&1; then
            wal -i "$image" -n
        else
            printf "${RED}[!] pywal (wal) is not installed, but -p was passed.${WHITE}\n" >&2
        fi
    fi
}

## ---------------------------------------------------------------------------
## Display info
## ---------------------------------------------------------------------------

display_info() {
    local session_name
    case "${CTX[env]}" in
        hyprland)        session_name="Hyprland" ;;
        sway)            session_name="Sway" ;;
        cosmic)          session_name="Cosmic" ;;
        niri)            session_name="Niri" ;;
        river)           session_name="River" ;;
        labwc)           session_name="Labwc" ;;
        wayfire)         session_name="Wayfire" ;;
        wayland-generic) session_name="Wayland (generic)" ;;
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
        x11-generic)     session_name="X11 (generic)" ;;
        unknown)         session_name="Unknown / Custom" ;;
        *)               session_name="${CTX[env]}" ;;
    esac

    printf "${ORANGE}[*] Setting wallpaper in ${GREEN}%s${ORANGE} session${WHITE}\n" "$session_name"
    printf "${ORANGE}[*] Using setter : ${MAGENTA}%s${WHITE}\n" "${CTX[setter]}"
    if [[ -n "${CTX[monitor]}" ]]; then
        printf "${ORANGE}[*] Target Monitor : ${MAGENTA}%s${WHITE}\n" "${CTX[monitor]}"
    fi
}

## ---------------------------------------------------------------------------
## Main
## ---------------------------------------------------------------------------

main() {
    local h=$((10#$(date +%H)))
    local current_image

    local lock_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-$(id -u).lock"
    exec 9>"$lock_file"
    if ! flock -n 9; then
        printf "${ORANGE}[*] Another instance of dwall is running, exiting.${WHITE}\n" >&2
        exit 0
    fi

    current_image=$(get_img "$h") || exit 1
    apply_wallpaper "$current_image"
    display_info

    reset_color
    exit 0
}

## ---------------------------------------------------------------------------
## Entry point
## ---------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

if [[ "$1" == "rm" ]]; then
    if [[ -z "${2:-}" ]]; then
        printf "${RED}[!] Usage: %s rm <style>${WHITE}\n" "$(basename "$0")" >&2
        exit 1
    fi
    remove_style "$2"
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)     usage; exit 0 ;;
        -p|--pywal)    CTX[pywal]=true; shift ;;
        -l|--list)     list_styles; exit 0 ;;
        -r|--random)   CTX[random_mode]=true; shift ;;
        -s|--style)
            if [[ $# -lt 2 ]]; then
                printf "${RED}[!] Option %s requires an argument.${WHITE}\n" "$1" >&2
                exit 1
            fi
            CTX[style]="$2"
            shift 2
            ;;
        -S|--setter)   CTX[setter]="$2"; shift 2 ;;
        -m|--monitor)  CTX[monitor]="$2"; shift 2 ;;
        --) shift; break ;;
        -*) printf "${RED}[!] Unknown option: %s\nRun %s --help for usage.${WHITE}\n" "$1" "$(basename "$0")" >&2; exit 1 ;;
        *) break ;;
    esac
done

if [[ -n "${CTX[random_mode]}" && -z "${CTX[style]}" ]]; then
    random_style
fi

if [[ -n "${CTX[style]}" ]]; then
    detect_environment
    choose_setter
    check_style "${CTX[style]}"
    validate_monitor
    main
else
    usage
    exit 1
fi