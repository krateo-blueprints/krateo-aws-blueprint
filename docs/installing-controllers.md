# Installing ACK service controllers (prerequisite)

These blueprints render **ACK custom resources**, but they do not install the ACK controllers
that reconcile them. Each AWS service has its own controller, published by AWS as a Helm OCI
chart. Install the controller for a service **before** registering or using a blueprint that
targets it.

## Install pattern

Every controller follows the same coordinates:

```
oci://public.ecr.aws/aws-controllers-k8s/<service>-chart
```

Example — the S3 controller (needed for the `aws-s3-bucket` blueprint):

```sh
# Pick the AWS region the controller operates in
export SERVICE=s3
export AWS_REGION=eu-west-1
# Resolve the latest chart version
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

Configure credentials via `--set` (or a values file) according to
[`authentication.md`](authentication.md).

## Per-resource region

A controller is installed with a default region (`aws.region`). Individual resources can
override it per-Composition: every blueprint exposes a `region` field that is rendered onto the
ACK custom resource as the `services.k8s.aws/region` annotation. If you leave it empty, the
controller's default region is used.

## Verifying a controller is ready

```sh
kubectl get pods -n ack-system
kubectl get crds | grep services.k8s.aws
```

You should see the controller `Deployment` running and the service's CRDs registered (e.g.
`buckets.s3.services.k8s.aws`).

## Reference

- ACK service list & status: <https://aws-controllers-k8s.github.io/community/docs/community/services/>
- Install guide: <https://aws-controllers-k8s.github.io/community/docs/user-docs/install/>
