# Krateo Stack — AWS Security Group

A **composite** Krateo blueprint that provisions an AWS EC2 Security Group with its ingress and
egress rules as one Composition, replicating the
[`terraform-aws-modules/security-group/aws`](https://registry.terraform.io/modules/terraform-aws-modules/security-group/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **ec2** controller.

## How it works

One `AwsSecurityGroupStack` Composition is rendered by Krateo's composition-dynamic-controller
into a single native ACK ec2 `SecurityGroup` resource, with the ingress/egress rules inlined into
its `spec.ingressRules` / `spec.egressRules`. The resource reconciles through the ACK state
machine — **New → Resolving refs → Creating (AWS API) → Synced/Ready** — and retries on
`ACK.Recoverable` errors. The security group is attached to an **existing** VPC by ID
(`vpc_id` → `spec.vpcID`); deleting the Composition tears the real security group (and its rules)
down.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes ACK resources from the module's interface. Creating one `AwsSecurityGroupStack`
Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| Security Group | `SecurityGroup` | `vpcID` → existing VPC; ingress/egress rules inlined in `ingressRules`/`egressRules` |

Each Terraform-style rule object is mapped into an ACK `IpPermission`:

| Terraform rule field | ACK rule field |
| -------------------- | -------------- |
| `ip_protocol` | `ipProtocol` |
| `from_port` | `fromPort` |
| `to_port` | `toPort` |
| `cidr_ipv4` | `ipRanges[].cidrIP` |
| `cidr_ipv6` | `ipv6Ranges[].cidrIPv6` |
| `prefix_list_id` | `prefixListIDs[].prefixListID` |
| `referenced_security_group_id` | `userIDGroupPairs[].groupID` |
| `description` | `ipRanges[].description` (etc.) |

The convenience inputs `ingress_cidr_blocks` / `egress_cidr_blocks` add one IPv4 range per listed
CIDR to every rule that does not already set `cidr_ipv4`.

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated core
subset of its inputs). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | string | Name of security group. **Required.** |
| `description` | string | Description of security group. |
| `vpc_id` | string | ID of the **existing** VPC where the SG is created. |
| `ingress_rules` | list(object) | Ingress rules (`ip_protocol`, `from_port`, `to_port`, `cidr_ipv4`, `cidr_ipv6`, `prefix_list_id`, `referenced_security_group_id`, `description`). |
| `egress_rules` | list(object) | Egress rules (same shape as `ingress_rules`). |
| `ingress_cidr_blocks` | list(string) | IPv4 CIDR ranges applied to ingress rules with no explicit `cidr_ipv4`. |
| `egress_cidr_blocks` | list(string) | IPv4 CIDR ranges applied to egress rules with no explicit `cidr_ipv4`. |
| `revoke_rules_on_delete` | bool | Carried from the module; informational only (ACK handles rule teardown on delete). |
| `tags` | map(string) | Tags added to the security group. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Prerequisites

- **ACK ec2 controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/ec2-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs EC2 security-group permissions.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-security-group-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsSecurityGroupStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsSecurityGroupStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awssecuritygroupstacks`), pulling `oci://ghcr.io/braghettos/charts/aws-security-group-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsSecurityGroupStack
metadata:
  name: my-web-sg
  namespace: aws-security-group-system
spec:
  region: eu-central-1
  name: my-web-sg
  description: "Web tier security group"
  vpc_id: vpc-0123456789abcdef0
  ingress_rules:
    - description: "HTTP from anywhere"
      from_port: 80
      to_port: 80
      ip_protocol: tcp
      cidr_ipv4: "0.0.0.0/0"
    - description: "HTTPS from anywhere"
      from_port: 443
      to_port: 443
      ip_protocol: tcp
      cidr_ipv4: "0.0.0.0/0"
  egress_rules:
    - description: "All outbound"
      from_port: -1
      to_port: -1
      ip_protocol: "-1"
      cidr_ipv4: "0.0.0.0/0"
  tags:
    team: platform
```

### Verify

```sh
kubectl get awssecuritygroupstack -n aws-security-group-system
kubectl get securitygroups.ec2.services.k8s.aws -n aws-security-group-system
```

## Limitations

- Mirrors the module's **core** inputs, not all of them (e.g. `use_name_prefix`, `timeouts`,
  `vpc_associations`, `enable_exclusive_rules` are not exposed).
- The **VPC must already exist** — `vpc_id` is passed straight to the ACK `SecurityGroup` as
  `spec.vpcID`. Likewise `referenced_security_group_id` and `prefix_list_id` reference
  **existing** external resources by ID; this stack does not create them.
- `revoke_rules_on_delete` is accepted for input-name parity but has no effect: the ACK controller
  removes the security group and its inlined rules together when the Composition is deleted.
- The TF module models `ingress_rules`/`egress_rules` as maps; here they are modeled as a list of
  rule objects so the Krateo form can render them, with each rule mapped to one ACK `IpPermission`.
