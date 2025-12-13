#!/bin/sh

if [[ `command -v virsh >/dev/null 2>&1` -eq "0" ]] && [ "$(id -u)" == "0" ]; then
    for vm in $(virsh list --name); do
	echo "Destroying $vm.";
	virsh destroy $vm; done;
fi
