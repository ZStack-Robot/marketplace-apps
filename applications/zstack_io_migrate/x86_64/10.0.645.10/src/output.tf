output "vm_uuids" {
   value = zstack_vm.vm.uuid
}

output "application_protocol" {
   value = "https"
}

output "application_ip" {
   value = zstack_vm.vm.ip
}

output "application_port" {
   value = 443
}

output "default_account" {
   value = "admin"
}

output "default_password" {
   value = "admin"
}
