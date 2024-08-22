all:
  hosts:
    k8s-1:
      ansible_host: ${host1_ip}
      ansible_port: 22
      ip: ${host1_ip}
    k8s-2:
      ansible_host: ${host2_ip}
      ansible_port: 22
      ip: ${host2_ip}
    k8s-3:
      ansible_host: ${host3_ip}
      ansible_port: 22
      ip: ${host3_ip}
  vars:
    # 基础配置==================================================
    # 机器密码
    cluster_host_root_password: "zstack@123@%"
    # 配置外部的ntp服务
    ntp_servers: [${ntp_servers_ip}]
    # 基础服务VIP，结合keepalived暴露K8S网关等
    cluster_vip: ${preserved_ip}
    # dns
    cluster_dns_servers: ["223.5.5.5"]

    # keepalived配置
    keepalived_config:
      - vip: ${preserved_ip}
        router_id: 76
        network_card: ${host_interface}

    # 存储配置==================================================
    # lvm盘符
    lvm_disks:
      k8s-1:
        - vg: "zecsi"
          devices: ["/dev/sdb"]
      k8s-2:
        - vg: "zecsi"
          devices: ["/dev/sdb"]
      k8s-3:
        - vg: "zecsi"
          devices: ["/dev/sdb"]
    # lvm存储映射
    lvm_storage_map:
      edge-lvm:
        vg: "zecsi"
        format: "ext4"

    # service网段
    kube_service_addresses: "10.233.0.0/18"
    # pod网段
    kube_pods_subnet: "10.233.64.0/18"

    # metallb配置
    # metallb的vip池，Zaku控制台vip要加入vip池。若环境是“IPv4和IPv6双栈”，则Zaku控制台IPv6 vip也要加入vip池，IPv6的前缀长度是128。
    # metallb_ip_range: ["172.31.16.85/32","2001:db8::100/128"]
    metallb_ip_range: [${metallb_ip}/32]
    # metallb的vip绑定的网卡
    metallb_interfaces: [${host_interface}]

    # 系统资源预留，默认每个节点预留4C8G
    node_system_reserved:
      k8s-1:
        system_cpu_reserved: 1
        system_memory_reserved: 2G
      k8s-2:
        system_cpu_reserved: 1
        system_memory_reserved: 2G
      k8s-3:
        system_cpu_reserved: 1
        system_memory_reserved: 2G

    # zaku配置==================================================

    # 设置为Zaku控制台vip
    zstack_gateway_ip: ${metallb_ip}

    # harbor配置
    # harbor的访问地址，一般和Zaku控制台vip一样
    zstack_harbor_external_domain: ${metallb_ip}
    # harbor证书需要信任的ip，如果zstack_harbor_external_domain是ip，一般和Zaku控制台vip一样
    harbor_cert_alt_ips: [${metallb_ip}]
    # harbor证书需要信任的域名，如果zstack_harbor_external_domain是域名
    harbor_cert_alt_names: []

    # 是否部署zadig
    zadig_enabled: ${devOps}

    # 是否接入ZStack云平台License
    zstack_license_docking: true
    # ZStack云平台API访问入口，仅当zstack_license_docking为true时需要该字段
    zstack_cloud_host: ${cloud_host}
    # ZStack云平台API访问Admin账号，仅当zstack_license_docking为true时需要该字段
    zstack_cloud_admin: ${cloud_account_name}
    # ZStack云平台API访问Admin账号密码，仅当zstack_license_docking为true时需要该字段
    zstack_cloud_admin_pwd: ${cloud_password}
    # ZStack云平台API访问Admin账号AccessKey ID，仅当zstack_license_docking为true时需要该字段
    zstack_cloud_admin_access_key_id: ${cloud_admin_access_key_id}
    # ZStack云平台API访问Admin账号AccessKey Secret，仅当zstack_license_docking为true时需要该字段
    zstack_cloud_admin_access_secret: ${admin_access_secret}
    # 是否嵌入ZStack云平台
    zstack_cloud_ui_embed: true
    # ZStack云平台控制台地址
    zstack_cloud_ui_url: ${cloud_host_ui}
    # ZStack云平台Nginx中的Zaku代理转发端口
    zstack_cloud_ui_zaku_port: 10998


# 如果有纯k8s worker，需要加入到kube_node下面
etcd:
  hosts:
    k8s-1: null
    k8s-2: null
    k8s-3: null
k8s_cluster:
  children:
    kube_control_plane:
      hosts:
        k8s-1: null
        k8s-2: null
        k8s-3: null
    kube_node: null
    calico_rr: null
vault: null
