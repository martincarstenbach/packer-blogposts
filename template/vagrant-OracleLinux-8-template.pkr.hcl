packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

# Reference: https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso
source "virtualbox-iso" "ol8packer" {
  boot_command             = [
    "<esc>", "<wait>", "linux text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ol8.ks", "<enter>"
  ]
  disk_size                = "20480"
  guest_additions_path     = "/home/vagrant/VBoxGuestAdditions.iso"
  guest_os_type            = "Oracle_64"
  hard_drive_interface     = "sata"
  hard_drive_nonrotational = "true"
  hard_drive_discard       = "true"
  http_directory           = "http"
  iso_checksum             = "sha256:REPLACE_ME_SHA256SUM"
  iso_url                  = "file://REPLACE_ME_INSTALL_ISO"
  output_directory         = "output-virtualbox-iso-ol8packer"
  sata_port_count          = "10"
  shutdown_command         = "echo 'packer' | sudo -S shutdown -P now"
  ssh_agent_auth           = true
  ssh_timeout              = "6000s"
  ssh_username             = "vagrant"
  vboxmanage               = [
    ["modifyvm", "{{ .Name }}", "--memory", "2048"], 
    ["modifyvm", "{{ .Name }}", "--cpus", "2"],
    ["modifyvm", "{{.Name}}", "--nat-localhostreachable1", "on" ]

  ]
  vm_name                  = "ol8packer"
}

build {
  sources = [
    "source.virtualbox-iso.ol8packer"
  ]

  provisioner "ansible" {
    playbook_file = "ansible/vagrant-OracleLinux-8-guest-additions.yml"
    user          = "vagrant"
    # avoid "Failed to connect to the host via scp: bash: /usr/lib/sftp-server: No such file or directory"
    # by setting compatibility flags to work around openssh9 features
    extra_arguments = [ "--scp-extra-args", "'-O'" ]
  }

  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "REPLACE_ME_BOXNAME"
  }
}
