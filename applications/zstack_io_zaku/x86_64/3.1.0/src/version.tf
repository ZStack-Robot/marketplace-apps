terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.4.1"
    }
    zstack = {
      source = "zstack.io/terraform-provider-zstack/zstack"
    }
    template = {
      source  = "hashicorp/template"
      version = "2.2.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.3"
    }
  }
}