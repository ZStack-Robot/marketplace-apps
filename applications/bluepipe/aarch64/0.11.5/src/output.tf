output "vm_uuids" {
   value =  [zstack_vm.vm.uuid]
}

output "application_ip" {
   value =  zstack_vm.vm.ip
}

output "application_port" {
   value = 80
}

output "default_account" {
   value = "root"
}

output "default_password" {
   value = "213456"
}

output "default_host_root_password" {
   value = "password"
}