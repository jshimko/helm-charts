{{/*
Expand the name of the chart.
*/}}
{{- define "svix.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "svix.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "svix.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "svix.labels" -}}
helm.sh/chart: {{ include "svix.chart" . }}
{{ include "svix.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "svix.selectorLabels" -}}
app.kubernetes.io/name: "svix-server"
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common postgres/redis env
*/}}
{{- define "svix.dbEnv" -}}
# postgres
{{- if or .Values.postgrescluster.enabled .Values.svix.postgresClusterSecret }}
- name: SVIX_DB_DSN
  valueFrom:
    secretKeyRef:
      {{- if .Values.svix.postgresClusterSecret }}
      name: "{{ .Values.svix.postgresClusterSecret }}"
      {{- else }}
      name: "{{ .Values.postgrescluster.name }}-pguser-svix"
      {{- end }}
      key: "pgbouncer-uri"
{{- end }}

# redis
{{- if .Values.redis.enabled  }}
- name: SVIX_REDIS_DSN
  value: "redis://{{ .Values.redis.fullnameOverride }}-master:6379"
- name: SVIX_QUEUE_DSN
  value: "$(SVIX_REDIS_DSN)"
- name: SVIX_CACHE_DSN
  value: "$(SVIX_REDIS_DSN)"
{{- end }}
{{- end }}
