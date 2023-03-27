
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
- does not clone and move the webapp to the Apache directory
- does not install ansible

**The above tasks will be done by ansible on the host nodes.**

`once the above servers (master and hosts) are up and running, we have successfully set up the base environment necessary to configure and deploy the webapp at scale with ansible.`

## Changing Hostnames

1. Open the CLI terminal and login to the ansible master server 

2. use the following command to login. **`ssh ansible@public-IP`**. Replace public-ip with the corresponding public IP of the ansible master server.

3. On the master node, use the command **`sudo nano /etc/hostname`** to edit its hostname. When the nano editor opens the hostname file, change its hostname to `ansible-master` hit **ctrl+x,yand enter** to save and exit the nano editor

4. Reboot the server with the `sudo reboot command to pickup the new changes.

5. Re-SSH into the master node to view the new hostname.

6. From the master node, ssh into node1 using the following command **ssh ansible@Private_IP** of node1. Insert the ansible node1 user password "ansible" to login. 

7. Repeat steps **3, 4 and 5** to change the hostname of Node1

8. Repeat steps `6,3,4 and 5`  on node2  changing its hostnames to   Node2 respectively.

**master node hostname**

![masterhostname](https://user-images.githubusercontent.com/99888333/224829953-2bc7181f-0e77-435e-bdc6-40fa996e29ff.png)

**Node1 hostname**

![node1hostname](https://user-images.githubusercontent.com/99888333/224831252-18c6b076-58e5-418a-a81e-2665215ceb66.png)

**Node2 hostname**

![Node2](https://user-images.githubusercontent.com/99888333/224830948-a97a69d9-c580-43f0-96ba-ec79c7a2c6b2.png)

**The environment is well set up for ansible master node to ssh into host nodes with all servers having distinct hostnames but the ansible user of the master node  is still prompt to provide the password of hostnodes each time it tries to ssh. This is a massive problem as we wont be available to provide passwords during automation when playbooks run. Tos solve this, we create a private SSH keypair in the master node and copy or share it with the respective hostnodes.**

## Creating Internal SSH Keypair
- Login to the master node as ansible user if not already logged in.
- To generate new keypair, use this command **`ssh-keygen -t rsa`**. save the key in the path /home/ansible/.ssh/id_rsa
- Leave paraphrase empty by hitting enter
- Your screen should look like this when key is generated 

![privsshkeypair](https://user-images.githubusercontent.com/99888333/224834200-e31921d6-f825-4ca4-8aba-bf6eb0d35bd0.png)

1. Before copying the new keypair to hostnodes, we have to setup proper rights on .ssh folder for ansible user to copy it. Use the following command to do so **`sudo chmod 700 /home/ansible/.ssh`**
2. Copy the ssh public key to Node1. **`ssh-copy-id ansible@Private-IP Of Node1`**
- Your screen should look like this with a success

![copykey](https://user-images.githubusercontent.com/99888333/224839977-9a5c27a7-5ce5-428d-a79c-161a3ff6efe6.png)

3. Repeat step 2 for node2 aswell.
4. Test the ssh connection from master node to node1 and node2 respectively. `ssh ansible@Private-IP Of hostnode`. You should not get a password prompt prior to connection this time as seen in the node1 example below.

![testssh](https://user-images.githubusercontent.com/99888333/224839682-856ee753-3685-43f4-b465-606d0fde465c.png)

**Next we have to add the private IP addresses of our hostnodes as a group of webservers to the inventory file or hosts file of ansible found in the master node. This is how ansible knows where to execute playbooks**

## Configuring Inventory
- Move to the aansible master as ansible user.
- navigate to the directory `/etc/ansible`
- `ls` to list the files.
- `sudo nano hosts` to edit the hosts file
- Uncomment the `webservers` group and copy paste the private IPs of your `Node1 and Node2` respectively as shown below

![hosts](https://user-images.githubusercontent.com/99888333/224843312-a88cee5b-7b4e-4d6a-ab48-b66f7c4f3b9f.png)

- save and exit the hosts file `ctr+x,y enter`
- Test the connection of ansible to webservers group of host nodes using the ping command **`ansible webservers -m ping`**
- Your screen should look like this for a success.

![ping](https://user-images.githubusercontent.com/99888333/224845162-a7cc1c6c-153b-4aae-babf-360542638dd7.png)


## Create And Run The Ansible Playbook
- We are going to create the playbook in the `/etc/ansible` directory
- Once in the ansible directory, create an empty file which will contain the playbook with this command **`sudo nano webservers-playbook.yml`**
- Paste the following playbook in the file. THis playbook is also found in the scripts file of this repo.

```bash
---
- name: Install, start, and enable Apache web server
  hosts: webservers
  become: yes

  vars:
    git_repo: "https://github.com/Sensini7/Host-a-Secure-Static-Website-On-S3-Bucket-With-Cloudfront-And-Route53.git"
    git_branch: "main"
    html_file: "index.html"

  tasks:
  - name: Update target servers
    yum:
      name: '*'
      state: latest
    when: ansible_distribution == 'CentOS' and ansible_distribution_major_version == '7'

  - name: Install Apache
    yum:
      name: httpd
      state: present

  - name: Start Apache
    service:
      name: httpd
      state: started

  - name: Enable Apache at boot time
    service:
      name: httpd
      enabled: yes

  - name: Install Git
    yum:
      name: git
      state: present

  - name: Clone repository
    git:
        repo: "{{ git_repo }}"
        dest: "/tmp/repo"
        version: "{{ git_branch }}"
        clone: yes
        force: yes

  - name: Move HTML file to Apache directory
    command: mv "/tmp/repo/{{ html_file }}" "/var/www/html/{{ html_file }}"

  - name: Delete cloned repository
    file:
      path: /tmp/repo
      state: absent

  - name: Restart Apache
    service:
      name: httpd
      state: restarted


