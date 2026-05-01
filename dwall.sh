#!/usr/bin/env bash

## Minimum Bash version: 4.3

set -euo pipefail

## Author  : Aditya Shakya (adi1090x), Aina KANTY (@AinaKANTY)
## Mail    : adi1090x@gmail.com, aina.kanty9@gmail.com
## Github  : @adi1090x, @AinaKANTY
## Twitter : @adi1090x, @Aina_KANTY

## Dynamic Wallpaper : Set wallpapers according to current time.
## Created to work better with job schedulers

## ---------------------------------------------------------------------------
## ANSI color helpers — emit codes only when the relevant fd is a real terminal
## ---------------------------------------------------------------------------

RED="" GREEN="" ORANGE="" BLUE="" MAGENTA="" CYAN="" WHITE="" RESET=""

_init_colors() {
    if [[ -n "${TERM:-}" && "${TERM:-}" != "dumb" && -t 1 && -t 2 ]]; then
        RED=$'\033[31m'     GREEN=$'\033[32m'
        ORANGE=$'\033[33m'  BLUE=$'\033[34m'
        MAGENTA=$'\033[35m' CYAN=$'\033[36m'
        WHITE=$'\033[37m'   RESET=$'\033[0m'
    fi
}

_init_colors

_info()  { printf '%s[*] %s%s\n'   "$ORANGE" "$*" "$WHITE"; }
_ok()    { printf '%s[*] %s%s\n'   "$GREEN"  "$*" "$WHITE"; }
_detail(){ printf '%s[*] %s%s\n'   "$BLUE"   "$*" "$WHITE"; }
_cyan()  { printf '%s[*] %s%s\n'   "$CYAN"   "$*" "$WHITE"; }
_warn()  { printf '%s[!] %s%s\n'   "$ORANGE" "$*" "$WHITE" >&2; }
_err()   { printf '%s[!] %s%s\n'   "$RED"    "$*" "$WHITE" >&2; }

## ---------------------------------------------------------------------------
## Config
## ---------------------------------------------------------------------------

## Wallpaper directory
DIR="${DWALL_DIR:-/usr/share/dynamic-wallpaper/images}"

## Lock file path — assigned in entry point after detect_environment() sets XDG_RUNTIME_DIR
DWALL_LOCK_FILE=""

## Timeout constants for daemon startup polling
## awww-daemon: 10 attempts × 0.3 s = 3 s max (fast start expected)
readonly _AWWW_MAX_ATTEMPTS=10
readonly _AWWW_SLEEP=0.3
## hyprpaper:  100 attempts × 0.1 s = 10 s max (IPC socket init is slower)
readonly _HYPRPAPER_MAX_ATTEMPTS=100
readonly _HYPRPAPER_SLEEP=0.1

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
    [[ -n "$RESET" ]] && printf '%s' "$RESET"
}

cleanup_lock() {
    if [[ -n "$DWALL_LOCK_FILE" && -f "$DWALL_LOCK_FILE" ]]; then
        rm -f "$DWALL_LOCK_FILE" >/dev/null 2>&1 || true
    fi
}

die_on_signal() {
    local sig_name="$1"
    local exit_code="$2"
    reset_color
    printf '\n\n%s[!] Program Terminated (%s).%s\n\n' "$RED" "$sig_name" "$RESET" >&2
    exit "$exit_code"
}

trap 'die_on_signal "SIGINT"  130' SIGINT    # Ctrl+C
trap 'die_on_signal "SIGQUIT" 131' SIGQUIT   # Ctrl+\
trap 'die_on_signal "SIGHUP"  129' SIGHUP    # Terminal closing
trap 'die_on_signal "SIGTERM" 143' SIGTERM   # kill

trap cleanup_lock EXIT

## ---------------------------------------------------------------------------
## Style management
## ---------------------------------------------------------------------------

