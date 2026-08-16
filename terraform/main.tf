terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc09"
    }
  }
}

# docs for vm_qemu
# https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md


provider "proxmox" {
  pm_api_url          = "https://192.168.2.93:8006/api2/json"
  pm_tls_insecure     = true # By default Proxmox Virtual Environment uses self-signed certificates.
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
}


resource "proxmox_vm_qemu" "k3s-node" {
  count              = 1
  name               = "k3s-node-${count.index + 1}"
  target_node        = var.proxmox_host
  agent              = 1
  memory             = 8192
  boot               = "order=scsi0" # has to be the same as the OS disk of the template
  clone              = var.template_name
  full_clone         = true
  scsihw             = "virtio-scsi-single"
  automatic_reboot   = true
  start_at_node_boot = true

  cpu { cores = 2 }

  # vm_state         = "running"

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml
  ciupgrade  = true
  nameserver = "1.1.1.1 8.8.8.8"
  ipconfig0  = "ip=192.168.2.12${count.index + 1}/24,gw=192.168.2.1"
  skip_ipv6  = true
  ciuser     = "root"
  cipassword = "password"
  sshkeys    = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDe5dCm4KjWTm6Dbjezf1XxbvxStk/zxDJoHNqJ2Lv9U margo@DESKTOP-K4INHQG
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILqCke7fIY95QRmvTpn5tOMMfeHkH6eBA7uG5USzuozA margo@DESKTOP-K4INHQG
EOF

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "data" # name of my proxmox disk
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size     = "40G"
          iothread = true
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = "data"
        }
      }
    }
  }

  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}
