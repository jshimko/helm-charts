# Ente Museum: Complete Environment Variable Reference

> Canonical reference traced from source code (`viper.Get*` calls across the
> entire `server/` codebase). Not derived from documentation.

## Naming Convention

All Museum config keys can be set as environment variables:

1. Add prefix `ENTE_`
2. Replace dots (`.`) with underscores (`_`)
3. Replace hyphens (`-`) with underscores (`_`)
4. Uppercase everything

Example: `s3.b2-eu-cen.endpoint` becomes `ENTE_S3_B2_EU_CEN_ENDPOINT`

## Configuration Precedence (highest to lowest)

1. Environment variables with `ENTE_` prefix
2. `museum.yaml` in the working directory
3. Credentials file (`credentials.yaml` or value of `credentials-file`)
4. `configurations/{ENVIRONMENT}.yaml` (base config)

---

## Meta / File-level


| YAML Key             | Env Var                   | Type   | Default            | Notes                                                                           |
| -------------------- | ------------------------- | ------ | ------------------ | ------------------------------------------------------------------------------- |
| `credentials-file`   | `ENTE_CREDENTIALS_FILE`   | string | `credentials.yaml` | Path to credentials override file                                               |
| `credentials-dir`    | `ENTE_CREDENTIALS_DIR`    | string | `credentials`      | Dir for TLS certs, service accounts                                             |
| `billing-config-dir` | `ENTE_BILLING_CONFIG_DIR` | string | `data/billing/`    | Billing config directory                                                        |
| `log-file`           | `ENTE_LOG_FILE`           | string | `""` (stdout)      | Required in non-local environments                                              |
| —                    | `ENVIRONMENT`             | string | `local`            | **Not Viper** — `os.Getenv`. Selects config file: `configurations/{value}.yaml` |
| —                    | `GIT_COMMIT`              | string | —                  | **Not Viper** — build arg, shown in healthcheck response                        |


## HTTP


| YAML Key       | Env Var             | Type | Default | Notes                                                                |
| -------------- | ------------------- | ---- | ------- | -------------------------------------------------------------------- |
| `http.port`    | `ENTE_HTTP_PORT`    | int  | `8080`  | **Only used when TLS is off.** TLS hardcodes to 443 (`main.go:1023`) |
| `http.use-tls` | `ENTE_HTTP_USE_TLS` | bool | `false` | Requires `credentials/tls.cert` and `credentials/tls.key`            |


## App Endpoints


| YAML Key                   | Env Var                         | Type   | Default                    | Source                                       |
| -------------------------- | ------------------------------- | ------ | -------------------------- | -------------------------------------------- |
| `apps.public-albums`       | `ENTE_APPS_PUBLIC_ALBUMS`       | string | `https://albums.ente.io`   | `viper.SetDefault` `main.go:103`             |
| `apps.embed-albums`        | `ENTE_APPS_EMBED_ALBUMS`        | string | `https://embed.ente.io`    | `viper.SetDefault` `main.go:104`             |
| `apps.public-locker`       | `ENTE_APPS_PUBLIC_LOCKER`       | string | `https://share.ente.io`    | `viper.SetDefault` `main.go:106`             |
| `apps.public-paste`        | `ENTE_APPS_PUBLIC_PASTE`        | string | `https://paste.ente.io`    | `viper.SetDefault` `main.go:107`             |
| `apps.cast`                | `ENTE_APPS_CAST`                | string | `https://cast.ente.io`     | `viper.SetDefault` `main.go:109`             |
| `apps.accounts`            | `ENTE_APPS_ACCOUNTS`            | string | `https://accounts.ente.io` | `viper.SetDefault` `main.go:108`             |
| `apps.family`              | `ENTE_APPS_FAMILY`              | string | `https://family.ente.io`   | `viper.SetDefault` `main.go:110`             |
| `apps.public-memories`     | `ENTE_APPS_PUBLIC_MEMORIES`     | string | `https://memories.ente.io` | Fallback in `pkg/repo/memory_share.go:24-26` |
| `apps.custom-domain.cname` | `ENTE_APPS_CUSTOM_DOMAIN_CNAME` | string | `my.ente.io`               | `viper.SetDefault` `main.go:105`             |


## Database


| YAML Key      | Env Var            | Type   | Default     | Notes                        |
| ------------- | ------------------ | ------ | ----------- | ---------------------------- |
| `db.host`     | `ENTE_DB_HOST`     | string | `localhost` |                              |
| `db.port`     | `ENTE_DB_PORT`     | int    | `5432`      |                              |
| `db.name`     | `ENTE_DB_NAME`     | string | `ente_db`   |                              |
| `db.user`     | `ENTE_DB_USER`     | string | —           |                              |
| `db.password` | `ENTE_DB_PASSWORD` | string | —           |                              |
| `db.sslmode`  | `ENTE_DB_SSLMODE`  | string | `disable`   | Use `require` for production |
| `db.extra`    | `ENTE_DB_EXTRA`    | string | —           | Appended verbatim to DSN     |


