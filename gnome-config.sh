#!/usr/bin/env bash
# =============================================================================
# GNOME Workspace Keybinding & Multi-Monitor Setup
# =============================================================================
# Sets up:
#   Super+<N>       → switch to workspace N
#   Super+Shift+<N> → move current window to workspace N
#   All monitors follow the active workspace (not just the primary)
# =============================================================================

info()    { echo "[INFO]  $*"; }
success() { echo "[OK]    $*"; }
error()   { echo "[ERROR] $*" >&2; exit 1; }

workspaces()
{

    NUM_WORKSPACES=6

    echo "==> Configuring GNOME workspace settings..."

    # ---------------------------------------------------------------------------
    # 1. Multi-monitor behaviour: all monitors span the same workspace
    #    workspaces-only-on-primary = false  →  all monitors switch together
    # ---------------------------------------------------------------------------
    gsettings set org.gnome.mutter workspaces-only-on-primary false
    echo "    [✓] All monitors now follow the active workspace"

    # ---------------------------------------------------------------------------
    # 2. Make sure we have enough workspaces and they are dynamic (or static)
    #    Use dynamic workspaces so GNOME manages the count automatically, OR
    #    switch to static and pin the number – uncomment the block you prefer.
    # ---------------------------------------------------------------------------

    # --- Option A: dynamic workspaces (default GNOME behaviour) ----------------
    #gsettings set org.gnome.mutter dynamic-workspaces true
    #echo "    [✓] Dynamic workspaces enabled"

    # --- Option B: static workspaces – uncomment to use -----------------------
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces $NUM_WORKSPACES
    echo "    [✓] Static workspaces set to $NUM_WORKSPACES"

    # ---------------------------------------------------------------------------
    # 3. Clear any existing conflicting shortcuts first
    # ---------------------------------------------------------------------------
    echo "==> Clearing existing workspace shortcuts..."

    for i in $(seq 1 $NUM_WORKSPACES); do
        # Clear switch-to-workspace
        gsettings set org.gnome.desktop.wm.keybindings \
            "switch-to-workspace-${i}" "[]" 2>/dev/null || true

        # Clear move-to-workspace
        gsettings set org.gnome.desktop.wm.keybindings \
            "move-to-workspace-${i}" "[]" 2>/dev/null || true
    done
    echo "    [✓] Existing shortcuts cleared"

    # ---------------------------------------------------------------------------
    # 4. Bind Super+<N> → switch to workspace N
    #    Bind Super+Shift+<N> → move window to workspace N
    # ---------------------------------------------------------------------------
    echo "==> Applying new workspace shortcuts..."

    for i in $(seq 1 9); do
        gsettings set org.gnome.desktop.wm.keybindings \
            "switch-to-workspace-${i}" "['<Super>${i}']"

        gsettings set org.gnome.desktop.wm.keybindings \
            "move-to-workspace-${i}" "['<Super><Shift>${i}']"
    done

    # Workspace 10 mapped to Super+0 / Super+Shift+0
    gsettings set org.gnome.desktop.wm.keybindings \
        "switch-to-workspace-10" "['<Super>0']"

    gsettings set org.gnome.desktop.wm.keybindings \
        "move-to-workspace-10" "['<Super><Shift>0']"

    echo "    [✓] Super+1…9 → switch to workspace 1–9"
    echo "    [✓] Super+0   → switch to workspace 10"
    echo "    [✓] Super+Shift+1…9 → move window to workspace 1–9"
    echo "    [✓] Super+Shift+0   → move window to workspace 10"

    # ---------------------------------------------------------------------------
    # 5. (Optional) Remove GNOME Shell's default Super+<N> app-launch shortcuts
    #    so they don't conflict with the workspace bindings above.
    # ---------------------------------------------------------------------------
    echo "==> Removing conflicting app-launch shortcuts (Super+1…9)..."

    for i in $(seq 1 9); do
        gsettings set org.gnome.shell.keybindings \
            "switch-to-application-${i}" "[]" 2>/dev/null || true
    done
    echo "    [✓] App-launch shortcuts cleared"

    # ---------------------------------------------------------------------------
    # 6. Verify — print a summary of active bindings
    # ---------------------------------------------------------------------------
    echo ""
    echo "==> Current bindings (verification):"
    echo "    --- Switch to workspace ---"
    for i in $(seq 1 9); do
        val=$(gsettings get org.gnome.desktop.wm.keybindings "switch-to-workspace-${i}")
        echo "    switch-to-workspace-${i}: ${val}"
    done
    val=$(gsettings get org.gnome.desktop.wm.keybindings "switch-to-workspace-10")
    echo "    switch-to-workspace-10: ${val}"

    echo ""
    echo "    --- Move window to workspace ---"
    for i in $(seq 1 9); do
        val=$(gsettings get org.gnome.desktop.wm.keybindings "move-to-workspace-${i}")
        echo "    move-to-workspace-${i}: ${val}"
    done
    val=$(gsettings get org.gnome.desktop.wm.keybindings "move-to-workspace-10")
    echo "    move-to-workspace-10: ${val}"

    echo ""
    echo "    --- Multi-monitor ---"
    gsettings get org.gnome.mutter workspaces-only-on-primary \
        | xargs -I{} echo "    workspaces-only-on-primary: {}"

    echo ""
    echo "==> Workspace settings changed"
}

