Server installieren
/boot partition
/ partition (100GB)

neubooten, netplan anpassen, insbesondere vswitch settings.


  vlans:
    eth0.4000:
      id: 4000
      link: eth0
      mtu: 1400
      addresses:
        - 192.168.100.1/24


ansible-playbook -i hosts.yaml install.yaml
ansible-playbook -i hosts.yaml harden.yaml
ansible-playbook -i hosts.yaml wireguard.yaml

# manuelles anlegen eines zpools

zuerst mit fdisk neue Partitionen erzeugen
fdisk /dev/nvme0n1
fdisk /dev/nvme1n1

prüfen: lsblk

zpool erstellen, jeweils dritte partition

zpool create -o ashift=12 zpool mirror /dev/nvme0n1p3 /dev/nvme1n1p3
zfs set compression=lz4 zpool

zfs create -o compression=lz4 -o mountpoint=/var/log -o atime=off zpool/logs

zfs create -o compression=lz4 -o mountpoint=/var/lib/rancher -o atime=off zpool/rancher
zfs create -o compression=lz4 -o mountpoint=/var/lib/rancher/k3s/agent/containerd/io.containerd.snapshotter.v1.zfs -o atime=off zpool/containerd
zfs create -o compression=lz4 -o mountpoint=/var/lib/kubelet -o atime=off zpool/kubelet

zfs create -o compression=lz4 -o atime=off zpool/pvcs

zfs create zpool/longhorn -V 150G
mkfs.ext4 /dev/zvol/zpool/longhorn
mkdir -p /storage/longhorn
mount -o noatime,discard /dev/zvol/zpool/longhorn /storage/longhorn

in die fstab:

/dev/zvol/zpool/longhorn /storage/longhorn ext4 noatime,discard 0 0


prüfen: 

zfs list

ansible-playbook -i hosts.yaml setup-k3s.yaml

