variable "tenant_id" {
  description = "Entra ID tenant ID for the lab tenant"
  type        = string
}

variable "lab_prefix" {
  description = "Prefix used in every display name so lab objects are easy to find and clean up"
  type        = string
  default     = "gavinbarbee"
}

variable "contractor_access_days" {
  description = "How long a contractor's access package assignment lasts before it expires on its own"
  type        = number
  default     = 90
}

variable "break_glass_upn" {
  description = "Admin account excluded from Conditional Access, standing in for a break-glass account"
  type        = string
}