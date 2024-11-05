resource "zstack_vm" "vm" {
  depends_on = [null_resource.check_process_exporter_connectivity, null_resource.check_zs_exporter_connectivity]
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

# 查询管理所有管理节点
data "zstack_mnnodes" "mnhosts" {
  
}

# 查询所有节点
data "zstack_hosts" "hosts" {

}

# 提取 mnhosts 中的 host_name 列表
locals {
  mnhosts_hostnames = [for mn in data.zstack_mnnodes.mnhosts.mn_nodes : mn.host_name]
  hosts_management_ips = [for host in data.zstack_hosts.hosts.hosts : host.managementip]
  # Compute hosts (排除 MN hosts)
  compute_hosts = [for host in data.zstack_hosts.hosts.hosts : host.managementip if !contains(local.mnhosts_hostnames, host.managementip)]
}

# 过滤掉重叠的mn节点
locals {
  compute_process_json = jsonencode([
    {
      "targets": [
        for host in data.zstack_hosts.hosts.hosts :
        "${host.managementip}:9256"
        if !contains(local.mnhosts_hostnames, host.managementip)
      ],
      "labels": {
        "node_type": "compute"
      }
    }
  ])
}

# 输出mn节点ip到配置文件mn_process.json
resource "local_file" "mn_hosts_json" {
  content = jsonencode([
    {
      targets = [for mn in data.zstack_mnnodes.mnhosts.mn_nodes : "${mn.host_name}:9256"]
      labels = {"node_type": "management"}
    }
  ])

  filename = "${path.module}/mn_process.json"
}

# 输出计算节点到配置文件compute_process.json
resource "local_file" "compute_hosts_json" {
  filename = "${path.module}/compute_process.json"
  content  = local.compute_process_json
}


# 输出所有hosts的ip到zstack_service_exporter.json配置文件
resource "local_file" "hosts_json" {
  content = jsonencode([
    {
      targets = [for host in data.zstack_hosts.hosts.hosts : "${host.managementip}:9112"]
      labels  = {}
    }
  ])

  filename = "${path.module}/zstack_service_exporter.json"
}

# 为脚本添加执行权限
resource "null_resource" "add_execute_permission" {
  provisioner "local-exec" {
    command = "chmod +x ${path.module}/scripts/exporter_check.sh"
  }
}

# Cloud节点对应target 9256连通性检查
resource "null_resource" "check_process_exporter_connectivity" {
  depends_on = [data.zstack_hosts.hosts]

  provisioner "local-exec" {
    command = <<-EOT
     ${path.module}/scripts/exporter_check.sh "9256" ${join(" ",local.hosts_management_ips)}
    EOT
  }
}

# Cloud节点对应target 9112连通性检查
resource "null_resource" "check_zs_exporter_connectivity" {
  depends_on = [data.zstack_hosts.hosts]

  provisioner "local-exec" {
    command = <<-EOT
     ${path.module}/scripts/exporter_check.sh "9112" ${join(" ",local.hosts_management_ips)}
    EOT
   }
}

# 把zstack_service_exporter.json配置文件写到Prometheus的对应路径
resource "terraform_data" "copy_files_to_vm" {
  depends_on = [zstack_vm.vm]
    connection {
    type     = "ssh"
    user     = "root"
    password = "ZStack@123"
    host     = zstack_vm.vm.0.ip
    timeout  = "40m"
  }
  provisioner "file" {
    source      = "${path.module}/zstack_service_exporter.json"
    destination = "/usr/local/zstack/prometheus/discovery/zstack_service/zstack_service_exporter.json"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/mn_process.json"
    destination = "/usr/local/zstack/prometheus/discovery/mnprocess/process.json"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/compute_process.json"
    destination = "/usr/local/zstack/prometheus/discovery/computeprocess/process.json"
    on_failure = fail
  }
}

resource "terraform_data" "healthy_check" {
  depends_on = [zstack_vm.vm.0]

  provisioner "local-exec" { 
     command     = var.wait_for_migrate_health_cmd 
     environment = { 
       ENDPOINT =  "http://${zstack_vm.vm.0.ip}:3000/"
     } 
   } 
}
