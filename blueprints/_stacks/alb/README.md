# Krateo Stack — AWS ALB

A **composite** Krateo blueprint that provisions an AWS Application/Network Load Balancer as one
Composition, replicating the
[`terraform-aws-modules/alb/aws`](https://registry.terraform.io/modules/terraform-aws-modules/alb/aws)
module on top of the [ACK](https://aws-controllers-k8s.github.io/community/) **elbv2** controller.

> **Try it end-to-end:** see [quickstart.md](quickstart.md) — provision a real ALB on a local
> kind cluster, from controller install to cleanup.

## How it works

One `AwsAlbStack` Composition is rendered by Krateo's composition-dynamic-controller into native
ACK elbv2 resources: one `LoadBalancer`, one `TargetGroup` per entry in `target_groups`, and one
`Listener` per entry in `listeners`. Each resource reconciles through the ACK state machine —
**New → Resolving refs → Creating (AWS API) → Synced/Ready** — where a resource stays in
*Resolving refs* until every `*Ref` target it points at is itself `Synced`, and retries on
`ACK.Recoverable` errors. Because the listener references the load balancer (`loadBalancerRef`)
and forwards to a target group (`forwardConfig.targetGroups[].targetGroupRef`), the resources come
up in strict dependency order: **LoadBalancer + TargetGroup(s) → Listener(s)**.

## Composed resources

Unlike the single-resource `blueprints/<service>/<resource>` charts (one ACK CR each), a *stack*
composes several wired-together ACK resources. Creating one `AwsAlbStack` Composition renders:

| Resource | ACK Kind | Wiring |
| -------- | -------- | ------ |
| Load balancer | `LoadBalancer` | `subnets` / `securityGroups` from existing IDs; LB attributes from `idle_timeout`, `enable_http2`, `enable_deletion_protection`, `enable_cross_zone_load_balancing` |
| Target group(s) (per `target_groups` key) | `TargetGroup` | `vpcID` → existing VPC; `port` / `protocol` / `targetType` / health check from the entry |
| Listener(s) (per `listeners` key) | `Listener` | `loadBalancerRef` → LoadBalancer, `defaultActions[0]` = forward → `targetGroupRef` TargetGroup |

## Inputs

The Composition `spec` uses the **same input names as the Terraform module** (a curated core
subset of its 60+ inputs). Full schema in [`chart/values.schema.json`](chart/values.schema.json).

| Input | Type | Description |
| ----- | ---- | ----------- |
| `name` | string | The name of the LB (unique per region/account). |
| `name_prefix` | string | Unique name prefix; conflicts with `name`. |
| `load_balancer_type` | string | `application` / `network` / `gateway`. |
| `internal` | bool | If true, the LB is internal. |
| `vpc_id` | string | Existing VPC ID for the target group(s). |
| `subnets` | list(string) | Existing subnet IDs to attach to the LB. |
| `security_groups` | list(string) | Existing security group IDs to assign to the LB. |
| `ip_address_type` | string | `ipv4` / `dualstack`. |
| `enable_deletion_protection` | bool | Disable deletion via the AWS API. |
| `enable_http2` | bool | Enable HTTP/2 (application LBs). |
| `enable_cross_zone_load_balancing` | bool | Cross-zone load balancing (network/gateway LBs). |
| `idle_timeout` | number | Connection idle timeout in seconds (application LBs). |
| `default_port` / `default_protocol` | number / string | Defaults applied across listener and target group. |
| `target_groups` | map(object) | Target group configs (name, port, protocol, target_type, health_check, tags). |
| `listeners` | map(object) | Listener configs (port, protocol, certificate_arn, ssl_policy, forward.target_group_key, tags). |
| `tags` | map(string) | Tags added to all resources. |
| `region` | string | **Krateo/ACK wiring** (not a TF input) — AWS region; empty = controller default. |

## Prerequisites

- **ACK elbv2 controller installed** (`oci://public.ecr.aws/aws-controllers-k8s/elbv2-chart`) with
  AWS credentials — see [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md)
  and [`../../../docs/authentication.md`](../../../docs/authentication.md). The controller's IAM
  principal needs `elasticloadbalancing:*` permissions (and `ec2:Describe*` for subnets/SGs).
- Krateo `core-provider` installed.

## How to install

```sh
kubectl create namespace aws-alb-system
kubectl apply -f compositiondefinition.yaml   # publishes the AwsAlbStack type
kubectl apply -f customform.yaml              # optional: portal card + form
```

This publishes an `AwsAlbStack` Composition type (`composition.krateo.io/v0-3-0`, plural
`awsalbstacks`), pulling `oci://ghcr.io/krateo-blueprints/charts/aws-alb-stack`.

### Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsAlbStack
metadata:
  name: my-alb
  namespace: aws-alb-system
spec:
  region: eu-central-1
  name: my-alb
  load_balancer_type: application
  internal: false
  vpc_id: vpc-0123456789abcdef0
  subnets:
    - subnet-0aaaa1111bbbb2222
    - subnet-0cccc3333dddd4444
  security_groups:
    - sg-00001111222233334
  target_groups:
    http:
      port: 80
      protocol: HTTP
      target_type: instance
      health_check:
        enabled: true
        path: "/"
  listeners:
    http:
      port: 80
      protocol: HTTP
      forward:
        target_group_key: http
  tags:
    team: platform
```

### Verify

```sh
kubectl get awsalbstack -n aws-alb-system
kubectl get loadbalancers.elbv2.services.k8s.aws,targetgroups.elbv2.services.k8s.aws,listeners.elbv2.services.k8s.aws -n aws-alb-system
```

## Limitations

- This stack mirrors the module's **core inputs**, not all 60+. The Terraform module's security
  group creation, Route53 records, WAF association, access/connection logging, listener rules, and
  weighted/redirect/fixed-response actions are not composed here.
- Inputs that reference **existing external resources** are accepted as Composition inputs (using
  the Terraform input names) and passed to ACK as IDs/ARNs — this stack does **not** create them:
  - `vpc_id` → ACK `TargetGroup.spec.vpcID`
  - `subnets` → ACK `LoadBalancer.spec.subnets`
  - `security_groups` → ACK `LoadBalancer.spec.securityGroups`
  - per-listener `certificate_arn` → ACK `Listener.spec.certificates[].certificateARN`
  Create the VPC, subnets, and security groups beforehand (e.g. with the `aws-vpc-stack`
  blueprint) and an ACM certificate for HTTPS listeners.
- Each listener's default action is a single-target-group `forward`. If a listener does not set
  `forward.target_group_key`, the first declared target group is used.
