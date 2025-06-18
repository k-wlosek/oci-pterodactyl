resource "oci_core_vcn" "main" {
  cidr_block     = "10.0.0.0/16"
  display_name   = "pterodactyl-vcn"
  compartment_id = var.compartment_id
  dns_label = "pterovcn"
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "ptero-igw"
}

resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "ptero-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw.id
  }
}

resource "oci_core_security_list" "sec_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "open-ingress"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "public_subnet" {
  cidr_block        = "10.0.0.0/24"
  display_name      = "ptero-subnet"
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main.id
  route_table_id    = oci_core_route_table.route_table.id
  security_list_ids = [oci_core_security_list.sec_list.id]
  dns_label         = "pterosubnet"
  prohibit_public_ip_on_vnic = false
}
