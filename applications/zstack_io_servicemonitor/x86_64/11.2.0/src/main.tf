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

  # 判断如果只有一个管理节点，则配置为management, 且使用
}

# 根据 mn 节点数量决定配置文件
locals {
 # node_type = length(local.mnhosts_hostnames) == 1 ? "management" : "ha"
  config_file = length(local.mnhosts_hostnames) == 1 ? "mn_zs_service_export_config.yaml" : "ha_zs_service_export_config.yaml"
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

# 读取mn的ssh id_rsa
locals {
  private_key_path = "${data.external.check_mn.result["zstack_home"]}/WEB-INF/classes/ansible/rsaKeys/id_rsa"
  private_key      = fileexists(local.private_key_path) ? file(local.private_key_path) : ""
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

# 把zstack_service_exporter.json配置文件写到Prometheus的对应路径
resource "terraform_data" "copy_files_to_vm" {
  depends_on = [zstack_vm.vm]
    connection {
    type     = "ssh"
    user     = "root"
    password = "ZStack@123"
    host     = zstack_vm.vm.0.ip
    timeout  = "10m"
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

# 部署zssvc_exporter和process_exporter到mn节点
resource "terraform_data" "copy_and_enable_service_on_mn" {
  count = length(data.zstack_mnnodes.mnhosts.mn_nodes)
  depends_on = [zstack_vm.vm]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = local.private_key
    host        = data.zstack_mnnodes.mnhosts.mn_nodes[count.index].host_name
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/zstack/zsservice"
    ]
  }
  provisioner "file" {
    source      = "${path.module}/scripts/${local.config_file}" # "${path.module}/scripts/mn_zs_service_export_config.yaml"
    destination = "/var/lib/zstack/zsservice/config.yaml"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/process-config.yaml"
    destination = "/var/lib/zstack/zsservice/process-config.yaml"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/process_exporter.service"
    destination = "/etc/systemd/system/process_exporter.service"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/zstack_service_exporter.service"
    destination = "/etc/systemd/system/zstack_service_exporter.service"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/bin/zs_service_exporter"
    destination = "/var/lib/zstack/zsservice/zs_service_exporter"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/bin/process-exporter"
    destination = "/var/lib/zstack/zsservice/process-exporter"
    on_failure = fail
  }
  provisioner "remote-exec" {
    inline = [
    "systemctl daemon-reload",
    "chmod +x /var/lib/zstack/zsservice/zs_service_exporter",
    "chmod +x /var/lib/zstack/zsservice/process-exporter",
    "systemctl enable zstack_service_exporter.service",
    "systemctl enable process_exporter.service",
    "systemctl start zstack_service_exporter.service",
    "systemctl start process_exporter.service"
    ]
    on_failure = fail
  }
}

# 部署zssvc_exporter和process_exporter到计算节点
resource "terraform_data" "copy_and_enable_service_on_compute" {
  count = length(local.compute_hosts)
  depends_on = [zstack_vm.vm]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = local.private_key
    host        = local.compute_hosts[count.index]
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /var/lib/zstack/zsservice"
    ]
  }
  provisioner "file" {
    source      = "${path.module}/scripts/compute_zs_service_export_config.yaml"
    destination = "/var/lib/zstack/zsservice/config.yaml"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/process-config.yaml"
    destination = "/var/lib/zstack/zsservice/process-config.yaml"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/process_exporter.service"
    destination = "/etc/systemd/system/process_exporter.service"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/scripts/zstack_service_exporter.service"
    destination = "/etc/systemd/system/zstack_service_exporter.service"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/bin/zs_service_exporter"
    destination = "/var/lib/zstack/zsservice/zs_service_exporter"
    on_failure = fail
  }
  provisioner "file" {
    source      = "${path.module}/bin/process-exporter"
    destination = "/var/lib/zstack/zsservice/process-exporter"
    on_failure = fail
  }
  provisioner "remote-exec" {
    inline = [
    "systemctl daemon-reload",
    "chmod +x /var/lib/zstack/zsservice/zs_service_exporter",
    "chmod +x /var/lib/zstack/zsservice/process-exporter",
    "systemctl enable zstack_service_exporter.service",
    "systemctl enable process_exporter.service",
    "systemctl start zstack_service_exporter.service",
    "systemctl start process_exporter.service"
    ]
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

# 当资源释放时，同时卸载mn节点的exporter
resource "null_resource" "destroy_service_on_mn" {
  count =  length(data.zstack_mnnodes.mnhosts.mn_nodes)
  triggers = {
    mn = data.zstack_mnnodes.mnhosts.mn_nodes[count.index].host_name
    private_key = local.private_key
  }
  connection {
    type        = "ssh"
    user        = "root"
    private_key = self.triggers.private_key
    host        = self.triggers.mn 
  }
  
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "systemctl stop zstack_service_exporter.service",
      "systemctl stop process_exporter.service",
      "systemctl disable zstack_service_exporter.service",
      "systemctl disable process_exporter.service",
      "rm /etc/systemd/system/zstack_service_exporter.service",
      "rm /etc/systemd/system/process_exporter.service",
      "rm -rf /var/lib/zstack/zsservice",
      "systemctl daemon-reload"
    ]
  }
}

# 当资源释放时，同时卸载计算节点的exporter
resource "null_resource" "destroy_service_on_compute" {
  count = length(local.compute_hosts)
  triggers = {
    compute = local.compute_hosts[count.index]
    private_key = local.private_key
  }
  connection {
    type        = "ssh"
    user        = "root"
    private_key = self.triggers.private_key
    host        = self.triggers.compute 
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "systemctl stop zstack_service_exporter.service",
      "systemctl stop process_exporter.service",
      "systemctl disable zstack_service_exporter.service",
      "systemctl disable process_exporter.service",
      "rm /etc/systemd/system/zstack_service_exporter.service",
      "rm /etc/systemd/system/process_exporter.service",
      "rm -rf /var/lib/zstack/zsservice",
      "systemctl daemon-reload"
    ]
  }
}