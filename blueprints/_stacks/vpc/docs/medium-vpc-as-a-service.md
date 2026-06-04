# VPC-as-a-Service: a whole AWS network from one YAML

### Why putting Krateo on top of AWS — with Kubernetes as the backbone — beats handing every team a Terraform module

Every platform team eventually hits the same wall. A product squad needs "a VPC with public and private subnets and a NAT gateway, in eu-central-1." Simple enough — except the squad doesn't know Terraform, the platform team owns the state file, and now there's a ticket, a review, a `terraform apply`, and a Slack thread that lives for three days.

What if that squad could instead write twelve lines of YAML, `kubectl apply`, and get a correct, opinionated network a minute later — while the platform team keeps full control of *what* "correct" means?

That's what we built with `aws-vpc-stack`: a Krateo blueprint that turns one Composition into a complete AWS VPC, using **Kubernetes as the backbone** and **AWS Controllers for Kubernetes (ACK)** as the hands. Here's the design — and why this stack of choices is more than the sum of its parts.

## One Composition, not a ticket

Here is the entire request a developer makes:

```yaml
apiVersion: composition.krateo.io/v0-3-0
kind: AwsVpcStack
metadata:
  name: my-vpc
  namespace: aws-vpc-system
spec:
  region: eu-central-1
  cidr: "10.0.0.0/16"
  azs: ["eu-central-1a", "eu-central-1b"]
  public_subnets:  ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnets: ["10.0.10.0/24", "10.0.11.0/24"]
  enable_nat_gateway: true
  single_nat_gateway: true
```

If those field names look familiar, that's deliberate: they're the **same inputs as the popular `terraform-aws-modules/vpc/aws` module**. We didn't invent a new vocabulary; we met people where they already are.

Applying that one object produces ~10 real AWS resources, correctly wired: a VPC, public and private subnets across two AZs, an internet gateway, a NAT gateway with its Elastic IP, and route tables sending public traffic to the IGW and private traffic through the NAT. Delete the Composition and they're torn down in reverse. No state bucket, no `apply`, no ticket.

So how does twelve lines become a network? Three layers, each doing one job well.

## The backbone: Kubernetes as a control plane

Strip away the containers and Kubernetes is really a **declarative, self-healing control loop with an API, an authorization model, and an event system**. You declare desired state; controllers continuously reconcile reality toward it. That machinery is exactly what cloud provisioning has always wanted and rarely had.

Using Kubernetes as the backbone means infrastructure inherits, for free, the things teams already built around it:

- **Reconciliation, not one-shot apply.** A controller doesn't run once and forget. It keeps comparing desired vs. actual. If someone hand-edits a route table in the console, it gets corrected. Drift is a bug the system fixes, not a surprise you discover next quarter.
- **One API surface and one RBAC model.** The same `kubectl`, the same namespaces, the same role bindings that govern your workloads now govern your VPCs. Multi-tenancy and "who can create what" stop being a separate IAM puzzle.
- **GitOps by default.** A VPC is a YAML object, so Argo CD or Flux can own it like anything else. Your network has a pull request history.
- **An event-driven graph.** Resources can reference each other and wait. That turns out to be the whole trick for composing a network, as we'll see.

## The hands: ACK turns AWS into Kubernetes resources

[AWS Controllers for Kubernetes](https://aws-controllers-k8s.github.io/community/) are official AWS controllers that expose AWS services as native Custom Resources. A `Bucket`, a `DBInstance`, a `Subnet` — each is a Kubernetes object that an AWS-maintained controller reconciles against the real AWS API.

Crucially, ACK resources can reference each other by name. A `Subnet` points at a `VPC` via `vpcRef`; a `RouteTable` route points at an `InternetGateway` via `gatewayRef`; a `NATGateway` points at its `Subnet` and `ElasticIPAddress`. The controller resolves those references and **only creates a resource once everything it depends on is ready**.

That gives us a dependency state machine for free. Each resource moves through *New → Resolving refs → Creating → Synced*, and the references gate the order:

> VPC → Internet Gateway → public route table → public subnets → NAT gateway (+ EIP) → private route table → private subnets

We didn't write an orchestrator. We wrote a Helm chart that emits ten cross-referencing resources and let ACK's reconciliation figure out the order. (When we first tested it live, the logs literally showed each resource politely waiting — "the referenced resource is not synced yet" — until its turn.)

## The product: Krateo turns resources into self-service

ACK gives you the building blocks. It does **not** give you a product. A developer still has to know which ten resources to create, how to wire `vpcRef` to `routeTableRefs`, and which fields matter. That's where [Krateo](https://krateo.io) comes in.

A Krateo **CompositionDefinition** points at a Helm chart (our `aws-vpc-stack`). When applied, Krateo:

1. Builds a brand-new CRD — `AwsVpcStack` — from the chart's JSON Schema. The schema *is* the API contract: it's how we expose a curated, Terraform-module-shaped set of inputs and hide the 200+ knobs nobody needs.
2. Spins up a controller that, on each `AwsVpcStack` you create, renders the chart and applies the resulting ACK resources.
3. Renders a **portal form** from that same schema, so the network can be requested from a UI, not just YAML.

The result is a *golden path*: the platform team curates one opinionated blueprint — single-NAT or per-AZ NAT, sane defaults, validated CIDRs — publishes it once as an OCI artifact, and every team consumes it without copy-pasting a Terraform module and slowly drifting apart.

## Why this combination wins

Any one layer alone is incomplete. Raw Terraform gives you modules but a state file someone has to babysit and a CLI someone has to run. Raw ACK gives you Kubernetes-native AWS resources but no abstraction or self-service. Kubernetes alone doesn't speak AWS. Put them together and the advantages compound:

- **Self-service with guardrails.** Developers get a small, friendly API; platform teams keep the implementation, defaults, and policy.
- **Continuous correctness.** Reconciliation means the network matches Git, always — drift is auto-corrected instead of audited.
- **No extra control plane to run.** No Terraform state backend, no separate CI to run `apply`. The cluster you already operate is the engine.
- **Unified governance.** One RBAC model, one audit log, one GitOps pipeline for apps *and* infrastructure.
- **Composability.** A VPC stack is just an object; an app blueprint can depend on it, and an internal developer portal can list both as cards.

To be honest about the trade-offs: you need ACK controllers and IAM permissions in place (a one-time platform setup), some resources legitimately take minutes (a NAT gateway is a NAT gateway), and ACK doesn't cover every last AWS corner. But for the 80% that platform teams provision over and over, this is a dramatically shorter path.

## Try it

`aws-vpc-stack` is one of a set of composite "stack" blueprints (RDS, EKS, ALB, IAM, security groups, autoscaling, ECS) that replicate the most-used Terraform modules on top of ACK. Each is a published OCI chart with a quickstart and an architecture diagram. We validated the VPC stack end-to-end on a real AWS account: one Composition in, a real multi-AZ network out, and a clean teardown when the Composition is deleted.

Kubernetes as the backbone, ACK as the hands, Krateo as the product. Twelve lines of YAML, a whole network, and a platform team that finally gets out of the ticket queue.
