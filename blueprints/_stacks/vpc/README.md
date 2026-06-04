# Krateo Stack — AWS VPC

A **composite** Krateo blueprint that provisions a full AWS VPC as one Composition, replicating
the [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **ec2** controller.

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsVpcStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| VPC | `VPC` | — |
| Internet Gateway | `InternetGateway` | `vpcRef` → VPC |
| Public route table | `RouteTable` | `vpcRef` → VPC, route `0.0.0.0/0` → `gatewayRef` IGW |
| Public subnets (per CIDR) | `Subnet` | `vpcRef` → VPC, `routeTableRefs` → public RT |
| NAT EIP(s) | `ElasticIPAddress` | — |
| NAT gateway(s) | `NATGateway` | `subnetRef` → public subnet, `allocationRef` → EIP |
| Private route table(s) | `RouteTable` | `vpcRef` → VPC, route `0.0.0.0/0` → `natGatewayRef` NAT |
| Private subnets (per CIDR) | `Subnet` | `vpcRef` → VPC, `routeTableRefs` → private RT |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated subset
of its 200+ inputs). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | string | Name used on all resources as identifier. |
| `cidr` | string | IPv4 CIDR block for the VPC. |
| `azs` | list(string) | Availability zone names. |
| `public_subnets` | list(string) | Public subnet CIDR blocks (paired with `azs` by index). |
| `private_subnets` | list(string) | Private subnet CIDR blocks. |
| `enable_nat_gateway` | bool | Provision NAT gateway(s) for private subnets. |
| `single_nat_gateway` | bool | One shared NAT (vs one per public subnet/AZ). |
| `enable_dns_hostnames` / `enable_dns_support` | bool | VPC DNS settings. |
| `map_public_ip_on_launch` | bool | Auto-assign public IPs in public subnets. |
| `instance_tenancy` | string | `default` / `dedicated`. |
| `create_igw` | bool | Create an Internet Gateway for public subnets. |
| `tags` / `public_subnet_tags` / `private_subnet_tags` | map(string) | Tags. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Prerequisites

- **ACK ec2 controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/ec2-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs EC2 VPC/subnet/route-table/IGW/NAT/EIP permissions.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-vpc-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsVpcStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsVpcStack` Composition type (`composition.krateo.io/v0-2-0`, plural
`awsvpcstacks`), pulling `oci://ghcr.io/braghettos/charts/aws-vpc-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-2-0
kind: AwsVpcStack
metadata:
  name: my-vpc
  namespace: aws-vpc-system
spec:
  region: eu-central-1
  name: my-vpc
  cidr: "10.0.0.0/16"
  azs: ["eu-central-1a", "eu-central-1b"]
  public_subnets:  ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets: ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway: true
  single_nat_gateway: true
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsvpcstack -n aws-vpc-system
kubectl get vpcs.ec2.services.k8s.aws,subnets.ec2.services.k8s.aws,natgateways.ec2.services.k8s.aws -n aws-vpc-system
```

> **Note:** mirrors the module's core inputs, not all 200+. NAT supports `single_nat_gateway`
> (one NAT) or one NAT per public subnet/AZ when `false`.
