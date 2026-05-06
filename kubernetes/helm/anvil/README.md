# Anvil Helm chart

Deploys [Anvil](https://github.com/your-org/anvil) — the self-service load
testing platform — to Kubernetes. Bundles Postgres, Redis, InfluxDB v1, and
Grafana so you can `helm install` and have a working stack, with
straightforward overrides to point at existing services in production.

## Prerequisites

- Kubernetes 1.24+
- Helm 3.x
- A registry where you've pushed the api/worker/web container images. Easiest
  way to publish them after cloning the repo:

  ```bash
  REGISTRY=ghcr.io/your-org TAG=0.1.0
  docker buildx build -t $REGISTRY/anvil-api:$TAG    api    --push
  docker buildx build -t $REGISTRY/anvil-worker:$TAG worker --push
  docker buildx build -t $REGISTRY/anvil-web:$TAG    web    --push
  ```

## Install

### From the GHCR OCI registry (recommended)

After a `v*.*.*` tag is pushed, the **Publish Helm chart** GitHub Actions
workflow uploads the chart to GHCR and the images to the matching tag:

```bash
helm install anvil oci://ghcr.io/your-org/charts/anvil --version 0.1.0 \
  --set image.api.repository=ghcr.io/your-org/anvil-api \
  --set image.worker.repository=ghcr.io/your-org/anvil-worker \
  --set image.web.repository=ghcr.io/your-org/anvil-web \
  --set image.api.tag=0.1.0 \
  --set image.worker.tag=0.1.0 \
  --set image.web.tag=0.1.0
```

If your GHCR packages are private, run `helm registry login ghcr.io` first.

### From a local checkout

```bash
helm install anvil ./deploy/helm/anvil \
  --set image.api.repository=ghcr.io/your-org/anvil-api \
  --set image.worker.repository=ghcr.io/your-org/anvil-worker \
  --set image.web.repository=ghcr.io/your-org/anvil-web \
  --set image.api.tag=0.1.0 \
  --set image.worker.tag=0.1.0 \
  --set image.web.tag=0.1.0
```

Then port-forward to try it:

```bash
kubectl port-forward svc/anvil-web 5173:5173
kubectl port-forward svc/anvil-api 4000:4000
```

Open http://localhost:5173.

## Bringing your own backing services

Each backing service has the same shape: an `enabled` flag and an `external`
block consumed when `enabled` is false. Example values file pointing at a
managed Postgres and managed Grafana while still bundling Redis + InfluxDB:

```yaml
# values.production.yaml
postgres:
  enabled: false
  external:
    url: postgresql://anvil:secret@pg.internal:5432/anvil

grafana:
  enabled: false
  external:
    baseUrl: https://grafana.your-org.com   # used to build "Open in Grafana" deep-links
  dashboardUid: anvil

# bundled redis + influxdb stay enabled — adjust as needed
```

```bash
helm install anvil ./deploy/helm/anvil -f values.production.yaml
```

## Exposing publicly with Ingress

```yaml
web:
  apiUrl: https://anvil.example.com/api
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: anvil.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts: [anvil.example.com]
        secretName: anvil-tls

grafana:
  baseUrl: https://grafana.example.com
  ingress:
    enabled: true
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt
    hosts:
      - host: grafana.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts: [grafana.example.com]
        secretName: grafana-tls
```

For routing the `/api` path to the api Service alongside web on the same
host, you'll typically add a second Ingress rule or path entry — left to the
operator since ingress controllers vary.

## Safety guards

The same env-driven guards from docker-compose are exposed:

```yaml
api:
  guards:
    targetHostAllowlist: "*.internal.example.com,api.example.com"
    maxVus: 500
    maxDurationSeconds: 1800
    maxConcurrentRuns: 3
```

Empty / 0 means no limit.

## Storage

Postgres, InfluxDB, and Grafana mount PersistentVolumeClaims by default
(`<svc>.persistence.enabled`). Set `<svc>.persistence.storageClass` to pin
to a specific class; otherwise the cluster default is used.

Redis defaults to ephemeral storage — the BullMQ queue can be rebuilt on
boot, so persistence isn't critical. Flip `redis.persistence.enabled=true`
if you'd rather preserve in-flight jobs across restarts.

## Upgrading

The dashboard JSON is shipped inside the chart at `files/anvil.json`. After
editing `infra/grafana-dashboard.json` in the project root, run
`./infra/sync-dashboard.sh` — it now also mirrors the dashboard into the
chart, so the next `helm upgrade` ships your edits.

## Uninstalling

```bash
helm uninstall anvil
```

PVCs (Postgres, InfluxDB, Grafana data) are **not** deleted automatically —
that's by design so you can recover after a misclick. Delete them
explicitly when you're sure:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=anvil
```
