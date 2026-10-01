locals {
  global_admin_template_id = "62e90394-69f5-4237-9190-012177145e10"
}

data "azuread_user" "break_glass" {
  user_principal_name = var.break_glass_upn
}

# Report-only first: see who would be affected before enforcing anything
resource "azuread_conditional_access_policy" "admin_mfa" {
  display_name = "CA001-${var.lab_prefix}-require-mfa-for-admin-roles"
  state        = "enabledForReportingButNotEnforced"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles = [
        local.global_admin_template_id,
        azuread_directory_role.user_admin.template_id,
      ]
      # Excluding the admin running this lab, standing in for a break-glass account
        excluded_users = [data.azuread_user.break_glass.object_id]
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
