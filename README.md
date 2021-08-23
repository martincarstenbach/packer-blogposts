# HashiCorp Packer examples

Code examples from my blog covering Packer, Ansible, Vagrant and VirtualBox. See https://martincarstenbach.wordpress.com/ for more details.

## Usage

The code in this repository allows you to create a local Vagrant base box meeting [the requirements](https://www.vagrantup.com/docs/boxes/base) documented by HashiCorp as conveniently as possible. Although I tried to be quite generic in the way the code is written, I wrote it for myself and, nor won't guarantee it works for you. Please refer to the [License](LICENSE) for details.

For each Packer build I implemented you'll find a `prepare-*.sh` script prompting you for input before creating the Packer JSON file. Each build contains a set of templates in the `template` folder. Placeholders in the templates will be substituted with your answers. Once that's completed, a build file will be present in the top level directory for you to run.

It is assumed you verified the installation media, most notably the SHA256 checksums.

Once the base install is complete, Ansible playbooks are executed, installing Virtual Box [Guest Additions](https://www.virtualbox.org/manual/ch04.html) matching your VirtualBox version.

## Warning

Virtual Box Guest Additions work best when Dynamic Kernel Module Support (DKMS) is present on your system. If you have them installed, Virtualbox guest additions (= kernel modules) are automatically created as part of a kernel upgrade. DKMS is _not_ required, but due to its usefulness I opted to _include it in my build_. This would be too good to be true if it didn't came with a caveat.

Oracle Linux 7 and 8 don't ship DKMS in the standard repositories, you need to enable the Extra Packages for Enterprise Linux (EPEL) repository to install the RPM. As per https://yum.oracle.com, the EPEL repository for both [Oracle Linux 7](https://yum.oracle.com/oracle-linux-7.html) and [Oracle Linux 8](https://yum.oracle.com/oracle-linux-8.html) is listed in *Packages for Test and Development*. Quoting Oracle:

> Note: The contents in the following repositories are for development purposes only. Oracle suggests these not be used in production.

This is really important! Please make sure you understand the implications in case you plan to use the code in this repository! If you can't use the EPEL packages, don't use this code.

## Examples

The process of creating Vagrant base boxes is documented on my blog.

- [Debian 11](https://martincarstenbach.wordpress.com/)
- [Oracle Linux 7](https://martincarstenbach.wordpress.com/)
- [Oracle Linux 8](https://martincarstenbach.wordpress.com/)

## Notes

This repository's code was developed on Ubuntu 20.04 LTS using

- Ansible 2.9
- Packer 1.7
- VirtualBox 6.1.26