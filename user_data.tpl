#cloud-config
fqdn: ${fqdn}
manage_etc_hosts: true
users:
  - name: ${username}
    passwd: ${password}
    lock_passwd: false
    ssh-authorized-keys:
      - ${jsonencode(trimspace(file("~/.ssh/id_rsa.pub")))}
      - ${ssh_pub}
disk_setup:
  /dev/sdb:
    table_type: mbr
    layout:
      - [100, 83]
    overwrite: false
fs_setup:
  - label: ${data_label}
    device: /dev/sdb1
    filesystem: ext4
    overwrite: false
mounts:
  - [ /dev/sdb1, ${data_mount}, ext4, 'defaults,discard,nofail', '0', '2' ]
runcmd:
  - rm -f /etc/netplan/01-netcfg.yaml
  - sed -i '/vagrant insecure public key/d' /home/systemsupport/.ssh/authorized_keys
  - sudo apt update
  - sudo apt upgrade -y
  - sudo reboot
