# Helm Charts

This repository contains [Helm](https://helm.sh/) charts for various open source applications and services. To learn more, please see the readme for each available chart.

- [Stack Auth](./charts/stack-auth/) - See also <https://stack-auth.com>
- [Svix Webhooks](./charts/svix/) - See also <https://www.svix.com>

## Usage

[Helm](https://helm.sh) must be installed to use this chart. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Add this repo as follows:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions. You can then run `helm search repo
jshimko` to see the available charts.

To install a chart:

```sh
helm install my-release -n my-namespace jshimko/chart-name
```
