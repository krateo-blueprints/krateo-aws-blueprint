# Krateo Stack — AWS Auto Scaling group

A **composite** Krateo blueprint that provisions an EC2 Auto Scaling group as one Composition,
replicating the [`terraform-aws-modules/autoscaling/aws`](https://registry.terraform.io/modules/terraform-aws-modules/autoscaling/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **ec2** and
**autoscaling** controllers.

## How it works

One `AwsAutoscalingStack` Composition is rendered by Krateo's composition-dynamic-controller into
two native ACK resources: an ec2 **LaunchTemplate** and an autoscaling **AutoScalingGroup**. Each
resource reconciles through the ACK state machine — **New → Resolving refs → Creating (AWS API) →
Synced/Ready** — and retries on `ACK.Recoverable` errors.

The Auto Scaling group launches instances from the launch template created by the same stack. The
ACK `AutoScalingGroup` has no `launchTemplateRef` field, so the two resources are wired by the
**deterministic launch-template name** that the stack sets on both the LaunchTemplate
(`spec.name`) and the AutoScalingGroup (`spec.launchTemplate.launchTemplateName`). Once the
LaunchTemplate is `Synced`, the AutoScalingGroup resolves it by name and launches instances.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsAutoscalingStack` Composition
renders:

| Resource | ACK Kind | API group | Wiring |
| -------- | -------- | --------- | ------ |
| Launch template | `LaunchTemplate` | `ec2.services.k8s.aws/v1alpha1` | holds `image_id`, `instance_type`, `key_name`, `user_data`, security groups, IAM instance profile |
| Auto Scaling group | `AutoScalingGroup` | `autoscaling.services.k8s.aws/v1alpha1` | `launchTemplate.launchTemplateName` → launch template (by AWS name); subnets, sizes, health check, target groups |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated core
subset of its inputs). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | string | Name used across the resources created. |
| `min_size` | number | Minimum size of the autoscaling group. |
| `max_size` | number | Maximum size of the autoscaling group. |
| `desired_capacity` | number | Number of EC2 instances that should be running. |
| `image_id` | string | The AMI from which to launch the instance. |
| `instance_type` | string | The type of the instance (e.g. `t3.micro`). |
| `vpc_zone_identifier` | list(string) | Subnet IDs to launch resources in (existing subnets). |
| `availability_zones` | list(string) | AZs for the group (alternative to `vpc_zone_identifier`). |
| `health_check_type` | string | `EC2` or `ELB`. |
| `health_check_grace_period` | number | Seconds before health checks start. |
| `default_cooldown` | number | Seconds between scaling activities. |
| `capacity_rebalance` | bool | Enable Spot Capacity Rebalancing. |
| `key_name` | string | Existing EC2 key pair name. |
| `ebs_optimized` | bool | Launch EBS-optimized instances. |
| `user_data` | string | Base64-encoded user data. |
| `security_groups` | list(string) | Existing security group IDs for the launch template. |
| `target_group_arns` | list(string) | Existing ELB target group ARNs. |
| `iam_instance_profile_arn` | string | Existing IAM instance profile ARN. |
| `launch_template_name` | string | Name of launch template to create (defaults to `<name>`). |
| `launch_template_description` | string | Description of the launch template. |
| `launch_template_version` | string | Launch template version (`$Latest` / `$Default` / number). |
| `tags` | map(string) | Tags to assign to resources. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Limitations

This stack composes the **launch template + auto scaling group** core of the module. It mirrors a
curated subset of the module's inputs, not all of them. In particular:

- **External resources are passed through, not created.** `vpc_zone_identifier` (subnet IDs),
  `security_groups` (security group IDs), `target_group_arns` (ELB target group ARNs),
  `iam_instance_profile_arn` (IAM instance profile ARN) and `key_name` (EC2 key pair) all
  reference **existing** AWS resources. Provide them as IDs/ARNs/names. Create the upstream
  VPC/subnets with the `aws-vpc-stack` blueprint and IAM/SG resources separately.
- The module's optional sub-resources (scaling policies, scheduled actions, lifecycle hooks,
  CloudWatch alarms, IAM instance-profile creation, mixed-instances policy, instance refresh)
  are **not** composed here.
- The ACK `AutoScalingGroup` references the launch template by AWS **name** (not a k8s `*Ref`),
  so both resources share the deterministic launch-template name set by the stack.

## Prerequisites

- **ACK ec2 controller** (`oci://public.ecr.aws/aws-controllers-k8s/ec2-chart`) and **ACK
  autoscaling controller** (`oci://public.ecr.aws/aws-controllers-k8s/autoscaling-chart`)
  installed with AWS credentials — see
  [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md) and
  [`../../../docs/authentication.md`](../../../docs/authentication.md). The controllers' IAM
  principal needs EC2 launch-template and Auto Scaling permissions.
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-autoscaling-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsAutoscalingStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsAutoscalingStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awsautoscalingstacks`), pulling `oci://ghcr.io/braghettos/charts/aws-autoscaling-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsAutoscalingStack
metadata:
  name: my-asg
  namespace: aws-autoscaling-system
spec:
  region: eu-central-1
  name: my-asg
  min_size: 1
  max_size: 3
  desired_capacity: 2
  image_id: "ami-0123456789abcdef0"
  instance_type: "t3.micro"
  vpc_zone_identifier:
    - "subnet-0123456789abcdef0"
    - "subnet-0fedcba9876543210"
  health_check_type: EC2
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsautoscalingstack -n aws-autoscaling-system
kubectl get launchtemplates.ec2.services.k8s.aws,autoscalinggroups.autoscaling.services.k8s.aws -n aws-autoscaling-system
```

> **Note:** mirrors the module's core inputs, not all of them. Upstream subnets, security groups,
> target groups, IAM instance profiles and key pairs must already exist.
