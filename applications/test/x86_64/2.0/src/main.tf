resource "zstack_vm" "vm" {
    name = "test"
    description = "test"
    root_disk = {
        size = var.root_disk_size
        primary_storage_uuid = var.primary_storage_uuid
        ceph_pool_name = var.ceph_pool_name
    }
    l3_network_uuids = var.l3_network_uuids
    memory_size = var.memory_size
    cpu_num = var.cpu_num
    cluster_uuid = var.cluster_uuid
    
    marketplace = true
    never_stop = true
}