> **Note:** `db.max-open-conns` and `db.max-idle-conns` do NOT exist in the
> server code. Go's `sql.DB` defaults are used. The Helm chart previously
> exposed these but they had zero effect.

## Security Keys

| YAML Key         | Env Var               | Type   | Default             | Notes                                                                               |
| ---------------- | --------------------- | ------ | ------------------- | ----------------------------------------------------------------------------------- | ------- | -------------- |
| `key.encryption` | `ENTE_KEY_ENCRYPTION` | string | Hardcoded dev value | 32 bytes, standard base64. `openssl rand 32                                         | base64` |
| `key.hash`       | `ENTE_KEY_HASH`       | string | Hardcoded dev value | 64 bytes, standard base64. `openssl rand 64                                         | base64` |
| `jwt.secret`     | `ENTE_JWT_SECRET`     | string | Hardcoded dev value | 32 bytes, **URL-safe base64** (decoded with `base64.URLEncoding`). `openssl rand 32 | base64  | tr '+/' '-\_'` |

> **Critical:** These MUST be set for production. The defaults in `local.yaml`
> are publicly known.

## S3 Storage — Global


| YAML Key                   | Env Var                         | Type   | Default                  | Notes                                         |
| -------------------------- | ------------------------------- | ------ | ------------------------ | --------------------------------------------- |
| `s3.are_local_buckets`     | `ENTE_S3_ARE_LOCAL_BUCKETS`     | bool   | `false`                  | Disables SSL, path-style URLs, skips GLACIER  |
| `s3.use_path_style_urls`   | `ENTE_S3_USE_PATH_STYLE_URLS`   | bool   | `false`                  | Path-style instead of subdomain-style S3 URLs |
| `s3.hot_storage.primary`   | `ENTE_S3_HOT_STORAGE_PRIMARY`   | string | `b2-eu-cen`              | Must be valid DC name                         |
| `s3.hot_storage.secondary` | `ENTE_S3_HOT_STORAGE_SECONDARY` | string | `wasabi-eu-central-2-v3` | Must be valid DC name                         |
| `s3.derived-storage`       | `ENTE_S3_DERIVED_STORAGE`       | string | Same as hot primary      | For embeddings, previews                      |


## S3 Storage — Per-Bucket

Valid bucket/DC names: `b2-eu-cen`, `wasabi-eu-central-2-v3`, `scw-eu-fr-v3`,
`wasabi-eu-central-2-derived`, `b5`, `b6`

For each `{dc}` below, replace hyphens with underscores in env var name:


| YAML Key                               | Env Var (example: b2-eu-cen)                | Type   | Notes                           |
| -------------------------------------- | ------------------------------------------- | ------ | ------------------------------- |
| `s3.{dc}.key`                          | `ENTE_S3_B2_EU_CEN_KEY`                     | string | S3 access key                   |
| `s3.{dc}.secret`                       | `ENTE_S3_B2_EU_CEN_SECRET`                  | string | S3 secret key                   |
| `s3.{dc}.endpoint`                     | `ENTE_S3_B2_EU_CEN_ENDPOINT`                | string | S3 endpoint URL                 |
| `s3.{dc}.region`                       | `ENTE_S3_B2_EU_CEN_REGION`                  | string | S3 region                       |
| `s3.{dc}.bucket`                       | `ENTE_S3_B2_EU_CEN_BUCKET`                  | string | Bucket name                     |
| `s3.{dc}.use_path_style_urls`          | `ENTE_S3_B2_EU_CEN_USE_PATH_STYLE_URLS`     | bool   | Per-bucket override             |
| `s3.{dc}.are_local_buckets`            | `ENTE_S3_B2_EU_CEN_ARE_LOCAL_BUCKETS`       | bool   | Per-bucket override             |
| `s3.{dc}.disable_ssl`                  | `ENTE_S3_B2_EU_CEN_DISABLE_SSL`             | bool   | Per-bucket SSL disable          |
| `s3.wasabi-eu-central-2-v3.compliance` | `ENTE_S3_WASABI_EU_CENTRAL_2_V3_COMPLIANCE` | bool   | Only for wasabi-eu-central-2-v3 |


## S3 — File Data Config (Advanced)


| YAML Key                                    | Type     | Notes                                |
| ------------------------------------------- | -------- | ------------------------------------ |
| `s3.file-data-config.{type}.primaryBucket`  | string   | type = `mldata`, `img_preview`, etc. |
| `s3.file-data-config.{type}.replicaBuckets` | string[] | Replica bucket IDs                   |


