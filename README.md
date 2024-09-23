# Helm Charts

This repository contains Helm charts for various applications and services.

## Usage

Add the repository and install any included chart using Helm like this:

```sh
# add the repo
helm repo add jshimko https://jshimko.github.io/helm-charts
helm repo update

# install chart
helm install my-release -n my-namespace jshimko/chart-name
```
