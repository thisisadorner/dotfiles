#!/usr/bin/env bash
# setup.sh — earlgrey dotfiles installer (no root required)
# Usage: ./setup.sh [--dry-run]
#
# Requires packages to already be installed.
# If they're not, ask a sudoer to run: sudo ./install-deps.sh

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ME="$(whoami)"
MYHOME="$HOME"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ─── colors ────────────────────────────────────────────────────────────────
RED='\033[31m'; GRN='\033[32m'; YLW='\033[33m'
CYN='\033[36m'; BLD='\033[1m'; RST='\033[0m'

info()   { printf "${CYN}=>${RST} %s\n"  "$*"; }
ok()     { printf "${GRN}ok${RST}  %s\n" "$*"; }
warn()   { printf "${YLW}!!${RST}  %s\n" "$*"; }
die()    { printf "${RED}ERR${RST} %s\n" "$*" >&2; exit 1; }
header() { printf "\n${BLD}━━━ %s ━━━${RST}\n" "$*"; }
ask()    { printf "${CYN}?${RST}  %s " "$*"; }

copy() {
    local src="$1" dst="$2"
    if $DRY_RUN; then
        info "[dry-run] $src -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp -r "$src" "$dst"
        ok "$dst"
    fi
}

# ─── dependency check ──────────────────────────────────────────────────────
header "Checking dependencies"

NEED=()
for cmd in i3 i3blocks alacritty rofi nitrogen tmux vim xrandr \
           xscreensaver brightnessctl pactl nm-applet volumeicon xclip python3; do
    command -v "$cmd" &>/dev/null || NEED+=("$cmd")
done

