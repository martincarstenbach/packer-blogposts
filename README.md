# HashiCorp Packer examples

Code examples from my blog covering [Packer](https://www.packer.io/), [Ansible](https://www.ansible.com/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/). Now including the [libvirt-provider](https://github.com/vagrant-libvirt/vagrant-libvirt) for Vagrant as well. See <https://martincarstenbach.wordpress.com/> for more details.

## Usage

The code in this repository allows you to create a local Vagrant base box meeting [the requirements](https://www.vagrantup.com/docs/boxes/base) documented by HashiCorp as conveniently as possible. Although I tried to be quite generic in the way the code is written, I wrote it for myself and, nor won't guarantee it works for you. Please refer to the [License](LICENSE) for details.

For each Packer build I implemented you'll find a `prepare-*.sh` script prompting you for input before creating the Packer HCL file. Each build contains a set of templates in the `template` folder. Placeholders in the templates will be substituted with your answers. Once that's completed, a build file will be present in the top level directory for you to run. Make sure you check the auto-generated file for correctness. As I said before, this file works for what I need it to do, your directory structure is most likely different.

It is assumed you verified the installation media, most notably the SHA256 checksums, before using them.

Once the base install is complete, Ansible playbooks are executed, installing Virtual Box [Guest Additions](https://www.virtualbox.org/manual/ch04.html) matching your VirtualBox version in case you build your Vagrant box for this platform. Building for KVM doesn't require this step.

If you get the following message when validating the generated HCL file you will need to install the plugins as per the instructions on screen.

```
Error: Missing plugins

The following plugins are required, but not installed:

* github.com/hashicorp/ansible ~> 1
* github.com/hashicorp/qemu ~> 1
* github.com/hashicorp/vagrant ~> 1

Did you run packer init for this project ?
```

## Warning

Virtual Box Guest Additions work best when Dynamic Kernel Module Support (DKMS) is present on your system. If you have them installed, Virtualbox guest additions (= kernel modules) are automatically created as part of a kernel upgrade. DKMS is _not_ required, but due to its usefulness I opted to _include it in my build_. This would be too good to be true if it didn't came with a caveat.

Oracle Linux 8 doesn't ship DKMS in the standard repositories, you need to enable the Extra Packages for Enterprise Linux (EPEL) repository to install the RPM. As per <https://yum.oracle.com>, the EPEL repository for [Oracle Linux 8](https://yum.oracle.com/oracle-linux-8.html) is listed in *Packages for Test and Development*. Quoting Oracle:

> Note: The contents in the following repositories are for development purposes only. Oracle suggests these not be used in production.

This is really important! Please make sure you understand the implications in case you plan to use the code in this repository! If you can't use the EPEL packages, don't use this code.

## Notes

This repository's code was written using Fedora 38 on x86-64 using the following software:

- ansible-7.7.0-1.fc38.noarch
- ansible-core-2.14.8-1.fc38.noarch
- ansible-packaging-1-10.fc38.noarch
- ansible-srpm-macros-1-10.fc38.noarch
- packer-1.9.4-1.x86_64
- vagrant-2.3.7-1.x86_64
- VirtualBox 7.0.10

Packer and Vagrant have been downloaded from HashiCorp's YUM repository. VirtualBox has been downloaded from <https://www.virtualbox.org>

> Before installing software always make sure you read, understand and abide by the license agreement!

## Version History

Major milestones - all the history can be found in Git.

| Date | Comment |
| -- | -- |
| 210820  | initial commit |
| in between  | further minor revisions |
| 221031 | update for OL8.5, Packer 1.8 and Ansible 2.10.x |
| 230912 | update to Packer 1.9.4 and HCL2, dropped support for Oracle Linux 7 |
| 231003 | fixes for Debian 11 and 12, add support for `vagrant-libvirt` |