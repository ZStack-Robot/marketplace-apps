resource "zstack_vm" "vm" {
  name = "Grafana"
  description = "应用市场-Grafana-可视化"
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
       ENDPOINT =  "http://${zstack_vm.vm.ip}:3000/"
     } 
   } 
}