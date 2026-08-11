# Krateo Stack — AWS IAM

A **composite** Krateo blueprint that provisions an AWS IAM role as one Composition, replicating
the [`terraform-aws-modules/iam/aws`](https://registry.terraform.io/modules/terraform-aws-modules/iam/aws)
module (its `iam-role` / `iam-assumable-role` submodules) on top of the
[ACK](https://aws-controllers-k8s.github.io/community/) **iam** controller.

> **Try it end-to-end:** see [quickstart.md](quickstart.md) — install on kind and provision a real
> IAM role through Krateo, with an [architecture diagram](docs/architecture.svg) of the composed
> resources.

## How it works

One `AwsIamStack` Composition is rendered by Krateo's composition-dynamic-controller into native
ACK iam resources: an `iam` **Role** plus, when `create_inline_policy` is true, an `iam` **Policy**
that the role attaches via `policyRefs`. Each resource reconciles through the ACK state machine —
**New → Resolving refs → Creating (AWS API) → Synced/Ready** — where the Role stays in *Resolving
refs* until the inline `Policy` it points at (`policyRefs`) is itself `Synced`. The trust policy
(`assumeRolePolicyDocument`) is taken from `assume_role_policy` if provided, otherwise generated
from `trusted_role_services`. Attached AWS-managed policies are passed through as ARNs in
`spec.policies`.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsIamStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| IAM role | `Role` | `assumeRolePolicyDocument` (from `assume_role_policy` / `trusted_role_services`), `policies` ← `managed_policy_arns`, `policyRefs` → inline Policy |
| Inline policy (when `create_inline_policy`) | `Policy` | referenced by the Role via `policyRefs` → `{name}-inline-policy` |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated core
subset). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `create` | bool | Controls if resources should be created (affects all resources). |
| `name` | string | Name to use on IAM role created. |
| `path` | string | Path of IAM role. |
| `description` | string | Description of the role. |
| `max_session_duration` | number | Maximum session duration (seconds), 3600–43200. |
| `permissions_boundary` | string | ARN of the policy used as the role's permissions boundary. |
| `assume_role_policy` | string | Trust relationship policy document (JSON). Maps to `assumeRolePolicyDocument`. |
| `trusted_role_services` | list(string) | AWS services that can assume the role; used to generate the trust policy when `assume_role_policy` is empty. |
| `managed_policy_arns` | list(string) | ARNs of **existing** managed policies to attach (→ `spec.policies`). |
| `create_inline_policy` | bool | Create a customer-managed policy from `inline_policy` and attach it. |
| `inline_policy` | string | JSON permissions document for the created policy (→ `Policy.spec.policyDocument`). |
| `tags` | map(string) | Tags added to all resources. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — sets the `services.k8s.aws/region` annotation; empty = controller default. |

## Prerequisites

- **ACK iam controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/iam-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs IAM role/policy permissions.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-iam-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsIamStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsIamStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awsiamstacks`), pulling `oci://ghcr.io/krateo-blueprints/charts/aws-iam-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsIamStack
metadata:
  name: my-iam-role
  namespace: aws-iam-system
spec:
  region: eu-central-1
  name: my-app-role
  path: "/"
  description: "Role for my app"
  trusted_role_services:
    - ec2.amazonaws.com
  managed_policy_arns:
    - "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  create_inline_policy: true
  inline_policy: |
    {"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:GetObject"],"Resource":"*"}]}
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsiamstack -n aws-iam-system
kubectl get roles.iam.services.k8s.aws,policies.iam.services.k8s.aws -n aws-iam-system
```

## Limitations

- Mirrors the module's **core** inputs, not all of them (the upstream module spans several
  submodules with many OIDC/SAML/condition options). The OIDC/SAML assume-role helpers, condition
  blocks, instance-profile creation, and group/user submodules are not composed here.
- Inputs that reference **existing external resources** are accepted as-is and passed through to
  ACK as ARNs — they are **not** created by this stack:
  - `managed_policy_arns` — ARNs of pre-existing managed policies (→ `Role.spec.policies`).
  - `permissions_boundary` — ARN of a pre-existing policy used as the boundary.
- IAM is a global service; `region` only sets the `services.k8s.aws/region` annotation consumed by
  the ACK controller.
