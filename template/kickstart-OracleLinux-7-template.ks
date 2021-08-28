#version=DEVEL

# Simple kickstart file for Oracle Linux 7.x to create the most basic Vagrant base box
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
#
# ONLY TO BE USED TO CREATE A MINIMAL VAGRANT BOX IN THE CONTEXT OF THIS REPOSITORY

# ----------------------- installation settings

cdrom
text

# ----------------------- system settings

# create the vagrant account, password = vagrant as per https://www.vagrantup.com/docs/boxes/base
auth --enableshadow --passalgo=sha512
user --name=vagrant --iscrypted $6$22FQNGFudjDgx9Ss$vkEbaR74hbh8ArfYBoZyFT5QcrMpBN48dhKyFM.bv9ZsIPlbgrP1T86LS7ZB0w7u0M3NgLlveZ/1fRDSx.aNO/
sshkey --username=vagrant "REPLACE_ME_SSHKEY"

# root password = vagrant as per https://www.vagrantup.com/docs/boxes/base
rootpw --iscrypted $6$22FQNGFudjDgx9Ss$vkEbaR74hbh8ArfYBoZyFT5QcrMpBN48dhKyFM.bv9ZsIPlbgrP1T86LS7ZB0w7u0M3NgLlveZ/1fRDSx.aNO/

keyboard --vckeymap=us --xlayouts=us
lang en_US

services --enabled="chronyd"
timezone Europe/London --isUtc

firewall --enabled
selinux --enforcing

# ----------------------- network
network  --bootproto=dhcp
network  --hostname=ol7base

# ----------------------- partitioning and boot loader
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
ignoredisk --only-use=sda
autopart --type=lvm
clearpart --none --initlabel

# ----------------------- software

%packages
@^minimal
@core
chrony
openssh-server
bzip2
unzip
deltarpm
curl
wget
%end

%post --log=/root/ks-post.log

/bin/echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant

%end

reboot