## SMTP


| YAML Key           | Env Var                 | Type   | Notes                               |
| ------------------ | ----------------------- | ------ | ----------------------------------- |
| `smtp.host`        | `ENTE_SMTP_HOST`        | string | If set, SMTP is used over Transmail |
| `smtp.port`        | `ENTE_SMTP_PORT`        | string |                                     |
| `smtp.username`    | `ENTE_SMTP_USERNAME`    | string | Optional (for local relay)          |
| `smtp.password`    | `ENTE_SMTP_PASSWORD`    | string | Optional (for local relay)          |
| `smtp.email`       | `ENTE_SMTP_EMAIL`       | string | From address                        |
| `smtp.sender-name` | `ENTE_SMTP_SENDER_NAME` | string | Display name                        |
| `smtp.encryption`  | `ENTE_SMTP_ENCRYPTION`  | string | `tls` or `ssl`                      |


## Transmail (Zoho Zeptomail)


| YAML Key        | Env Var              | Type   | Notes                           |
| --------------- | -------------------- | ------ | ------------------------------- |
| `transmail.key` | `ENTE_TRANSMAIL_KEY` | string | Fallback if SMTP not configured |


## Zoho Campaigns (Ente production only)


| YAML Key             | Env Var                   | Type   |
| -------------------- | ------------------------- | ------ |
| `zoho.client-id`     | `ENTE_ZOHO_CLIENT_ID`     | string |
| `zoho.client-secret` | `ENTE_ZOHO_CLIENT_SECRET` | string |
| `zoho.refresh-token` | `ENTE_ZOHO_REFRESH_TOKEN` | string |
| `zoho.list-key`      | `ENTE_ZOHO_LIST_KEY`      | string |
| `zoho.topic-ids`     | `ENTE_ZOHO_TOPIC_IDS`     | string |
| `zoho.access_token`  | `ENTE_ZOHO_ACCESS_TOKEN`  | string |


## Listmonk (Self-hosted mailing lists)


| YAML Key              | Env Var                    | Type   | Notes                                         |
| --------------------- | -------------------------- | ------ | --------------------------------------------- |
| `listmonk.server-url` | `ENTE_LISTMONK_SERVER_URL` | string |                                               |
| `listmonk.username`   | `ENTE_LISTMONK_USERNAME`   | string |                                               |
| `listmonk.password`   | `ENTE_LISTMONK_PASSWORD`   | string |                                               |
| `listmonk.list-ids`   | `ENTE_LISTMONK_LIST_IDS`   | int[]  | Viper slice quirks — may need comma-separated |


## Stripe (Optional)


| YAML Key                           | Env Var                                 | Type     |
| ---------------------------------- | --------------------------------------- | -------- |
| `stripe.us.key`                    | `ENTE_STRIPE_US_KEY`                    | string   |
| `stripe.us.webhook-secret`         | `ENTE_STRIPE_US_WEBHOOK_SECRET`         | string   |
| `stripe.in.key`                    | `ENTE_STRIPE_IN_KEY`                    | string   |
| `stripe.in.webhook-secret`         | `ENTE_STRIPE_IN_WEBHOOK_SECRET`         | string   |
| `stripe.whitelisted-redirect-urls` | `ENTE_STRIPE_WHITELISTED_REDIRECT_URLS` | string[] |
| `stripe.path.success`              | `ENTE_STRIPE_PATH_SUCCESS`              | string   |
| `stripe.path.cancel`               | `ENTE_STRIPE_PATH_CANCEL`               | string   |


## Apple IAP (Optional)


| YAML Key              | Env Var                    | Type   |
| --------------------- | -------------------------- | ------ |
| `apple.shared-secret` | `ENTE_APPLE_SHARED_SECRET` | string |


## WebAuthn / Passkeys


| YAML Key             | Env Var                   | Type     | Default                     |
| -------------------- | ------------------------- | -------- | --------------------------- |
| `webauthn.rpid`      | `ENTE_WEBAUTHN_RPID`      | string   | `localhost`                 |
| `webauthn.rporigins` | `ENTE_WEBAUTHN_RPORIGINS` | string[] | `["http://localhost:3001"]` |


## Discord Notifications


| YAML Key                        | Env Var                              | Type   |
| ------------------------------- | ------------------------------------ | ------ |
| `discord.bot.cha-ching.token`   | `ENTE_DISCORD_BOT_CHA_CHING_TOKEN`   | string |
| `discord.bot.cha-ching.channel` | `ENTE_DISCORD_BOT_CHA_CHING_CHANNEL` | string |
| `discord.bot.mona-lisa.token`   | `ENTE_DISCORD_BOT_MONA_LISA_TOKEN`   | string |
| `discord.bot.mona-lisa.channel` | `ENTE_DISCORD_BOT_MONA_LISA_CHANNEL` | string |


