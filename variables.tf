variable "ca_file" {
  type = string
}

variable "docker_cert" {
  type = string
}

variable "docker_key" {
  type = string
  sensitive = true
}

variable "ci_db_user" {
  type = string
}

variable "ci_db_password" {
  type = string
  sensitive = true
}

variable "ci_secret_client" {
  type = string
  sensitive = true
}

variable "ci_secret_tsa" {
  type = string
  sensitive = true
}
