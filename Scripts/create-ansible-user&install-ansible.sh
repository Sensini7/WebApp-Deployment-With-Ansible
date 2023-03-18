#!/bin/bash
# get admin privileges
sudo su

# Add a new user named "ansible"
useradd ansible

# Set a password for the user "ansible"
echo "ansible:ansible" | chpasswd

# Edit the SSH configuration file to allow root login and password authentication
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/# %wheel/%wheel/g' /etc/sudoers

# Restart the SSH service to apply the changes
service sshd restart

# Add the user "ansible" to the "ansiblegroup" group
usermod -aG wheel ansible

# Run ansible. I am using the amazon linux2 OS. pacakages for ansible2 are included in the amazon linux extras repository topic "ansible2".
#To download the packages, run the command below
#If you are running CentOS, comment the command below by appending a # before sudo
# and uncomment the last two commands to install CentOS packages for ansible and install ansible from the packages respectively.
#sudo amazon-linux-extras install -y ansible2

#Install ansible packages for CentOS
sudo yum install epel-release -y

#Install ansible
sudo yum install ansible -y

#Install nano editor
sudo yum install nano -y
