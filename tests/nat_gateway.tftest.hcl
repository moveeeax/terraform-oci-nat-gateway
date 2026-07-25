# Test-only requirement: `mock_provider` needs Terraform >= 1.7 (or OpenTofu >= 1.7).
# The module itself still supports >= 1.5 -- do not bump versions.tf for these tests.
#
# Every run uses `command = plan` so nothing is ever sent to OCI: the mock
# provider satisfies provider configuration, and explicitly-configured
# attributes are known at plan time.

mock_provider "oci" {}

variables {
  compartment_id = "ocid1.compartment.oc1..aaaaaaaaexamplecompartment"
  vcn_id         = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  display_name   = "test-nat"
}

# --- defaults -----------------------------------------------------------

run "defaults_do_not_block_traffic" {
  command = plan

  assert {
    condition     = oci_core_nat_gateway.this.block_traffic == false
    error_message = "block_traffic must default to false. A NAT gateway created with block_traffic = true applies cleanly but silently drops all outbound traffic from private subnets."
  }

  assert {
    condition     = var.public_ip_id == null
    error_message = "public_ip_id must default to null so Oracle allocates an ephemeral public IP."
  }

  assert {
    condition     = var.route_table_id == null
    error_message = "route_table_id must default to null so the VCN default route table is used."
  }
}

# --- pass-through of the real knobs -------------------------------------

run "block_traffic_is_wired_to_the_resource" {
  command = plan

  variables {
    block_traffic = true
  }

  assert {
    condition     = oci_core_nat_gateway.this.block_traffic == true
    error_message = "block_traffic must be passed through to oci_core_nat_gateway."
  }
}

run "reserved_public_ip_is_wired_to_the_resource" {
  command = plan

  variables {
    public_ip_id = "ocid1.publicip.oc1.phx.aaaaaaaaexamplepublicip"
  }

  assert {
    condition     = oci_core_nat_gateway.this.public_ip_id == "ocid1.publicip.oc1.phx.aaaaaaaaexamplepublicip"
    error_message = "public_ip_id must be passed through so a reserved public IP survives gateway recreation."
  }
}

run "route_table_and_tags_are_wired_to_the_resource" {
  command = plan

  variables {
    route_table_id = "ocid1.routetable.oc1.phx.aaaaaaaaexampleroutetable"
    freeform_tags  = { Environment = "test" }
    defined_tags   = { "Operations.CostCenter" = "42" }
  }

  assert {
    condition     = oci_core_nat_gateway.this.route_table_id == "ocid1.routetable.oc1.phx.aaaaaaaaexampleroutetable"
    error_message = "route_table_id must be passed through to oci_core_nat_gateway."
  }

  assert {
    condition     = oci_core_nat_gateway.this.freeform_tags["Environment"] == "test"
    error_message = "freeform_tags must be passed through to oci_core_nat_gateway."
  }

  assert {
    condition     = oci_core_nat_gateway.this.defined_tags["Operations.CostCenter"] == "42"
    error_message = "defined_tags must be passed through to oci_core_nat_gateway."
  }

  assert {
    condition     = oci_core_nat_gateway.this.display_name == "test-nat"
    error_message = "display_name must be passed through to oci_core_nat_gateway."
  }
}

# --- OCID validation ----------------------------------------------------

run "root_compartment_may_be_given_as_a_tenancy_ocid" {
  command = plan

  variables {
    compartment_id = "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
  }

  assert {
    condition     = oci_core_nat_gateway.this.compartment_id == "ocid1.tenancy.oc1..aaaaaaaaexampletenancy"
    error_message = "The tenancy OCID identifies the root compartment and must be accepted for compartment_id."
  }
}

run "rejects_a_compartment_id_that_is_not_an_ocid" {
  command = plan

  variables {
    compartment_id = "my-compartment"
  }

  expect_failures = [var.compartment_id]
}

run "rejects_a_vcn_ocid_supplied_as_the_compartment_id" {
  command = plan

  variables {
    compartment_id = "ocid1.vcn.oc1.phx.aaaaaaaaexamplevcn"
  }

  expect_failures = [var.compartment_id]
}

run "rejects_a_subnet_ocid_supplied_as_the_vcn_id" {
  command = plan

  variables {
    vcn_id = "ocid1.subnet.oc1.phx.aaaaaaaaexamplesubnet"
  }

  expect_failures = [var.vcn_id]
}

run "rejects_a_public_ip_id_that_is_not_a_reserved_public_ip_ocid" {
  command = plan

  variables {
    public_ip_id = "ocid1.privateip.oc1.phx.aaaaaaaaexampleprivateip"
  }

  expect_failures = [var.public_ip_id]
}

run "rejects_a_route_table_id_that_is_not_a_route_table_ocid" {
  command = plan

  variables {
    route_table_id = "ocid1.securitylist.oc1.phx.aaaaaaaaexamplesecuritylist"
  }

  expect_failures = [var.route_table_id]
}

# --- display_name constraints -------------------------------------------

run "rejects_an_empty_display_name" {
  command = plan

  variables {
    display_name = ""
  }

  expect_failures = [var.display_name]
}

run "rejects_a_display_name_longer_than_255_characters" {
  command = plan

  variables {
    display_name = "nat-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }

  expect_failures = [var.display_name]
}
