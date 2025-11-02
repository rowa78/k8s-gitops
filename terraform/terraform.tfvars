ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMk2F84s8jly921L4YmuhpeTCoiGX+yrorkOUTGHXr4 ronny@Ronnys-MacBook-Pro-2.local"

vm_definitions = {
  master01 = {
    vmid       = 100
    name       = "master01"
    node       = "discovery"
    cores      = 2
    memory     = 4096
    balloon    = 2048
    disk_size  = "32G"
    ipconfig0  = "ip=10.1.0.10/24,gw=10.1.0.1"
    startupid  = "order=10"
    tags       = "k8s,master"
  }  
  master02 = {
    vmid       = 101
    name       = "master02"
    node       = "voyager"
    cores      = 2
    memory     = 4096
    balloon    = 2048
    disk_size  = "32G"
    ipconfig0  = "ip=10.1.1.10/24,gw=10.1.1.1"
    startupid  = "order=10"
    tags       = "k8s,master"
  }
  worker01 = {
    vmid       = 110
    name       = "worker01"
    node       = "discovery"
    cores      = 10
    memory     = 24576
    balloon    = 16384
    disk_size  = "350G"
    ipconfig0  = "ip=10.1.0.20/24,gw=10.1.0.1"
    startupid  = "order=20"      
    tags       = "k8s,worker"
  }  
  worker02 = {
    vmid       = 111
    name       = "worker02"
    node       = "voyager"
    cores      = 10
    memory     = 24576
    balloon    = 16384
    disk_size  = "350G"
    ipconfig0  = "ip=10.1.1.20/24,gw=10.1.1.1"
    startupid  = "order=20"      
    tags       = "k8s,worker"
  }
  worker03 = {
    vmid       = 112
    name       = "worker03"
    node       = "discovery"
    cores      = 10
    memory     = 24576
    balloon    = 16384
    disk_size  = "350G"
    ipconfig0  = "ip=10.1.0.21/24,gw=10.1.0.1"
    startupid  = "order=21"    
    tags       = "k8s,worker"
  }  
  worker04 = {
    vmid       = 113
    name       = "worker04"
    node       = "voyager"
    cores      = 10
    memory     = 24576
    balloon    = 16384
    disk_size  = "350G"
    ipconfig0  = "ip=10.1.1.21/24,gw=10.1.1.1"
    startupid  = "order=21"    
    tags       = "k8s,worker"
  }
  tools = {
    vmid       = 200
    name       = "tools"
    node       = "voyager"
    cores      = 10
    memory     = 16000
    balloon    = 4096
    disk_size  = "100G"
    ipconfig0  = "ip=10.1.1.99/24,gw=10.1.1.1"
    startupid  = "order=30"   
    tags       = "tools"     
  }
}