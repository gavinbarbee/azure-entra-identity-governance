output "manager_upn" {
  value = azuread_user.manager.user_principal_name
}

output "employee_upn" {
  value = azuread_user.employee.user_principal_name
}

output "contractor_upn" {
  value = azuread_user.contractor.user_principal_name
}

output "access_package_name" {
  value = azuread_access_package.contractor_apollo.display_name
}

output "conditional_access_policy_name" {
  value = azuread_conditional_access_policy.admin_mfa.display_name
}

# Read locally only if needed: terraform output -json initial_passwords
output "initial_passwords" {
  value = {
    for k, v in random_password.user : k => v.result
  }
  sensitive = true
}