## Replication


| YAML Key                             | Env Var                                   | Type   | Default           |
| ------------------------------------ | ----------------------------------------- | ------ | ----------------- |
| `replication.enabled`                | `ENTE_REPLICATION_ENABLED`                | bool   | `false`           |
| `replication.worker-url`             | `ENTE_REPLICATION_WORKER_URL`             | string | —                 |
| `replication.worker-count`           | `ENTE_REPLICATION_WORKER_COUNT`           | int    | `6`               |
| `replication.tmp-storage`            | `ENTE_REPLICATION_TMP_STORAGE`            | string | `tmp/replication` |
| `replication.file-data.worker-count` | `ENTE_REPLICATION_FILE_DATA_WORKER_COUNT` | int    | `6`               |
| `replication.file-data.tmp-storage`  | `ENTE_REPLICATION_FILE_DATA_TMP_STORAGE`  | string | `tmp/replication` |


## Background Jobs


| YAML Key                                      | Env Var                                            | Type   | Default |
| --------------------------------------------- | -------------------------------------------------- | ------ | ------- |
| `jobs.cron.skip`                              | `ENTE_JOBS_CRON_SKIP`                              | bool   | `false` |
| `jobs.remove-unreported-objects.worker-count` | `ENTE_JOBS_REMOVE_UNREPORTED_OBJECTS_WORKER_COUNT` | int    | `1`     |
| `jobs.clear-orphan-objects.enabled`           | `ENTE_JOBS_CLEAR_ORPHAN_OBJECTS_ENABLED`           | bool   | `false` |
| `jobs.clear-orphan-objects.prefix`            | `ENTE_JOBS_CLEAR_ORPHAN_OBJECTS_PREFIX`            | string | `""`    |


## Internal


| YAML Key                                     | Env Var                                           | Type     | Default | Notes                                                         |
| -------------------------------------------- | ------------------------------------------------- | -------- | ------- | ------------------------------------------------------------- |
| `internal.silent`                            | `ENTE_INTERNAL_SILENT`                            | bool     | `false` | Suppresses emails, Discord alerts                             |
| `internal.trusted-client-ip-header`          | `ENTE_INTERNAL_TRUSTED_CLIENT_IP_HEADER`          | string   | —       | Sets Gin's `TrustedPlatform` for proxy setups                 |
| `internal.health-check-url`                  | `ENTE_INTERNAL_HEALTH_CHECK_URL`                  | string   | —       | External healthcheck to ping                                  |
| `internal.hardcoded-ott.emails`              | `ENTE_INTERNAL_HARDCODED_OTT_EMAILS`              | string[] | `[]`    | Format: `"email@example.com,123456"`                          |
| `internal.hardcoded-ott.local-domain-suffix` | `ENTE_INTERNAL_HARDCODED_OTT_LOCAL_DOMAIN_SUFFIX` | string   | —       | Only in local env                                             |
| `internal.hardcoded-ott.local-domain-value`  | `ENTE_INTERNAL_HARDCODED_OTT_LOCAL_DOMAIN_VALUE`  | string   | —       | Only in local env                                             |
| `internal.admins`                            | `ENTE_INTERNAL_ADMINS`                            | int[]    | `[]`    | Viper has issues with int slices from env vars                |
| `internal.admin`                             | `ENTE_INTERNAL_ADMIN`                             | int      | —       | Single admin fallback — use this for env-var-only deployments |
| `internal.disable-registration`              | `ENTE_INTERNAL_DISABLE_REGISTRATION`              | bool     | `false` |                                                               |


## Web App Environment Variables (Docker/Compose, not Museum)


| Env Var                | Service  | Description                                    |
| ---------------------- | -------- | ---------------------------------------------- |
| `ENTE_API_ORIGIN`      | web apps | Alias for `NEXT_PUBLIC_ENTE_ENDPOINT`          |
| `ENTE_ALBUMS_ORIGIN`   | web apps | Alias for `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT`   |
| `ENTE_PHOTOS_ORIGIN`   | web apps | Alias for `NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT`   |
| `ENTE_ACCOUNTS_ORIGIN` | web apps | Alias for `NEXT_PUBLIC_ENTE_ACCOUNTS_ENDPOINT` |
| `POSTGRES_USER`        | postgres | PostgreSQL container user                      |
| `POSTGRES_PASSWORD`    | postgres | PostgreSQL container password                  |
| `POSTGRES_DB`          | postgres | PostgreSQL container database                  |
| `MINIO_ROOT_USER`      | minio    | MinIO admin user                               |
| `MINIO_ROOT_PASSWORD`  | minio    | MinIO admin password                           |


