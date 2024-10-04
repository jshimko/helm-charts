# Svix Webhooks

![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart to deploy the Svix open source webhooks service. <https://www.svix.com>

## Usage

[Helm](https://helm.sh) must be installed to use this chart. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Add this chart repository if you haven't already:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
helm repo update
```

To install:

```sh
helm install svix --namespace svix jshimko/svix
```

To uninstall:

```sh
helm delete svix --namespace svix
```

## Included Dependencies

| Repository                              | Name       | Version |
| --------------------------------------- | ---------- | ------- |
| `https://jshimko.github.io/helm-charts` | [postgrescluster](../postgrescluster/) | 5.6.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| extraTemplates | list | `[]` |  |
| fullnameOverride | string | `""` |  |
| nameOverride | string | `""` |  |
| postgrescluster.annotations | object | `{}` | PostgresCluster annotations |
| postgrescluster.enabled | bool | `false` | disabled by default in case PostgresOperator is not installed in the cluster |
| postgrescluster.instances | list | `[{"dataVolumeClaimSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"2Gi"}}},"name":"svix","replicas":1,"resources":{}}]` | Postgres instances |
| postgrescluster.instances[0].resources | object | `{}` | Postgres instance resources |
| postgrescluster.name | string | `"postgres-svix"` | PostgresCluster name |
| postgrescluster.pgBackRestConfig | object | `{"global":{"repo1-retention-full":"7","repo1-retention-full-type":"time"},"manual":{"options":["--type=full"],"repoName":"repo1"},"repos":[{"name":"repo1","schedules":{"differential":"0 12 * * 1-6","full":"0 12 * * 0"},"volume":{"volumeClaimSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"10Gi"}}}}}]}` | <https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/backups-disaster-recovery/backups> |
| postgrescluster.pgBouncerReplicas | int | `1` |  |
| postgrescluster.users | list | `[{"name":"postgres"},{"databases":["svix"],"name":"svix"}]` | Postgres users to create and assign access to databases |
| postgrescluster.users[0] | object | `{"name":"postgres"}` | db admin |
| postgrescluster.users[1] | object | `{"databases":["svix"],"name":"svix"}` | app user |
| redis.architecture | string | `"standalone"` |  |
| redis.auth.enabled | bool | `false` |  |
| redis.enabled | bool | `true` |  |
| redis.fullnameOverride | string | `"svix-redis"` |  |
| redis.master.extraFlags[0] | string | `"--save 60 500"` |  |
| redis.master.extraFlags[1] | string | `"--appendonly yes"` |  |
| redis.master.extraFlags[2] | string | `"--appendfsync everysec"` |  |
| svix.affinity | object | `{}` |  |
| svix.autoscaling.enabled | bool | `false` |  |
| svix.autoscaling.maxReplicas | int | `10` |  |
| svix.autoscaling.minReplicas | int | `1` |  |
| svix.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| svix.autoscaling.targetMemoryUtilizationPercentage | int | `95` |  |
| svix.createJwtSecret.annotations | object | `{}` |  |
| svix.createJwtSecret.enabled | bool | `false` |  |
| svix.createJwtSecret.secretKey | string | `"SVIX_API_KEY"` |  |
| svix.createJwtSecret.secretName | string | `"svix-jwt"` |  |
| svix.dbUrlOptions | string | `"schema=svix&sslmode=require&application_name=svix"` | PostgresCluster connection string options. e.g. schema=stack,connection_limit=10,connect_timeout=10,pool_timeout=10 |
| svix.env | list | `[]` |  |
| svix.envFrom | list | `[]` |  |
| svix.image.pullPolicy | string | `"Always"` |  |
| svix.image.repository | string | `"svix/svix-server"` |  |
| svix.image.tag | string | `"latest"` |  |
| svix.imagePullSecrets | list | `[]` |  |
| svix.ingress.annotations | object | `{}` |  |
| svix.ingress.className | string | `""` |  |
| svix.ingress.enabled | bool | `false` |  |
| svix.ingress.hosts[0].host | string | `"example.com"` |  |
| svix.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| svix.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| svix.ingress.tls | list | `[]` |  |
| svix.livenessProbe | string | `nil` |  |
| svix.nodeSelector | object | `{}` |  |
| svix.podAnnotations | object | `{}` |  |
| svix.podLabels | object | `{}` |  |
| svix.podSecurityContext | object | `{}` |  |
| svix.postgresClusterSecret | string | `""` | optional Postgres Operator cluster secret name. This is useful if you deploy a PostgresCluster instance outside of this chart. |
| svix.readinessProbe | string | `nil` |  |
| svix.replicaCount | int | `1` |  |
| svix.resources | object | `{}` |  |
| svix.securityContext | object | `{}` |  |
| svix.service.port | int | `8071` |  |
| svix.service.type | string | `"ClusterIP"` |  |
| svix.serviceAccount.annotations | object | `{}` |  |
| svix.serviceAccount.automount | bool | `true` |  |
| svix.serviceAccount.create | bool | `true` |  |
| svix.serviceAccount.name | string | `""` |  |
| svix.startupProbe | string | `nil` |  |
| svix.tolerations | list | `[]` |  |
| svix.volumeMounts | list | `[]` |  |
| svix.volumes | list | `[]` |  |