other-shortcuts()
{
    # change alt tab to switch windows and not applications
    gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']" && gsettings set org.gnome.desktop.wm.keybindings switch-applications "['']"
    echo "change alt+tab to switch windows instead of applications"
}

custom-shortcuts()
{
    # shortcut definitions

    declare -A NAMES COMMANDS BINDINGS

    NAMES[0]="Firefox"
    COMMANDS[0]="flatpak run org.mozilla.Firefox"
    BINDINGS[0]="<Super><Shift>p"

    NAMES[1]="Double Commander"
    COMMANDS[1]="doublecmd"
    BINDINGS[1]="<Super><Shift>i"

    NAMES[2]="Terminal (tmux)"
    COMMANDS[2]="gnome-terminal -- tmux new-session zsh"
    BINDINGS[2]="<Super>Return"

    # schema paths

    MEDIA_KEYS="org.gnome.settings-daemon.plugins.media-keys"
    CUSTOM_BASE="${MEDIA_KEYS}.custom-keybinding"
    CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

    # read existing custom shortcuts so we don't wipe them

    existing_list=$(gsettings get "${MEDIA_KEYS}" custom-keybindings)

    # Normalise: strip leading/trailing whitespace + surrounding brackets
    existing_list=$(echo "${existing_list}" | sed "s/^[[:space:]]*\[//;s/\][[:space:]]*$//")

    # Build array of currently used slot numbers so we pick fresh ones
    used_slots=()
    for entry in $(echo "${existing_list}" | tr ',' '\n' | tr -d " '"); do
        [[ -z "$entry" ]] && continue
        num=$(echo "$entry" | grep -oP '(?<=custom)\d+' || true)
        [[ -n "$num" ]] && used_slots+=("$num")
    done

    # assign slot numbers

    new_paths=()
    slot=0

    for i in 0 1 2; do
        # Find next unused slot
        while [[ " ${used_slots[*]} " =~ " ${slot} " ]]; do
            (( slot++ ))
        done

        path="${CUSTOM_PATH}/custom${slot}/"
        new_paths+=("'${path}'")
        used_slots+=("${slot}")

        info "Registering '${NAMES[$i]}' -> [${BINDINGS[$i]}] -> \"${COMMANDS[$i]}\""

        gsettings set "${CUSTOM_BASE}:${path}" name    "${NAMES[$i]}"
        gsettings set "${CUSTOM_BASE}:${path}" command "${COMMANDS[$i]}"
        gsettings set "${CUSTOM_BASE}:${path}" binding "${BINDINGS[$i]}"

        success "Slot custom${slot} written."
        (( slot++ ))
    done

    #  merge new paths into the master list 

    # Collect existing non-empty entries
    existing_entries=()
    for entry in $(echo "${existing_list}" | tr ',' '\n' | tr -d " '"); do
        [[ -n "$entry" ]] && existing_entries+=("'${entry}'")
    done

    all_entries=( "${existing_entries[@]}" "${new_paths[@]}" )

    # Build gsettings list string: ['a', 'b', ...]
    joined=$(printf "%s, " "${all_entries[@]}")
    joined="[${joined%, }]"   # trim trailing ", " and wrap

    gsettings set "${MEDIA_KEYS}" custom-keybindings "${joined}"

    # summary 

    echo ""
    echo "=================================================="
    echo "  Custom shortcuts registered successfully"
    echo "=================================================="
    printf "  %-22s  %s\n" "Shortcut" "Action"
    printf "  %-22s  %s\n" "----------------------" "--------------------------------------"
    printf "  %-22s  %s\n" "Super+Shift+P"  "flatpak run org.mozilla.Firefox"
    printf "  %-22s  %s\n" "Super+Shift+I"  "doublecmd"
    printf "  %-22s  %s\n" "Super+Enter"    "gnome-terminal -- tmux new-session zsh"
    echo ""
    echo "=================================================="
}

main()
{
    # Check that gsettings is available
    command -v gsettings &>/dev/null || error "gsettings not found – is GNOME installed?"
    set -euo pipefail
    workspaces
    custom-shortcuts
}

main $@
