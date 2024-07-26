output "vm_uuids" {
   value =  [zstack_vm.vm.uuid]
}

output "application_ip" {
   value =  zstack_vm.vm.ip
}

output "application_port" {
   value = 8100
}

output "default_account" {
   value = "admin"
}

output "default_password" {
   value = "password"
}

output "default_host_root_password" {
   value = "password"
}