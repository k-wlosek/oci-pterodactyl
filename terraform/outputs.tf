output "instance_public_ip" {
  value = oci_core_instance.ptero_vm.public_ip
}

output "instance_ocid" {
  value = oci_core_instance.ptero_vm.id
}
