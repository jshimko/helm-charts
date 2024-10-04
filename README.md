# Helm Charts

This repository contains [Helm](https://helm.sh/) charts for various open source applications and services. To learn more, please see the readme for each available chart.

- [Crunchy Postgres Operator](./charts/pgo/) - See also <https://access.crunchydata.com/documentation/postgres-operator/latest>
- [PostgresCluster](./charts/postgrescluster/) - See also <https://access.crunchydata.com/documentation/postgres-operator/latest>
- [Stack Auth](./charts/stack-auth/) - See also <https://stack-auth.com>
- [Svix Webhooks](./charts/svix/) - See also <https://www.svix.com>

## Usage

Add this chart repository:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
helm repo update
```

To install any chart in this repository:

```sh
helm install my-release -n my-namespace jshimko/chart-name
```
