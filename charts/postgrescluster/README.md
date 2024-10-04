# PostgresCluster

This chart is used to deploy a `PostgresCluster` instance using [Crunchy Postgres Operator](https://access.crunchydata.com/documentation/postgres-operator/latest).

This chart is just a copy of [their official example chart](https://github.com/CrunchyData/postgres-operator-examples/tree/main/helm/postgres). It is only copied here so that it is published in a Helm repository (the official chart is not published anywhere and requires a manual git clone).

Docs:

<https://access.crunchydata.com/documentation/postgres-operator/latest/>

Full `PostgresCluster` CRD reference (all of these configs are available in the values of this chart):

<https://access.crunchydata.com/documentation/postgres-operator/latest/references/crd/5.6.x/postgrescluster>

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

If you haven't already installed the PGO chart in your cluster, you will need to do that first so the `PostgresCluster` CRD is available.

```sh
helm install pgo -n pgo jshimko/pgo --set features.AutoCreateUserSchema=true
```

Note that we are installing the PGO chart above with the `AutoCreateUserSchema` feature flag enabled ([more info](https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/basic-setup/user-management#automatically-creating-per-user-schemas)). This is recommended so you don't have to manually create a user schema and grant permissions for your application user. If you choose not to enable this, you will need to manually grant the necessary permissions for your application user to access the database.

To deploy a `PostgresCluster` instance:

```sh
helm install my-pg-cluster -n my-namespace -f my-values.yaml jshimko/postgrescluster --set autoCreateUserSchema=true
```
