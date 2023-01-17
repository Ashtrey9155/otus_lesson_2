## otus_lesson #2
### Добавить в Vagrantfile еще дисков
<details>
В файл *Vagrantfile* добавил 5й диск
>:sata5 => {
			:dfile => './disk5.vdi',
			:size => 250,
			:port => 5
>		}

Список добавленных дисков можно получить командой lshw
>**vagrant@otuslearn:\~$ sudo lshw -short | grep disk** \
/0/3/0.0.0    /dev/sda   disk       42GB VBOX HARDDISK \
/0/4/0.0.0    /dev/sdb   disk       262MB VBOX HARDDISK \
/0/5/0.0.0    /dev/sdc   disk       262MB VBOX HARDDISK \
/0/6/0.0.0    /dev/sdd   disk       262MB VBOX HARDDISK \
/0/7/0.0.0    /dev/sde   disk       262MB VBOX HARDDISK \
/0/8/0.0.0    /dev/sdf   disk       262MB VBOX HARDDISK \
>vagrant@otuslearn:~$ 

Далее создадим RAID6 на основе наших дисков:
>**vagrant@otuslearn:\~$ cat /proc/mdstat** \
Personalities : [raid6] [raid5] [raid4] \
md0 : active raid6 sdf[4] sde[3] sdd[2] sdc[1] sdb[0] \
      766464 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU] \
      \
unused devices: <none> \
>vagrant@otuslearn:~$ \

>**vagrant@otuslearn:\~$ sudo mdadm --detail --scan --verbose** \
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=otuslearn:0 UUID=7cae2cc1:804951b0:d37f597f:3225ed27 \
   devices=/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf \
>vagrant@otuslearn:~$ \
</details>


### Сломать/починить RAID
<details>

Зафейлим диск
>**root@otuslearn:/home/vagrant# mdadm /dev/md0 --fail /dev/sde** \
mdadm: set /dev/sde faulty in /dev/md0 \
 \
**root@otuslearn:/home/vagrant# cat /proc/mdstat** \
Personalities : [raid6] [raid5] [raid4] \
md0 : active raid6 sdf[4] sde[3](F) sdd[2] sdc[1] sdb[0] \
      766464 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/4] [UUU_U] \
 \
unused devices: <none> \
root@otuslearn:/home/vagrant#
 \
**root@otuslearn:/home/vagrant# mdadm -D /dev/md0** \
/dev/md0: \
        Version : 1.2 \
  Creation Time : Tue Jan 17 16:33:13 2023 \
     Raid Level : raid6 \
     Array Size : 766464 (748.63 MiB 784.86 MB) \
  Used Dev Size : 255488 (249.54 MiB 261.62 MB) \
   Raid Devices : 5 \
  Total Devices : 5 \
    Persistence : Superblock is persistent \
 \
           Name : otuslearn:0  (local to host otuslearn) \
           UUID : 7cae2cc1:804951b0:d37f597f:3225ed27 \
         Events : 19 \
 \
    Number   Major   Minor   RaidDevice State \
       0       8       16        0      active sync   /dev/sdb \
       1       8       32        1      active sync   /dev/sdc \
       2       8       48        2      active sync   /dev/sdd \
       3       0        0        3      removed \
       4       8       80        4      active sync   /dev/sdf \
 \
       3       8       64        -      faulty spare   /dev/sde \
root@otuslearn:/home/vagrant# \
 \
**root@otuslearn:/home/vagrant# cat /proc/mdstat** \
Personalities : [raid6] [raid5] [raid4] \
md0 : active raid6 sde[5](F) sdf[4] sdd[2] sdc[1] sdb[0] \
      766464 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/4] [UUU_U] \
      \
unused devices: <none> \
 \
**root@otuslearn:/home/vagrant# mdadm /dev/md0 --remove /dev/sde** \
mdadm: hot removed /dev/sde from /dev/md0 \
**root@otuslearn:/home/vagrant# mdadm /dev/md0 --add /dev/sde** \
mdadm: added /dev/sde \
**root@otuslearn:/home/vagrant# cat /proc/mdstat** \
Personalities : [raid6] [raid5] [raid4] \
md0 : active raid6 sde[5] sdf[4] sdd[2] sdc[1] sdb[0] \
      766464 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/4] [UUU_U] \
      [============>........]  recovery = 60.8% (155912/255488) finish=0.0min speed=77956K/sec \
      
>unused devices: <none> \
root@otuslearn:/home/vagrant# \
**root@otuslearn:/home/vagrant# cat /proc/mdstat** \
Personalities : [raid6] [raid5] [raid4] \
md0 : active raid6 sde[5] sdf[4] sdd[2] sdc[1] sdb[0] \
      766464 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU] \
      
>unused devices: <none> \
>root@otuslearn:/home/vagrant# 
</details>

### Создать GPT раздел, пять партиций и смонтировать их на диск

<details>
	
