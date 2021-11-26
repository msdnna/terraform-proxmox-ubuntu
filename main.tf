terraform {
  required_providers {
    local	= {
      source	= "hashicorp/local"
      version	= "2.1.0"
    }
    template	= {
      source	= "hashicorp/template"
      version	= "2.2.0"
    }
    proxmox	= {
      source	= "telmate/proxmox"
      version	= "2.9.3"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url	= var.connection.api_uri
  pm_user	= var.connection.api_username
  pm_password	= var.connection.api_password
}

data "template_cloudinit_config" "cloudinit_config" {
  for_each	= var.vms
  base64_encode	= true
  part {
    content_type = "text/cloud-config"
    content	= data.template_file.user_data[each.key].rendered
  }
}

data "template_file" "user_data" {
  for_each	= var.vms
  template	= file("${path.module}/user_data.tpl")
  vars		= {
    fqdn	= format("%s.%s", each.key, each.value.searchdomain)
    username	= each.value.username
    password	= each.value.password
    ssh_pub	= each.value.ssh_pub
    data_label	= each.value.datadisk.label
    data_mount	= each.value.datadisk.mount
  }
}

resource "local_file" "file" {
  for_each	= var.vms
  content_base64 = data.template_cloudinit_config.cloudinit_config[each.key].rendered
  file_permission = 0644
  filename	= "${path.module}/../snippets/${each.key}_cloudinit.yml"
}

resource "proxmox_vm_qemu" "vm_qemu" {
  for_each	= var.vms
  name		= each.key
  vmid		= can(each.value.vmid) ? each.value.vmid : null
  clone		= can(each.value.template) ? each.value.template : "ubuntu-20.04-amd64-pve"
  target_node	= each.value.node
  desc		= can(each.value.description) ? each.value.description : ""
  onboot	= can(each.value.onboot) ? each.value.onboot : true
  boot		= "order=scsi0;ide2;net0"
  agent		= 1
  memory	= each.value.memory
  balloon	= each.value.balloon
  sockets	= each.value.sockets
  cores		= each.value.cores
  cpu		= can(each.value.cpu) ? each.value.cpu : "host"
  numa		= can(each.value.numa) ? each.value.numa : false
  hotplug	= can(each.value.hotplug) ? each.value.hotplug : "network,disk,usb"
  scsihw	= can(each.value.scsihw) ? each.value.scsihw : "virtio-scsi-pci"
  pool		= can(each.value.pool) ? each.value.pool : ""
  os_type	= "cloud-init"
  cicustom	= "user=TERRAFORM:snippets/${each.key}_cloudinit.yml"
  ipconfig0	= each.value.ipconfig0
  nameserver	= each.value.nameserver
  searchdomain	= each.value.searchdomain
  disk {
    type	= "scsi"
    storage	= each.value.osdisk.storage
    size	= each.value.osdisk.size
    format	= can(each.value.osdisk.format) ? each.value.osdisk.format : "qcow2"
    backup	= 1
    ssd		= can(each.value.osdisk.ssd) ? each.value.osdisk.ssd : 0
    discard	= can(each.value.osdisk.discard) ? each.value.osdisk.discard : "ignore"
    cache	= can(each.value.osdisk.cache) ? each.value.osdisk.cache : "none"
  }
  disk {
    type	= "scsi"
    storage	= each.value.datadisk.storage
    size	= each.value.datadisk.size
    format	= can(each.value.datadisk.format) ? each.value.datadisk.format : "qcow2"
    backup	= 1
    ssd		= can(each.value.datadisk.ssd) ? each.value.datadisk.ssd : 0
    discard	= can(each.value.datadisk.discard) ? each.value.datadisk.discard : "ignore"
    cache	= can(each.value.datadisk.cache) ? each.value.datadisk.cache : "none"
  }
  network {
    model	= "virtio"
    bridge	= can(each.value.network.bridge) ? each.value.network.bridge : "vmbr0"
    firewall	= true
  }
  vga {
    type	= can(each.value.vga.type) ? each.value.vga.type : "qxl"
  }
  provisioner "remote-exec" {
    inline = [
      <<-EOF
      set -x
      id
      uname -a
      cat /etc/os-release
      echo "machine-id is $(cat /etc/machine-id)"
      hostname --fqdn
      cat /etc/hosts
      sudo sfdisk -l
      lsblk -x KNAME -o KNAME,SIZE,TRAN,SUBSYSTEMS,FSTYPE,UUID,LABEL,MODEL,SERIAL
      mount | grep ^/dev
      df -h
      EOF
    ]
    connection {
      type      = "ssh"
      user      = each.value.username
      host      = replace(each.value.ipconfig0, "/\\/[0-9][0-9]?,gw=.*|ip=/", "")
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

output "IPs" {
   # value = tomap({ for ip, vm in proxmox_vm_qemu.vm_qemu : ip => length(vm.default_ipv4_address) > 0 ? jsonencode(vm.default_ipv4_address) : "" })
  value = tomap({ for ip, vm in var.vms : ip => replace(vm.ipconfig0, "/\\/[0-9][0-9]?,gw=.*|ip=/", "") })
}
