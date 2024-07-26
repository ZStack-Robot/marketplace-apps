variable "memory_size" {
    type = number
    default = 34359738368
}

variable "cpu_num" {
    type = number
    default = 16
}

variable "root_disk_size" {
    type = number
    default = 107374182400
}

variable "l3_network_uuids" {
    type = list
    default = []
}

variable "primary_storage_uuid" {
    type = string
}

variable "primary_storage_ceph_pool_uuid" {
    type = string
}

variable "cluster_uuid" {
    type = string
}