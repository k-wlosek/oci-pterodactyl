variable "tenancy_ocid"     {}
variable "user_ocid"        {}
variable "fingerprint"      {}
variable "private_key_path" {}
variable "region"           {}

variable "compartment_id" {}
variable "ssh_public_key_path" {
  default = "~/.ssh/oci_ptero.pub"
}
variable "vm_name" {
  default = "pterodactyl-arm"
}
