# Krateo Blueprint — AWS S3 Bucket

Provisions an [Amazon S3](https://aws.amazon.com/s3/) bucket through the
[AWS Controllers for Kubernetes (ACK)](https://aws-controllers-k8s.github.io/community/) S3
controller. Once the `CompositionDefinition` is applied, **every `AwsS3Bucket` Composition you
create becomes an S3 bucket**.

The chart renders a native `s3.services.k8s.aws/v1alpha1` `Bucket` resource; the ACK S3
controller reconciles it into a real bucket and reports status back onto the Composition.

## Prerequisites

- **ACK S3 controller installed** in the cluster — see
  [`../../../docs/installing-controllers.md`](../../../docs/installing-controllers.md):
  ```sh
  helm install ack-s3-controller \
    oci://public.ecr.aws/aws-controllers-k8s/s3-chart \
    --namespace ack-system --create-namespace \
    --set aws.region=eu-west-1
  ```
- **AWS credentials configured** on that controller (IRSA/Pod Identity or static) — see
  [`../../../docs/authentication.md`](../../../docs/authentication.md).
- Krateo `core-provider` installed.

## Configuration

Composition `spec` fields **mirror the ACK Bucket spec** (curated subset). Full schema in
[`chart/values.schema.json`](chart/values.schema.json).

| Value                        | Description                                                                 |
| ---------------------------- | --------------------------------------------------------------------------- |
| `name`                       | Globally-unique bucket name. **Required.**                                  |
| `region`                     | AWS region (e.g. `eu-west-1`). Empty = controller default. → region annotation. |
| `acl`                        | Canned ACL: `private` / `public-read` / `public-read-write` / `authenticated-read`. |
| `versioning.status`          | `Enabled` / `Suspended`.                                                    |
| `objectLockEnabledForBucket` | Enable Object Lock at creation (requires versioning).                       |
| `publicAccessBlock.*`        | `blockPublicACLs`, `blockPublicPolicy`, `ignorePublicACLs`, `restrictPublicBuckets`. |
| `tagging.tagSet`             | List of `{ key, value }` tags.                                              |
| `policy`                     | Bucket policy as a JSON string.                                             |

## How to install

### 1. Register the blueprint

```sh
kubectl create namespace aws-s3-system
kubectl apply -f compositiondefinition.yaml
```

This publishes an `AwsS3Bucket` Composition type (`composition.krateo.io/v0-1-0`, plural
`awss3buckets`). `compositiondefinition.yaml` pulls the chart from
`oci://ghcr.io/braghettos/charts/aws-s3-bucket` (make that GHCR package public, or set the
`credentials` block).

### 2. (Optional) Register the portal card + form

```sh
kubectl apply -f customform.yaml
```

### 3. Create a Composition

```yaml
apiVersion: composition.krateo.io/v0-1-0
kind: AwsS3Bucket
metadata:
  name: my-bucket
  namespace: aws-s3-system
spec:
  name: my-unique-bucket-name-12345
  region: eu-west-1
  versioning:
    status: Enabled
  publicAccessBlock:
    blockPublicACLs: true
    blockPublicPolicy: true
    ignorePublicACLs: true
    restrictPublicBuckets: true
  tagging:
    tagSet:
      - key: env
        value: dev
```

```sh
kubectl apply -f my-bucket.yaml
```

### 4. Check status

```sh
# The Composition / ACK resource:
kubectl get awss3buckets.composition.krateo.io -n aws-s3-system
kubectl get buckets.s3.services.k8s.aws -A
kubectl describe bucket -n aws-s3-system my-bucket
```