get_styles() {
    local -n _styles_ref="$1"
    if [[ ! -d "$DIR" ]]; then
        _err "Wallpaper directory not found: $DIR"
        exit 1
    fi
    readarray -d "" _styles_ref < <(find "$DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\0" 2>/dev/null)
    if [[ ${#_styles_ref[@]} -eq 0 ]]; then
        _err "No styles found in $DIR"
        exit 1
    fi
}

list_styles() {
    local styles
    get_styles styles
    printf '%s' "$ORANGE"
    printf '%s  ' "${styles[@]}"
    printf '\n%s\n' "$WHITE"
}

remove_style() {
    local style="$1"

    if [[ ! -d "$DIR" ]]; then
        _err "Wallpaper directory not found: $DIR"
        exit 1
    fi

    local target base
    target=$(realpath -m "$DIR/$style")
    base=$(realpath -m "$DIR")

    if [[ "$target" != "$base/"* ]]; then
        _err "Invalid style path: $style"
        exit 1
    fi

    if [[ ! -d "$target" ]]; then
        _err "Style not found: $style"
        exit 1
    fi

    _warn "This will permanently delete: $target"

    if [[ ! -t 0 ]]; then
        _err "remove_style requires an interactive terminal (stdin is not a tty)."
        exit 1
    fi

    read -r -p "Are you sure? [y/n] " confirm

    if [[ "${confirm,,}" != "y" ]]; then
        _info "Aborted."
        exit 0
    fi

    if [[ -w "$target" ]]; then
        rm -rf "$target"
        _ok "Style '$style' removed successfully."
    else
        _warn "Directory requires elevated privileges to delete."
        _warn "Please run: sudo $0 rm $style"
        exit 1
    fi
}

random_style() {
    local styles
    get_styles styles
    CTX[style]=$(printf '%s\n' "${styles[@]}" | shuf -n 1)
    _info "Random style selected: ${MAGENTA}${CTX[style]}${WHITE}"
}

check_style() {
    local style="$1"
    if [[ -d "$DIR/$style" ]]; then
        _detail "Using style : ${MAGENTA}${style}"
    else
        _err "Invalid style name : $style"
        local styles
        get_styles styles
        _err "Available styles are : ${styles[*]}"
        exit 1
    fi
}

## ---------------------------------------------------------------------------
## Usage
## ---------------------------------------------------------------------------

usage() {
    [[ -t 1 ]] && clear
    cat <<- EOF
		${RED}╺┳┓╻ ╻┏┓╻┏━┓┏┳┓╻┏━╸   ${GREEN}╻ ╻┏━┓╻  ╻  ┏━┓┏━┓┏━┓┏━╸┏━┓
		${RED} ┃┃┗┳┛┃┗┫┣━┫┃┃┃┃┃     ${GREEN}┃╻┃┣━┫┃  ┃  ┣━┛┣━┫┣━┛┣╸ ┣┳┛
		${RED}╺┻┛ ╹ ╹ ╹╹ ╹╹ ╹╹┗━╸   ${GREEN}┗┻┛╹ ╹┗━╸┗━╸╹  ╹ ╹╹  ┗━╸╹┗╸${WHITE}

		Dwall V0.5.2 : Set wallpapers according to current time.
		Developed By : Aditya Shakya (@adi1090x) and forked by Aina KANTY (@AinaKANTY).

		Usage : $(basename "$0") [OPTION...]
		        $(basename "$0") rm <style>

		Options:
		   -h, --help	           Show this help message
		   -p, --pywal	           Use pywal to set wallpaper instead of matugen
		   -s, --style <style>	   Name of the style to apply
		   -S, --setter <setter>   Force a specific wallpaper setter
		   -m, --monitor <name>    Target a specific monitor (ex: DP-1, eDP-1)
		   -l, --list              List available styles
		   -r, --random            Pick a random style

		Subcommands:
		   rm <style>              Remove an installed style

	EOF

    printf 'Styles:\n\t%s' "$ORANGE"
    if [[ -d "$DIR" ]]; then
        list_styles
    else
        printf '(no styles directory found)%s\n' "$WHITE"
    fi
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

## ---------------------------------------------------------------------------
## DE resolution — ordered array to guarantee deterministic priority.
## ---------------------------------------------------------------------------

_DE_RULES=(
    ## XDG_CURRENT_DESKTOP
    '*GNOME:gnome'
    '*budgie:gnome'
    '*Deepin:gnome'
    '*Pantheon:gnome'
    '*unity*:gnome'
    '*KDE:kde'
    '*Plasma*:kde'
    '*XFCE*:xfce'
    'MATE:mate'
    'X-Cinnamon:cinnamon'
    'LXDE:lxde'
    'LXQt:lxqt'
    'ENLIGHTENMENT:enlightenment'
    
    ## DESKTOP_SESSION
    'gnome:gnome'
    'ubuntu:gnome'
    'budgie-desktop:gnome'
    'deepin:gnome'
    'pantheon:gnome'
    'unity:gnome'
    'gnome-flashback:gnome'
    'pop:gnome'
    'zorin:gnome'
    'plasma:kde'
    'kde-plasma:kde'
    'kde:kde'
    'xfce:xfce'
    'xfce4:xfce'
    'mate:mate'
    'cinnamon:cinnamon'
    'lxde:lxde'
    'lxqt:lxqt'
    'enlightenment:enlightenment'
)

_resolve_de() {
    local key="$1"
    local rule pattern result
    for rule in "${_DE_RULES[@]}"; do
        pattern="${rule%%:*}"
        result="${rule##*:}"

        case "$key" in
            $pattern) printf '%s' "$result"; return 0 ;;
        esac
    done
    printf 'x11-generic'
}

## ---------------------------------------------------------------------------
## JSON name extraction
##
## Preferred: python3 (handles any valid JSON formatting, including compact).
## Fallback:  if python3 is absent, exit with a clear error rather than
##            silently producing wrong results from a broken awk heuristic.
##            The awk regex approach fails on compact JSON (no spaces around
##            ':') and on multi-value objects — it gives a false sense of
##            safety while being unreliable in practice.
## ---------------------------------------------------------------------------

_json_extract_names() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and "name" in item:
                print(item["name"])
    elif isinstance(data, dict) and "name" in data:
        print(data["name"])
except Exception:
    pass
'
    else
        awk -F'"' '
            /"name"[[:space:]]*:/ {
                for (i = 1; i <= NF; i++) {
                    if ($i == "name") { print $(i+2); break }
                }
            }
        '
    fi
}

detect_environment() {
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        local _xrd
        _xrd="/run/user/$(id -u)"
        export XDG_RUNTIME_DIR="$_xrd"
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DISPLAY:-}" ]]; then
        local sock
        for sock in "wayland-0" "wayland-1"; do
            if [[ -S "${XDG_RUNTIME_DIR}/$sock" ]]; then
                export WAYLAND_DISPLAY="$sock"
                break
            fi
        done

        if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
            local wld
            wld=$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 \
                  -name 'wayland-[0-9]*' -not -name '*.lock' \
                  -printf "%T@ %f\n" 2>/dev/null \
                | sort -n | tail -n 1 | cut -d' ' -f2 || true)
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
        env=$(_resolve_de "${XDG_CURRENT_DESKTOP:-}")
        if [[ "$env" == "x11-generic" ]]; then
            env=$(_resolve_de "$(basename "${DESKTOP_SESSION:-}")")
        fi
    else
        env="unknown"
        _warn "Environment not recognized. You may need to use --setter (-S)"
    fi

    CTX[env]="$env"
    _info "Detected environment: ${MAGENTA}${CTX[env]}"
}

