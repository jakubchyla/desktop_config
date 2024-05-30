#! /usr/bin/env sh

CURRENT_DIR="$(pwd)"
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
if [ "$1" = "zeus" ]; then
    ANSIBLE_OPTIONS="-i inventory_zeus.yaml --skip-tags kernel_sound_module"
elif [ "$1" = "poseidon" ]; then
    ANSIBLE_OPTIONS="-i inventory_poseidon.yaml --skip-tags KDE"
else
    printf "%s\n" "unknown host, exiting..." 1>&2
    exit 1
fi

# run ansible
cd "${SCRIPT_DIR}/ansible" || { printf "%s\n" "${SCRIPT_DIR}/ansible doesn't exist!" 1>&2; exit 1; }
ansible-playbook site.yaml $ANSIBLE_OPTIONS
cd "$CURRENT_DIR"
