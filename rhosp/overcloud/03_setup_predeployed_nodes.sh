#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

if [ -f /home/stack/rhosp-environment.sh ]; then
   source /home/stack/rhosp-environment.sh
else
   echo "File /home/stack/rhosp-environment.sh not found"
   exit
fi

if [ ! -f /home/stack/rhel_provisioning.sh ]; then
   echo "File /home/stack/rhel_provisioning.sh not found"
   exit
fi

if [ ! -f /home/stack/docker_mtu_setup.sh ]; then
   echo "File /home/stack/docker_mtu_setup.sh not found"
   exit
fi



#Removing default gateway if it's defined
check_gateway=$(ip route list | grep -c default)
if (( $check_gateway > 0 )); then
   ip route delete default
   echo default gateway deleted
fi

ip route add default via ${prov_ip} dev eth0
sed -i '/nameserver/d'  /etc/resolv.conf
echo 'nameserver 8.8.8.8' >> /etc/resolv.conf

/home/stack/rhel_provisioning.sh
/home/stack/docker_mtu_setup.sh

echo INSECURE_REGISTRY="--insecure-registry ${prov_ip}:8787" >> /etc/sysconfig/docker
systemctl restart docker

#Heat Stack will fail if INSECURE_REGISTRY is presented in the file
#so we delete it and let Heat to append this later
sed -i '$ d' /etc/sysconfig/docker


