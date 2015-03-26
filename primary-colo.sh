#!/bin/sh
# (1) change @disk_path to your own path of disk image 
# (2) sh primary-colo.sh 

disk_path=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img

net_param="-netdev tap,id=hn0,colo_script=./scripts/colo-proxy-script.sh,colo_nicname=eth2 -device virtio-net-pci,id=net-pci0,netdev=hn0"
block_param="-drive if=virtio,driver=quorum,read-pattern=fifo,children.0.file.filename=$disk_path,children.0.driver=raw,children.1.file.driver=nbd+colo,children.1.file.host=192.168.3.8,children.1.file.port=8889,children.1.file.export=colo1,children.1.driver=raw,children.1.ignore-errors=on"

cmdline="x86_64-softmmu/qemu-system-x86_64 -machine pc-i440fx-2.3,accel=kvm,usb=off $net_param -boot c $block_param -vnc :7 -m 192 -smp 1 -device piix3-usb-uhci -device usb-tablet -monitor stdio -S"

echo $cmdline
echo "Please Enter: migrate_set_capability colo on"
echo "Please Enter: migrate tcp:192.168.3.8:8888"
modprobe nf_conntrack_colo
modprobe xt_mark
modprobe kvm-intel
modprobe nf_conntrack_ipv4
rmmod vhost-net
modprobe vhost-net experimental_zcopytx=0
exec $cmdline
