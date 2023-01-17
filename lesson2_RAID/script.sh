#!/bin/bash
sdx="/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf"
for i in $sdx; do
echo "n\np\n1\n\nt\nfd\nw" | fdisk $i;done
