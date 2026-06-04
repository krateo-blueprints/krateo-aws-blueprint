# Krateo Stack — AWS RDS

A **composite** Krateo blueprint that provisions an AWS RDS database as one Composition,
replicating the [`terraform-aws-modules/rds/aws`](https://registry.terraform.io/modules/terraform-aws-modules/rds/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **rds** controller.

> **Try it end-to-end:** see [quickstart.md](quickstart.md) — install on kind and provision a real
> RDS database step by step.

## How it works

One `AwsRdsStack` Composition is rendered by Krateo's composition-dynamic-controller into native
ACK rds resources. Each resource reconciles through the ACK state machine — **New → Resolving
refs → Creating (AWS API) → Synced/Ready** — where a resource stays in *Resolving refs* until
every `*Ref` target it points at is itself `Synced`, and retries on `ACK.Recoverable` errors.
Because the `DBInstance` references the `DBSubnetGroup` (`dbSubnetGroupRef`) and, when created,
the `DBParameterGroup` (`dbParameterGroupRef`), they come up in dependency order:
**DBSubnetGroup (+ DBParameterGroup) → DBInstance**.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsRdsStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| DB subnet group | `DBSubnetGroup` | built from `subnet_ids` (`spec.subnetIDs`); only when `create_db_subnet_group` and `subnet_ids` non-empty |
| DB parameter group | `DBParameterGroup` | built from `parameters` (`spec.parameterOverrides`) + `family`; only when `create_db_parameter_group` |
| DB instance | `DBInstance` | `dbSubnetGroupRef` → DBSubnetGroup, `dbParameterGroupRef` → DBParameterGroup |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated core
subset of its 100+ inputs). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `identifier` | string | The name of the RDS instance. |
| `engine` / `engine_version` | string | Database engine and version. |
| `instance_class` | string | The instance type of the RDS instance. |
| `allocated_storage` / `max_allocated_storage` | number | Storage size and autoscaling upper limit. |
| `storage_type` / `iops` / `storage_throughput` | string/number | Storage class and provisioned IOPS / throughput. |
| `storage_encrypted` / `kms_key_id` | bool / string | Encryption at rest and KMS key ARN. |
| `db_name` | string | Initial database name. |
| `username` | string | Master DB username. |
| `manage_master_user_password` | bool | Let RDS manage the master password in Secrets Manager. |
| `master_user_password_secret` | object | **Krateo/ACK wiring** — Secret reference (`name`/`namespace`/`key`) used when `manage_master_user_password` is false. |
| `port` | string | Port the DB accepts connections on. |
| `multi_az` / `availability_zone` | bool / string | Multi-AZ deployment or a specific AZ. |
| `publicly_accessible` / `network_type` | bool / string | Public access and IPV4/DUAL network type. |
| `subnet_ids` | list(string) | VPC subnet IDs used to build the DB subnet group. |
| `vpc_security_group_ids` | list(string) | VPC security groups to associate. |
| `backup_retention_period` / `backup_window` / `maintenance_window` | number / string | Backup and maintenance scheduling. |
| `copy_tags_to_snapshot` / `deletion_protection` / `auto_minor_version_upgrade` | bool | Lifecycle flags. |
| `iam_database_authentication_enabled` / `performance_insights_enabled` | bool | IAM auth and Performance Insights. |
| `enabled_cloudwatch_logs_exports` | list(string) | Log types to export to CloudWatch. |
| `license_model` / `ca_cert_identifier` | string | License model and CA certificate identifier. |
| `monitoring_interval` / `monitoring_role_arn` | number / string | Enhanced Monitoring. |
| `create_db_subnet_group` / `db_subnet_group_name` / `db_subnet_group_description` | bool / string | Create vs reference a DB subnet group. |
| `create_db_parameter_group` / `parameter_group_name` / `parameter_group_description` / `family` / `parameters` | bool / string / map(string) | Create vs reference a DB parameter group. |
| `tags` / `db_instance_tags` / `db_subnet_group_tags` / `db_parameter_group_tags` | map(string) | Tags. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Master user password

The Terraform module accepts the master password as a literal string (or manages it in Secrets
Manager). ACK's `DBInstance` instead requires a `masterUserPassword` **SecretKeyRef**. This stack
therefore:

- Defaults to `manage_master_user_password: true` — RDS generates and manages the password in
  AWS Secrets Manager, so no Kubernetes Secret is needed.
- When `manage_master_user_password: false`, set `master_user_password_secret` to reference an
  existing Kubernetes Secret:

  ```yaml
  master_user_password_secret:
    name: krateo-rds-master   # Secret in the Composition namespace (or set namespace)
    key: password             # key inside the Secret
  ```

## Limitations

- This stack provisions only the RDS resources (subnet group, instance, optional parameter
  group). Inputs that reference **existing external resources** are passed through by ID/ARN and
  are **not** created here:
  - `subnet_ids` — must be existing VPC subnet IDs (used to build the DB subnet group).
  - `vpc_security_group_ids` — must be existing security group IDs.
  - `kms_key_id`, `monitoring_role_arn` — must be existing KMS key / IAM role ARNs.
- Mirrors the module's **core** inputs, not all 100+. The TF `parameters` list-of-objects input
  is expressed here as a `map(string)` (name → value), matching ACK `parameterOverrides`;
  per-parameter `apply_method` is not exposed.
- The TF module's IAM monitoring role, CloudWatch log group, and option group sub-resources are
  not composed; supply `monitoring_role_arn` for Enhanced Monitoring.

## Prerequisites

- **ACK rds controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/rds-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs RDS create/modify/delete permissions.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-rds-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsRdsStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsRdsStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awsrdsstacks`), pulling `oci://ghcr.io/braghettos/charts/aws-rds-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsRdsStack
metadata:
  name: my-rds
  namespace: aws-rds-system
spec:
  region: eu-central-1
  identifier: my-rds
  engine: postgres
  engine_version: "16.4"
  instance_class: db.t3.micro
  allocated_storage: 20
  storage_encrypted: true
  db_name: appdb
  username: krateoadmin
  manage_master_user_password: true
  subnet_ids: ["subnet-aaa", "subnet-bbb"]
  vpc_security_group_ids: ["sg-123"]
  backup_retention_period: 7
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsrdsstack -n aws-rds-system
kubectl get dbinstances.rds.services.k8s.aws,dbsubnetgroups.rds.services.k8s.aws -n aws-rds-system
```

> **Note:** mirrors the module's core inputs, not all 100+. Set `create_db_subnet_group: false`
> with `db_subnet_group_name` to attach to a pre-existing subnet group.
