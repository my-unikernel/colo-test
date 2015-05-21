#!/bin/sh
# usage
# (1) change @disk_path to your own path of disk image 
# (2) set @dst to your own migration destination ip address
# (3) set @forward_dev to interface for forward packet
# (4) sh primary-colo.sh

disk_path=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img
dst=3.3.3.8
forward_dev=eth1

net_param="-netdev tap,id=hn0,script=/etc/qemu-ifup,downscript=/etc/qemu-ifdown,colo_script=./scripts/colo-proxy-script.sh,colo_nicname=$forward_dev,vhost=on -device virtio-net-pci,id=net-pci0,netdev=hn0"
block_param="-drive if=virtio,driver=quorum,read-pattern=fifo,no-connect=on,children.0.file.filename=$disk_path,children.1.file.driver=nbd,children.1.file.host=$dst,children.1.file.port=8889,children.1.file.export=colo1,children.1.driver=replication,children.1.mode=primary,children.1.ignore-errors=on"
cmdline="x86_64-softmmu/qemu-system-x86_64 -enable-kvm $net_param -boot c $block_param -vnc :7 -m 2048 -smp 2 -device piix3-usb-uhci -device usb-tablet -monitor stdio -S"

echo $cmdline
echo
echo "Please Enter: migrate_set_capability colo on"
echo "Please Enter: migrate tcp:$dst:8888"
echo
modprobe nf_conntrack_colo
modprobe xt_PMYCOLO
modprobe nfnetlink_colo
modprobe xt_mark
modprobe kvm-intel
modprobe nf_conntrack_ipv4
rmmod vhost-net
modprobe vhost-net experimental_zcopytx=0
exec $cmdline
