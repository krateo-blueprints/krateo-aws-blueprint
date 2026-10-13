---
type: Runbook
title: Installing ACK service controllers
description: How to install the AWS Controllers for Kubernetes (ACK) service controller for a given AWS service before registering or using a blueprint that targets it — as a Krateo operator blueprint, not a by-hand helm install.
resource: oci://ghcr.io/krateo-blueprints/charts/krateo-aws-ack-s3
tags: [aws, ack, controllers, install, prerequisite]
timestamp: 2026-10-13T00:00:00Z
---

# Installing ACK service controllers (prerequisite)

The blueprints in this repo render **ACK custom resources**. They do nothing until the controller
for their service is running: each AWS service has its own controller, and a `Bucket` with no
`s3-controller` just sits there.

Those controllers ship from this repo as **operator blueprints** under `operator/`, one per service.
That is the supported path — a dependency in Krateo is installed as a blueprint, not fetched by hand.

## Install the controller for a service

```sh
helm install krateo-aws-ack-s3 \
  oci://ghcr.io/krateo-blueprints/charts/krateo-aws-ack-s3 \
  --namespace ack-system --create-namespace \
  --set ack.aws.region=eu-west-1
```

Substitute the service you need: `krateo-aws-ack-<service>`, where `<service>` is the directory name
under `blueprints/`. The wrapper pins the upstream controller version, ships its CRDs, and forwards
everything under a single `ack` key — see each wrapper's own README for the value table.

### Credentials

Prefer IRSA / EKS Pod Identity. No secret material enters the cluster:

```sh
--set ack.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::<account>:role/<role>
```

A shared credentials file in a Secret also works, per [`authentication.md`](authentication.md):

```sh
--set ack.aws.credentials.secretName=aws-creds \
--set ack.aws.credentials.profile=default
```

### Deletion policy — read this one

```sh
--set ack.deletionPolicy=retain
```

The upstream default is `delete`: removing the Kubernetes resource **destroys the real AWS
resource**. `retain` orphans it instead — still running, still billable. The wrappers surface this
knob deliberately rather than leaving it buried in the upstream chart, because the default is the
destructive one.

## Per-resource region

A controller is installed with a default region (`ack.aws.region`). Individual resources override it
per Composition: every blueprint exposes a `region` field that is rendered onto the ACK custom
resource as the `services.k8s.aws/region` annotation. If you leave it empty, the controller's default
region is used — and if **both** are empty the controller has no region at all and the resource never
reconciles.

## Verifying a controller is ready

```sh
kubectl get pods -n ack-system
kubectl get crds | grep services.k8s.aws
```

You should see the controller `Deployment` running and the service's CRDs registered (e.g.
`buckets.s3.services.k8s.aws`). The CRDs come from the upstream chart's own `crds/` directory, which
is why there is no companion `-crds` chart for these — the same arrangement as `krateo-azure-aso`.

## `networkmanager` has no controller

`blueprints/networkmanager/globalnetwork` renders `networkmanager.services.k8s.aws/v1alpha1`
resources, but AWS publishes no `networkmanager-chart`:

```
$ helm show chart oci://public.ecr.aws/aws-controllers-k8s/networkmanager-chart
Error: ... response status code 404: name unknown: The repository with name
'networkmanager-chart' does not exist in the registry with id 'aws-controllers-k8s'
```

Reproduced on three separate attempts, so this is a hard absence rather than a transient failure.
That blueprint therefore has **no controller that can reconcile it** and no operator wrapper exists
for it. It is not pinned to a guess; the gap is recorded in
`tools/ackgen/ack-controllers.yaml`. Every other service in `blueprints/` has one.

## Installing a controller by hand

Still possible, and the right fallback for a service this repo has no blueprint for:

```sh
export SERVICE=s3
export AWS_REGION=eu-west-1
export CHART_VERSION=$(
  helm show chart oci://public.ecr.aws/aws-controllers-k8s/${SERVICE}-chart 2>/dev/null \
    | awk '/^version:/{print $2}'
)

helm install ack-${SERVICE}-controller \
  oci://public.ecr.aws/aws-controllers-k8s/${SERVICE}-chart \
  --version "${CHART_VERSION}" \
  --namespace ack-system --create-namespace \
  --set aws.region="${AWS_REGION}"
```

Note the values path differs: upstream has no `ack` prefix, because that prefix is the Helm
dependency alias the wrapper adds.

One caution if you script this over many services: **do not resolve these charts in parallel.**
Concurrent requests to `public.ecr.aws` return empty results instead of errors. Probing all 68
service directories with `xargs -P 10` reported 19 as having no chart; re-probing those one at a
time resolved 18 of them, including `s3`. Resolve serially, with a short delay.

## Bumping a pinned controller

The wrappers are generated. Change the version in `tools/ackgen/ack-controllers.yaml` and re-run:

```sh
cd tools/ackgen
go build -o ackgen .
./ackgen -operators ack-controllers.yaml -out ../../operator
```

`tools/ackgen/operators_test.go` regenerates every wrapper and diffs it against what is committed,
so a hand-edited `Chart.yaml` fails CI instead of being silently reverted by the next regeneration.

## Reference

- ACK service list & status: <https://aws-controllers-k8s.github.io/community/docs/community/services/>
- Install guide: <https://aws-controllers-k8s.github.io/community/docs/user-docs/install/>
