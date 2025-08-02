# see https://github.com/hashicorp/terraform
terraform {
  required_version = "1.12.2"
  required_providers {
    # see https://github.com/keycloak/terraform-provider-keycloak
    # see https://registry.terraform.io/providers/keycloak/keycloak
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.4.0"
    }
  }
  backend "local" {
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "https://pandora.incus.test:8443"
}