choose_setter() {
    if [[ -n "${CTX[setter]}" ]]; then
        if [[ "${CTX[setter]}" == "wpaperd" || "${CTX[setter]}" == "wpaperctl" ]]; then
            _err "wpaperd/wpaperctl is not supported as a dwall setter."
            _err "wpaperctl cannot accept a specific image path at runtime."
            _err "Use --setter swaybg, --setter awww, or --setter wbg instead."
            exit 1
        fi
        if command -v "${CTX[setter]}" >/dev/null 2>&1; then
            return
        else
            _err "Specified setter not found: ${CTX[setter]}"
            exit 1
        fi
    fi

    if [[ -z "${CTX[env]}" ]]; then
        _err "Internal error: environment not detected before choose_setter()"
        exit 1
    fi

    local wall_setter
    for wall_setter in ${SETTER_PRIORITY[${CTX[env]}]:-}; do
        if command -v "$wall_setter" >/dev/null 2>&1; then
            CTX[setter]="$wall_setter"
            return
        fi
    done
    _err "No setters found for your environment: ${CTX[env]}"
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
                if ! hyprctl monitors -j | jq -e --arg m "${CTX[monitor]}" \
                        '.[] | select(.name == $m)' >/dev/null 2>&1; then
                    _err "Monitor '${CTX[monitor]}' not found"
                    exit 1
                fi
            elif ! hyprctl monitors -j | _json_extract_names | grep -qxF "${CTX[monitor]}"; then
                _err "Monitor '${CTX[monitor]}' not found"
                exit 1
            fi
            ;;
        kde)
            local -a kde_screens=()
            if command -v jq >/dev/null 2>&1; then
                readarray -t kde_screens < <(
                    "${CTX[setter]}" org.kde.plasmashell /PlasmaShell \
                        org.kde.PlasmaShell.evaluateScript \
                        "print(JSON.stringify(desktops().map(function(d){return d.screen;})))" \
                        2>/dev/null | jq -r '.[]' 2>/dev/null || true
                )
            fi
            if [[ ${#kde_screens[@]} -gt 0 ]]; then
                local found=0 s
                for s in "${kde_screens[@]}"; do
                    [[ "$s" == "${CTX[monitor]}" ]] && { found=1; break; }
                done
                if [[ $found -eq 0 ]]; then
                    _err "Monitor '${CTX[monitor]}' not found in KDE desktops"
                    exit 1
                fi
            else
                _warn "Could not verify monitor '${CTX[monitor]}' for KDE, proceeding."
            fi
            ;;
        xfce)
            local xfce_props
            if xfce_props=$(xfconf-query -c xfce4-desktop -l 2>/dev/null); then
                if ! printf '%s\n' "$xfce_props" | grep -qiF "${CTX[monitor]}"; then
                    _err "Monitor '${CTX[monitor]}' not found in XFCE configuration."
                    exit 1
                fi
            else
                _warn "Could not verify monitor '${CTX[monitor]}' for XFCE, proceeding."
            fi
            ;;
        sway)
            if ! swaymsg -t get_outputs 2>/dev/null | _json_extract_names | grep -qxF "${CTX[monitor]}"; then
                _err "Monitor '${CTX[monitor]}' not found in Sway outputs"
                exit 1
            fi
            ;;
        *)
            _warn "--monitor not natively supported for ${CTX[env]}, applying globally."
            ;;
    esac
}

