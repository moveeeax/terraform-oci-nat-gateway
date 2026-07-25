# terraform-oci-nat-gateway

Terraform module that manages an [Oracle Cloud Infrastructure](https://www.oracle.com/cloud/)
NAT gateway inside an existing VCN, letting instances in private subnets reach the
internet for outbound-only traffic.

## Usage

```hcl
module "nat_gateway" {
  source = "github.com/moveeeax/terraform-oci-nat-gateway"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "prod-nat"

  freeform_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

A runnable example lives in [`examples/basic`](examples/basic).

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5   |
| oci       | >= 5.0   |

## Inputs

| Name             | Description                                                                        | Type          | Default | Required |
|------------------|------------------------------------------------------------------------------------|---------------|---------|:--------:|
| `compartment_id` | Compartment OCID to create the gateway in. The tenancy OCID means root compartment. | `string`      | n/a     |   yes    |
| `vcn_id`         | OCID of the VCN the NAT gateway belongs to.                                        | `string`      | n/a     |   yes    |
| `display_name`   | Human-readable name for the NAT gateway. 1-255 characters.                         | `string`      | n/a     |    yes   |
| `block_traffic`  | Break-glass switch that drops **all** traffic through the gateway. See below.       | `bool`        | `false` |    no    |
| `public_ip_id`   | Reserved public IP OCID to assign. Null allocates an ephemeral one.                | `string`      | `null`  |    no    |
| `route_table_id` | Route table OCID the gateway uses. Null uses the VCN default.                      | `string`      | `null`  |    no    |
| `freeform_tags`  | Free-form tags applied to the NAT gateway.                                         | `map(string)` | `{}`    |    no    |
| `defined_tags`   | Defined tags applied to the gateway, keyed `namespace.key`.                        | `map(string)` | `{}`    |    no    |

The OCID inputs are validated for the right resource type, so a subnet OCID passed as
`vcn_id` (or a plain name passed as `compartment_id`) fails at plan time rather than
after a round trip to the OCI API.

### `block_traffic`

`block_traffic = true` does **not** delete or detach anything — the gateway is still
created and route rules still resolve, but OCI silently drops every packet through it,
so private subnets lose outbound internet while `terraform apply` reports success. It
exists as an incident break-glass switch. Leave it at the `false` default for a
working gateway.

### `public_ip_id`

Left null, OCI assigns an ephemeral public IP that changes whenever the gateway is
recreated. Pass a reserved public IP OCID if anything downstream allow-lists your
egress address.

## Outputs

| Name            | Description                                            |
|-----------------|--------------------------------------------------------|
| `id`            | OCID of the NAT gateway.                               |
| `nat_ip`        | Public IP the NAT gateway uses for outbound traffic.  |
| `block_traffic` | Whether the NAT gateway is currently blocking traffic.|
| `state`         | Lifecycle state of the NAT gateway.                   |

## Development

```
terraform init -backend=false
terraform validate
terraform test
```

`terraform test` uses `mock_provider`, so it needs no OCI credentials and makes no API
calls. The tests require Terraform (or OpenTofu) >= 1.7 for `mock_provider`; the module
itself still supports >= 1.5.

## License

[MIT](LICENSE)
