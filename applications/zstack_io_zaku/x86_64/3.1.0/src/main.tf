
data "external" "check_mn" {
  program = ["/usr/bin/sh", "./check-mn.sh"]
}


resource "zstack_vm" "vm" {
  count = 3
  name = "Zaku-${count.index + 1}"
  description = "应用市场-ZaKu容器服务"
  root_disk = {
    size = {{.root_disk_size}}
    primary_storage_uuid = {{.primary_storage_uuid}}
    ceph_pool_name = {{.ceph_pool_name}}
  }
  data_disks = [
    {
      size = {{.data_disk_size}}
      primary_storage_uuid = {{.primary_storage_uuid}}
    }
  ]
  l3_network_uuids = {{.l3_network_uuids}}
  memory_size = {{.memory_size}}
  cpu_num = {{.cpu_num}}
  user_data = "I2Nsb3VkLWNvbmZpZwpydW5jbWQ6CiAgLSB8CiAgICBwdl9saXN0PSQocHZzIC0tbm9oZWFkaW5ncyAtbyBwdl9uYW1lKQogICAgcHZfY291bnQ9JChlY2hvICIkcHZfbGlzdCIgfCB3YyAtbCkKICAgIHB2X25hbWU9JChlY2hvICIkcHZfbGlzdCIgfCB0ciAtZCAnICcpCgogICAgdmdfbmFtZT0kKHB2cyAtLW5vaGVhZGluZ3MgLW8gdmdfbmFtZSAkcHZfbmFtZSB8IHRyIC1kICcgJykKCiAgICBncm93cGFydCAkKGVjaG8gJHB2X25hbWUgfCBzZWQgJ3MvWzAtOV0qJC8vJykgJChlY2hvICRwdl9uYW1lIHwgZ3JlcCAtbyAnWzAtOV0qJCcpCiAgICBwdnJlc2l6ZSAkcHZfbmFtZQoKICAgIGx2X25hbWU9JChsdnMgLS1ub2hlYWRpbmdzIC1vIGx2X25hbWUgLS1zb3J0IC1zaXplIHwgdGFpbCAtMSB8IHRyIC1kICcgJykKCiAgICBsdmV4dGVuZCAtbCArMTAwJUZSRUUgL2Rldi8kdmdfbmFtZS8kbHZfbmFtZQoKICAgIGx2X3BhdGg9Ii9kZXYvJHZnX25hbWUvJGx2X25hbWUiCiAgICBtYXBwZXJfbmFtZT0kKHJlYWRsaW5rIC1mICRsdl9wYXRoIHwgYXdrIC1GICcvJyAne3ByaW50ICQzfScpCgogICAgbHZfbWFwcGVyX25hbWU9JChscyAtbCAvZGV2L21hcHBlci8gfCBncmVwICIkbWFwcGVyX25hbWUiIHwgYXdrICd7cHJpbnQgJDl9JykKCiAgICBibGtpZCB8IGdyZXAgIi9kZXYvbWFwcGVyLyRsdl9tYXBwZXJfbmFtZSIgfCBncmVwIC1xIHhmcwoKICAgIGlmIFsgJD8gLWVxIDAgXTsgdGhlbgogICAgICAgIHhmc19ncm93ZnMgL2Rldi9tYXBwZXIvJGx2X21hcHBlcl9uYW1lCiAgICBlbHNlCiAgICAgICAgcmVzaXplMmZzIC9kZXYvbWFwcGVyLyRsdl9tYXBwZXJfbmFtZQogICAgZmkKICAgIHBhcnRwcm9iZQ=="
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

resource "zstack_reserved_ip" "reserved_ip" {
  l3_network_uuid = var.l3Uuids[0]
  start_ip = data.zstack_l3network.network.free_ips.0.ip
  end_ip = data.zstack_l3network.network.free_ips.0.ip
}

resource "zstack_reserved_ip" "reserved_ip1" {
  l3_network_uuid = var.l3Uuids[0]
  start_ip = data.zstack_l3network.network.free_ips.1.ip
  end_ip = data.zstack_l3network.network.free_ips.1.ip
}

resource "local_file" "hosts_cfg" {
  depends_on = [zstack_vm.vm]
  content = templatefile("./hosts-zaku.yaml.tpl", {
    host1_ip = zstack_vm.vm.0.ip
    host2_ip = zstack_vm.vm.1.ip
    host3_ip = zstack_vm.vm.2.ip
    host_interface = "ens3"
    preserved_ip = data.zstack_l3network.network.free_ips.0.ip
    preserved_ip_range = data.zstack_l3network.network.ip_range.0.cidr
    preserved_network_gateway = data.zstack_l3network.network.ip_range.0.gateway
    cloud_host = data.external.check_mn.result["vip"] != "" ? data.external.check_mn.result["vip"] : data.external.check_mn.result["self_ip"]
    cloud_host_ui = {{.cloud_host_ui}}
    cloud_account_name = "admin"
    cloud_password = {{.cloud_password}}
    cloud_admin_access_key_id = {{.access_key}}
    admin_access_secret = {{.access_secret}}
    devOps = {{.dev_ops}}
    metallb_ip = data.zstack_l3network.network.free_ips.1.ip
    ntp_servers_ip = {{.ntp_servers_ip}}
  })
  filename = "./hosts.yaml"
}



resource "local_file" "cloud_nginx" {
  content = templatefile("./cloud-nginx.conf.tpl", {
    proxy_pass = data.zstack_l3network.network.free_ips.1.ip
  })
  filename = "./zaku.http.nginx.conf"
}


resource "terraform_data" "check_host" {
  count = length(zstack_vm.vm)

  connection {
    type     = "ssh"
    user     = "root"
    password = "zstack@123@%"
    host     = zstack_vm.vm[count.index].ip
    timeout  = "15m"
  }

  provisioner "local-exec" {
    command = "echo 'Host ${zstack_vm.vm[count.index].ip} is reachable' >> connection.log 2>&1"
  }
}

resource "terraform_data" "remote-exec" {
  depends_on = [terraform_data.check_host]
  connection {
    type = "ssh"
    user = "root"
    password = "zstack@123@%"
    host = zstack_vm.vm.2.ip
    timeout = "5m"
  }

  provisioner "file" {
    source      = "./hosts.yaml"
    destination = "/opt/zstack-edge/kubespray/inventory/sample/hosts.yaml"
    on_failure = fail
  }

  provisioner "local-exec" {
    command = "echo 'Host ${zstack_vm.vm.2.ip} is copy file' >> connection.log 2>&1"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /opt/zstack-edge/kubespray",
      "sed -i \"s|/dev/sdb|/dev/$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT | grep disk | awk 'NR==2 {print $1}')|g\" inventory/sample/hosts.yaml",
       "ansible-playbook -i inventory/sample/hosts.yaml zaku-management-cluster.yml > /var/log/zstack-edge-installer.log"
    ]
    on_failure = fail
  }
}

