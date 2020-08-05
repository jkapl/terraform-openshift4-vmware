# Noel Colon's Terraform OCP4 Automation on VMware:
These are a few notes detailing my experience using Noel Colon's Terraform scripts for automating the installation of OpenShift on VMware. The original repository is located here: https://github.com/ncolon/terraform-openshift4-vmware

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
- Need to have [password-less sudo](https://stackoverflow.com/questions/10420713/regex-pattern-to-edit-etc-sudoers-file) enabled for the helper node
- Need to have [SELinux enabled](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/changing-selinux-states-and-modes_using-selinux) for the helper node - permissive mode ok
- I used RHEL8 for the helper node template OS - with above modifications - but other operating systems should work including CentOS. If using RHEL8 may need to modify `epel-release install` command in the helper node module. Believe there is an issue with a Red Hat subscription setting
- Initially I had an issue with httpd binding to port 80, preventing haproxy from starting - but I added a command to turn off httpd before the Ansible scripts start. This seems to work
- Modified the `ssh_config` file in the helper node because of timeouts in the ssh connection during final `openshift-install` commands (waiting for the API server). [See here for how to change this](https://patrickmn.com/aside/how-to-keep-alive-ssh-sessions/) in /etc/ssh/ssh_config

Couple of vSphere specific things/bugs
- Can specify if resource pool or folders are preexisting in case permissions are restricted

### Resources
- [Noel's repo](https://github.com/ncolon/terraform-openshift4-vmware)
- [Red Hat helper node repo](https://github.com/RedHatOfficial/ocp4-helpernode)