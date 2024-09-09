resource "zstack_vm" "vm" {
  name = "ZMigrate"
  description = "应用市场-ZMigrate 迁移服务"
  root_disk = {
    size = {{.root_disk_size}}
  }

  l3_network_uuids = {{.l3_network_uuids}}
  memory_size = {{.memory_size}}
  cpu_num = {{.cpu_num}}
  marketplace = true
  never_stop = true
}

variable "l3Uuids" {
  type = list(string)
  default = {{.l3_network_uuids}}
}

data "zstack_l3network" "network" {
    depends_on = [zstack_vm.vm]
    uuid = var.l3Uuids[0]
}

resource "terraform_data" "healthy_check" {
  depends_on = [zstack_vm.vm]

  provisioner "local-exec" { 
     command     = var.wait_for_migrate_health_cmd 
     environment = { 
       ENDPOINT =  "https://${zstack_vm.vm.ip}/console"
     } 
   } 
}