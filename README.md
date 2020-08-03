# Noel Colon's Terraform OCP4 Automation on VMWare:
https://github.com/ncolon/terraform-openshift4-vmware

### Key takeaways:
- Uses Terraform to provision a [Red Hat official helper node](https://github.com/RedHatOfficial/ocp4-helpernode) to:
  - Provide DNS for the cluster (optional but recommended - requires fewer DNS entries by a sysadmin)
  - Provide load balancing for the cluster (haproxy)
  - Provide a web server for ignition config files
  - Create a bootable ISO for each node with IPs and ignition params preset, and to store the ISO on vSphere for use when VMs are provisioned
- Uses Terraform to subsequently provision the cluster nodes and run the `openshift-install` commands

### How to get started
1. Go to Noel's [original GitHub repo](https://github.com/ncolon/terraform-openshift4-vmware) to download the Terraform files. It also has detail on each required variable in the `terraform.tfvars` file.
2. Provision a range of IPs from a sysadmin. These IPs need to be accessible to the public internet so that nodes can download images from quay.io when they begin to boot. In CSP Lab not all IP ranges have routing in place in the OCP network. But that's it - once you have a range set aside for your cluster, you can select arbitrary IPs within that range for each node. No need to provision a VM, get a MAC address, have it assigned a static IP, add a record to the DNS server, etc. This approach uses the helper node for the majority of the DNS records - those that are necessary for in-cluster routing - and sets static IPs for each node using the bootable ISO method mentioned above.
3. Have a sysadmin create [a couple of DNS records](https://docs.openshift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html#installation-dns-user-infra_installing-vsphere) pointing to the public IP of the helper node:
  - A or CNAME record for `api-int.<cluster-name>.<base-domain>.`
  - A or CNAME record for `api.<cluster-name>.<base-domain>.`
  - A or CNAME record for `*.apps.<cluster-name>.<base-domain>.`
4. Run the Terraform script according the original repo's instructions.

### Notes
- Need to have password-less sudo enabled for the helper node
- Need to have SELinux enabled for the helper node - permissive mode ok
- I used RHEL8 for the helper node template OS - with above modifications - but other operating systems should work including CentOS
- Initially I had an issue with httpd binding to port 80, preventing haproxy from starting - but I added a command to turn off httpd before the Ansible scripts start. This seems to work
- Had to modify `epel-release install` command
- Install completes successfully but doesn't get to 'post' step because of ssh keepalive setting. [See here for how to change this](https://patrickmn.com/aside/how-to-keep-alive-ssh-sessions/) in /etc/ssh/ssh_config

Couple of vSphere specific things/bugs
- Have to add `var.datastore_id` to the disk section of the helper node Terraform module. I believe this is a vSphere requirement.
- vSphere provider has to have `version="< 1.16.0"`
- Make the resource pool a data object, not a Terraform provisioned resource. In CSP Lab we are using preexisting resource pools, and don't have permission to create new ones.