#!/usr/bin/env bash

# prepare-OracleLinux-8.sh
# ---------------------------------------------------------------------------
# A short script to set up packer for building an Oracle Linux 8 system
# Refer to the readme file for details
#
# Version History
# 20210823 initial version
# 20221031 update for Oracle Linux 8.5/Packer 1.8.x/Ansible 2.10.x
#
# Copyright 2022 Martin Bach
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

set -euo pipefail

echo
echo "INFO: preparing packer build instructions for the creation of an Oracle Linux 8 Vagrant base box"
echo

# need to create the http directory, it will contain the customised kickstart file
[[ ! -d http ]] && mkdir http

# -------------------------- step 1: create the kickstart file

DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub"

/bin/ls -1 ${HOME}/.ssh/*.pub
echo 
read -p "Enter the full path to your public SSH key (${DEFAULT_SSH_KEY}): " SSH_KEY
if [ ! -f "${SSH_KEY:=${DEFAULT_SSH_KEY}}" ]; then
    echo "ERR: ${SSH_KEY} cannot be found, exiting"
    exit 1
fi

VAGRANT_PUBLIC_KEY=$(/bin/cat "${SSH_KEY}")

echo
echo "INFO: adding the SSH key to the agent"

# start the SSH agent if it is not yet started
[[ -z ${SSH_AGENT_PID} ]] && { 
    echo "INFO: SSH agent not yet started, starting it now"
    eval $(/usr/bin/ssh-agent)
}

/usr/bin/ssh-add "${SSH_KEY%.pub}" || {
    echo "ERR: failed to add the SSH key to the agent, check logs"
    exit 1
}

/bin/sed \
-e "s#REPLACE_ME_SSHKEY#${VAGRANT_PUBLIC_KEY}#" \
template/kickstart-OracleLinux-8-template.ks > http/ol8.ks

echo
echo "INFO: kickstart file ready"
echo
# -------------------------- step 2: create the packer build instructions

DEFAULT_INSTALL_ISO="/m/stage/OracleLinux-R8-U8-x86_64-dvd.iso"
DEFAULT_BOX_LOC="${HOME}/vagrant/boxes/ol8_8.8.0.box"

read -p "Enter the location of the Oracle Linux 8 installation media (${DEFAULT_INSTALL_ISO})": INSTALL_ISO
if [ ! -f ${INSTALL_ISO:=${DEFAULT_INSTALL_ISO}} ]; then
    echo "ERR: cannot find ${INSTALL_ISO}, exiting"
    exit 1
fi

echo
echo "INFO: calculating SHA256sum for ${INSTALL_ISO}"
SHA256SUM=$(/usr/bin/sha256sum "${INSTALL_ISO}" | /usr/bin/awk '{print $1}')
echo

read -p "Enter the full path to store the new vagrant box (${DEFAULT_BOX_LOC}):" VAGRANT_BOX_LOC 
if [ ! -d $(/usr/bin/dirname ${VAGRANT_BOX_LOC:=${DEFAULT_BOX_LOC}}) ]; then
    echo "ERR: $(/usr/bin/dirname ${VAGRANT_BOX_LOC}) is not a directory, exiting"
    exit 1
elif [ -f "${VAGRANT_BOX_LOC:=${DEFAULT_BOX_LOC}}" ]; then
    echo "ERR: ${VAGRANT_BOX_LOC} exists, exiting"
    exit 1
fi

/bin/sed \
-e "s#REPLACE_ME_SHA256SUM#${SHA256SUM}#" \
-e "s#REPLACE_ME_INSTALL_ISO#${INSTALL_ISO}#" \
-e "s#REPLACE_ME_BOXNAME#${VAGRANT_BOX_LOC}#" \
template/vagrant-OracleLinux-8-template.pkr.hcl > vagrant-ol8.pkr.hcl

# -------------------------- job done

echo
echo "INFO: preparation complete, next run packer validate vagrant-ol8.pkr.hcl && packer build vagrant-ol8.pkr.hcl"
echo