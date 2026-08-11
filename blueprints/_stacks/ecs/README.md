# Krateo Stack — AWS ECS

A **composite** Krateo blueprint that provisions an AWS ECS workload as one Composition,
replicating the [`terraform-aws-modules/ecs/aws`](https://registry.terraform.io/modules/terraform-aws-modules/ecs/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **ecs** controller.

> **Try it end-to-end:** see [quickstart.md](quickstart.md) — install on kind and provision a real
> AWS ECS cluster, task definition and service.

## How it works

One `AwsEcsStack` Composition is rendered by Krateo's composition-dynamic-controller into three
native ACK ecs resources: a **Cluster**, a **TaskDefinition**, and a **Service**. Each resource
reconciles through the ACK state machine — **New → Resolving refs → Creating (AWS API) →
Synced/Ready** — where a resource stays in *Resolving refs* until every `*Ref` target it points
at is itself `Synced`, and retries on `ACK.Recoverable` errors. Because the Service references
the Cluster (`clusterRef`) and the TaskDefinition (`taskDefinitionRef`), they come up in strict
dependency order: **Cluster + TaskDefinition → Service**.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsEcsStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| Cluster | `Cluster` | — (`spec.name` = `cluster_name`) |
| Task definition | `TaskDefinition` | — (`family`, `containerDefinitions`, `cpu`, `memory`, `requiresCompatibilities`, `networkMode`, optional `executionRoleARN`/`taskRoleARN`) |
| Service | `Service` | `clusterRef` → Cluster, `taskDefinitionRef` → TaskDefinition; `networkConfiguration.awsVPCConfiguration` populated from `subnet_ids` / `security_group_ids` |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** — a curated CORE
subset of its inputs: the cluster-level inputs plus the per-service inputs from the module's
deeply-nested `services` map, flattened for a single service. Full schema in
[`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `cluster_name` | string | Name of the cluster. |
| `cluster_setting` | list(object) | Cluster settings (e.g. `containerInsights`). |
| `default_capacity_provider_strategy` | map(object) | Default capacity provider strategy (base/weight per provider). |
| `cluster_capacity_providers` | list(string) | Capacity providers to associate (e.g. `FARGATE`, `FARGATE_SPOT`). |
| `family` | string | Task definition family name. |
| `container_name` | string | Container name in the task definition. |
| `image` | string | Container image. |
| `container_port` | number | Container port mapping. |
| `cpu` / `memory` | string | Task-level CPU units / memory (MiB) as strings. |
| `network_mode` | string | `awsvpc` / `bridge` / `host` / `none`. |
| `requires_compatibilities` | list(string) | Launch types required (e.g. `["FARGATE"]`). |
| `task_exec_iam_role_arn` | string | **Existing** task execution role ARN → `executionRoleARN`. |
| `tasks_iam_role_arn` | string | **Existing** task role ARN → `taskRoleARN`. |
| `desired_count` | number | Number of tasks to keep running. |
| `launch_type` | string | `FARGATE` / `EC2` / `EXTERNAL`. |
| `platform_version` | string | Fargate platform version. |
| `scheduling_strategy` | string | `REPLICA` / `DAEMON`. |
| `assign_public_ip` | bool | Assign public IP to the task ENI (`awsvpc`). |
| `subnet_ids` | list(string) | **Existing** subnet IDs → `awsVPCConfiguration.subnets`. |
| `security_group_ids` | list(string) | **Existing** security group IDs → `awsVPCConfiguration.securityGroups`. |
| `enable_execute_command` | bool | Turn on ECS Exec for the service. |
| `enable_ecs_managed_tags` | bool | Turn on ECS managed tags. |
| `tags` / `cluster_tags` / `service_tags` | map(string) | Tags. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Prerequisites

- **ACK ecs controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/ecs-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs ECS cluster/task-definition/service permissions (and `iam:PassRole` for the
  task roles).
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-ecs-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsEcsStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsEcsStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awsecsstacks`), pulling `oci://ghcr.io/krateo-blueprints/charts/aws-ecs-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsEcsStack
metadata:
  name: my-ecs
  namespace: aws-ecs-system
spec:
  region: eu-central-1
  cluster_name: my-ecs
  cluster_setting:
    - name: containerInsights
      value: enabled
  family: my-app
  container_name: app
  image: public.ecr.aws/nginx/nginx:latest
  container_port: 80
  cpu: "256"
  memory: "512"
  network_mode: awsvpc
  requires_compatibilities: ["FARGATE"]
  desired_count: 1
  launch_type: FARGATE
  assign_public_ip: true
  subnet_ids: ["subnet-0123456789abcdef0"]
  security_group_ids: ["sg-0123456789abcdef0"]
  task_exec_iam_role_arn: "arn:aws:iam::111122223333:role/ecsTaskExecutionRole"
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsecsstack -n aws-ecs-system
kubectl get clusters.ecs.services.k8s.aws,taskdefinitions.ecs.services.k8s.aws,services.ecs.services.k8s.aws -n aws-ecs-system
```

## Limitations

- Mirrors the module's **core** inputs for a **single service**, not all 60+ top-level inputs nor
  the full nested `services` map (auto-scaling, multiple services, load balancers, service
  connect, EBS volume configuration, etc. are out of scope).
- The Terraform module can **create** supporting resources (IAM task-exec/task roles, a security
  group, a CloudWatch log group, a VPC association). This stack does **not** create those. Inputs
  that reference EXISTING external resources are accepted by their TF names and passed through as
  IDs/ARNs:
  - `subnet_ids` → `Service.networkConfiguration.awsVPCConfiguration.subnets`
  - `security_group_ids` → `Service.networkConfiguration.awsVPCConfiguration.securityGroups`
  - `task_exec_iam_role_arn` → `TaskDefinition.executionRoleARN`
  - `tasks_iam_role_arn` → `TaskDefinition.taskRoleARN`

  Provide a VPC/subnets/security-groups (e.g. via the sibling `aws-vpc-stack`) and IAM roles out
  of band.
- `network_mode: awsvpc` requires `subnet_ids` (and usually `security_group_ids`) to be set for
  the Service to reconcile; the `networkConfiguration` block is only rendered when at least one
  of them is provided.
