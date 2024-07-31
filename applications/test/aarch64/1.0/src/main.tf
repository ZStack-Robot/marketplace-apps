resource "zstack_vm" "vm" {
    name = "test"
    description = "test"
    root_disk = {
        size = {{.root_disk_size}}
    }
    l3_network_uuids = {{.l3_network_uuids}}
    memory_size = {{.memory_size}}
    cpu_num = {{.cpu_num}}
    marketplace = true
    never_stop = true
}