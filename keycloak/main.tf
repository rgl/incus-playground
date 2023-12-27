# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/realm
resource "keycloak_realm" "pandora" {
  realm                    = "pandora"
  verify_email             = true
  login_with_email_allowed = true
  reset_password_allowed   = true
  smtp_server {
    host = "localhost"
    port = 1025
    from = "keycloak@pandora.incus.test"
  }
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/group
resource "keycloak_group" "administrators" {
  realm_id = keycloak_realm.pandora.id
  name     = "administrators"
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/group_memberships
resource "keycloak_group_memberships" "administrators" {
  realm_id = keycloak_realm.pandora.id
  group_id = keycloak_group.administrators.id
  members = [
    keycloak_user.alice.username,
  ]
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/user
resource "keycloak_user" "alice" {
  realm_id       = keycloak_realm.pandora.id
  username       = "alice"
  email          = "alice@pandora.incus.test"
  email_verified = true
  first_name     = "Alice"
  last_name      = "Doe"
  // NB in a real program, omit this initial_password section and force a
  //    password reset.
  initial_password {
    value     = "alice"
    temporary = false
  }
}

# see https://registry.terraform.io/providers/mrparkers/keycloak/latest/docs/resources/openid_client
resource "keycloak_openid_client" "incus" {
  realm_id                                  = keycloak_realm.pandora.id
  description                               = "Incus"
  client_id                                 = "incus"
  access_type                               = "PUBLIC"
  oauth2_device_authorization_grant_enabled = true
}

# see https://developer.hashicorp.com/terraform/language/values/outputs
output "incus_oidc_client" {
  sensitive = true
  value = {
    client_id = keycloak_openid_client.incus.client_id
  }
}
