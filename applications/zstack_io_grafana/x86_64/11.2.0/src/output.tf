output "vm_uuids" {
   value = zstack_vm.vm.uuid
}

output "application_protocol" {
   value = "http"
}

output "application_ip" {
   value = zstack_vm.vm.ip
}

output "application_port" {
   value = 3000
}

output "default_account" {
   value = "admin"
}

output "default_password" {
   value = "ZStack@123"
}

output "default_host_root_password" {
   value = "ZStack@123"
}

