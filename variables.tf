variable "DBPass" {
  description = "The password for the database"
  type        = string
}

variable "Environment" {
  description = "Deployment environment name (e.g., dev, prod)"
  type        = string
}

variable "Owner" {
  description = "Owner or project responsible party"
  type        = string
}
