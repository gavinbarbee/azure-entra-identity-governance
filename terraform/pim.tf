# Activate the User Administrator role in the tenant so it can be referenced
resource "azuread_directory_role" "user_admin" {
  display_name = "User Administrator"
}

# ELIGIBLE assignment: the employee has no standing admin rights and must activate the role through PIM
resource "azuread_directory_role_eligibility_schedule_request" "employee_user_admin" {
  role_definition_id = azuread_directory_role.user_admin.template_id
  principal_id       = azuread_user.employee.object_id
  directory_scope_id = "/"
  justification      = "Lab: just-in-time User Administrator for helpdesk escalations"
}
