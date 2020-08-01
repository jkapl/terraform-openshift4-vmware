resource "null_resource" "dependency" {
  triggers = {
    all_dependencies = join(",", var.dependson)
  }
}

resource "vsphere_virtual_machine" "vm" {
  count = var.vminfo["count"]
  depends_on = [
    null_resource.dependency
  ]

  name             = "${var.cluster_id}-${var.vmtype}-${count.index + 1}"
  resource_pool_id = var.resource_pool_id
  datastore_id     = var.datastore_id
  folder           = var.folder

  wait_for_guest_ip_timeout = 5

  num_cpus = var.vminfo["cpu"]
  memory   = var.vminfo["memory"]
  guest_id = "other3xLinux64Guest"

  network_interface {
    network_id = var.network_id
  }

  enable_disk_uuid = true
  disk {
    label            = "disk0"
    size             = var.vminfo["disk"]
    thin_provisioned = true
  }

  cdrom {
    datastore_id = var.image_datastore_id
    path         = "${var.image_datastore_path}/${var.cluster_id}-${var.vmtype}-${count.index + 1}.iso"
  }

  connection {
    host        = self.default_ip_address
    user        = "core"
    private_key = var.ssh_private_key

    bastion_host        = var.helper_public_ip
    bastion_user        = var.helper["username"]
    bastion_password    = var.helper["password"]
    bastion_private_key = var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "sudo eject cdrom",
    ]
  }
}


