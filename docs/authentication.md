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

For non-EKS clusters (kind, on-prem, demos), supply an access key/secret via a Secret and point
the controller at it. This is simpler but puts long-lived credentials in the cluster — prefer
IRSA in production.

```sh
kubectl create namespace ack-system

kubectl create secret generic aws-credentials -n ack-system \
  --from-literal=AWS_ACCESS_KEY_ID=<AKIA...> \
  --from-literal=AWS_SECRET_ACCESS_KEY=<secret>

helm install ack-s3-controller \
  oci://public.ecr.aws/aws-controllers-k8s/s3-chart \
  --namespace ack-system \
  --set aws.region=eu-west-1 \
  --set "aws.credentials.secretName=aws-credentials" \
  --set "aws.credentials.secretKey=AWS_ACCESS_KEY_ID"
```

> Exact value keys vary slightly between controller chart versions. Confirm with
> `helm show values oci://public.ecr.aws/aws-controllers-k8s/s3-chart`.

## Where region comes from

- The controller is installed with a default region (`aws.region`).
- Each blueprint exposes a per-Composition `region` field, rendered as the
  `services.k8s.aws/region` annotation on the ACK custom resource, overriding the default for
  that resource. Leave it empty to inherit the controller default.

## Reference

- ACK auth & permissions: <https://aws-controllers-k8s.github.io/community/docs/user-docs/authentication/>
