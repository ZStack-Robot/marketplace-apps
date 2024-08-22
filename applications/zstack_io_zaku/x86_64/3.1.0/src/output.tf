output "vm_uuids" {
   value =  [zstack_vm.vm.0.uuid,zstack_vm.vm.1.uuid,zstack_vm.vm.2.uuid]
}

output "application_ip" {
   value =  data.zstack_l3network.network.free_ips.1.ip
}

output "application_port" {
   value = "80"
}

output "default_account" {
   value = "admin"
}

output "default_password" {
   value = "admin@123"
}

output "default_host_root_password" {
   value = "zstack@123@%"
}

