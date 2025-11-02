terraform {
 required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }

  backend "s3" {
    endpoint         = "http://192.168.0.3:9000"
    bucket           = "terraform"
    key              = "proxmox/terraform.tfstate"
    region           = "us-east-1"
    skip_credentials_validation = true
    skip_region_validation      = true
    force_path_style            = true
  }
}

provider "proxmox" {
  pm_api_url      = "${var.PROXMOX_API_HOST}/api2/json"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "vm" {
  for_each    = var.vm_definitions

  vmid        = each.value.vmid
  name        = each.value.name
  target_node = each.value.node
  agent       = 1
  cores       = each.value.cores
  memory      = each.value.memory
  balloon     = each.value.balloon
  boot        = "order=scsi0"
  onboot      = "true"
  startup     = each.value.startupid
  clone       = "debian12-cloudinit"
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  ciupgrade   = true
  cicustom   = "vendor=local:snippets/qemu-guest-agent.yml" # /var/lib/vz/snippets/qemu-guest-agent.yml  
  nameserver  = "100.100.100.100"
  ipconfig0   = each.value.ipconfig0
  ciuser      = "debian"
  cipassword  = "Enter123!"
  sshkeys     = var.ssh_public_key
  tags        = each.value.tags

  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-zfs"
          size    = each.value.disk_size
          discard = "true"
          emulatessd = "true"
          iothread = "true"
          asyncio = "native"
        }
      }
    }

    ide {
      ide1 {
        cloudinit {
          storage = "local-zfs"
        }
      }
    }
  }

  network {
    id      = 0
    bridge  = "vmbr_lan"
    model   = "virtio"
  }
}