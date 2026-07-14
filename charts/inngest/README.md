# Inngest Self-Hosted Helm Chart

A Helm chart for deploying Inngest on Kubernetes clusters.

> **Note:** Inngest publishes an official chart ([`inngest/inngest-helm`](https://github.com/inngest/inngest-helm)). This chart is a custom, opinionated alternative: operator-managed PostgreSQL (CloudNativePG) and Redis (OpsTree), Kubernetes Gateway API routing instead of Ingress, and KEDA autoscaling via a Prometheus sidecar.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.0+
- Persistent Volume support for PostgreSQL and Redis
- Storage class supporting ReadWriteOnce volumes
- For external access (optional): a Gateway API implementation with `ListenerSet` support (see [Gateway API Routing](#gateway-api-routing)), or `service.type: LoadBalancer`
- KEDA operator (optional, for autoscaling)

## Installation

### Quick Start with Internal Postgres and Redis

Deploy Inngest with bundled PostgreSQL and Redis instances:

```bash
# Install with required secrets (creates "inngest" namespace automatically)
helm install inngest . \
  --set inngest.eventKey="your_event_key_here" \
  --set inngest.signingKey="your_signing_key_here" \
  --create-namespace
```

**Important:** The `eventKey` and `signingKey` are required and must be hexadecimal strings for Inngest to function properly.

### Custom Values File

Create a `my-values.yaml` file:

```yaml
inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string

# Customize resource limits
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

Install with custom values:

```bash
helm install inngest . -f my-values.yaml --create-namespace
```

## Resource Naming and Release Names

**Key Concept:** This chart uses **consistent resource naming** regardless of your chosen Helm release name.

- **Helm Release Name:** The first argument (`inngest`) is your chosen release name for Helm tracking
- **Kubernetes Resource Names:** Always consistent: `inngest`, `inngest-postgres`, `inngest-redis`

**Examples:**

```bash
# All of these create identical Kubernetes resource names
helm install my-production-inngest . --create-namespace
helm install dev-environment . --create-namespace
helm install company-inngest . --create-namespace

# All result in the same resources:
# - service/inngest
# - deployment/inngest
# - secret/inngest-secret
# - cluster.postgresql.cnpg.io/inngest-postgres
# - redis.redis.opstreelabs.in/inngest-redis
```

**Benefits:**

- Consistent resource names across all environments
- Documentation examples work for everyone
- Scripts and automation can rely on predictable names
- Easy to reference services from applications

## Configuration Examples

### 1. Using Internal PostgreSQL and Redis (Default)

This is the simplest setup with bundled dependencies:

```yaml
# values-internal.yaml
inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string

# Resource limits
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi
```

Deploy:

```bash
helm install inngest . -f values-internal.yaml --create-namespace
```

### 2. Using External PostgreSQL and Redis

For production deployments with external managed databases, disable the operator-managed instances and provide connection URIs — either inline (stored in the chart-managed `inngest-secret`) or as a reference to an existing Secret:

```yaml
# values-external.yaml
inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string

  postgres:
    # Option A: inline URI (rendered into inngest-secret)
    uri: "postgres://username:password@postgres.example.com:5432/inngest"
    # Option B: reference an existing Secret instead
    # uriSecretRef:
    #   name: my-postgres-creds
    #   key: uri

    # Optional connection pool tuning (defaults shown)
    maxIdleConns: 10
    maxOpenConns: 100
    connMaxIdleTime: 5 # minutes
    connMaxLifetime: 30 # minutes

  redis:
    uri: "redis://redis.example.com:6379"
    # uriSecretRef:
    #   name: my-redis-creds
    #   key: uri

# Disable internal dependencies
postgres:
  enabled: false

redis:
  enabled: false
```

**Note:** the external `inngest.postgres.*` / `inngest.redis.*` settings only take effect when the corresponding top-level `postgres.enabled` / `redis.enabled` is `false`. If a Secret reference and an inline URI are both set, the Secret reference wins. The `pg_isready` init container only runs for the operator-managed database — external database readiness is your platform's responsibility.

Deploy:

```bash
helm install inngest-prod . -f values-external.yaml --create-namespace
```

### 3. Using KEDA for Autoscaling

Enable KEDA-based autoscaling using Prometheus metrics from Inngest:

**Important:** KEDA scaling uses a Prometheus sidecar container to scrape the Inngest `/metrics` endpoint. The sidecar handles Bearer token authentication using the `signingKey`, and KEDA queries the sidecar's Prometheus API for scaling decisions based on `inngest_queue_depth`.

```yaml
# values-keda.yaml
inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string

# Enable KEDA autoscaling
keda:
  enabled: true
  minReplicas: 2
  maxReplicas: 20
  pollingInterval: 30
  cooldownPeriod: 300
  triggers:
    - type: prometheus
      metadata:
        metricName: inngest_queue_depth
        threshold: "10"
        query: inngest_queue_depth
```

Deploy with KEDA:

```bash
# Install KEDA using Helm (recommended method)
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda-system --create-namespace

# Verify KEDA installation
kubectl get pods -n keda-system

# Deploy Inngest with KEDA
helm install inngest . -f values-keda.yaml --create-namespace
```

**Alternative KEDA Installation Methods:**

```bash
# Method 1: Using kubectl (if Helm method fails)
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.12.0/keda-2.12.0.yaml

# Method 2: Using specific version via Helm
helm install keda kedacore/keda --version 2.12.0 --namespace keda-system --create-namespace
```

### 4. Complete Production Example

A comprehensive production setup with external dependencies, ingress, and monitoring:

```yaml
# values-production.yaml
replicaCount: 3

inngest:
  eventKey: "your_production_event_key" # Must be a hexadecimal string
  signingKey: "your_production_signing_key" # Must be a hexadecimal string
  logLevel: "info"
  queueWorkers: 200
  postgres:
    uri: "postgres://inngest:secure_password@postgres-prod.example.com:5432/inngest"
  redis:
    uri: "redis://redis-prod.example.com:6379"

# Use external managed databases
postgres:
  enabled: false

redis:
  enabled: false

# External access via Gateway API (see "Gateway API Routing" below)
gateway:
  enabled: true
  hostname: inngest.example.com

# KEDA autoscaling configuration
keda:
  enabled: true
  minReplicas: 3
  maxReplicas: 50
  triggers:
    - type: prometheus
      metadata:
        metricName: inngest_queue_depth
        threshold: "10"
        query: inngest_queue_depth

# Resource limits
resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi

# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000

podSecurityContext:
  fsGroup: 1000

# Network policy for security
networkPolicy:
  enabled: true
```

Deploy production setup:

```bash
helm install inngest-prod . -f values-production.yaml --create-namespace
```

## Gateway API Routing

External access is provided via the [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/) instead of classic Ingress. When `gateway.enabled` is set, the chart renders:

- A **`ListenerSet`** attached to a shared `Gateway` (default: `kgateway-shared` in the `kgateway` namespace). The ListenerSet owns the per-hostname HTTPS (and optional HTTP redirect) listeners, and carries a `cert-manager.io/cluster-issuer` annotation so cert-manager provisions certificates into the referenced TLS Secrets automatically.
- An **`HTTPRoute`** for the main Inngest API/UI (port 8288), plus an HTTP→HTTPS 308 redirect route when `gateway.httpsRedirect` is on (default).
- Optionally an HTTPRoute pair for the **Connect gateway** (port 8289, WebSocket) on a separate hostname when `gateway.connect.enabled` is set.

### Cluster prerequisites

1. **Gateway API experimental-channel CRDs** — `ListenerSet` is an experimental Gateway API resource:

   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/experimental-install.yaml
   ```

2. **A Gateway API implementation with ListenerSet support** — e.g. [kgateway](https://kgateway.dev/) with experimental features enabled (`controller.extraEnv.KGW_ENABLE_GATEWAY_API_EXPERIMENTAL_FEATURES=true`).

3. **A shared Gateway that permits ListenerSet attachment** from other namespaces:

   ```yaml
   apiVersion: gateway.networking.k8s.io/v1
   kind: Gateway
   metadata:
     name: kgateway-shared
     namespace: kgateway
   spec:
     gatewayClassName: kgateway
     listeners:
       # Dummy listener - spec requires at least one; real listeners
       # live in per-app ListenerSets
       - name: http
         hostname: dummy
         protocol: HTTP
         port: 80
     allowedListeners:
       namespaces:
         from: All
   ```

4. **cert-manager with Gateway API + ListenerSet support** (`config.enableGatewayAPI`, `featureGates.ListenerSets: true`) and a ClusterIssuer whose HTTP-01 solver uses `gatewayHTTPRoute`:

   ```yaml
   apiVersion: cert-manager.io/v1
   kind: ClusterIssuer
   metadata:
     name: letsencrypt-gateway
   spec:
     acme:
       server: https://acme-v02.api.letsencrypt.org/directory
       email: your-email@example.com
       privateKeySecretRef:
         name: letsencrypt-gateway
       solvers:
         - http01:
             gatewayHTTPRoute: {}
   ```

### Example

```yaml
# values-gateway.yaml
inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string
  noUI: true # Consider disabling the UI when publicly exposed

gateway:
  enabled: true
  hostname: inngest.example.com
  # Defaults shown - override to match your platform:
  # parentRef:
  #   name: kgateway-shared
  #   namespace: kgateway
  # clusterIssuer: letsencrypt-gateway
  # tlsSecretName: inngest-tls
  # httpsRedirect: true

  # Only needed when Inngest Connect workers run OUTSIDE the cluster.
  # In-cluster workers should use the Service directly (ws://inngest:8289).
  connect:
    enabled: true
    hostname: inngest-connect.example.com
```

```bash
helm install inngest . -f values-gateway.yaml --create-namespace
```

**Access URLs after deployment:**

- Event API / REST API: `https://inngest.example.com`
- Connect gateway (external workers): `wss://inngest-connect.example.com/v0/connect`
- UI Dashboard: disabled in this example (`noUI: true`)

**Security Warning:** When exposing Inngest publicly, the web UI and GraphQL endpoints are accessible unless protected. Either set `inngest.noUI: true` (as above) or add authentication at the gateway layer.

**Why a separate Connect hostname?** Ports 8288 and 8289 are distinct HTTP servers that both own `/v0/...` paths, and the Inngest SDKs take a base URL rather than a path prefix — so path-based routing on a single hostname would be ambiguous. The Connect listeners live on the same ListenerSet, so a second hostname costs no extra resources beyond its certificate.

### Verifying

```bash
# ListenerSet accepted and programmed by the Gateway
kubectl get listenerset -n inngest
kubectl describe listenerset inngest -n inngest

# Routes accepted
kubectl get httproute -n inngest

# Certificates issued by cert-manager
kubectl get certificate -n inngest
kubectl describe certificate inngest-tls -n inngest
```

**Common issues:**

1. **ListenerSet not accepted**: check that the shared Gateway has `allowedListeners.namespaces.from: All` and the implementation has experimental features enabled.
2. **Certificate stuck not-Ready**: verify DNS points at the Gateway's address and port 80 is reachable for the HTTP-01 challenge; check `kubectl logs -n cert-manager deployment/cert-manager`.
3. **Hostname conflicts**: listener hostnames must be unique across *all* ListenerSets attached to the shared Gateway.
4. **Let's Encrypt rate limits**: point `gateway.clusterIssuer` at a staging issuer while testing.

### Migrating from the old `ingress` values

Chart `0.2.0` removed classic Ingress support. Translate your values as follows:

| Old (`ingress.*`)                                | New (`gateway.*`)       |
| ------------------------------------------------ | ----------------------- |
| `ingress.enabled`                                | `gateway.enabled`       |
| `ingress.hosts[0].host`                          | `gateway.hostname`      |
| `ingress.tls[0].secretName`                      | `gateway.tlsSecretName` |
| `annotations["cert-manager.io/cluster-issuer"]`  | `gateway.clusterIssuer` |
| `annotations[".../ssl-redirect"]`                | `gateway.httpsRedirect` |
| `ingress.className`                              | — (implementation is chosen by the parent Gateway) |
| `ingress.hosts[].paths`                          | — (routes always match `PathPrefix: /`) |

Before upgrading a live install, delete the old `Ingress` and any Ingress-era `Certificate` for `inngest-tls` first — otherwise the old and new cert-manager flows will contend for the same TLS Secret. The Secret itself can be reused.

## Health Probes

The chart ships working probe defaults (override or empty out `startupProbe` / `livenessProbe` / `readinessProbe` in values):

- **Startup**: `GET /health` on port 8288, up to 2 minutes (`failureThreshold: 60` × 2s) for first boot and database migrations
- **Liveness**: `GET /health` on port 8288 every 10s
- **Readiness**: `inngest alpha doctor healthcheck` (exec) every 10s — the docs-recommended check, which verifies both the main API (8288) and the Connect gateway (8289) are ready

## Logging

- `inngest.logLevel` sets the plain `LOG_LEVEL` environment variable — this is what the server's logger actually reads (`INNGEST_LOG_LEVEL` is **not** honored, and `LOG_LEVEL` overrides the `--log-level` flag).
- Logs are always JSON in-cluster: the server forces JSON output whenever stdout is not a TTY, so there is no JSON toggle to configure.

## Prometheus Metrics

`GET /metrics` on port 8288 (Bearer-authenticated with the signing key) always exposes `inngest_queue_depth`, which the KEDA setup scales on. Set `inngest.experimentalPromMetrics: true` to additionally emit per-function lifecycle counters (`inngest_function_run_scheduled_total`, `inngest_function_run_started_total`, `inngest_function_run_ended_total`, `inngest_sdk_req_*_total`) for richer dashboards or finer-grained scaling triggers.

## Namespace Configuration

The chart creates and manages its own namespace by default. You can customize this behavior:

### Default Namespace

```bash
# Uses default "inngest" namespace
helm install inngest . --create-namespace
```

### Custom Namespace

```yaml
# values-custom-namespace.yaml
namespace:
  create: true
  name: "my-inngest-ns"

inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string
```

```bash
helm install inngest . -f values-custom-namespace.yaml --create-namespace
```

### Use Existing Namespace

```yaml
# values-existing-namespace.yaml
namespace:
  create: false
  name: "existing-namespace"

inngest:
  eventKey: "your_event_key_here" # Must be a hexadecimal string
  signingKey: "your_signing_key_here" # Must be a hexadecimal string
```

```bash
# Create namespace first if it doesn't exist
kubectl create namespace existing-namespace
helm install inngest . -f values-existing-namespace.yaml
```

**Note:** When using an existing namespace, don't use `--create-namespace` flag.

## Accessing Inngest

After deployment, you can access Inngest through:

**Resource Names:** Regardless of your chosen release name, the Kubernetes resources are always named:

- Main service: `inngest`
- PostgreSQL: `inngest-postgres`
- Redis: `inngest-redis`

### Port Forward (Development)

```bash
kubectl port-forward svc/inngest 8288:8288 -n inngest
# Access UI at http://localhost:8288
```

### Service URLs for Applications

Configure your applications to send events to:

- Internal: `http://inngest:8288` (within cluster)
- External: `https://inngest.example.com` (see Gateway API Routing above)

## Monitoring and Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=inngest -n inngest
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=inngest -f -n inngest
```

### Check Configuration

```bash
kubectl get secret inngest-secret -o yaml -n inngest
# Prometheus sidecar config (only when keda.enabled)
kubectl get configmap inngest-prometheus-config -o yaml -n inngest
```

### KEDA Scaling Status

```bash
kubectl get scaledobject -n inngest
kubectl describe scaledobject inngest -n inngest
```

#### Pods stuck in "Pending" state

Check for resource constraints or storage issues:

```bash
kubectl describe pods -l app.kubernetes.io/name=inngest -n inngest
kubectl get pvc -n inngest
kubectl get storageclass
```

## Upgrading

### Upgrade Chart

```bash
helm upgrade inngest . -f your-values.yaml -n inngest
```

**Note:** Always specify the namespace when upgrading to ensure Helm finds the correct release.

### Database Migrations

Inngest handles database migrations automatically on startup. Ensure you have backups before upgrading.

## Uninstalling

```bash
helm uninstall inngest -n inngest
```

**Note:** This will not delete persistent volumes. To delete all data:

```bash
kubectl delete pvc -l app.kubernetes.io/name=inngest -n inngest
```

## Configuration Reference

### Key Configuration Options

| Parameter                          | Description                              | Default                | Required           |
| ---------------------------------- | ---------------------------------------- | ---------------------- | ------------------ |
| `namespace.create`                 | Create namespace                         | `true`                 | No                 |
| `namespace.name`                   | Namespace name                           | `"inngest"`            | No                 |
| `inngest.eventKey`                 | Event key for sending events             | `""`                   | **Yes**            |
| `inngest.signingKey`               | Signing key for validation               | `""`                   | **Yes**            |
| `postgres.enabled`                 | Enable operator-managed PostgreSQL       | `true`                 | No                 |
| `redis.enabled`                    | Enable operator-managed Redis            | `true`                 | No                 |
| `inngest.postgres.uri`             | External PostgreSQL URI                  | `""`                   | No                 |
| `inngest.redis.uri`                | External Redis URI                       | `""`                   | No                 |
| `gateway.enabled`                  | Enable Gateway API routing               | `false`                | No                 |
| `gateway.hostname`                 | Public hostname for the API/UI           | `""`                   | If gateway enabled |
| `gateway.connect.enabled`          | Expose the Connect gateway externally    | `false`                | No                 |
| `inngest.experimentalPromMetrics`  | Per-function Prometheus counters         | `false`                | No                 |
| `keda.enabled`                     | Enable KEDA autoscaling                  | `false`                | No                 |

**Security:** This chart implements security best practices by default:

- Non-root user execution (UID 1000 for Inngest, 999 for PostgreSQL/Redis)
- Read-only root filesystem with temporary volumes for writable directories
- Dropped capabilities and disabled privilege escalation
- Database credentials stored in Kubernetes Secrets (not plain text)
- Network policies available for additional isolation

**Resource Names:** All Kubernetes resources use consistent names regardless of Helm release name:

- Main application: `inngest` (service, deployment, routes), `inngest-secret`
- PostgreSQL: `inngest-postgres` (CloudNativePG cluster + generated services/pvcs)
- Redis: `inngest-redis` (OpsTree Redis CR + generated service/pvc)

For a complete list of configuration options, see `values.yaml`.

## Support

- [Inngest Documentation](https://www.inngest.com/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