```

This is a playbook that **`installs, starts, and enables Apache web server on target webservers. It then installs Git, clones a repository from a specified URL, and moves an HTML file from the cloned repository to the Apache directory. Finally, it restarts the Apache service.`**

**Here is a breakdown of each task:**

- `name:` This is just a name for the playbook to help identify what it does.

- `hosts:` This specifies which group of servers the playbook will run on. In this case, it is the webservers group.

- `become:` This tells Ansible to run the playbook with sudo privileges.

- `vars:` This section defines variables that will be used throughout the playbook. In this case, there are three variables defined: `git_repo,` `git_branch,` and    `html_file.` These variables are used later in the playbook to specify the GitHub repository to clone, the branch to check out, and the HTML file to move to the         Apache  directory.

- `tasks:` This is where the main part of the playbook starts. It contains a list of tasks that will be executed in order on the target servers.

1. Update target servers: Uses the yum module to update all packages on the target servers, but only when the OS is CentOS 7.

2. Install Apache: Uses the yum module to install the Apache web server on the target servers.
 
3. Start Apache: Uses the service module to start the Apache web server.
 
4. Enable Apache at boot time: Uses the service module to enable the Apache web server to start at boot time.
 
5. Install Git: Uses the yum module to install Git on the target servers.
 
6. Clone repository: Uses the git module to clone the specified Git repository to the /tmp/repo directory on the target servers, checking out the specified branch and    forcing any existing changes to be overwritten.
 
7. Move HTML file to Apache directory: Uses the command module to move the index.html file from the cloned repository to the Apache web server's document root            directory (/var/www/html/).
 
8. Delete cloned repository: Uses the file module to delete the cloned repository from the target servers.
 
9. Restart Apache: Uses the service module to restart the Apache web server.

- Run the playbook with the following command `ansible-playbook webservers-playbook.yml
`
- With a success, you should get something similar to the output below

- In your case All tasks should indicate`CHANGED` and in `yellow`. I have a couple of `OK` tasks marked in green because i am running this playbook for the second time   and ansible recognizes that those tasks have already been performed.


![gitmoduleplaybookoutput](https://user-images.githubusercontent.com/99888333/226077211-0911167c-a64c-4067-82f1-0a06a4252e5b.png)


**Navigate to the EC2 console, copy the Public IPs of Node1 and Node2 and paste in the browser to view the newly deployed webapp on hostnodes.**

![success](https://user-images.githubusercontent.com/99888333/224850678-3d7db057-0092-4e74-a401-7ad3db7b084e.png)

**Congratulations you have successfully deployed a webapp to multiple webservers using ansible**

**To cleanup, shut down all 3 instances**























