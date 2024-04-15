in den VMs

network:
  ethernets:
    ens18:
      addresses:
        - 10.0.1.2/24
        - "fd00:1111:2222:0::2/64"
      nameservers:
        addresses: [10.0.1.1]
      routes:
        - to: default
          via: 10.0.1.1
  version: 2

  tailscale up --advertise-routes=10.0.1.2/32,fd00:1111:2222::2/128 --accept-routes