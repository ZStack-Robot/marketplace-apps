terraform {
  required_providers {
    zstack = {
      source = "zstack.io/terraform-provider-zstack/zstack"
    }
    grafana = {
      source = "grafana/grafana"
      version = "3.2.1"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.3"
    }
  }
}