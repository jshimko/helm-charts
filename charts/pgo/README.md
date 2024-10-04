# Crunchy Postgres Operator

This chart is used to deploy [Crunchy Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/latest) (PGO).

This chart is just a copy of [their official chart](https://github.com/CrunchyData/postgres-operator-examples/tree/main/helm/install). It is only copied here so that it is published in a Helm repository (the official chart is not published anywhere and requires a manual git clone).

Docs:

<https://access.crunchydata.com/documentation/postgres-operator/latest/>

Examples Repo:

<https://github.com/CrunchyData/postgres-operator-examples>

Original source of this chart:

<https://github.com/CrunchyData/postgres-operator-examples/tree/main/helm/postgres>

## Usage

Add this chart repository if you haven't already:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
helm repo update
```

To install PGO in your cluster:

```sh
helm install pgo -n pgo jshimko/pgo
```

Now you can deploy a `PostgresCluster` in any namespace:

```sh
helm install my-pg-cluster -n my-namespace -f my-values.yaml jshimko/postgrescluster
```

See the [postgrescluster chart](../postgrescluster) for more info.
