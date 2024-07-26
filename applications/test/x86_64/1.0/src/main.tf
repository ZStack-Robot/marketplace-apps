resource "zstack_vm" "vm" {
    name = "test"
    description = "test"
    root_disk = {
        size = var.root_disk_size
    }
    l3_network_uuids = var.l3_network_uuids
    memory_size = var.memory_size
    cpu_num = var.cpu_num
    marketplace = true
    never_stop = true
}