## ---------------------------------------------------------------------------
## Image resolution (smart time fallback — walk back up to 24 h)
## ---------------------------------------------------------------------------

get_img() {
    local target_hour="$1"
    local formats=("png" "jpg" "jpeg" "webp" "gif")
    local h i img

    if ! find "$DIR/${CTX[style]}" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
        _err "Error: Style directory '${CTX[style]}' is empty or missing."
        exit 1
    fi

    for (( i=0; i<24; i++ )); do
        h=$(( (target_hour - i + 24) % 24 ))
        for fmt in "${formats[@]}"; do
            img="$DIR/${CTX[style]}/${h}.${fmt}"
            if [[ -f "$img" ]]; then
                printf '%s\n' "$img"
                return 0
            fi
        done
    done


    _err "Error: No image found for style '${CTX[style]}' in $DIR/${CTX[style]}/"
    _err "Expected files named 0.png … 23.png (or .jpg/.jpeg/.webp/.gif)."
    exit 1
}

## ---------------------------------------------------------------------------
## Lock fd helper
## ---------------------------------------------------------------------------

_close_lock_fd() {
    { exec 9>&-; } 2>/dev/null || true
}

## ---------------------------------------------------------------------------
## Setter implementations
## ---------------------------------------------------------------------------

_setter_gsettings() {
    local img="$1"
    case "${CTX[env]}" in
        cinnamon)
            gsettings set org.cinnamon.desktop.background picture-uri      "file://$img"
            gsettings set org.cinnamon.desktop.background picture-uri-dark "file://$img"
            ;;
        mate)
            gsettings set org.mate.background picture-filename "$img"
            ;;
        *)
            ## gnome, budgie, deepin, pantheon, unity, gnome-flashback
            gsettings set org.gnome.desktop.background   picture-uri      "file://$img"
            gsettings set org.gnome.desktop.background   picture-uri-dark "file://$img"
            gsettings set org.gnome.desktop.screensaver  picture-uri      "file://$img"
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
    " || { _err "Failed to set KDE wallpaper"; exit 1; }
}

