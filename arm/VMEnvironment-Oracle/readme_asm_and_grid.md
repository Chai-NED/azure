# Install Oracle ASM

## Reference

<https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/oracle/configure-oracle-asm>

Please note, the following steps are condensed from the above document with minor modifications for readability, where applicable.

## Steps

### Install Oracle ASM

```bash
sudo su -

yum list | grep oracleasm

yum -y install kmod-oracleasm.x86_64
yum -y install oracleasm-support.x86_64

wget http://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.12-1.el6.x86_64.rpm
yum -y install oracleasmlib-2.0.12-1.el6.x86_64.rpm
rm -f oracleasmlib-2.0.12-1.el6.x86_64.rpm

rpm -qa |grep oracleasm

groupadd -g 54345 asmadmin
groupadd -g 54346 asmdba
groupadd -g 54347 asmoper
useradd -u 3000 -g oinstall -G dba,asmadmin,asmdba,asmoper grid
usermod -g oinstall -G dba,asmdba,asmadmin oracle

id grid

mkdir /u01/app/grid
chown grid:oinstall /u01/app/grid
 ```

### Set up Oracle ASM

```bash
/usr/sbin/oracleasm configure -i
```

```text
Default user to own the driver interface []: grid
Default group to own the driver interface []: asmadmin
Start Oracle ASM library driver on boot (y/n) [n]: y
Scan for Oracle ASM disks on boot (y/n) [y]: y
```

```bash
cat /proc/partitions | sort -u -k4
```

For a VM with 8 data disks and 4 reco disks (i.e. 12 total), run the following commands. Provide the same answers each time:
n, p, 1, [Enter], [Enter], w

```bash
fdisk /dev/sdc
fdisk /dev/sdd
fdisk /dev/sde
fdisk /dev/sdf
fdisk /dev/sdg
fdisk /dev/sdh
fdisk /dev/sdi
fdisk /dev/sdj
fdisk /dev/sdk
fdisk /dev/sdl
fdisk /dev/sdm
fdisk /dev/sdn
```

Should now see each disk with a partition:

```bash
cat /proc/partitions | sort -u -k4
```

or

```bash
 ls -ltrh /dev/sd* | sort -u -k7
 ```

Check ASM status, start the service, check status again, list disks (should show none yet):

```bash
service oracleasm status
service oracleasm start
service oracleasm status
service oracleasm listdisks
```

Create ASM disks:

```bash
service oracleasm createdisk DATA1 /dev/sdc1
service oracleasm createdisk DATA2 /dev/sdd1
service oracleasm createdisk DATA3 /dev/sde1
service oracleasm createdisk DATA4 /dev/sdf1
service oracleasm createdisk DATA5 /dev/sdg1
service oracleasm createdisk DATA6 /dev/sdh1
service oracleasm createdisk DATA7 /dev/sdi1
service oracleasm createdisk DATA8 /dev/sdj1

service oracleasm createdisk RECO1 /dev/sdk1
service oracleasm createdisk RECO2 /dev/sdl1
service oracleasm createdisk RECO3 /dev/sdm1
service oracleasm createdisk RECO4 /dev/sdn1

service oracleasm listdisks
```

Change account passwords:

```bash
passwd oracle
passwd grid
passwd root
```

Change folder permissions:

```bash
chmod -R 775 /opt
chown grid:oinstall /opt

chown oracle:oinstall /dev/sdc1
chown oracle:oinstall /dev/sdd1
chown oracle:oinstall /dev/sde1
chown oracle:oinstall /dev/sdf1
chown oracle:oinstall /dev/sdg1
chown oracle:oinstall /dev/sdh1
chown oracle:oinstall /dev/sdi1
chown oracle:oinstall /dev/sdj1
chown oracle:oinstall /dev/sdk1
chown oracle:oinstall /dev/sdl1
chown oracle:oinstall /dev/sdm1
chown oracle:oinstall /dev/sdn1

chmod 600 /dev/sdc1
chmod 600 /dev/sdd1
chmod 600 /dev/sde1
chmod 600 /dev/sdf1
chmod 600 /dev/sdg1
chmod 600 /dev/sdh1
chmod 600 /dev/sdi1
chmod 600 /dev/sdj1
chmod 600 /dev/sdk1
chmod 600 /dev/sdl1
chmod 600 /dev/sdm1
chmod 600 /dev/sdn1
```

### Oracle Grid Infrastructure

Follow the steps here to obtain the Oracle Grid Infrastructure installer files and copy them to the Oracle VM:\
<https://docs.microsoft.com/azure/virtual-machines/workloads/oracle/configure-oracle-asm#download-and-prepare-oracle-grid-infrastructure>

Note: on Windows, you can use Putty's pscp command to upload zip files to the Oracle VM. Examples:

```bash
pscp -scp S:\Oracle\Grid\linuxamd64_12102_grid_1of2.zip oraadmin@172.16.1.4:
pscp -scp S:\Oracle\Grid\linuxamd64_12102_grid_2of2.zip oraadmin@172.16.1.4:
```

```bash
sudo mv ./*.zip /opt
cd /opt
sudo chown grid:oinstall linuxamd64_12102_grid_1of2.zip
sudo chown grid:oinstall linuxamd64_12102_grid_2of2.zip
```

```bash
sudo yum install unzip
sudo unzip linuxamd64_12102_grid_1of2.zip
sudo unzip linuxamd64_12102_grid_2of2.zip

sudo chown -R grid:oinstall /opt/grid
```

Change swap space size (ResourceDisk.SwapSizeMB) from 2048 to 20480. The referenced article says 8G, but Grid install (below) fails with less than 16G; I'm using 20480 to be comfortably above the minimum and not fail install based on a few bytes. The article also uses vi, here I'm using nano instead.

```bash
sudo chmod 777 /etc/waagent.conf

sudo yum install nano

sudo nano /etc/waagent.conf
```

After saving the changes to /etc/waagent.conf, check swap space before and after restarting the Azure Linux agent to see /dev/sdb1 go from 2.1G used to 21G:

```bash
df -h

sudo service waagent restart

df -h
```

### Completing Oracle ASM and Grid Setup

Follow the linked article's instructions on preparing an X11 session, including preparing an SSH public key for the grid user.

```bash
sudo su - grid
mkdir .ssh
cd .ssh
touch authorized_keys
nano authorized_keys
```

SSH as the grid user. Run the installer and go through it as described in the reference link above.

```bash
cd /opt/grid
./runInstaller
```

### Complete Oracle ASM installation, including creation of additional disk groups

```bash
cd /u01/app/grid/product/12.1.0/grid/bin
./asmca
```