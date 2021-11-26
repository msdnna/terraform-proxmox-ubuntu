# Usage (Ubuntu 20.04 host)

Create and install the [base Ubuntu vagrant box](https://github.com/msdnna/ubuntu-vagrant).

**Install Terraform:**

```bash
wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
unzip terraform_1.0.11_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

**Before deployment, connect the common directory with snippets to the Proxmox node, as well as to the machine from which you plan to deploy:**

>On Terraform machine:

```bash
mount SHARE_IP:/path/on/nfs/share /path/on/terraform/machine
mv terraform-proxmox-ubuntu /path/on/terraform/machine
cd /path/on/terraform/machine/terraform-proxmox-ubuntu
```

>On Proxmox node:

![alt text](https://github.com/msdnna/terraform-proxmox-ubuntu/blob/master/add_terraform_storage.png?raw=true)

**Create the infrastructure:**

```bash
terraform init
terraform plan
terraform apply
```

**Destroy the infrastructure:**

```bash
terraform destroy
```

**Example terraform.tfvars:**

```
connection = {
  api_uri       = "https://proxmox_url:8006/api2/json"
  api_username  = "terraform@pve"
  api_password  = "secret"
}

vms = {
  host-dev-01 = {
    vmid        = 301
    node        = "proxmox-01"
    description = "Development VM"
    pool        = "Terraform"
    memory      = 2048          # [MiB]
    balloon     = 2048          # [MiB]
    sockets     = 1
    cores       = 2
    username    = "administrator"
    password    = "secret"
    ipconfig0   = "ip=192.168.1.11/24,gw=192.168.1.1"   # Format: ip=x.x.x.x/xx,gw=x.x.x.x
    nameserver  = "192.168.1.2 192.168.1.1"             # Format: dns1 dns2 ... dns99
    searchdomain = "domain.local"                       # Format: domain1 domain2 ... domain99
    ssh_pub     = "ssh-rsa AAAA... user@you.localdomain"
    osdisk = {
      storage   = "nvmePool-VM"
      size      = "8G"          # [GiB]
      ssd       = 1
      discard   = "on"          # Format: on/ignore
    }
    datadisk = {
      storage   = "RAIDPool-VM"
      size      = "32G"         # [GiB]
      cache     = "writeback"   # none/direct/writethrough/writeback/unsafe
      label     = "data"        # ext4 FS label
      mount     = "/data"       # ext4 mountpoint
    }
  }
  srvprod-01 = {
    vmid        = 302
    node        = "proxmox-01"
    description = "Production VM"
    pool        = "Terraform"
    memory      = 4096          # [MiB]
    balloon     = 4096          # [MiB]
    sockets     = 1
    cores       = 2
    username    = "administrator"
    password    = "secret"
    ipconfig0   = "ip=192.168.1.12/24,gw=192.168.1.1"   # Format: ip=x.x.x.x/xx,gw=x.x.x.x
    nameserver  = "192.168.1.2 192.168.1.1"             # Format: dns1 dns2 ... dns99
    searchdomain = "domain.local"                       # Format: domain1 domain2 ... domain99
    ssh_pub     = "ssh-rsa AAAA... user@you.localdomain"
    osdisk = {
      storage   = "nvmePool-VM"
      size      = "16G"          # [GiB]
      ssd       = 1
      discard   = "on"          # Format: on/ignore
    }
    datadisk = {
      storage   = "RAIDPool-VM"
      size      = "32G"         # [GiB]
      cache     = "writeback"   # none/direct/writethrough/writeback/unsafe
      label     = "data"        # ext4 FS label
      mount     = "/data"       # ext4 mountpoint
    }
  }
}
```