_setter_xfconf_query() {
    local img="$1"
    local properties

    if ! properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null); then
        _err "xfce: xfconf-query failed (is XFCE running?)"
        exit 1
    fi
    properties=$(printf '%s\n' "$properties" | grep "last-image" || true)

    if [[ -z "$properties" ]]; then
        _err "xfce: no wallpaper properties found via xfconf-query"
        exit 1
    fi

    if [[ -n "${CTX[monitor]}" ]]; then
        properties=$(printf '%s\n' "$properties" | grep -iF "${CTX[monitor]}" || true)
        if [[ -z "$properties" ]]; then
            _err "xfce: Monitor '${CTX[monitor]}' not found in configuration."
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
        if ! command -v awww-daemon >/dev/null 2>&1; then
            _err "awww-daemon not found. Is awww installed correctly?"
            exit 1
        fi

        _close_lock_fd
        awww-daemon >"${XDG_RUNTIME_DIR:-/tmp}/dwall-awww-daemon.log" 2>&1 &
        disown

        local i=0
        until awww query >/dev/null 2>&1; do
            if (( i >= _AWWW_MAX_ATTEMPTS )); then
                _err "awww-daemon failed to start after ${_AWWW_MAX_ATTEMPTS} attempts (${_AWWW_SLEEP}s each)"
                exit 1
            fi
            i=$(( i + 1 ))
            sleep "$_AWWW_SLEEP" || true
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

    if ! pgrep -x "hyprpaper" > /dev/null; then
        _ok "Starting hyprpaper daemon..."
        _close_lock_fd
        hyprpaper > /dev/null 2>&1 &

        local attempt=0
        local hyprpaper_sock
        until hyprpaper_sock=$(find "${XDG_RUNTIME_DIR}" -maxdepth 1 \
                -name 'hyprpaper.sock*' -print -quit 2>/dev/null) \
              && [[ -n "$hyprpaper_sock" ]]; do
            if ! pgrep -x "hyprpaper" > /dev/null; then
                _err "hyprpaper daemon failed to start"
                exit 1
            fi
            if (( attempt >= _HYPRPAPER_MAX_ATTEMPTS )); then
                _err "Timed out waiting for hyprpaper socket (${_HYPRPAPER_MAX_ATTEMPTS} × ${_HYPRPAPER_SLEEP}s)"
                exit 1
            fi
            attempt=$(( attempt + 1 ))
            sleep "$_HYPRPAPER_SLEEP"
        done
    fi

    if [[ -n "${CTX[monitor]:-}" ]]; then
        if ! hyprctl hyprpaper wallpaper "${CTX[monitor]},${img}"; then
            _err "Failed to set wallpaper on ${CTX[monitor]}"
            exit 1
        fi
    else
        local -a monitors=()
        if command -v jq >/dev/null 2>&1; then
            readarray -t monitors < <(hyprctl monitors -j | jq -r '.[].name' 2>/dev/null)
        else
            readarray -t monitors < <(hyprctl monitors | awk '/^Monitor/ {print $2}')
        fi

        if [[ ${#monitors[@]} -eq 0 ]]; then
            _err "No monitors detected by hyprctl"
            exit 1
        fi

        local failed=0 total=0 mon
        for mon in "${monitors[@]}"; do
            [[ -z "$mon" ]] && continue
            total=$(( total + 1 ))
            if ! hyprctl hyprpaper wallpaper "${mon},${img}"; then
                _err "Failed to set wallpaper on monitor: $mon"
                failed=$(( failed + 1 ))
            fi
        done
        if (( total > 0 && failed == total )); then
            _err "Failed to set wallpaper on all monitors"
            exit 1
        fi
    fi

    hyprctl hyprpaper unload unused >/dev/null 2>&1 || true
}

_setter_swaybg() {
    local img="$1"
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-swaybg.pid"

    if [[ "${CTX[env]}" == "sway" ]]; then
        local target="${CTX[monitor]:-*}"
        swaymsg output "$target" bg "$img" fill >/dev/null 2>&1
    else
        if [[ -n "${CTX[monitor]}" ]]; then
            _warn "swaybg in non-Sway mode does not support --monitor; applying wallpaper globally."
        fi

        if [[ -f "$pid_file" ]]; then
            local old_pid
            old_pid=$(cat "$pid_file")
            if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
                kill "$old_pid" 2>/dev/null || true
            fi
        fi

        _close_lock_fd
        swaybg -i "$img" -m fill >/dev/null 2>&1 &
        local new_pid=$!
        disown "$new_pid"
        printf '%s\n' "$new_pid" > "$pid_file"
    fi
}

_setter_wpaperctl() {
    _err "wpaperd is not supported as a dwall setter."
    _err "wpaperctl cannot accept a specific image path at runtime."
    _err "Use --setter swaybg, --setter awww, or --setter wbg instead."
    exit 1
}

_setter_wbg() {
    local img="$1"
    local pid_file="${XDG_RUNTIME_DIR:-/tmp}/dwall-wbg.pid"

    if [[ -f "$pid_file" ]]; then
        local old_pid
        old_pid=$(cat "$pid_file")
        if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null || true
        fi
    fi

    _close_lock_fd
    wbg "$img" >/dev/null 2>&1 &
    local new_pid=$!
    disown "$new_pid"
    printf '%s\n' "$new_pid" > "$pid_file"
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
    _warn "cosmic-bg runtime wallpaper change not yet supported."
    exit 1
}

apply_wallpaper() {
    local img="$1"

    case "${CTX[setter]}" in
        gsettings)            _setter_gsettings        "$img" ;;
        qdbus6|qdbus)         _setter_qdbus            "$img" ;;
        xfconf-query)         _setter_xfconf_query     "$img" ;;
        awww)                 _setter_awww             "$img" ;;
        hyprpaper)            _setter_hyprpaper        "$img" ;;
        swaybg)               _setter_swaybg           "$img" ;;
        wpaperd)              _setter_wpaperctl        "$img" ;;
        wbg)                  _setter_wbg              "$img" ;;
        feh)                  _setter_feh              "$img" ;;
        nitrogen)             _setter_nitrogen         "$img" ;;
        hsetroot)             _setter_hsetroot         "$img" ;;
        xwallpaper)           _setter_xwallpaper       "$img" ;;
        pcmanfm-qt)           _setter_pcmanfm_qt       "$img" ;;
        pcmanfm)              _setter_pcmanfm          "$img" ;;
        enlightenment_remote) _setter_enlightenment_remote "$img" ;;
        cosmic-bg)            _setter_cosmic_bg        "$img" ;;
        *)
            _err "Unknown setter: ${CTX[setter]}"
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
    if printf '%s\n' "$1" > "${cfile}.tmp"; then
        mv "${cfile}.tmp" "$cfile" || {
            rm -f "${cfile}.tmp" 2>/dev/null || true
            _err "Failed to move cache file into place"
        }
    else
        rm -f "${cfile}.tmp" 2>/dev/null || true
        _err "Failed to write cache"
    fi
}

