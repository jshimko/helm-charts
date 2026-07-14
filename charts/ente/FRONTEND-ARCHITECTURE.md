# Frontend Architecture: Docker Image & Helm Deployment

Reference documentation for how the `ghcr.io/ente-io/web` Docker image works internally and how this Helm chart deploys it.

---

## Table of Contents

- [Frontend Architecture: Docker Image \& Helm Deployment](#frontend-architecture-docker-image--helm-deployment)
  - [Table of Contents](#table-of-contents)
  - [Docker Image Overview](#docker-image-overview)
  - [Build Stage: Static Site Generation](#build-stage-static-site-generation)
  - [Runtime Stage: nginx Entrypoint](#runtime-stage-nginx-entrypoint)
    - [Full Startup Sequence](#full-startup-sequence)
  - [Environment Variable Substitution](#environment-variable-substitution)
    - [Available Environment Variables](#available-environment-variables)
    - [Why This Pattern Exists](#why-this-pattern-exists)
  - [nginx Server Blocks \& Port Map](#nginx-server-blocks--port-map)
    - [Important Details](#important-details)
  - [Helm Chart Deployment Model](#helm-chart-deployment-model)
    - [How It Works](#how-it-works)
    - [Enabled Services (default)](#enabled-services-default)
  - [Environment Variable Flow](#environment-variable-flow)
    - [Frontend (Web Apps)](#frontend-web-apps)
    - [Museum (Backend API)](#museum-backend-api)
  - [Museum App Endpoint Configuration](#museum-app-endpoint-configuration)
  - [Memories App](#memories-app)
    - [What It Is](#what-it-is)
    - [How It Works](#how-it-works-1)
    - [Server-Side Support (Museum)](#server-side-support-museum)
    - [Status in the Docker Image](#status-in-the-docker-image)
    - [Status in This Helm Chart](#status-in-this-helm-chart)
    - [Deploying Memories Self-Hosted](#deploying-memories-self-hosted)
  - [Known Issues \& Gotchas](#known-issues--gotchas)
    - [1. Embed Port Mismatch](#1-embed-port-mismatch)
    - [2. Every Pod Runs All Apps](#2-every-pod-runs-all-apps)
    - [3. Environment Substitution is One-Shot](#3-environment-substitution-is-one-shot)
    - [4. Albums and Photos Are the Same Build](#4-albums-and-photos-are-the-same-build)
    - [5. Missing Apps in the Docker Image](#5-missing-apps-in-the-docker-image)
    - [6. No Health Check Endpoint](#6-no-health-check-endpoint)

---

## Docker Image Overview

The `ghcr.io/ente-io/web` image is a **multi-stage build** that compiles all Ente web apps into static files, then serves them from a single nginx container on 8 different ports. Images are published weekly (every Wednesday).

Source: [`web/Dockerfile`](https://github.com/ente-io/ente/blob/main/web/Dockerfile)

---

## Build Stage: Static Site Generation

**Base image:** `node:22`

The builder stage:

1. **Installs Rust** (needed to compile `ente-wasm`, the WebAssembly crypto bindings from `rust/core/`)
2. **Copies** `web/` and `rust/core/` into the build context
3. **Injects placeholder strings** as `NEXT_PUBLIC_*` environment variables:

   ```
   NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER
   NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=ENTE_ALBUMS_ORIGIN_PLACEHOLDER
   NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT=ENTE_PHOTOS_ORIGIN_PLACEHOLDER
   ```

   Since Next.js inlines `NEXT_PUBLIC_*` values at build time, these literal placeholder strings are baked into the compiled JavaScript bundles.
4. **Builds 7 apps** sequentially via `yarn build:<app>`:
   - photos, accounts, auth, cast, share, embed, paste
5. **Outputs static files** to `apps/<name>/out/` for each app

All apps are built as Next.js static exports (`output: 'export'`), producing plain HTML/CSS/JS with no server-side rendering.

---

## Runtime Stage: nginx Entrypoint

**Base image:** `nginx` (official)

The official nginx Docker image has a built-in entrypoint at `/docker-entrypoint.sh` that:

1. Scans `/docker-entrypoint.d/` for scripts (sorted alphabetically)
2. Executes each `.sh` file found
3. Starts nginx in the foreground as PID 1

### Full Startup Sequence

```
Container starts
  |
  v
/docker-entrypoint.sh (nginx built-in ENTRYPOINT)
  |
  +--> /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh   [nginx default]
  +--> /docker-entrypoint.d/15-local-resolvers.envsh           [nginx default]
  +--> /docker-entrypoint.d/20-envsubst-on-templates.sh        [nginx default]
  +--> /docker-entrypoint.d/30-tune-worker-processes.sh        [nginx default]
  +--> /docker-entrypoint.d/90-replace-ente-env.sh             [CUSTOM - see below]
  |
  v
nginx starts (foreground, PID 1)
  - Master process spawns worker processes
  - All 8 server blocks listen on their respective ports
  - Single process tree serves all apps
```

There is **one nginx process** serving **all 8 apps**. There is no process manager (supervisord, s6, etc.) — nginx is the only process in the container.

---

## Environment Variable Substitution

The custom script `/docker-entrypoint.d/90-replace-ente-env.sh` performs runtime string replacement on the pre-built JavaScript bundles using `sed`:

```bash
# Replace API origin in ALL apps
find /out -name '*.js' |
    xargs sed -i'' "s#ENTE_API_ORIGIN_PLACEHOLDER#$ENTE_API_ORIGIN#g"

# Replace albums/photos origins in photos app ONLY
find /out/photos -name '*.js' |
    xargs sed -i'' "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#$ENTE_ALBUMS_ORIGIN#g"
find /out/photos -name '*.js' |
    xargs sed -i'' "s#ENTE_PHOTOS_ORIGIN_PLACEHOLDER#$ENTE_PHOTOS_ORIGIN#g"
```

### Available Environment Variables

| Env Var | Default | Scope | Purpose |
|---------|---------|-------|---------|
| `ENTE_API_ORIGIN` | `http://localhost:8080` | All apps (`/out/**/*.js`) | Museum API server endpoint |
| `ENTE_ALBUMS_ORIGIN` | `https://localhost:3002` | Photos only (`/out/photos/**/*.js`) | External URL where albums app is hosted |
| `ENTE_PHOTOS_ORIGIN` | `https://localhost:3000` | Photos only (`/out/photos/**/*.js`) | External URL where photos app is hosted (for join-album links) |

### Why This Pattern Exists

Next.js `NEXT_PUBLIC_*` variables are inlined at **build time**, not runtime. To allow a single Docker image to be configured for different environments, the build bakes in placeholder strings, and the entrypoint script replaces them with actual values from environment variables before nginx starts serving the files.

This replacement happens **once** at container startup. Changing env vars after the container is running requires a restart.

---

## nginx Server Blocks & Port Map

The Dockerfile writes an inline nginx config to `/etc/nginx/conf.d/default.conf` with 8 server blocks:

| Port | App | Document Root | Notes |
|------|-----|---------------|-------|
| 3000 | Photos | `/out/photos` | Main photo management app |
| 3001 | Accounts | `/out/accounts` | Passkey/account management |
| 3002 | Albums | `/out/photos` | **Same files as Photos** (port determines mode) |
| 3003 | Auth | `/out/auth` | 2FA authentication app |
| 3004 | Cast | `/out/cast` | Chromecast/browser casting |
| 3005 | Share | `/out/share` | Public sharing (Locker) |
| 3006 | Embed | `/out/embed` | Embeddable photo viewer |
| 3008 | Paste | `/out/paste` | Text/file paste sharing |

All server blocks use the same SPA routing rule:

```nginx
location / { try_files $uri $uri.html /index.html; }
```

### Important Details

- **Albums and Photos share the same static files** (`/out/photos`). The app uses the serving port/URL to determine which UI mode to render.
- **Port 3007 does not exist.** The numbering skips from 3006 (embed) to 3008 (paste).
- **Apps not included in the image:** locker, memories, ensu, twoof3 (not built in the Dockerfile).

---

## Helm Chart Deployment Model

This chart deploys **separate Kubernetes Deployments** for each frontend app, all using the same `ghcr.io/ente-io/web` Docker image:

```
                         ghcr.io/ente-io/web (same image)
                        /        |        |        \
                       /         |        |         \
               +-----------+ +-------+ +--------+ +-------+
               | ente-photos| |ente-auth| |ente-accounts| | ... |
               | Deployment | |Deployment| |Deployment  | |     |
               +-----------+ +-------+ +--------+ +-------+
                    |            |          |          |
               +-----------+ +-------+ +--------+ +-------+
               | Service   | |Service| |Service | |Service|
               | port:3000 | |p:3003 | |p:3001  | |  ...  |
               +-----------+ +-------+ +--------+ +-------+
                    |            |          |          |
               +-----------+ +-------+ +--------+ +-------+
               | Ingress   | |Ingress| |Ingress | |Ingress|
               | photos.x  | |auth.x | |accts.x | |  ...  |
               +-----------+ +-------+ +--------+ +-------+
```

### How It Works

1. **Every pod runs all 8 nginx server blocks** — even though each Kubernetes Service only routes to one port. The other 7 ports are listening but receive no traffic.
2. **The `sed` replacement runs in every pod** — the shared env vars (`ENTE_API_ORIGIN`, etc.) are substituted at container startup in every replica of every Deployment.
3. **Each Service targets a single container port**, routing external traffic to just one of the 8 apps.

### Enabled Services (default)

| Service | Enabled | Service Port | Container Port |
|---------|---------|-------------|----------------|
| photos | yes | 3000 | 3000 |
| accounts | yes | 3001 | 3001 |
| auth | yes | 3003 | 3003 |
| share | yes | 3005 | 3005 |
| embed | yes | 3006 | 3006 |
| cast | no | 3004 | 3004 |
| memories | no | 3007 | 3007 | not in Docker image — requires custom build, see [Memories App](#memories-app) |
| paste | no | 3008 | 3008 |

---

## Environment Variable Flow

Environment variables flow through two separate systems — one for the **frontend apps** (nginx/JS) and one for the **Museum backend** (Go API server):

### Frontend (Web Apps)

```
values.yaml                    Container Startup              Browser
+-----------------------+      +-------------------------+    +------------------+
| sharedConfig.env:     |      | 90-replace-ente-env.sh  |    | JS app reads     |
|   ENTE_API_ORIGIN     | ---> | sed replaces in *.js:   | -> | window.__NEXT_   |
|   ENTE_ALBUMS_ORIGIN  |      |   PLACEHOLDER -> value  |    | or inline config |
|   ENTE_PHOTOS_ORIGIN  |      +-------------------------+    +------------------+
+-----------------------+
```

Configure these in `sharedConfig.env` (applied to all frontend Deployments):

```yaml
sharedConfig:
  env:
    - name: ENTE_API_ORIGIN
      value: "https://api.example.com"
    - name: ENTE_ALBUMS_ORIGIN
      value: "https://albums.example.com"
    - name: ENTE_PHOTOS_ORIGIN
      value: "https://photos.example.com"
```

### Museum (Backend API)

The Museum server needs to know where the frontend apps are hosted so it can generate correct URLs in emails, redirects, etc. These are separate configuration keys:

| Museum Env Var | Purpose | Example |
|---------------|---------|---------|
| `ENTE_APPS_PUBLIC_ALBUMS` | Albums app URL (for shared album links in emails) | `https://albums.example.com` |
| `ENTE_APPS_EMBED_ALBUMS` | Embed app URL | `https://embed.example.com` |
| `ENTE_APPS_PUBLIC_LOCKER` | Share/Locker app URL | `https://share.example.com` |
| `ENTE_APPS_ACCOUNTS` | Accounts app URL (passkey redirects) | `https://accounts.example.com` |
| `ENTE_APPS_CAST` | Cast app URL | `https://cast.example.com` |
| `ENTE_APPS_PUBLIC_PASTE` | Paste app URL | `https://paste.example.com` |
| `ENTE_APPS_PUBLIC_MEMORIES` | Memories app URL | `https://memories.example.com` |
| `ENTE_APPS_FAMILY` | Family plan management URL | `https://family.example.com` |

These go in `museum.env` in your values file, **not** in `sharedConfig.env`.

---

## Museum App Endpoint Configuration

Museum configuration keys follow a naming convention where dots become underscores with an `ENTE_` prefix:

```
Config key:  apps.public-albums
Env var:     ENTE_APPS_PUBLIC_ALBUMS
```

For a complete self-hosted deployment, you need **both sides configured consistently**:

| What | Frontend Env Var | Museum Env Var | Must Match? |
|------|-----------------|----------------|-------------|
| API server | `ENTE_API_ORIGIN` | N/A (it IS the API) | N/A |
| Albums/Photos app | `ENTE_ALBUMS_ORIGIN` | `ENTE_APPS_PUBLIC_ALBUMS` | Yes |
| Photos app | `ENTE_PHOTOS_ORIGIN` | N/A | No direct counterpart |
| Accounts app | N/A | `ENTE_APPS_ACCOUNTS` | N/A |
| Embed app | N/A | `ENTE_APPS_EMBED_ALBUMS` | N/A |
| Share app | N/A | `ENTE_APPS_PUBLIC_LOCKER` | N/A |
| Cast app | N/A | `ENTE_APPS_CAST` | N/A |

---

## Memories App

The memories app is a special case — it exists in the monorepo with full build scripts and backend API support, but is **not included in the standard Docker image**.

### What It Is

A standalone Next.js app for viewing **shareable photo memories** — curated slideshows with end-to-end encryption and a 7-day automatic expiry. It runs on **port 3010** in development (`yarn dev:memories`).

It supports two viewer modes:

- **"share"** — user-curated selections of specific photos
- **"lane"** — auto-generated memory lanes with face crops, temporal grouping, and a 3D stacked card effect

### How It Works

1. A user creates a memory share from the Photos mobile/web app
2. Museum stores encrypted metadata and file keys in the `memory_shares` / `memory_share_files` tables
3. A public URL is generated: `https://memories.example.com/{accessToken}#shareKey`
4. The memories web app loads, fetches data via public Museum API endpoints, and decrypts client-side using the share key from the URL hash fragment
5. No account is needed to view — the access token + hash key are sufficient
6. Shares auto-expire after **7 days**

### Server-Side Support (Museum)

Museum has full API support for memories regardless of whether the web app is deployed:

| Endpoint | Purpose |
|----------|---------|
| `/public-memory/info` | Fetch share metadata (encrypted) |
| `/public-memory/files` | List files in a memory share |
| `/public-memory/files/{fileID}/thumbnail` | Fetch encrypted thumbnail |
| `/public-memory/files/{fileID}/file` | Fetch encrypted full file |

Authentication is via `X-Auth-Access-Token` header (the token from the share URL).

Museum reads the `apps.public-memories` config key (env var: `ENTE_APPS_PUBLIC_MEMORIES`, defaults to `https://memories.ente.io`) to construct share URLs included in notifications. If you don't deploy memories, these URLs will be dead links.

### Status in the Docker Image

**Not included.** The `ghcr.io/ente-io/web` Dockerfile builds 7 apps (photos, accounts, auth, cast, share, embed, paste) but skips memories. There is:

- No `yarn build:memories` step in the Dockerfile
- No `/out/memories` directory in the image
- No nginx server block listening for memories
- No port allocation (the dev port 3010 is not used)

A `yarn build:memories` script **does exist** in `web/package.json`, so a custom image could include it.

### Status in This Helm Chart

The chart defines a `memories` service (disabled by default) with **port 3010**. Since the Docker image doesn't include the memories app or an nginx server block for it, enabling this service requires a custom image. See below.

### Deploying Memories Self-Hosted

To actually deploy memories, you would need to either:

1. **Build a custom Docker image** — add `RUN yarn build:memories` to the Dockerfile, copy `/out/memories` into the runtime stage, and add an nginx server block on port 3010 (or any free port)
2. **Deploy separately** — build `yarn build:memories` in CI, serve the static output from its own container (any static file server works), and configure `ENTE_APPS_PUBLIC_MEMORIES` on Museum to point to it

In either case, the memories app needs `ENTE_API_ORIGIN` set so it can reach the Museum API for fetching encrypted share data.

**Mobile integration:** Both iOS and Android have home screen widgets that display memories with deeplinks back into the photos app. These work independently of the web app — they use the native Museum API directly.

---

## Known Issues & Gotchas

### 1. Embed Port Mismatch

The Dockerfile serves embed on **port 3006**, but `values.yaml` configures the embed service with port **3005**. This means the embed Service routes to a port where the share app is listening, not embed.

**Fix:** Change embed's ports in `values.yaml` to 3006:

```yaml
embed:
  service:
    port: 3006
    targetPort: 3006
```

### 2. Every Pod Runs All Apps

Each pod in every frontend Deployment runs all 8 nginx server blocks. Only one port is actually routed to via the Kubernetes Service. This is a minor inefficiency but functionally harmless — nginx idle listeners consume negligible resources.

**Alternative architecture:** Deploy a single Deployment with one pod, and create 8 separate Services each targeting a different port. This would reduce total pod count but sacrifices per-app scaling and fault isolation.

### 3. Environment Substitution is One-Shot

The `sed` replacement in `90-replace-ente-env.sh` runs once at container startup. Changing environment variables on a running pod (e.g., via `kubectl set env`) has **no effect** — the JS files were already modified. You must restart the pod.

### 4. Albums and Photos Are the Same Build

Port 3002 (Albums) and port 3000 (Photos) serve identical static files from `/out/photos`. The app determines its mode from the URL it's being served at. If you're exposing Albums, your `ENTE_ALBUMS_ORIGIN` must point to whatever hostname resolves to port 3002.

### 5. Missing Apps in the Docker Image

The Docker image does **not** include builds for: locker, memories, ensu, or twoof3. There are no nginx server blocks or document roots for these apps. If a chart service targets a port that happens to serve a different app (e.g., port 3000 = photos), you'll silently get the wrong app. See the [Memories App](#memories-app) section for details on that specific case.

### 6. No Health Check Endpoint

The frontend nginx container has no dedicated health check path. Kubernetes probes should use a simple TCP check on the service port or an HTTP GET on `/` (which will return the SPA's `index.html` with a 200).
