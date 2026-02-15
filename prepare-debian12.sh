#!/usr/bin/env bash

# prepare-debian12.sh
# ---------------------------------------------------------------------------
# A short script to set up packer for building a debian 12 system
#
# Tested and written on Linux Mint 22
#
# Version History
# 241003 initial version
# 241218 update for Oracle Linux 8.10/9.5/Packer 1.11.2/Ansible 11.1.0
#
# Copyright 2025 Martin Bach
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prepares preseed and Packer configuration files for building
# a Debian 12 Vagrant base box.
#
# This script:
#   1. Injects mirror + SSH key into a preseed template
#   2. Calculates ISO SHA256 checksum
#   3. Generates a Packer HCL configuration file
#
# Designed for robustness, safety, and maintainability.

set -euo pipefail
IFS=$'\n\t'
umask 077

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# Colour Handling (enabled only when stdout is a TTY)
# -----------------------------------------------------------------------------

if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    readonly RED="$(tput setaf 1)"
    readonly GREEN="$(tput setaf 2)"
    readonly YELLOW="$(tput setaf 3)"
    readonly BLUE="$(tput setaf 4)"
    readonly RESET="$(tput sgr0)"
else
    readonly RED=""
    readonly GREEN=""
    readonly YELLOW=""
    readonly BLUE=""
    readonly RESET=""
fi

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

# log_info MESSAGE
# Prints informational message in blue.
log_info() {
    printf '%b\n' "${BLUE}INFO:${RESET} $*"
}

# log_warn MESSAGE
# Prints warning message in yellow.
log_warn() {
    printf '%b\n' "${YELLOW}WARN:${RESET} $*" >&2
}

# log_success MESSAGE
# Prints success message in green.
log_success() {
    printf '%b\n' "${GREEN}SUCCESS:${RESET} $*"
}

