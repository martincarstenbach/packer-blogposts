#!/usr/bin/env bash

# prepare-debian11.sh
# ---------------------------------------------------------------------------
# A short script to set up packer for building a debian 11 system
#
# Tested and written on Ubuntu 20.04 LTS
#
# Version History
# 20210823 initial version
# 20221031 maintenance updates
# 20230915 update for HCL2 and Packer 1.9.x
#
# Copyright 2023 Martin Bach
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
echo "INFO: preparing your packer environment for the creation of a Debian 11 Vagrant base box"
echo

# need to create the http directory, it will contain the customised preseed file
[[ ! -d http ]] && mkdir http

# -------------------------- step 1: create the preseed file 

DEFAULT_MIRROR="http://ftp2.de.debian.org"
DEFAULT_MIRROR_DIR="/debian"
DEFAULT_SSH_KEY="${HOME}/.ssh/id_rsa.pub"

read -p "Enter your local Debian mirror (${DEFAULT_MIRROR}): " DEBIAN_MIRROR
read -p "Enter the mirror directory (${DEFAULT_MIRROR_DIR}): " DEBIAN_MIRROR_DIR

echo
/bin/ls -1 ${HOME}/.ssh/*.pub
echo 
read -p "Enter the full path to your public SSH key (${DEFAULT_SSH_KEY}): " SSH_KEY
if [ ! -f "${SSH_KEY:=${DEFAULT_SSH_KEY}}" ]; then
    echo "ERR: ${SSH_KEY} cannot be found, exiting"
    exit 1
fi

VAGRANT_PUBLIC_KEY=$(/bin/cat "${SSH_KEY}")
/usr/bin/ssh-add "${SSH_KEY%.pub}" || {
    echo "INFO: failed to add the SSH key to the agent, check logs"
    exit 1
}

/bin/sed \
-e "s#REPLACE_ME_MIRROR_DIR#${DEBIAN_MIRROR_DIR:-${DEFAULT_MIRROR_DIR}}#" \
-e "s#REPLACE_ME_MIRROR#${DEBIAN_MIRROR:-${DEFAULT_MIRROR}}#" \
-e "s#REPLACE_ME_SSHKEY#${VAGRANT_PUBLIC_KEY}#" \
template/preseed-debian-11-template.cfg > http/preseed.cfg

# -------------------------- step 2: create the packer build instructions

DEFAULT_NETINST_ISO="/m/stage/debian-11.7.0-amd64-netinst.iso"
DEFAULT_BOX_LOC="${HOME}/vagrant/boxes/debian-11.7.0.box"

read -p "Enter the location of the Debian 11 network installation media (${DEFAULT_NETINST_ISO})": NETINST_ISO
if [ ! -f ${NETINST_ISO:=${DEFAULT_NETINST_ISO}} ]; then
    echo "ERR: cannot find ${NETINST_ISO}, exiting"
    exit 1
fi

SHA256SUM=$(/usr/bin/sha256sum "${NETINST_ISO}" | /usr/bin/awk '{print $1}')

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
-e "s#REPLACE_ME_DEBIAN11_NETINST#${NETINST_ISO}#" \
-e "s#REPLACE_ME_BOXNAME#${VAGRANT_BOX_LOC}#" \
template/vagrant-debian-11-template.pkr.hcl > vagrant-debian-11.pkr.hcl

# -------------------------- job done

echo
echo "INFO: preparation complete, next run packer init && packer validate vagrant-debian-11.pkr.hcl "
echo "INFO: followed by packer build vagrant-debian-11.pkr.hcl"
echo