```
**root@otuslearn:/home/vagrant# parted -s /dev/md0 mklabel gpt**
**root@otuslearn:/home/vagrant# parted /dev/md0 print free**
Model: Linux Software RAID Array (md)
Disk /dev/md0: 785MB 
Sector size (logical/physical): 512B/512B
Partition Table: gpt 

Number  Start   End    Size   File system  Name  Flags 
        17.4kB  785MB  785MB  Free Space 


**root@otuslearn:/home/vagrant# parted /dev/md0 print** 
Model: Linux Software RAID Array (md) 
Disk /dev/md0: 785MB \
Sector size (logical/physical): 512B/512B 
Partition Table: gpt 
 
Number  Start  End  Size  File system  Name  Flags 
 
**root@otuslearn:/home/vagrant# 
**root@otuslearn:/home/vagrant# parted /dev/md0 mkpart primary ext4 0% 20%** 
>Information: You may need to update /etc/fstab. 

**root@otuslearn:/home/vagrant# parted /dev/md0 mkpart primary ext4 20% 40%** 
>Information: You may need to update /etc/fstab. 

**root@otuslearn:/home/vagrant# parted /dev/md0 mkpart primary ext4 40% 60%** 
>Information: You may need to update /etc/fstab. 

**root@otuslearn:/home/vagrant# parted /dev/md0 mkpart primary ext4 60% 80%** 
>Information: You may need to update /etc/fstab. 

**root@otuslearn:/home/vagrant# parted /dev/md0 mkpart primary ext4 80% 100%** 
>Information: You may need to update /etc/fstab. 

**root@otuslearn:/home/vagrant# parted /dev/md0 print free 
>Model: Linux Software RAID Array (md) 
Disk /dev/md0: 785MB 
Sector size (logical/physical): 512B/512B 
Partition Table: gpt 
 
Number  Start   End     Size    File system  Name     Flags 
        17.4kB  1573kB  1555kB  Free Space 
 1      1573kB  157MB   156MB                primary 
 2      157MB   315MB   157MB                primary 
 3      315MB   470MB   156MB                primary 
 4      470MB   628MB   157MB                primary 
 5      628MB   783MB   156MB                primary 
        783MB   785MB   1556kB  Free Space 

**root@otuslearn:/home/vagrant# mkdir -p /raid/part{1,2,3,4,5}** 
**root@otuslearn:/home/vagrant# for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done** 
**root@otuslearn:/home/vagrant# df -h**
>Filesystem      Size  Used Avail Use% Mounted on 
udev            996M   12K  996M   1% /dev
tmpfs           201M  420K  200M   1% /run 
/dev/sda1        40G  1.5G   37G   4% / 
none            4.0K     0  4.0K   0% /sys/fs/cgroup 
none            5.0M     0  5.0M   0% /run/lock 
none           1001M     0 1001M   0% /run/shm 
none            100M     0  100M   0% /run/user 
none            457G   45G  412G  10% /vagrant 
/dev/md0p1      140M  1.6M  128M   2% /raid/part1 
/dev/md0p2      142M  1.6M  130M   2% /raid/part2 
/dev/md0p3      140M  1.6M  128M   2% /raid/part3 
/dev/md0p4      142M  1.6M  130M   2% /raid/part4 
/dev/md0p5      140M  1.6M  128M   2% /raid/part5 
>root@otuslearn:/home/vagrant# 
```
	
</details>

### Прописал собранный рейд в конфиг-файл /etc/mdadm/mdadm.conf, чтобы рейд собирался при загрузке
<details>
	
```
vagrant@otuslearn:~$ cat /etc/mdadm/mdadm.conf
DEVICE partitions
ARRAY /dev/md0 metadata=1.2 name=otuslearn:0 UUID=7cae2cc1:804951b0:d37f597f:3225ed27
vagrant@otuslearn:~$
```
</details>

### Cкрипт для создания рейда
<details>
	
```
#!/bin/bash
sdx="/dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf"
for i in $sdx; do
echo "n\np\n1\n\nt\nfd\nw" | fdisk $i;done
```
	
</details>

### Измененный Vagrantfile
<details>
	
```
MACHINES = {
  :otuslinux => {
        :box_name => "ubuntu/trusty64",
        :ip_addr => '192.168.11.101',
	:disks => {
		:sata1 => {
			:dfile => './disk1.vdi',
			:size => 250,
			:port => 1
		},
		:sata2 => {
			:dfile => './disk2.vdi',
                        :size => 250, # Megabytes
			:port => 2
		},
                :sata3 => {
                         :dfile => './disk3.vdi',
                         :size => 250,
                         :port => 3
                },
                :sata4 => {
                         :dfile => './disk4.vdi',
                         :size => 250, # Megabytes
                         :port => 4
                },
		:sata5 => {
			:dfile => './disk5.vdi',
			:size => 250,
			:port => 5
		}

	}		
  },
}

Vagrant.configure("2") do |config|
	MACHINES.each do |boxname, boxconfig|
	   config.vm.define boxname do |box|
		box.vm.box = "ubuntu/trusty64"
		box.vm.network "private_network", ip: "192.168.56.101"
		box.vm.host_name = "otuslearn"
		
		box.vm.provider :virtualbox do |vb|
			vb.customize ["modifyvm", :id, "--memory", "2048"]
			vb.customize ["modifyvm", :id, "--cpus", "2"] 
			vb.name = "ubuntu-lesson02_2"

			boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				vb.customize ['createmedium', 'disk', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size], '--format', 'VDI']
                                needsController =  true
                          end

			end
				boxconfig[:disks].each do |dname, dconf|
					vb.customize ['storageattach', :id,  '--storagectl', 'SATAController', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
				end
		end

	config.vm.provision "file", source: "script.sh", destination: "/home/vagrant/script.sh" 
	box.vm.provision "shell", inline: <<-SHELL
                mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
                apt-get install -y mdadm
		cd /home/vagrant && bash ./script.sh
		mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
		mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
		echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
		mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
		mkfs.ext4 /dev/md0
		mount /dev/md0 /mnt
        SHELL
	    end

	end
end

```

</details>
