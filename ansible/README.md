Server installieren
/boot partition
/ partition (50GB)

neubooten, netplan anpassen, insbesondere vswitch settings.


  vlans:
    eno1.4000:
      id: 4000
      link: eno1
      mtu: 1400
      addresses:
        - 10.0.1.2/24
        - "fd00:1111:2222:0::2/64"
      routes:
        - to: 10.0.0.0/24
          via: 10.0.1.1

tailscale installieren und jeweils registrieren

z.B. 
tailscale up --advertise-routes=10.0.1.2/32,fd00:1111:2222::2/128 --accept-routes
ansible-playbook -i hosts.yaml install.yaml
ansible-playbook -i hosts.yaml harden.yaml
#ansible-playbook -i hosts.yaml wireguard.yaml

# manuelles anlegen eines zpools

zuerst mit fdisk neue Partitionen erzeugen
fdisk /dev/nvme0n1
fdisk /dev/nvme1n1

prüfen: lsblk

zpool erstellen, jeweils dritte partition

zpool create -o ashift=12 zpool /dev/nvme0n1p3 /dev/nvme1n1p3
zfs set compression=lz4 zpool

zfs create -o compression=lz4 -o mountpoint=/var/lib/rancher -o atime=off zpool/rancher
zfs create -o compression=lz4 -o mountpoint=/var/lib/kubelet -o atime=off zpool/kubelet

zfs create -o compression=lz4 -o atime=off zpool/pvcs
zfs create -o compression=lz4 -o atime=off zpool/pg-pvcs

zfs create zpool/longhorn -V 600G
mkfs.xfs /dev/zvol/zpool/longhorn
mkdir -p /storage/longhorn
mount -o noatime,discard /dev/zvol/zpool/longhorn /storage/longhorn

in die fstab:

/dev/zvol/zpool/longhorn /storage/longhorn xfs noatime,discard 0 0


prüfen: 

zfs list

ansible-playbook -i hosts.yaml setup-k3s.yaml

