# Krateo Stack — AWS EKS

A **composite** Krateo blueprint that provisions an AWS EKS cluster with one managed node group
as one Composition, replicating the
[`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **eks** controller.

> **Try it end-to-end:** see [quickstart.md](quickstart.md) — install on kind and provision a
> real EKS cluster + managed node group step by step.

## How it works

One `AwsEksStack` Composition is rendered by Krateo's composition-dynamic-controller into two
native ACK eks resources. Each resource reconciles through the ACK state machine — **New →
Resolving refs → Creating (AWS API) → Synced/Ready** — where a resource stays in *Resolving refs*
until every `*Ref` target it points at is itself `Synced`, and retries on `ACK.Recoverable`
errors. The `Nodegroup` references the `Cluster` via `clusterRef`, so they come up in strict
dependency order: **Cluster → Nodegroup** (a node group cannot be created until its control plane
is `ACTIVE`).

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsEksStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| EKS cluster | `Cluster` (`eks.services.k8s.aws/v1alpha1`) | `roleARN` ← `cluster_iam_role_arn`; `resourcesVPCConfig.subnetIDs` ← `control_plane_subnet_ids` (or `subnet_ids`) |
| Managed node group | `Nodegroup` (`eks.services.k8s.aws/v1alpha1`) | `clusterRef` → Cluster; `nodeRole` ← `node_iam_role_arn`; `subnets` ← `subnet_ids` |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated CORE
subset of its 100+ inputs). Per-node-group inputs from the module's `eks_managed_node_groups` map
are surfaced with a `node_` prefix (this stack creates exactly one node group). Full schema in
[`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | string | Name of the EKS cluster. |
| `kubernetes_version` | string | Kubernetes `<major>.<minor>` version (e.g. `1.33`). |
| `authentication_mode` | string | `CONFIG_MAP` / `API` / `API_AND_CONFIG_MAP`. |
| `endpoint_public_access` | bool | Enable the public API server endpoint. |
| `endpoint_private_access` | bool | Enable the private API server endpoint. |
| `cluster_endpoint_public_access_cidrs` | list(string) | CIDRs allowed to reach the public endpoint. |
| `subnet_ids` | list(string) | Subnet IDs for nodes/node group (and control plane if `control_plane_subnet_ids` empty). |
| `control_plane_subnet_ids` | list(string) | Subnet IDs for the control plane ENIs. |
| `additional_security_group_ids` | list(string) | Extra security group IDs for the control plane. |
| `service_ipv4_cidr` | string | Service IP CIDR block. |
| `ip_family` | string | `ipv4` / `ipv6`. |
| `enabled_log_types` | list(string) | Control plane log types to enable. |
| `cluster_iam_role_arn` | string | **Pre-existing** cluster IAM role ARN (TF `iam_role_arn`). |
| `node_iam_role_arn` | string | **Pre-existing** node group IAM role ARN. |
| `node_group_name` | string | Managed node group name (TF `eks_managed_node_groups` key). |
| `node_ami_type` | string | AMI type for the node group. |
| `node_capacity_type` | string | `ON_DEMAND` / `SPOT`. |
| `node_instance_types` | list(string) | Instance types for the node group. |
| `node_disk_size` | number | Worker node disk size (GiB). |
| `node_desired_size` / `node_min_size` / `node_max_size` | number | Node group scaling config. |
| `node_labels` | map(string) | Kubernetes labels on the nodes. |
| `tags` / `cluster_tags` | map(string) | Tags. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Prerequisites

- **ACK eks controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/eks-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs EKS cluster and node group permissions plus `iam:PassRole` for the supplied
  role ARNs.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-eks-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsEksStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsEksStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awseksstacks`), pulling `oci://ghcr.io/braghettos/charts/aws-eks-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsEksStack
metadata:
  name: my-eks
  namespace: aws-eks-system
spec:
  region: eu-central-1
  name: my-eks
  kubernetes_version: "1.33"
  authentication_mode: API_AND_CONFIG_MAP
  endpoint_public_access: true
  endpoint_private_access: true
  subnet_ids:
    - subnet-0123456789abcdef0
    - subnet-0123456789abcdef1
  cluster_iam_role_arn: arn:aws:iam::111122223333:role/my-eks-cluster-role
  node_iam_role_arn: arn:aws:iam::111122223333:role/my-eks-node-role
  node_group_name: default
  node_instance_types: ["m5.large"]
  node_desired_size: 2
  node_min_size: 1
  node_max_size: 3
  tags:
    team: platform
```

### Verify

```sh
kubectl get awseksstack -n aws-eks-system
kubectl get clusters.eks.services.k8s.aws,nodegroups.eks.services.k8s.aws -n aws-eks-system
```

## Limitations

This stack mirrors the module's **core** inputs, not all 100+, and composes exactly two ACK
resources (one `Cluster` + one managed `Nodegroup`). In particular:

- **No IAM creation.** The TF module optionally creates cluster/node IAM roles and the IRSA/OIDC
  provider; that is heavy and out of scope here. You must supply **pre-existing** role ARNs via
  `cluster_iam_role_arn` (cluster control-plane role) and `node_iam_role_arn` (worker node role).
- **No VPC creation.** The cluster and node group attach to **pre-existing** subnets passed by ID
  via `subnet_ids` / `control_plane_subnet_ids`. Use the companion `aws-vpc-stack` (or an existing
  VPC) to provision the network first. Likewise `additional_security_group_ids` are pre-existing.
- **One node group only.** The module's `eks_managed_node_groups` map can define many groups; this
  stack surfaces a single group via the `node_*` inputs. Self-managed and Fargate profiles, EKS
  add-ons, access entries, and the security-group rule plumbing from the module are not composed
  here (use the dedicated single-resource `blueprints/eks/*` charts for those).
- **No OIDC / cluster add-ons** (CoreDNS, kube-proxy, VPC-CNI managed add-ons) are created.