apply_colors() {
    local image="$1"

    if [[ -n "${CTX[pywal]}" ]]; then
        if command -v wal >/dev/null 2>&1; then
            if wal -i "$image" -n >/dev/null 2>&1; then
                _cyan "pywal colors applied. Run 'wal --theme' to reload terminal colors."
            else
                _warn "pywal failed to generate colors (check your config/setup)."
            fi
        else
            _err "pywal (wal) is not installed, but -p was passed."
        fi
    elif command -v matugen >/dev/null 2>&1; then
        local matugen_config="${XDG_CONFIG_HOME:-$HOME/.config}/matugen/config.toml"
        if [[ -f "$matugen_config" ]]; then
            if matugen image "$image" >/dev/null 2>&1; then
                _cyan "matugen colors applied."
            else
                _warn "matugen failed to generate colors (check your matugen config)."
            fi
        else
            _info "matugen installed but no config.toml found. Skipping colors."
        fi
    else
        _info "No color generator found. Skipping colors."
    fi
}

## ---------------------------------------------------------------------------
## Display info — lookup table replaces the 25-arm case statement
## ---------------------------------------------------------------------------

declare -A _ENV_DISPLAY_NAMES=(
    [hyprland]="Hyprland"
    [sway]="Sway"
    [cosmic]="Cosmic"
    [niri]="Niri"
    [river]="River"
    [labwc]="Labwc"
    [wayfire]="Wayfire"
    [wayland-generic]="Wayland (generic)"
    [gnome]="GNOME"
    [kde]="KDE Plasma"
    [xfce]="XFCE"
    [budgie]="Budgie"
    [cinnamon]="Cinnamon"
    [deepin]="Deepin"
    [pantheon]="Pantheon"
    [mate]="MATE"
    [lxqt]="LXQt"
    [lxde]="LXDE"
    [unity]="Unity"
    [gnome-flashback]="GNOME Flashback"
    [enlightenment]="Enlightenment"
    [x11-generic]="X11 (generic)"
    [unknown]="Unknown / Custom"
)