resource "terraform_data" "change_local_nginxconfig_reload" {
  depends_on = [local_file.cloud_nginx]
  provisioner "local-exec" {
    command = "cp ./zaku.http.nginx.conf ${data.external.check_mn.result["zstack_config_path"]}/configs/zaku.http.nginx.conf && /usr/sbin/nginx -s reload -c ${data.external.check_mn.result["zstack_config_path"]}/configs/nginx.conf -p ${data.external.check_mn.result["zstack_config_path"]}"
  }
}

locals {
  private_key_path = "${data.external.check_mn.result["zstack_home"]}/WEB-INF/classes/ansible/rsaKeys/id_rsa"
  private_key      = fileexists(local.private_key_path) ? file(local.private_key_path) : ""
}

resource "terraform_data" "change_remote_nginxconfig_reload" {
  count = data.external.check_mn.result["peer_ip"] != "" ? 1 : 0
  depends_on = [local_file.cloud_nginx]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = local.private_key
    host        = data.external.check_mn.result["peer_ip"]
  }
  provisioner "file" {
    source      = "./zaku.http.nginx.conf"
    destination = "${data.external.check_mn.result["zstack_config_path"]}/configs/zaku.http.nginx.conf"
    on_failure = fail
  }
  provisioner "remote-exec" {
    inline = [
    "/usr/sbin/nginx -s reload -c ${data.external.check_mn.result["zstack_config_path"]}/configs/nginx.conf -p ${data.external.check_mn.result["zstack_config_path"]}"
    ]
  }
}

