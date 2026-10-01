# Catalog: the container of resources that can be handed out
resource "azuread_access_package_catalog" "contractors" {
  display_name = "cat-${var.lab_prefix}-contractor-resources"
  description  = "Resources that contractors can be granted through access packages"
}

resource "azuread_access_package_resource_catalog_association" "project_apollo" {
  catalog_id             = azuread_access_package_catalog.contractors.id
  resource_origin_id     = azuread_group.project_apollo.object_id
  resource_origin_system = "AadGroup"
}

# Access package: everything a contractor on Project Apollo needs, as one bundle
resource "azuread_access_package" "contractor_apollo" {
  catalog_id   = azuread_access_package_catalog.contractors.id
  display_name = "ap-${var.lab_prefix}-contractor-project-apollo"
  description  = "Time-boxed Project Apollo access for contractors"
}

resource "azuread_access_package_resource_package_association" "project_apollo" {
  access_package_id               = azuread_access_package.contractor_apollo.id
  catalog_resource_association_id = azuread_access_package_resource_catalog_association.project_apollo.id
}

# Policy: who can request, who approves, when it expires, and how often it gets reviewed
resource "azuread_access_package_assignment_policy" "contractor_apollo" {
  access_package_id = azuread_access_package.contractor_apollo.id
  display_name      = "pol-${var.lab_prefix}-contractor-${var.contractor_access_days}-days"
  description       = "Manager approval, ${var.contractor_access_days}-day expiry, quarterly access review"
  duration_in_days  = var.contractor_access_days

  requestor_settings {
    scope_type = "AllExistingDirectoryMemberUsers"
  }

  approval_settings {
    approval_required = true

    approval_stage {
      approval_timeout_in_days = 14

      primary_approver {
        object_id    = azuread_user.manager.object_id
        subject_type = "singleUser"
      }
    }
  }

  # Access review built into the assignment: if the reviewer doesn't confirm, access is removed
  assignment_review_settings {
    enabled                        = true
    review_frequency               = "quarterly"
    duration_in_days               = 14
    review_type                    = "Reviewers"
    access_review_timeout_behavior = "removeAccess"

    reviewer {
      object_id    = azuread_user.manager.object_id
      subject_type = "singleUser"
    }
  }
}
