
## Lets Dive Right In!!

## Setting Up Ansible Master Node

- Create a security group named **`Masternode-SG`**. Configure the inbound rules to accept `HTTP` from everywhere on port `80` and `SSH` on port `22` from everywhere 
- Launch a **CentOS** t2.micro EC2 server in the public subnet of your vpc. You wont find it in the AWS quick start AMIs. Search AWS narketplace for CentOS and select `CentOS 7` as shown below

Browse AWS AMIs

![aws-ami](https://user-images.githubusercontent.com/99888333/224610169-01719f67-799a-4718-b1f6-d7e56fb961b9.png)

Navigate to AWS marketplace and search for **centos** , then `select cetos7`

![centos7](https://user-images.githubusercontent.com/99888333/224610358-e3ac13d6-6101-49cb-be42-c555ed9de586.png)

- Select the `Masternode-SG` and click on advanced settings. **`P.S:`** We do not need a keypair as we will be using the newly created user to ssh with password authentication.
- Scrole down to user data and use the following shell script as user data for the master node. This script is also found in the **`Scripts`** Folder of this Repo

```bash
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

#Install apache
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service

# Install git if not already installed
sudo yum install git -y

# Clone the GitHub repository containing your website.
git clone https://github.com/Sensini7/Host-a-Secure-Static-Website-On-S3-Bucket-With-Cloudfront-And-Route53.git /tmp/staticwebsite

# Copy the HTML website to the /var/www/html directory
sudo cp /tmp/staticwebsite/index.html /var/www/html/index.html

# Remove the temporary directory
rm -rf /tmp/staticwebsite

# Restart Apache web server
sudo service httpd restart

```

**THE SCRIPT ABOVE DOES THE FOLLOWING**

- Assumes admin privileges
- Creates a new user in the master node called **`ansible`** and sets its password in this case, `ansible`
- Enables **RootLogin** , **password authentication for this user** and enables the **wheel** group with admin **sudoers** Permisions
- Restarts SSH to apply changes
- Adds the newly created ansible user to the **wheel** group to grant it sudo Permissions
- Installs epel-release ansible package
- Installs **`ansible`**
- Installs **nano editor** for centos.
- Updates the servers softwares, **`installs,starts and enable apache`**
- Installs git 
- Clones the github repo containing the webapp into a temporal directory on the server
- Copies the webapp from the temporal directory to the **html directory where apache can serve the content**
- Removes the cloned repo from the server
- Restarts apache

The last 5 lines of code ensures that our webapp is present in the master node. This is very important as we will be using the copy module with remote source in the playbook to deploy the webapp.

## Setting Up WebApp Host Nodes
- Create a second security group named **`Hostnode-SG`**. Open `HTTP port 80` to everywhere and `SSH Port 22` to the **`security group of the masternode`**
- Launch two t2.micro CentOs servers named `Node1` and `Node2` with this `SG` and use the following script as user data for these servers

```bash
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

#Install nano editor 
sudo yum install nano -y

```

**The script above does the same tasks on the host nodes as the later does on the master node except the following**

- it does not install git
- does not update th host nodes nor install apache
- does not clone and copy the webapp
- does not install ansible

**The above tasks will be done by ansible on the host nodes.**

`once the above servers (master and hosts) are up and running, we have successfully set up the base environment necessary to configure and deploy the webapp at scale with ansible.`

## Changing Hostnames

1. Open three CLI terminals and login to each of the servers as the ansible user on each terminal. i.e, one terminal for the master node,one for Node1 and the last for   Node2 
2. use the following command to login. **`ssh ansible@public-IP`**. Replace public-ip with the corresponding public IP of each server in each case.
3. On the master node, use the command **`sudo nano /etc/hostname`** to edit its hostname. When the nano editor opens the hostname file, change its hostname to `ansible-master` hit **ctrl+x,yand enter** to save and exit the nano editor
4. Reboot the server with the `sudo reboot1 command to pickup the new changes.
5. Re-SSH into the master node to view the new hostname.
6. Repeat steps `3,4 and 5`  on nodes 1 and 2 changing their hostnames to Node1 And Node2 respectively.

**master node hostname**

![masterhostname](https://user-images.githubusercontent.com/99888333/224829953-2bc7181f-0e77-435e-bdc6-40fa996e29ff.png)

**Node1 hostname**

![node1hostname](https://user-images.githubusercontent.com/99888333/224831252-18c6b076-58e5-418a-a81e-2665215ceb66.png)

**Node2 hostname**

![Node2](https://user-images.githubusercontent.com/99888333/224830948-a97a69d9-c580-43f0-96ba-ec79c7a2c6b2.png)

**The environment is well set up for ansible master node to ssh into host nodes with all servers having distinct hostnames but the ansible user of the master node  is still prompt to provide the password of hostnodes each time it tries to ssh. This is a massive problem as we wont be available to provide passwords during automation when playbooks run. Tos solve this, we create a private SSH keypair in the master node and copy or share it with the respective hostnodes.**

## Creating Private SSH Keypair
- Login to the master node as ansible user if not already logged in.
- 






