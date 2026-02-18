# oci3 (arm3) Instance Definition

resource "oci_core_vcn" "main_vcn" {
  cidr_block     = "10.3.0.0/16"
  compartment_id = oci_iam_compartment.network.id
  display_name   = "main-vcn"
  dns_label      = "mainvcn"
}

resource "oci_core_subnet" "private_subnet" {
  cidr_block        = "10.3.2.0/24"
  compartment_id    = oci_iam_compartment.network.id
  vcn_id            = oci_core_vcn.main_vcn.id
  display_name      = "private-subnet"
  dns_label         = "private"
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_instance" "oci3" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_iam_compartment.workloads.id
  display_name        = "oci3"
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.private_subnet.id
    display_name     = "primaryvnic"
    assign_public_ip = false
  }

  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  metadata = {
    ssh_authorized_keys = file("~/.ssh/atn_oci.pub")
    user_data           = base64encode(file("${path.module}/cloud-init.yml"))
  }

  preserve_boot_volume = false
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

variable "instance_image_ocid" {
  description = "OCID of the image to use"
}
