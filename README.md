# Helm Charts

This repository contains [Helm](https://helm.sh/) charts for various open source applications and services. To learn more, please see the readme for each available chart.

- [Ente Photos](./charts/ente/) - End-to-end encrypted photo storage. See also <https://ente.io>
- [Inngest](./charts/inngest/) - Self-hosted Inngest event-driven workflow platform. See also <https://www.inngest.com>
- [PGO](./charts/pgo/) - See also [Crunchy Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/latest)
- [PostgresCluster](./charts/postgrescluster/) - See also <https://access.crunchydata.com/documentation/postgres-operator/latest>
- [Svix Webhooks](./charts/svix/) - See also <https://www.svix.com>

## Usage

Add this chart repository:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
helm repo update
```

To install any chart in this repository:

```sh
helm install my-release -n my-namespace jshimko/$CHART_NAME
```
