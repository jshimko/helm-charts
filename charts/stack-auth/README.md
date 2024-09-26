# Stack Auth

![Version: 0.8.1](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Helm chart to deploy the Stack Auth platform. <https://stack-auth.com>

## Usage

[Helm](https://helm.sh) must be installed to use this chart. Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Add this repo as follows:

```sh
helm repo add jshimko https://jshimko.github.io/helm-charts
```

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions.

To install:

```sh
helm install stack --namespace stack jshimko/stack-auth
```

To uninstall:

```sh
helm delete stack --namespace stack
```

## Included Dependencies

| Repository                              | Name       | Version |
| --------------------------------------- | ---------- | ------- |
| `https://jshimko.github.io/helm-charts` | [postgrescluster](../postgrescluster/) | 5.6.1 |
| `https://jshimko.github.io/helm-charts` | [svix](../svix/) | 0.6.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backend.affinity | object | `{}` |  |
| backend.annotations | object | `{}` | Deployment annotations |
| backend.autoscaling.enabled | bool | `false` |  |
| backend.autoscaling.maxReplicas | int | `10` |  |
| backend.autoscaling.minReplicas | int | `1` |  |
| backend.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| backend.autoscaling.targetMemoryUtilizationPercentage | int | `95` |  |
| backend.dbUrlOptions | string | `"schema=stack&sslmode=require&application_name=stack-auth"` | PostgresCluster connection string options. e.g. schema=stack,connection_limit=10,connect_timeout=10,pool_timeout=10 |
| backend.env | list | `[]` | Backend environment variables - see available [.env](https://github.com/stack-auth/stack/blob/dev/apps/backend/.env) options |
| backend.envFrom | list | `[]` | Backend environment variables from secrets or configmaps |
| backend.image.pullPolicy | string | `"IfNotPresent"` |  |
| backend.image.repository | string | `"jshimko/stack-backend"` |  |
| backend.image.tag | string | `"dev"` |  |
| backend.imagePullSecrets | list | `[]` |  |
| backend.ingress.annotations | object | `{}` |  |
| backend.ingress.className | string | `"nginx"` |  |
| backend.ingress.enabled | bool | `false` |  |
| backend.ingress.hosts[0].host | string | `"example.com"` |  |
| backend.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| backend.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| backend.ingress.tls | list | `[]` |  |
| backend.livenessProbe | string | `nil` |  |
| backend.nodeSelector | object | `{}` |  |
| backend.podAnnotations | object | `{}` |  |
| backend.podLabels | object | `{}` |  |
| backend.podSecurityContext | object | `{}` |  |
| backend.postgresClusterSecret | string | `""` | optional Postgres Operator cluster secret name. This is useful if you deploy a PostgresCluster instance outside of this chart. |
| backend.readinessProbe | string | `nil` |  |
| backend.replicaCount | int | `1` |  |
| backend.resources | object | `{}` | <https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/> |
| backend.securityContext | object | `{}` |  |
| backend.service.port | int | `8102` |  |
| backend.service.type | string | `"ClusterIP"` |  |
| backend.serviceAccount.annotations | object | `{}` |  |
| backend.serviceAccount.automount | bool | `true` |  |
| backend.serviceAccount.create | bool | `true` |  |
| backend.serviceAccount.name | string | `""` |  |
| backend.startupProbe | string | `nil` |  |
| backend.tolerations | list | `[]` |  |
| backend.volumeMounts | list | `[]` | Additional volumeMounts on the output Deployment definition. |
| backend.volumes | list | `[]` | Additional volumes on the output Deployment definition. |
| dashboard.affinity | object | `{}` |  |
| dashboard.annotations | object | `{}` | Deployment annotations |
| dashboard.autoscaling.enabled | bool | `false` |  |
| dashboard.autoscaling.maxReplicas | int | `10` |  |
| dashboard.autoscaling.minReplicas | int | `1` |  |
| dashboard.autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| dashboard.autoscaling.targetMemoryUtilizationPercentage | int | `95` |  |
| dashboard.env | list | `[]` | Dashboard environment variables - see available [.env](https://github.com/stack-auth/stack/blob/dev/apps/dashboard/.env) options |
| dashboard.envFrom | list | `[]` | Dashboard environment variables from secrets or configmaps |
| dashboard.image.pullPolicy | string | `"IfNotPresent"` |  |
| dashboard.image.repository | string | `"jshimko/stack-dashboard"` |  |
| dashboard.image.tag | string | `"dev"` |  |
| dashboard.imagePullSecrets | list | `[]` |  |
| dashboard.ingress.annotations | object | `{}` |  |
| dashboard.ingress.className | string | `"nginx"` |  |
| dashboard.ingress.enabled | bool | `false` |  |
| dashboard.ingress.hosts[0].host | string | `"example.com"` |  |
| dashboard.ingress.hosts[0].paths[0].path | string | `"/"` |  |
| dashboard.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| dashboard.ingress.tls | list | `[]` |  |
| dashboard.livenessProbe | string | `nil` |  |
| dashboard.nodeSelector | object | `{}` |  |
| dashboard.podAnnotations | object | `{}` |  |
| dashboard.podLabels | object | `{}` |  |
| dashboard.podSecurityContext | object | `{}` |  |
| dashboard.readinessProbe | string | `nil` |  |
| dashboard.replicaCount | int | `1` |  |
| dashboard.resources | object | `{}` | <https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/> |
| dashboard.securityContext | object | `{}` |  |
| dashboard.service.port | int | `8101` |  |
| dashboard.service.type | string | `"ClusterIP"` |  |
| dashboard.serviceAccount.annotations | object | `{}` |  |
| dashboard.serviceAccount.automount | bool | `true` |  |
| dashboard.serviceAccount.create | bool | `true` |  |
| dashboard.serviceAccount.name | string | `""` |  |
| dashboard.startupProbe | string | `nil` |  |
| dashboard.tolerations | list | `[]` |  |
| dashboard.volumeMounts | list | `[]` |  |
| dashboard.volumes | list | `[]` |  |
| extraTemplates | list | `[]` | Any misc extra K8s manifests you'd like to create |
| fullnameOverride | string | `""` |  |
| manageNamespace.enabled | bool | `false` |  |
| nameOverride | string | `""` |  |
| postgrescluster.annotations | object | `{}` | PostgresCluster annotations |
| postgrescluster.enabled | bool | `false` | disabled by default in case PostgresOperator is not installed in the cluster |
| postgrescluster.instances | list | `[{"dataVolumeClaimSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"10Gi"}}},"name":"stack","replicas":1,"resources":{}}]` | Postgres instances |
| postgrescluster.instances[0].resources | object | `{}` | Postgres instance resources |
| postgrescluster.name | string | `"postgres-stack"` | PostgresCluster name |
| postgrescluster.pgBackRestConfig | object | `{"global":{"repo1-retention-full":"7","repo1-retention-full-type":"time"},"manual":{"options":["--type=full"],"repoName":"repo1"},"repos":[{"name":"repo1","schedules":{"differential":"0 12 * * 1-6","full":"0 12 * * 0"},"volume":{"volumeClaimSpec":{"accessModes":["ReadWriteOnce"],"resources":{"requests":{"storage":"10Gi"}}}}}]}` | <https://access.crunchydata.com/documentation/postgres-operator/latest/tutorials/backups-disaster-recovery/backups> |
| postgrescluster.pgBouncerReplicas | int | `1` |  |
| postgrescluster.users | list | `[{"name":"postgres"},{"databases":["stack"],"name":"stack"}]` | Postgres users to create and assign access to databases |
| postgrescluster.users[0] | object | `{"name":"postgres"}` | db admin |
| postgrescluster.users[1] | object | `{"databases":["stack"],"name":"stack"}` | app user |
| svix.enabled | bool | `true` |  |
| svix.fullnameOverride | string | `"svix"` |  |
| svix.postgresql.architecture | string | `"standalone"` | `standalone` or `replication` |
| svix.postgresql.enabled | bool | `true` |  |
| svix.postgresql.fullnameOverride | string | `"svix-postgresql"` |  |
| svix.redis.architecture | string | `"standalone"` | `standalone` or `replication` |
| svix.redis.enabled | bool | `true` |  |
| svix.redis.fullnameOverride | string | `"svix-redis"` |  |
| svix.svix.createJwtSecret.enabled | bool | `true` |  |
| svix.svix.createJwtSecret.secretKey | string | `"STACK_SVIX_API_KEY"` |  |
| svix.svix.createJwtSecret.secretName | string | `"svix-jwt-secret"` |  |
| svix.svix.env | list | `[]` | Svix server config. See [docs](https://github.com/svix/svix-webhooks/blob/main/server/svix-server/config.default.toml) |
| svix.svix.image.pullPolicy | string | `"Always"` |  |
| svix.svix.image.repository | string | `"svix/svix-server"` |  |
| svix.svix.image.tag | string | `"latest"` |  |
