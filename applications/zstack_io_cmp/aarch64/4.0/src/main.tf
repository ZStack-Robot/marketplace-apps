resource "zstack_vm" "vm" {
    name = "Marketplace_ZStack-CMP"
    description = "应用市场-CMP多云管理"
    root_disk = {
        size = var.root_disk_size
        primary_storage_uuid = var.primary_storage_uuid
        ceph_pool_name = var.ceph_pool_name
    }
    l3_network_uuids = var.l3_network_uuids
    memory_size = var.memory_size
    cpu_num = var.cpu_num
    cluster_uuid = var.cluster_uuid
    host_uuid = var.host_uuid

    marketplace = true
    never_stop = true
}

resource "terraform_data" "remote-exec" {
  depends_on = [zstack_vm.vm]
  connection {
    type     = "ssh"
    user     = "root"
    password = "password"
    host     = zstack_vm.vm.ip
    timeout = "5m"
  }

  provisioner "remote-exec" {
   inline = [
     "export DOCKER_BUILDKIT=0 && /bin/bash /root/packages/ZStack-CMP-installer-4.0.2.bin"
    ]
    on_failure = fail
  }
}




