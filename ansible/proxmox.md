https://blog.admin-intelligence.de/proxmox-zfs-auf-hetzner-server-installieren/

network:




echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
systemctl restart systemd-sysctl



bastion:
https://jpmurray.net/installing-tailscale-on-an-lxc-container-a274f5a24e34
So on the host, edit the /etc/pve/lxc/[container_id].conf file and add the following:
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file


zfs create rpool/k8s_nfs
zfs set sharenfs="rw=@10.10.0.0/24,sync,no_subtree_check,insecure,root_squash,fsid=1" rpool/k8s_nfs

# ZFS-Tuning
zfs set compression=lz4 rpool/k8s_nfs
zfs set atime=off rpool/k8s_nfs
zfs set xattr=sa rpool/k8s_nfs
zfs set acltype=posixacl rpool/k8s_nfs
zfs set recordsize=16K rpool/k8s_nfs

chown nobody:nogroup /rpool/k8s_nfs
chmod 777 /rpool/k8s_nfs

systemctl restart nfs-kernel-server
exportfs -v