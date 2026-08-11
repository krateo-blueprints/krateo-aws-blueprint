---
type: Runbook
title: AWS authentication for ACK controllers
description: How to give the ACK service controllers AWS credentials — IRSA / EKS Pod Identity (recommended) or a static shared-credentials Secret — a cluster-admin prerequisite the blueprints do not carry.
resource: oci://ghcr.io/krateo-blueprints/charts/aws-s3-bucket
tags: [aws, ack, authentication, irsa, prerequisite]
timestamp: 2026-08-11T00:00:00Z
---

# AWS authentication for ACK controllers (prerequisite)

ACK controllers call the AWS APIs, so each controller needs AWS credentials. This is configured
**on the controller** (a cluster-admin, install-time concern) — the blueprints in this repo do
not carry credentials. There are two supported models.

## Default: IRSA / EKS Pod Identity (recommended)

On EKS, give the controller's ServiceAccount an IAM role; no static keys ever touch the cluster.

### IRSA (IAM Roles for Service Accounts)

1. Create an IAM role with a trust policy for the controller's ServiceAccount and attach the
   service's recommended managed/inline policy (see the controller chart's docs).
2. Install the controller with the role ARN annotated onto its ServiceAccount:

```sh
helm install ack-s3-controller \
  oci://public.ecr.aws/aws-controllers-k8s/s3-chart \
  --namespace ack-system --create-namespace \
  --set aws.region=eu-west-1 \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=arn:aws:iam::<ACCOUNT_ID>:role/ack-s3-controller"
```

### EKS Pod Identity

Alternatively, create a Pod Identity association binding the role to the controller's
ServiceAccount:

```sh
aws eks create-pod-identity-association \
  --cluster-name <CLUSTER> \
  --namespace ack-system \
  --service-account ack-s3-controller \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/ack-s3-controller
```

## Alternative: static credentials (any cluster)

For non-EKS clusters (kind, on-prem, demos), give the controller an access key/secret via a
Secret. This is simpler but puts long-lived credentials in the cluster — prefer IRSA in
production.

**Important — it's a credentials *file*, not env-var literals.** ACK controllers do **not** read
`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` keys from the Secret. The chart mounts **one**
Secret key as an AWS [shared-credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
(it sets `AWS_SHARED_CREDENTIALS_FILE` to the mounted file and selects a profile via
`AWS_PROFILE`). So the Secret must hold a single key — here `credentials` — whose value is a
`[<profile>]` block:

```ini
[default]
aws_access_key_id = AKIA...
aws_secret_access_key = ...
```

Create the namespace and the Secret:

```sh
kubectl create namespace ack-system

kubectl create secret generic aws-credentials -n ack-system \
  --from-literal=credentials="$(printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
      'AKIA...' '<secret>')"
```

To keep the keys out of your shell history, source them from a local AWS CLI profile instead of
pasting them (this is the form verified end-to-end in this repo):

```sh
kubectl create secret generic aws-credentials -n ack-system \
  --from-literal=credentials="$(printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
      "$(aws --profile <your-profile> configure get aws_access_key_id)" \
      "$(aws --profile <your-profile> configure get aws_secret_access_key)")"
```

Install the controller pointing at that Secret. `secretKey` is the Secret **key name** (the file)
and `profile` is the header inside it:

```sh
helm install ack-s3-controller \
  oci://public.ecr.aws/aws-controllers-k8s/s3-chart --version 1.6.0 \
  --namespace ack-system \
  --set aws.region=eu-west-1 \
  --set aws.credentials.secretName=aws-credentials \
  --set aws.credentials.secretKey=credentials \
  --set aws.credentials.profile=default
```

The same Secret and `--set aws.credentials.*` flags work for every controller — install the
`ec2`, `rds`, … controllers from `oci://public.ecr.aws/aws-controllers-k8s/<service>-chart` the
same way.

> Verified end-to-end with the `s3` (v1.6.0) and `ec2` controllers on a kind cluster. Exact value
> keys can vary between chart versions — confirm with
> `helm show values oci://public.ecr.aws/aws-controllers-k8s/s3-chart`.

## Where region comes from

- The controller is installed with a default region (`aws.region`).
- Each blueprint exposes a per-Composition `region` field, rendered as the
  `services.k8s.aws/region` annotation on the ACK custom resource, overriding the default for
  that resource. Leave it empty to inherit the controller default.

## Reference

- ACK auth & permissions: <https://aws-controllers-k8s.github.io/community/docs/user-docs/authentication/>
