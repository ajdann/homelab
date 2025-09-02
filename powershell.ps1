# List all VMs
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' list vms

# Show network info for pfSense
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo "pfsense" --details | Select-String -Pattern "NIC" -Context 0,10

# Show network info for k3s-master
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo "k3s-master" --details | Select-String -Pattern "NIC" -Context 0,10

# Show network info for k3s-worker1
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo "k3s-worker1" --details | Select-String -Pattern "NIC" -Context 0,10

# Show network info for Nessus
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' showvminfo "nessus" --details | Select-String -Pattern "NIC" -Context 0,10



& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm "k3s-master" --nic1 nat
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' modifyvm "k3s-master" --nic2 intnet --intnet2 "k3s-net"