if [[ ${#NEED[@]} -gt 0 ]]; then
    warn "Missing packages: ${NEED[*]}"
    warn "Ask a sudoer to run:  sudo ./install-deps.sh"
    die "Cannot continue until dependencies are installed."
else
    ok "All dependencies present"
fi

# ─── display wizard ────────────────────────────────────────────────────────
header "Display Configuration"

XRANDR_LINE=""
PRIMARY_OUTPUT=""
SECONDARY_OUTPUT=""

if ! command -v xrandr &>/dev/null; then
    warn "xrandr not available — skipping display config"
else
    # Parse connected outputs and their unique resolutions
    declare -a OUTPUTS=()
    declare -A MODES   # output -> space-separated unique resolutions

    current_out=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^([A-Za-z0-9_-]+)[[:space:]]connected ]]; then
            current_out="${BASH_REMATCH[1]}"
            OUTPUTS+=("$current_out")
            MODES["$current_out"]=""
        elif [[ -n "$current_out" && "$line" =~ ^[[:space:]]+([0-9]+x[0-9]+) ]]; then
            res="${BASH_REMATCH[1]}"
            [[ "${MODES[$current_out]}" != *"$res"* ]] && MODES["$current_out"]+="$res "
        elif [[ "$line" =~ ^[A-Za-z] ]]; then
            current_out=""
        fi
    done < <(xrandr 2>/dev/null)

    if [[ ${#OUTPUTS[@]} -eq 0 ]]; then
        warn "No connected displays detected — skipping display config"
    else
        # ── pick primary ──
        echo ""
        info "Connected displays:"
        for i in "${!OUTPUTS[@]}"; do
            printf "   [%d] %s\n" "$i" "${OUTPUTS[$i]}"
        done
        echo ""
        ask "Primary display index [0]:"; read -r pidx
        pidx="${pidx:-0}"
        PRIMARY_OUTPUT="${OUTPUTS[$pidx]}"

        # ── resolution for primary ──
        IFS=' ' read -ra PMODES <<< "${MODES[$PRIMARY_OUTPUT]}"
        echo ""
        info "Resolutions for $PRIMARY_OUTPUT:"
        for i in "${!PMODES[@]}"; do
            printf "   [%d] %s\n" "$i" "${PMODES[$i]}"
        done
        ask "Select resolution [0]:"; read -r pres_idx
        pres_idx="${pres_idx:-0}"
        PRIMARY_RES="${PMODES[$pres_idx]}"

        # ── refresh rate for primary ──
        mapfile -t PRATES < <(
            xrandr 2>/dev/null | awk -v out="$PRIMARY_OUTPUT" -v res="$PRIMARY_RES" '
                $0 ~ out" connected" { found=1; next }
                found && /^[[:space:]]/ && $1==res {
                    for (i=2; i<=NF; i++) {
                        gsub(/[*+]/, "", $i)
                        if ($i ~ /^[0-9]/) print $i
                    }
                    next
                }
                found && /^[A-Za-z]/ { exit }
            '
        )
        echo ""
        info "Refresh rates for $PRIMARY_RES:"
        for i in "${!PRATES[@]}"; do
            printf "   [%d] %s Hz\n" "$i" "${PRATES[$i]}"
        done
        ask "Select rate [0]:"; read -r prate_idx
        prate_idx="${prate_idx:-0}"
        PRIMARY_RATE="${PRATES[$prate_idx]:-60.00}"

        # ── secondary display ──
        if [[ ${#OUTPUTS[@]} -gt 1 ]]; then
            echo ""
            info "Other available displays:"
            for i in "${!OUTPUTS[@]}"; do
                [[ "$i" -ne "$pidx" ]] && printf "   [%d] %s\n" "$i" "${OUTPUTS[$i]}"
            done
            ask "Enable a secondary display? Enter index or [n]:"; read -r sidx

            if [[ "$sidx" =~ ^[0-9]+$ ]] && \
               [[ "$sidx" -lt "${#OUTPUTS[@]}" ]] && \
               [[ "$sidx" -ne "$pidx" ]]; then

                SECONDARY_OUTPUT="${OUTPUTS[$sidx]}"

                # Resolution for secondary
                IFS=' ' read -ra SMODES <<< "${MODES[$SECONDARY_OUTPUT]}"
                echo ""
                info "Resolutions for $SECONDARY_OUTPUT:"
                for i in "${!SMODES[@]}"; do
                    printf "   [%d] %s\n" "$i" "${SMODES[$i]}"
                done
                ask "Select resolution [0]:"; read -r sres_idx
                sres_idx="${sres_idx:-0}"
                SECONDARY_RES="${SMODES[$sres_idx]}"

                # Rate for secondary
                mapfile -t SRATES < <(
                    xrandr 2>/dev/null | awk -v out="$SECONDARY_OUTPUT" -v res="$SECONDARY_RES" '
                        $0 ~ out" connected" { found=1; next }
                        found && /^[[:space:]]/ && $1==res {
                            for (i=2; i<=NF; i++) {
                                gsub(/[*+]/, "", $i)
                                if ($i ~ /^[0-9]/) print $i
                            }
                            next
                        }
                        found && /^[A-Za-z]/ { exit }
                    '
                )
                echo ""
                info "Refresh rates for $SECONDARY_RES:"
                for i in "${!SRATES[@]}"; do
                    printf "   [%d] %s Hz\n" "$i" "${SRATES[$i]}"
                done
                ask "Select rate [0]:"; read -r srate_idx
                srate_idx="${srate_idx:-0}"
                SECONDARY_RATE="${SRATES[$srate_idx]:-60.00}"

                # Position
                echo ""
                info "Position of $SECONDARY_OUTPUT relative to $PRIMARY_OUTPUT:"
                echo "   [0] left-of"
                echo "   [1] right-of"
                echo "   [2] above"
                echo "   [3] below"
                ask "Select [1]:"; read -r pos_idx
                pos_idx="${pos_idx:-1}"
                case "$pos_idx" in
                    0) POS="--left-of  $PRIMARY_OUTPUT" ;;
                    2) POS="--above    $PRIMARY_OUTPUT" ;;
                    3) POS="--below    $PRIMARY_OUTPUT" ;;
                    *) POS="--right-of $PRIMARY_OUTPUT" ;;
                esac

                XRANDR_LINE="exec --no-startup-id xrandr \
--output $PRIMARY_OUTPUT --primary --mode $PRIMARY_RES --rate $PRIMARY_RATE \
--output $SECONDARY_OUTPUT --mode $SECONDARY_RES --rate $SECONDARY_RATE $POS"
            fi
        fi

        # Single display (or user skipped secondary)
        if [[ -z "$XRANDR_LINE" ]]; then
            XRANDR_LINE="exec --no-startup-id xrandr \
--output $PRIMARY_OUTPUT --primary --mode $PRIMARY_RES --rate $PRIMARY_RATE"
        fi

        echo ""
        ok "Display: $XRANDR_LINE"
    fi
fi

# ─── deploy configs ────────────────────────────────────────────────────────
header "Deploying configs"

# alacritty
copy "$DOTFILES/alacritty/alacritty.yml"        "$MYHOME/.config/alacritty/alacritty.yml"

# vim
copy "$DOTFILES/vim/.vimrc"                      "$MYHOME/.vimrc"
copy "$DOTFILES/vim/colors"                      "$MYHOME/.vim/colors"

# tmux
copy "$DOTFILES/tmux/.tmux.conf"                 "$MYHOME/.tmux.conf"

# rofi
copy "$DOTFILES/rofi/config.rasi"                "$MYHOME/.config/rofi/config.rasi"
copy "$DOTFILES/rofi/themes/Arc-Dark.rasi"       "$MYHOME/.config/rofi/themes/Arc-Dark.rasi"

# i3blocks (no timer scripts)
copy "$DOTFILES/i3blocks/config"                 "$MYHOME/.config/i3blocks/config"

# i3 — copy first, patch display info below
copy "$DOTFILES/i3/config"                       "$MYHOME/.config/i3/config"

# nitrogen — substitute hardcoded username with current user
if ! $DRY_RUN; then
    mkdir -p "$MYHOME/.config/nitrogen"
    sed "s|/home/earlgrey|$MYHOME|g" \
        "$DOTFILES/nitrogen/bg-saved.cfg" > "$MYHOME/.config/nitrogen/bg-saved.cfg"
    sed "s|/home/earlgrey|$MYHOME|g" \
        "$DOTFILES/nitrogen/nitrogen.cfg"  > "$MYHOME/.config/nitrogen/nitrogen.cfg"
    ok "$MYHOME/.config/nitrogen/ (paths updated for $ME)"
else
    info "[dry-run] nitrogen configs -> $MYHOME/.config/nitrogen/ (with path substitution)"
fi

# ─── patch i3 config with display layout ───────────────────────────────────
if [[ -n "$PRIMARY_OUTPUT" ]] && ! $DRY_RUN; then
    header "Patching i3 display config"

    python3 - "$MYHOME/.config/i3/config" \
              "$PRIMARY_OUTPUT" \
              "$SECONDARY_OUTPUT" \
              "$XRANDR_LINE" <<'PYEOF'
import sys, re

cfg_path      = sys.argv[1]
primary       = sys.argv[2]
secondary     = sys.argv[3] if sys.argv[3] else None
xrandr_line   = sys.argv[4]

ws_main  = ['$ws1','$ws2','$ws3','$ws4','$ws5','$ws6','$ws7','$ws8','$ws9','$ws0']
ws_lines = [f'workspace {w} output {primary}' for w in ws_main]
ws_lines.append(f'workspace $wsa output {secondary if secondary else primary}')
ws_block = '\n'.join(ws_lines)

with open(cfg_path) as f:
    content = f.read()

# Replace workspace→output block (anchored to the #workspace comment)
content = re.sub(
    r'#workspace\n(workspace \$ws\S+ output \S+\n)+',
    '#workspace\n' + ws_block + '\n',
    content
)

# Replace the active (uncommented) xrandr exec line
content = re.sub(
    r'^exec --no-startup-id xrandr .*',
    xrandr_line,
    content,
    flags=re.MULTILINE
)

with open(cfg_path, 'w') as f:
    f.write(content)
PYEOF

    ok "i3 config patched with display layout"

elif [[ -n "$PRIMARY_OUTPUT" ]] && $DRY_RUN; then
    info "[dry-run] would patch i3 config: primary=$PRIMARY_OUTPUT secondary=${SECONDARY_OUTPUT:-none}"
fi

# ─── done ───────────────────────────────────────────────────────────────────
header "Done"
echo ""
info "Dotfiles deployed to $MYHOME"
[[ -n "$XRANDR_LINE" ]] && info "Display config: $XRANDR_LINE"
echo ""
warn "If running i3 now:  Mod+Shift+r  to reload"
warn "Wallpaper:          nitrogen --restore"
warn "If first login:     log out and select i3 from your display manager"
echo ""
