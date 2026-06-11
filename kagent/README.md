# kagent Agent: `aws-blueprints-expert`

A [kagent](https://kagent.dev) Agent CRD that turns an LLM into a
subject-matter expert on this repository:

- The reconciliation chain — `CompositionDefinition` → Krateo `core-provider`
  (which builds the Composition CRD from each chart's `values.schema.json`) →
  `composition-dynamic-controller` → a **native ACK custom resource** → the real
  AWS resource.
- Why ACK is consumed **directly** here (no KOG / OASGen / `RestDefinition`).
- The **242-blueprint / 68-service** catalog (`CATALOG.md`) and the 8 composite
  **stack** blueprints under [`blueprints/_stacks/`](../blueprints/_stacks) that
  replicate `terraform-aws-modules` modules on top of ACK.
- `tools/ackgen`, the Go generator that projects an ACK CRD into a crdgen-safe
  `values.schema.json` and renders the whole blueprint.

The system prompt also embeds the non-obvious gotchas that each cost a live
debugging session — the root `additionalProperties: false` / `global` trap,
`helm template` (not `helm lint`) as the gate, the `*Ref` object shape, the
EC2 "never restart the controller mid-`CreateVpc`" duplicate-VPC lesson — plus a
one-shot triage recipe for a Composition that won't provision.

It uses the built-in `kagent-tool-server` (`k8s_*` tools) to inspect and patch
`CompositionDefinition`s, Compositions, and ACK CRs on the cluster. No custom
MCP server is needed — everything is reconciled through standard Kubernetes
resources.

## Prerequisites

### 1. Install kagent

Pulled directly from the GHCR OCI registry — no `helm repo add` needed.

```bash
kubectl create ns kagent --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kagent-crds \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
  --version 0.9.6 --namespace kagent --wait --timeout 5m

helm upgrade --install kagent \
  oci://ghcr.io/kagent-dev/kagent/helm/kagent \
  --version 0.9.6 --namespace kagent \
  --set providers.default=anthropic \
  --set providers.anthropic.model=claude-sonnet-4-6 \
  --timeout 10m
```

Swap `providers.default` for `openAI`, `gemini`, `azureOpenAI`, or `ollama` if
you want a non-Anthropic auto-`ModelConfig`. The chart auto-creates a
`ModelConfig` named `default-model-config` for whichever provider you pick.

### 2. ModelConfig: Gemini on Vertex AI (what this repo ships)

The Agent references a `ModelConfig` named **`vertex-gemini`** of kind
`GeminiVertexAI` (see [`modelconfig-vertex-gemini.yaml`](./modelconfig-vertex-gemini.yaml)).

**One-time GCP prep:**

1. Enable the Vertex AI API on your GCP project.
2. Create a service account with role **`roles/aiplatform.user`**.
3. Download a JSON key for it.

**Create the secret** kagent mounts at `/creds/key.json`:

```bash
kubectl -n kagent create secret generic kagent-vertex \
  --from-file=key.json=$HOME/Downloads/<your-sa-key>.json
```

**Edit and apply the `ModelConfig`**, setting `projectID` and `location`:

```bash
$EDITOR kagent/modelconfig-vertex-gemini.yaml   # set projectID and location
kubectl apply -f kagent/modelconfig-vertex-gemini.yaml
```

#### Alternative providers

| `spec.provider`     | secret name        | secret key            | notes                          |
|---------------------|--------------------|-----------------------|--------------------------------|
| `Anthropic`         | `kagent-anthropic` | `ANTHROPIC_API_KEY`   | direct Anthropic API           |
| `OpenAI`            | `kagent-openai`    | `OPENAI_API_KEY`      |                                |
| `Gemini`            | `kagent-gemini`    | `GOOGLE_API_KEY`      | AI Studio (not Vertex)         |
| `GeminiVertexAI`    | `kagent-vertex`    | `key.json` (file)     | this repo                      |
| `AnthropicVertexAI` | same shape         | `key.json` (file)     | Claude via Vertex Model Garden |

If you swap providers, edit `spec.declarative.modelConfig` in
[`agent-aws-blueprints-expert.yaml`](./agent-aws-blueprints-expert.yaml) to point
at your `ModelConfig` (e.g. the chart's auto-created `default-model-config`).

### 3. Built-in `kagent-tool-server`

Shipped automatically by the kagent helm chart as a `RemoteMCPServer`. Provides
the `k8s_*` tool family the Agent uses. No extra setup.

## Apply

```bash
kubectl apply -f kagent/agent-aws-blueprints-expert.yaml
kubectl -n kagent get agent aws-blueprints-expert
```

Then open the kagent UI (or the A2A endpoint) and ask one of the example
prompts from `spec.declarative.a2aConfig.skills`:

- "How does a Composition become a real AWS resource?"
- "Why does this repo not use KOG / `RestDefinition` like the OpenStack one?"
- "How does the `aws-vpc-stack` compose a whole network from one Composition?"
- "My Composition is created but no AWS resource appears — where do I look?"
- "chart-inspector says \"additional properties 'global' not allowed\" — why?"
- "IRSA vs static credentials — which should I use and how?"

## What the agent can do

- Read `CompositionDefinition`s, Compositions, and ACK CRs and explain where a
  resource is in the reconciliation chain (incl. `ACK.ResourceSynced` /
  `ACK.Recoverable` / `ACK.Terminal`).
- Correlate a stuck Composition with the rendered ACK CR status and the ACK
  controller / `composition-dynamic-controller` logs.
- Patch a Composition `spec` (with confirmation) to fix a schema/value issue.
- Explain the catalog, the `ackgen` generator, the stacks' Terraform-input
  parity, and the CI/OCI publishing flow.
- Cite the canonical docs (`README.md`, `CATALOG.md`, `docs/authentication.md`,
  `docs/installing-controllers.md`, per-blueprint `README.md` / `quickstart.md`).

## What the agent will not do

- Call the AWS API directly or shell into ACK controllers — it reasons through
  the ACK CRs and their status.
- Install ACK controllers or configure AWS credentials (cluster-admin
  prerequisites, out of scope).
- Invent ACK state — it reads conditions from the live CR via
  `k8s_get_resource_yaml`.