display_info() {
    local session_name="${_ENV_DISPLAY_NAMES[${CTX[env]}]:-${CTX[env]}}"
    _info "Setting wallpaper in ${GREEN}${session_name}${ORANGE} session"
    _info "Using setter : ${MAGENTA}${CTX[setter]}"
    if [[ -n "${CTX[monitor]}" ]]; then
        _info "Target Monitor : ${MAGENTA}${CTX[monitor]}"
    fi
}

## ---------------------------------------------------------------------------
## Main
## ---------------------------------------------------------------------------

main() {
    local h
    h=$(( 10#$(date +%H) ))
    local current_image

    exec 9>"$DWALL_LOCK_FILE"
    if ! flock -n 9; then
        _info "Another instance of dwall is running, exiting."
        exit 0
    fi

    current_image=$(get_img "$h") || exit 1
    display_info
    apply_wallpaper "$current_image"

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
        _err "Usage: $(basename "$0") rm <style>"
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
                _err "Option $1 requires an argument."
                exit 1
            fi
            CTX[style]="$2"; shift 2 ;;
        -S|--setter)
            if [[ $# -lt 2 ]]; then
                _err "Option $1 requires an argument."
                exit 1
            fi
            CTX[setter]="$2"; shift 2 ;;
        -m|--monitor)
            if [[ $# -lt 2 ]]; then
                _err "Option $1 requires an argument."
                exit 1
            fi
            CTX[monitor]="$2"; shift 2 ;;
        --) shift; break ;;
        -*)
            _err "Unknown option: $1"
            _err "Run $(basename "$0") --help for usage."
            exit 1 ;;
        *) break ;;
    esac
done

if [[ -n "${CTX[random_mode]}" && -z "${CTX[style]}" ]]; then
    random_style
fi

if [[ -n "${CTX[style]}" ]]; then
    detect_environment
    DWALL_LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dwall-$(id -u).lock"
    choose_setter
    check_style "${CTX[style]}"
    validate_monitor
    main
else
    usage
    exit 1
fi