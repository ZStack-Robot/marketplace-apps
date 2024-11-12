data "external" "check_mn" {
  program = ["sudo", "/usr/bin/sh", "./scripts/check-mn.sh"]
}

resource "zstack_vm" "vm" {
  count = 1
  name = "ZStack组件服务监控套件"
  description = "应用市场-组件服务监控套件-Prometheus-Grafana"
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

provider "grafana" {
  # Configuration options
  url = "http://${zstack_vm.vm.0.ip}:3000/"
  auth = "admin:ZStack@123"
}

data "grafana_dashboard" "from_uid" {
   depends_on = [terraform_data.healthy_check]
   uid = "ddycpv4jsxr7k1"
}

 
locals {
   cloud_host = data.external.check_mn.result["vip"] != "" ? data.external.check_mn.result["vip"] : data.external.check_mn.result["self_ip"]
   dashboard_config = jsondecode(data.grafana_dashboard.from_uid.config_json)
   datasource_uid   = [
    for panel in local.dashboard_config.panels : panel.datasource.uid
    if contains(keys(panel), "datasource")
  ][0]
}

resource "grafana_data_source" "prometheus" {
  depends_on = [terraform_data.healthy_check]
  name       = "prometheus-cloud"
  type       = "prometheus"
  url        = "http://${local.cloud_host}:9090"  # Cloud Prometheus地址
  is_default = true
  uid = local.datasource_uid

  json_data_encoded = jsonencode({
    timeInterval = "15s"
  })
}

resource "terraform_data" "healthy_check" {
  depends_on = [zstack_vm.vm.0]

  provisioner "local-exec" { 
     command     = var.wait_for_migrate_health_cmd 
     environment = { 
       ENDPOINT =  "http://${zstack_vm.vm.0.ip}:3000"
     } 
   } 
  provisioner "local-exec" { 
     command     = var.wait_for_migrate_health_cmd 
     environment = { 
       ENDPOINT =  "http://${local.cloud_host}:9090"
     } 
   } 
}