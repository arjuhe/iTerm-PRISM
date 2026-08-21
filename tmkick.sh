#!/usr/bin/env bash
# tmkick — kick the Time Machine volume: report status, unmount, then (re)mount.
#   1. Reports whether the Time Machine volume is currently mounted.
#   2. If mounted, warns the user and asks whether to continue unmounting or exit.
#   3. Mounts (or remounts) the volume, unlocking it first if it is encrypted.
#
# Author:    Arnaldo Hernandez
# Co-author: Claude Opus 4.8 <noreply@anthropic.com>

tmkick() {
    local vol_name="Time Machine"
    local assume_yes=0     # skip the unmount confirmation prompt
    local force=0          # force the unmount even if the volume is busy
    local status_only=0    # only report status, do not (un)mount
    local quiet=0          # suppress informational output
    local dry_run=0        # show actions without performing them

    # Colors — only when the stream is a terminal, so pipes/logs stay clean.
    local RED= GRN= YLW= CYN= MAG= BLD= DIM= RST=
    if [ -t 1 ]; then
        RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'
        CYN=$'\033[36m'; MAG=$'\033[35m'; BLD=$'\033[1m'
        DIM=$'\033[2m';  RST=$'\033[0m'
    fi

    # Message helpers. Informational output honors --quiet; errors never do.
    local _say _info _ok _warn _step _err
    _say()  { [ "$quiet" -eq 1 ] || printf '%b\n' "$*"; }
    _info() { _say "${CYN}${*}${RST}"; }
    _ok()   { _say "${GRN}✓ ${*}${RST}"; }
    _warn() { _say "${YLW}⚠ ${*}${RST}"; }
    _step() { _say "${BLD}${MAG}» ${*}${RST}"; }
    _err()  { local r=; local z=; [ -t 2 ] && { r=$'\033[31m'; z=$'\033[0m'; }
              printf '%b\n' "${r}✗ ${*}${z}" >&2; }

    _banner() {
        [ "$quiet" -eq 1 ] && return 0
        printf '%b' "${BLD}${CYN}"
        cat <<'EOF'
  _              _      _      _
 | |_ _ __ ___  | | __ (_) ___| | __
 | __| '_ ` _ \ | |/ / | |/ __| |/ /
 | |_| | | | | ||   <  | | (__|   <
  \__|_| |_| |_||_|\_\ |_|\___|_|\_\
EOF
        printf '%b\n' "${RST}${DIM}   kick the Time Machine volume${RST}"
    }

    # Parse options.
    while [ $# -gt 0 ]; do
        case "$1" in
            -h | --help)
                cat <<EOF
Usage: tmkick [options]

Kick the Time Machine volume: report status, unmount, then (re)mount.
  1. Reports whether the Time Machine volume is currently mounted.
  2. If mounted, warns the user and asks whether to continue unmounting or exit.
  3. Mounts (or remounts) the volume, unlocking it first if it is encrypted.

Options:
  -y, --yes            Assume "yes"; skip the unmount confirmation prompt.
  -f, --force          Force the unmount even if the volume is busy (implies --yes).
  -s, --status         Only report mount status; do not mount or unmount.
  -V, --volume NAME    Volume name to operate on (default: "$vol_name").
  -n, --dry-run        Show what would be done without mounting/unmounting.
  -q, --quiet          Suppress informational output (errors still shown).
  -h, --help           Show this help message and exit.
EOF
                return 0
                ;;
            -y | --yes)
                assume_yes=1
                ;;
            -f | --force)
                force=1
                assume_yes=1
                ;;
            -s | --status)
                status_only=1
                ;;
            -n | --dry-run)
                dry_run=1
                ;;
            -q | --quiet)
                quiet=1
                ;;
            -V | --volume)
                if [ -z "$2" ]; then
                    _err "$1 requires a volume name argument."
                    return 1
                fi
                vol_name="$2"
                shift
                ;;
            *)
                _err "unknown option '$1'. See --help."
                return 1
                ;;
        esac
        shift
    done

    _banner

    # Resolve the volume's UUID from its name, so this works on any machine.
    local vol_uuid
    vol_uuid=$(diskutil info "$vol_name" 2>/dev/null | awk -F': *' '/Volume UUID/ {print $2; exit}')

    # Resolve the device identifier for the volume (by UUID, fallback to name).
    local dev
    if [ -n "$vol_uuid" ]; then
        dev=$(diskutil info "$vol_uuid" 2>/dev/null | awk -F': *' '/Device Identifier/ {print $2; exit}')
    fi
    if [ -z "$dev" ]; then
        dev=$(diskutil info "$vol_name" 2>/dev/null | awk -F': *' '/Device Identifier/ {print $2; exit}')
    fi

    if [ -z "$dev" ]; then
        _err "could not find the '$vol_name' volume${vol_uuid:+ (UUID: $vol_uuid)}."
        return 1
    fi

    # 1. Check mount status.
    local mounted
    mounted=$(diskutil info "$dev" 2>/dev/null | awk -F': *' '/Mounted/ {print $2; exit}')

    if [ "$mounted" = "Yes" ]; then
        # 2. Report it is mounted and ask before unmounting.
        local mount_point
        mount_point=$(diskutil info "$dev" 2>/dev/null | awk -F': *' '/Mount Point/ {print $2; exit}')
        _info "The '$vol_name' volume ($dev) is currently ${GRN}${BLD}MOUNTED${RST}${CYN} at: ${mount_point:-unknown}"

        # --status: report only, then stop.
        if [ "$status_only" -eq 1 ]; then
            return 0
        fi

        # Confirm unless --yes/--force was given.
        if [ "$assume_yes" -ne 1 ]; then
            local answer
            read -r -p "${YLW}Do you want to continue and unmount it? [y/N] ${RST}" answer
            case "$answer" in
                [yY] | [yY][eE][sS]) ;;
                *)
                    _warn "Aborted. Leaving '$vol_name' mounted."
                    return 0
                    ;;
            esac
        fi

        if [ "$dry_run" -eq 1 ]; then
            if [ "$force" -eq 1 ]; then
                _step "[dry-run] would force unmount '$vol_name' ($dev)."
            else
                _step "[dry-run] would unmount '$vol_name' ($dev)."
            fi
        else
            _step "Unmounting '$vol_name' ($dev)..."
            if [ "$force" -eq 1 ]; then
                if ! diskutil unmount force "$dev"; then
                    _err "failed to force unmount '$vol_name'."
                    return 1
                fi
            elif ! diskutil unmount "$dev"; then
                _err "failed to unmount '$vol_name'."
                return 1
            fi
        fi
    else
        _info "The '$vol_name' volume ($dev) is ${YLW}${BLD}NOT mounted${RST}${CYN}."
        # --status: report only, then stop.
        if [ "$status_only" -eq 1 ]; then
            return 0
        fi
    fi

    # 3. Mount the Time Machine volume.
    # Encrypted APFS volumes re-lock when unmounted, so detect a locked
    # volume and unlock it (which also mounts it) instead of a plain mount.
    local locked
    locked=$(diskutil info "$dev" 2>/dev/null | awk -F': *' '/Locked/ {print $2; exit}')

    if [ "$dry_run" -eq 1 ]; then
        if [ "$locked" = "Yes" ]; then
            _step "[dry-run] would unlock and mount encrypted '$vol_name' ($dev)."
        else
            _step "[dry-run] would mount '$vol_name' ($dev)."
        fi
        return 0
    fi

    if [ "$locked" = "Yes" ]; then
        _warn "'$vol_name' ($dev) is an encrypted APFS volume and is locked."
        local passphrase
        read -r -s -p "${CYN}Enter passphrase to unlock '$vol_name': ${RST}" passphrase
        echo    # terminate the hidden-input line with a newline
        if ! printf '%s' "$passphrase" | diskutil apfs unlockVolume "$dev" -stdinpassphrase; then
            unset passphrase
            _err "failed to unlock and mount '$vol_name'."
            return 1
        fi
        unset passphrase
    else
        _step "Mounting '$vol_name' ($dev)..."
        if ! diskutil mount "$dev"; then
            _err "failed to mount '$vol_name'."
            return 1
        fi

        # Alert the user if this backup volume is not encrypted.
        local filevault
        filevault=$(diskutil info "$dev" 2>/dev/null | awk -F': *' '/FileVault/ {print $2; exit}')
        if [ "$filevault" = "No" ]; then
            _warn "'$vol_name' is NOT encrypted."
            _say  "${DIM}   Time Machine backups can contain copies of every file on your"
            _say  "   Mac. Encrypting this volume protects that data if the drive is"
            _say  "   lost or stolen. Consider enabling encryption via:"
            _say  "     - Finder/System Settings, or"
            _say  "     - diskutil apfs encryptVolume \"$dev\" -user disk${RST}"
        fi
    fi

    _ok "'$vol_name' is now mounted."
}
