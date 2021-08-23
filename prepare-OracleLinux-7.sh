#!/usr/bin/env bash

# prepare-OracleLinux-7.sh
# ---------------------------------------------------------------------------
# A short script to set up packer for building an Oracle Linux 7 system
#
# Tested and written on Ubuntu 20.04 LTS
#
# Version History
# 20210823 initial version
#
# Copyright 2021 Martin Bach
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
echo "INFO: preparing your packer environment for the creation of an Oracle Linux 7 Vagrant base box"
echo

if [ ! -d http ]; then
    echo "ERR: must be in the top level directory to execute this script"
    exit 1
fi

# -------------------------- step 1: create the kickstart file

DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub"

echo
/bin/ls -1 ${HOME}/.ssh/*.pub
echo 
read -p "Enter the full path to your public SSH key (${DEFAULT_SSH_KEY}): " SSH_KEY
if [ ! -f "${SSH_KEY:=${DEFAULT_SSH_KEY}}" ]; then
    echo "ERR: ${SSH_KEY} cannot be found, exiting"
    exit 1
fi

VAGRANT_PUBLIC_KEY=$(/bin/cat "${SSH_KEY}")
/usr/bin/ssh-add "${SSH_KEY%.pub}" || echo "INFO: failed to add the SSH key to the agent, this may lead to errors if not corrected"

/bin/sed \
-e "s#REPLACE_ME_SSHKEY#${VAGRANT_PUBLIC_KEY}#" \
template/kickstart-OracleLinux-7-template.ks > http/ol7.ks

# -------------------------- step 2: create the packer build instructions

DEFAULT_INSTALL_ISO="/m/stage/V1009690-01-ol7.9.iso"
DEFAULT_BOX_LOC="${HOME}/vagrant/boxes/ol7_7.9.1.box"

read -p "Enter the location of the Oracle Linux 7 installation media (${DEFAULT_INSTALL_ISO})": INSTALL_ISO
if [ ! -f ${INSTALL_ISO:=${DEFAULT_INSTALL_ISO}} ]; then
    echo "ERR: cannot find ${INSTALL_ISO}, exiting"
    exit 1
fi

echo "INFO: calculating SHA256sum for ${INSTALL_ISO}"
SHA256SUM=$(/usr/bin/sha256sum "${INSTALL_ISO}" | /usr/bin/awk '{print $1}')

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
template/vagrant-OracleLinux-7-template.json > vagrant-ol7.json

# -------------------------- job done

echo
echo "INFO: preparation complete, next run packer validate vagrant-ol7.json && packer build vagrant-ol7.json"
echo