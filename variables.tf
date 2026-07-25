variable "compartment_id" {
  description = "OCID of the compartment in which to create the NAT gateway. The tenancy OCID is accepted, since the root compartment is identified by it."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment OCID (\"ocid1.compartment....\") or, for the root compartment, the tenancy OCID (\"ocid1.tenancy....\")."
  }
}

variable "vcn_id" {
  description = "OCID of the VCN the NAT gateway belongs to."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.vcn\\.", var.vcn_id))
    error_message = "vcn_id must be a VCN OCID (\"ocid1.vcn....\"). Subnet and compartment OCIDs are rejected here on purpose."
  }
}

variable "display_name" {
  description = "Human-readable name for the NAT gateway. 1-255 characters; not required to be unique."
  type        = string

  validation {
    condition     = length(var.display_name) >= 1 && length(var.display_name) <= 255
    error_message = "display_name must be between 1 and 255 characters."
  }
}

variable "block_traffic" {
  description = "Break-glass switch. When true, OCI drops ALL traffic through this NAT gateway; the gateway still exists and routes still point at it, so private subnets simply lose outbound internet. Leave false for a working gateway."
  type        = bool
  default     = false
}

variable "public_ip_id" {
  description = "OCID of a reserved public IP to assign. Null lets Oracle allocate an ephemeral public IP, which changes if the gateway is recreated."
  type        = string
  default     = null

  validation {
    condition     = var.public_ip_id == null || can(regex("^ocid1\\.publicip\\.", var.public_ip_id))
    error_message = "public_ip_id must be a reserved public IP OCID (\"ocid1.publicip....\") or null."
  }
}

variable "route_table_id" {
  description = "OCID of the route table the gateway uses. Null uses the VCN default."
  type        = string
  default     = null

  validation {
    condition     = var.route_table_id == null || can(regex("^ocid1\\.routetable\\.", var.route_table_id))
    error_message = "route_table_id must be a route table OCID (\"ocid1.routetable....\") or null."
  }
}

variable "freeform_tags" {
  description = "Free-form tags applied to the NAT gateway."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the NAT gateway, keyed as \"namespace.key\"."
  type        = map(string)
  default     = {}
}
