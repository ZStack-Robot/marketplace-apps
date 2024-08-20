resource "zstack_vm" "vm" {
    name = "Marketplace_Bluepipe"
    description = "bluepipe"
    root_disk = {
        size = {{ .root_disk_size }}
        primary_storage_uuid =  {{ .root_disk_primary_storage_uuid }}
        ceph_pool_name = {{ .root_disk_primary_storage_ceph_pool_uuid }}
    }
    networks = [{
        uuid = {{ .l3_network_uuid }}
    }]
    memory_size = {{ .memory_size }}
    cpu_num = {{ .cpu_num }}
    cluster_uuid = {{ .cluster_uuid }}
    host_uuid = {{ .host_uuid }}

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
     "/usr/bin/tar -xf /root/bluepipe-ce-arm-v0.11.5.tar.gz",
     "/usr/bin/docker load < /root/docker/bluepipe_images.tar.gz",
     "cd /root/docker && /usr/bin/docker compose up -d"
    ]
    on_failure = fail
  }
}




