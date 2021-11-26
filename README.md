# Usage (Ubuntu 20.04 host)

Create and install the [base Ubuntu vagrant box](https://github.com/msdnna/ubuntu-vagrant).

Install Terraform:

```bash
wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip
unzip terraform_1.0.11_linux_amd64.zip
sudo install terraform /usr/local/bin
rm terraform terraform_*_linux_amd64.zip
```

Before deployment, connect the common directory with snippets to the Proxmox node, as well as to the machine from which you plan to deploy: 

```bash
mount SHARE_IP:/path/on/nfs/share /path/on/terraform/machine
mv terraform-proxmox-ubuntu /path/on/terraform/machine
cd /path/on/terraform/machine/terraform-proxmox-ubuntu
```

![alt text](https://github.com/msdnna/terraform-proxmox-ubuntu/blob/master/add_terraform_storage.png?raw=true)

Create the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

Destroy the infrastructure:

```bash
terraform destroy
```
