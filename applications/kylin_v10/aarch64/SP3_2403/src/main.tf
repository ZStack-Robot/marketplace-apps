resource "zstack_vm" "vm" {
    name = "Marketplace_Kylin-V10-SP3-2403"
    description = "Marketplace_Kylin-V10-SP3-2403"
    root_disk = {
        size = {{ .root_disk_size }}
        primary_storage_uuid =  {{ .root_disk_primary_storage_uuid }}
        ceph_pool_name = {{ .root_disk_primary_storage_ceph_pool_uuid }}
    }
    l3_network_uuids = {{ .l3_network_uuids }}
    memory_size = {{ .memory_size }}
    cpu_num = {{ .cpu_num }}
    cluster_uuid = {{ .cluster_uuid }}
    host_uuid = {{ .host_uuid }}

    marketplace = true
    never_stop = true
}