# die MESSAGE
# Prints error message in red and exits.
die() {
    printf '%b\n' "${RED}ERR:${RESET} $*" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Validation Helpers
# -----------------------------------------------------------------------------

# require_file PATH
# Ensures the given path exists and is a regular file.
require_file() {
    [[ -f "$1" ]] || die "Required file not found: $1"
}

# require_dir PATH
# Ensures the given path exists and is a directory.
require_dir() {
    [[ -d "$1" ]] || die "Required directory not found: $1"
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# escape_sed_replacement STRING
# Escapes characters that are special in sed replacement context.
escape_sed_replacement() {
    printf '%s' "$1" | sed 's/[\/&]/\\&/g'
}

# start_ssh_agent_if_needed
# Verifies ssh-agent availability and starts one if necessary.
# Registers cleanup on exit.
start_ssh_agent_if_needed() {
    if ! ssh-add -l >/dev/null 2>&1; then
        log_info "SSH agent not running, starting it"
        eval "$(/usr/bin/ssh-agent -s)" >/dev/null
        trap 'ssh-agent -k >/dev/null 2>&1 || true' EXIT
    fi
}

# prompt_with_default PROMPT DEFAULT
# Prompts user and returns provided value or default.
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local input

    read -r -p "${prompt} (${default}): " input
    printf '%s\n' "${input:-$default}"
}

# -----------------------------------------------------------------------------
# Main Workflow
# -----------------------------------------------------------------------------

main() {

    log_info "Preparing packer environment for Debian 12 base box"
    printf '\n'

    mkdir -p -- "${SCRIPT_DIR}/http"

    # -------------------------------------------------------------------------
    # Step 1: Preseed file generation
    # -------------------------------------------------------------------------
    readonly DEFAULT_MIRROR="ftp2.de.debian.org"
    readonly DEFAULT_DIR="debian"
    readonly DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub"

    DEBIAN_MIRROR="$(prompt_with_default "Enter your local Debian mirror" "${DEFAULT_MIRROR}")"
    DEBIAN_MIRROR_DIR="$(prompt_with_default "Enter the mirror directory" "${DEFAULT_DIR}")"

    log_info "Available public SSH keys:"
    shopt -s nullglob
    ssh_keys=( "${HOME}"/.ssh/*.pub )
    shopt -u nullglob

    if (( ${#ssh_keys[@]} == 0 )); then
        die "No public SSH keys found in ${HOME}/.ssh/"
    fi

    printf '  %s\n' "${ssh_keys[@]}"
    printf '\n'

    SSH_KEY="$(prompt_with_default "Enter full path to your public SSH key" "${DEFAULT_SSH_KEY}")"
    require_file "${SSH_KEY}"

    VAGRANT_PUBLIC_KEY="$(<"${SSH_KEY}")"

    start_ssh_agent_if_needed

    if ! ssh-add "${SSH_KEY%.pub}" >/dev/null 2>&1; then
        die "Failed to add private key to ssh-agent"
    fi

    require_file "${SCRIPT_DIR}/template/preseed-debian-12-template.cfg"

    escaped_mirror="$(escape_sed_replacement "${DEBIAN_MIRROR}")"
    escaped_mirror_dir="$(escape_sed_replacement "${DEBIAN_MIRROR_DIR}")"
    escaped_key="$(escape_sed_replacement "${VAGRANT_PUBLIC_KEY}")"

    sed \
        -e "s#REPLACE_ME_MIRROR#${escaped_mirror}#" \
        -e "s#REPLACE_ME_DIR#${escaped_mirror_dir}#" \
        -e "s#REPLACE_ME_SSHKEY#${escaped_key}#" \
        "${SCRIPT_DIR}/template/preseed-debian-12-template.cfg" \
        > "${SCRIPT_DIR}/http/preseed.cfg"

    log_success "Preseed file generated (http/preseed.cfg)"
    printf '\n'

    # -------------------------------------------------------------------------
    # Step 2: ISO handling
    # -------------------------------------------------------------------------

    readonly DEFAULT_NETINST_ISO="/m/iso/debian-12.13.0-amd64-netinst.iso"

    NETINST_ISO="$(prompt_with_default "Enter location of Debian 12 netinst ISO" "${DEFAULT_NETINST_ISO}")"
    require_file "${NETINST_ISO}"

    log_info "Calculating SHA256 checksum..."
    SHA256SUM="$(sha256sum -- "${NETINST_ISO}" | awk '{print $1}')"
    log_info "SHA256 = ${SHA256SUM}"
    printf '\n'

    # -------------------------------------------------------------------------
    # Step 3: Vagrant box output location
    # -------------------------------------------------------------------------

    readonly DEFAULT_BOX_LOC="${HOME}/vagrant/boxes/debian-12.13.0.box"

    VAGRANT_BOX_LOC="$(prompt_with_default "Enter full path to store new vagrant box" "${DEFAULT_BOX_LOC}")"

    BOX_DIR="$(dirname -- "${VAGRANT_BOX_LOC}")"
    require_dir "${BOX_DIR}"

    if [[ -e "${VAGRANT_BOX_LOC}" ]]; then
        die "Target box file already exists: ${VAGRANT_BOX_LOC}"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Build target selection
    # -------------------------------------------------------------------------

    read -r -p "Build target (vbox/kvm): " VAGRANT_BUILD_TARGET
    case "${VAGRANT_BUILD_TARGET,,}" in
        kvm)
            VAGRANT_BUILD_TARGET="source.qemu.debian12qemu"
            ;;
        vbox)
            VAGRANT_BUILD_TARGET="source.virtualbox-iso.debian12vbox"
            ;;
        *)
            die "Invalid build target (must be 'kvm' or 'vbox')"
            ;;
    esac

    require_file "${SCRIPT_DIR}/template/vagrant-debian-12-template.pkr.hcl"

    escaped_iso="$(escape_sed_replacement "${NETINST_ISO}")"
    escaped_box="$(escape_sed_replacement "${VAGRANT_BOX_LOC}")"

    sed \
        -e "s#REPLACE_ME_SHA256SUM#${SHA256SUM}#" \
        -e "s#REPLACE_ME_DEBIAN12_NETINST#${escaped_iso}#" \
        -e "s#REPLACE_ME_BOXNAME#${escaped_box}#" \
        -e "s#REPLACE_ME_BUILD_ARCH#${VAGRANT_BUILD_TARGET}#" \
        "${SCRIPT_DIR}/template/vagrant-debian-12-template.pkr.hcl" \
        > "${SCRIPT_DIR}/vagrant-debian-12.pkr.hcl"

    log_success "Packer configuration file generated (vagrant-debian-12.pkr.hcl)"
    printf '\n'

    log_info "Next steps:"
    printf '  packer init vagrant-debian-12.pkr.hcl\n'
    printf '  packer validate vagrant-debian-12.pkr.hcl\n'
    printf '  packer build vagrant-debian-12.pkr.hcl\n'
    printf '\n'
}

main "$@"