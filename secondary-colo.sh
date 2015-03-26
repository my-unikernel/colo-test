#!/bin/sh
# usage:
# (1) change @disk_path to your own path of disk image 
# (2) sh secondary-colo.sh 

disk_path=/mnt/sdb/pure_IMG/redhat/redhat-7.0.img
active_disk=/mnt/ramfs/active_disk.img
hidden_disk=/mnt/ramfs/hidden_disk.img

net_param="-netdev tap,id=hn0,colo_script=./scripts/colo-proxy-script.sh,colo_nicname=eth2 -device virtio-net-pci,id=net-pci0,netdev=hn0"
block_param="-drive if=none,driver=raw,file=$disk_path,id=nbd_target1 -drive if=virtio,driver=qcow2+colo,file=$active_disk,export=colo1,backing_reference.drive_id=nbd_target1,backing_reference.hidden-disk.file.filename=$hidden_disk,backing_reference.hidden-disk.driver=qcow2,backing_reference.hidden-disk.allow-write-backing-file=on"
cmdline="x86_64-softmmu/qemu-system-x86_64 -machine pc-i440fx-2.3,accel=kvm,usb=off $net_param -boot c $block_param -vnc :7 -m 192 -smp 1 -device piix3-usb-uhci -device usb-tablet -monitor stdio -incoming tcp:0:8888"

function create_image()
{
    ./qemu-img create -f qcow2 $1 10G
}

function prepare_temp_images()
{
    grep -q "^none /mnt/ramfs ramfs" /proc/mounts
    if [[ $? -ne 0 ]]; then
        mkdir -p /mnt/ramfs/
        mount -t ramfs none /mnt/ramfs/ -o size=4G
    fi

    if [[ ! -e $active_disk ]]; then
        create_image $active_disk
    fi

    if [[ ! -e $hidden_disk ]]; then
        create_image $hidden_disk
    fi
}

prepare_temp_images

echo $cmdline
echo "Please Enter: nbd_server_start 192.168.3.8:8889"
modprobe nf_conntrack_colo
modprobe nf_conntrack_ipv4
modprobe kvm-intel
modprobe vhost-net experimental_zcopytx=0
exec $cmdline
