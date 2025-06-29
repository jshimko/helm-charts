{{/*
Expand the name of the chart.
*/}}
{{- define "hatchet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hatchet.fullname" -}}
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
{{- define "hatchet.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Global labels
*/}}
{{- define "hatchet.labels" -}}
helm.sh/chart: {{ include "hatchet.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "hatchet.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hatchet.name" . }}-frontend
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "hatchet.frontend.labels" -}}
{{ include "hatchet.frontend.selectorLabels" . }}
{{ include "hatchet.labels" . }}
{{- end }}

####################

{{/*
Get list of enabled backend services
*/}}
{{- define "hatchet.backendServices" -}}
{{- $services := list -}}
{{- if .Values.api.enabled -}}
{{- $services = append $services "api" -}}
{{- end -}}
{{- if .Values.grpc.enabled -}}
{{- $services = append $services "grpc" -}}
{{- end -}}
{{- if .Values.controller.enabled -}}
{{- $services = append $services "controller" -}}
{{- end -}}
{{- if .Values.scheduler.enabled -}}
{{- $services = append $services "scheduler" -}}
{{- end -}}
{{- $services -}}
{{- end -}}

{{/*
Create backend service name
*/}}
{{- define "hatchet.backendServiceName" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{- $serviceConfig := index $context.Values $serviceName -}}
{{- if $serviceConfig.fullnameOverride -}}
{{- $serviceConfig.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if $serviceConfig.nameOverride -}}
{{- printf "%s-%s" $context.Release.Name $serviceConfig.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" $context.Release.Name $serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create backend service labels
*/}}
{{- define "hatchet.backendServiceLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{ include "hatchet.labels" $context }}
app.kubernetes.io/name: {{ include "hatchet.backendServiceName" (dict "serviceName" $serviceName "context" $context) }}
app.kubernetes.io/component: {{ $serviceName }}
{{- end -}}

{{/*
Create backend service selector labels
*/}}
{{- define "hatchet.backendServiceSelectorLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
app.kubernetes.io/name: {{ include "hatchet.backendServiceName" (dict "serviceName" $serviceName "context" $context) }}
app.kubernetes.io/instance: {{ $context.Release.Name }}
app.kubernetes.io/component: {{ $serviceName }}
{{- end -}}

{{/*
Create backend service account name
*/}}
{{- define "hatchet.backendServiceAccountName" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{- $serviceConfig := index $context.Values $serviceName -}}
{{- if $serviceConfig.serviceAccount.create -}}
{{- default (include "hatchet.backendServiceName" (dict "serviceName" $serviceName "context" $context)) $serviceConfig.serviceAccount.name -}}
{{- else -}}
{{- default "default" $serviceConfig.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Generate shared environment variables for all Hatchet services
This helper generates common environment variables that should be available
to all backend services and jobs, including database connections, GRPC settings,
and other shared configuration.
*/}}
{{- define "hatchet.sharedEnv" -}}
{{- $context := . -}}

{{- with  $context.Values.sharedConfig.env -}}
{{- toYaml . -}}
{{- end -}}

{{- if $context.Values.postgrescluster.enabled }}
- name: PGBOUNCER_URI
  valueFrom:
    secretKeyRef:
      name: "postgres-hatchet-pguser-hatchet"
      key: "pgbouncer-uri"
# append sslmode=require to the pgbouncer URI
- name: DATABASE_URL
  value: "$(PGBOUNCER_URI)?sslmode=require"
{{- end }}

{{- if $context.Values.rabbitmqcluster.enabled }}
- name: RABBITMQ_USERNAME
  valueFrom:
    secretKeyRef:
      name: "rabbitmq-hatchet-default-user"
      key: "username"
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: "rabbitmq-hatchet-default-user"
      key: "password"
- name: RABBITMQ_HOST
  valueFrom:
    secretKeyRef:
      name: "rabbitmq-hatchet-default-user"
      key: "host"
- name: RABBITMQ_PORT
  valueFrom:
    secretKeyRef:
      name: "rabbitmq-hatchet-default-user"
      key: "port"
# build URL from username, password, host, and port above
- name: SERVER_TASKQUEUE_RABBITMQ_URL
  value: "amqp://$(RABBITMQ_USERNAME):$(RABBITMQ_PASSWORD)@$(RABBITMQ_HOST):$(RABBITMQ_PORT)/"
{{- end }}

{{- if $context.Values.postgres.enabled }}
- name: DATABASE_URL
  value: {{ printf "postgres://%s:%s@%s-postgres:%d/%s?sslmode=%s" $context.Values.postgres.auth.username $context.Values.postgres.auth.password $context.Release.Name ($context.Values.postgres.primary.service.ports.postgresql | int) $context.Values.postgres.auth.database (ternary "require" "disable" $context.Values.postgres.tls.enabled) }}
- name: DATABASE_POSTGRES_HOST
  value: {{ printf "%s-postgres" $context.Release.Name }}
- name: DATABASE_POSTGRES_PORT
  value: {{ $context.Values.postgres.primary.service.ports.postgresql | quote }}
- name: DATABASE_POSTGRES_USERNAME
  value: {{ $context.Values.postgres.auth.username | quote }}
- name: DATABASE_POSTGRES_PASSWORD
  value: {{ $context.Values.postgres.auth.password | quote }}
- name: DATABASE_POSTGRES_DATABASE
  value: {{ $context.Values.postgres.auth.database | quote }}
{{- end }}

{{- if $context.Values.rabbitmq.enabled }}
- name: SERVER_TASKQUEUE_RABBITMQ_URL
  value: {{ printf "amqp://%s:%s@%s-rabbitmq:%d/" $context.Values.rabbitmq.auth.username $context.Values.rabbitmq.auth.password $context.Release.Name ($context.Values.rabbitmq.service.ports.amqp | int) }}
- name: SERVER_TASKQUEUE_RABBITMQ_HOST
  value: {{ printf "%s-rabbitmq" $context.Release.Name }}
- name: SERVER_TASKQUEUE_RABBITMQ_PORT
  value: {{ $context.Values.rabbitmq.service.ports.amqp | quote }}
- name: SERVER_TASKQUEUE_RABBITMQ_USERNAME
  value: {{ $context.Values.rabbitmq.auth.username | quote }}
- name: SERVER_TASKQUEUE_RABBITMQ_PASSWORD
  value: {{ $context.Values.rabbitmq.auth.password | quote }}
{{- end }}
{{- end -}}

{{- define "hatchet.sharedEnvFrom" -}}
{{- $context := . -}}
{{- with  $context.Values.sharedConfig.envFrom -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}
