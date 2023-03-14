# WebApp Deployment With Ansible

**Architecture**

![ansible](https://user-images.githubusercontent.com/99888333/224481883-e5026c46-a55e-4f58-b3f7-5d7d9a4dcf08.png)

The diagram above depics the infrastrucure we are going to be setting up. Using Ansible, a configuration management tool,  we will be deploying a webapp to several host nodes.

At a high level, our webapp is said to be stored in a github repo and has to be deployed to webservers. Here's how.

- We will create a common user in master node and all host nodes
- Set a password for the user and configure password authentication
- Give newly created user Sudo rights on all nodes
- Install nano editor on all nodes as we will be using CentOS. PS: this is not required for amazon Linux2
- Install ansible on master node only
- Install apache to serve the webapp on all nodes
- Pull the webapp from github into the ansible master node
- Configure the master node to ssh into all host nodes without password prompt by creating an internal keypair in the master node and sharing with host nodes.
- Create an inventory in the master node containing the webservers
- Create and run an ansible playbook to deploy the webapp to hostnodes through a series of tasks
