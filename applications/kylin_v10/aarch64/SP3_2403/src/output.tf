output "vm_uuids" {
   value =  [zstack_vm.vm.uuid]
}

output "default_host_root_password" {
   value = "zstack@123"
}