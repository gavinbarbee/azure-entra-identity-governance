# The signed-in admin running Terraform (excluded from Conditional Access as the break-glass stand-in)
data "azuread_client_config" "current" {}

data "azuread_domains" "initial" {
  only_initial = true
}

locals {
  domain = data.azuread_domains.initial.domains[0].domain_name
}

resource "random_password" "user" {
  for_each         = toset(["manager", "employee", "contractor"])
  length           = 20
  special          = true
  override_special = "!@#%*-_"
}

# Manager: approves access requests and reviews contractor access
resource "azuread_user" "manager" {
  user_principal_name   = "${var.lab_prefix}-manager@${local.domain}"
  display_name          = "Maya Manager (${var.lab_prefix} lab)"
  department            = "Engineering"
  job_title             = "Engineering Manager"
  employee_type         = "Employee"
  usage_location        = "US"
  password              = random_password.user["manager"].result
  force_password_change = true
}

# Employee: holds an ELIGIBLE (not permanent) admin role through PIM
resource "azuread_user" "employee" {
  user_principal_name   = "${var.lab_prefix}-employee@${local.domain}"
  display_name          = "Eli Employee (${var.lab_prefix} lab)"
  department            = "IT"
  job_title             = "Systems Administrator"
  employee_type         = "Employee"
  usage_location        = "US"
  manager_id            = azuread_user.manager.object_id
  password              = random_password.user["employee"].result
  force_password_change = true
}

# Contractor: gets time-boxed access, then is offboarded by the leaver workflow
resource "azuread_user" "contractor" {
  user_principal_name   = "${var.lab_prefix}-contractor@${local.domain}"
  display_name          = "Casey Contractor (${var.lab_prefix} lab)"
  department            = "Contractors"
  job_title             = "Contract Developer"
  employee_type         = "Contractor"
  usage_location        = "US"
  manager_id            = azuread_user.manager.object_id
  password              = random_password.user["contractor"].result
  force_password_change = true
}

# The resource the contractor needs. Access is granted ONLY through the access package, never directly.
resource "azuread_group" "project_apollo" {
  display_name     = "grp-${var.lab_prefix}-project-apollo"
  description      = "Project Apollo resources. Membership granted through entitlement management only."
  security_enabled = true
}
