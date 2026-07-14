{{/*
Expand the name of the chart.
*/}}
{{- define "ente-photos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ente-photos.fullname" -}}
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
{{- define "ente-photos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ente-photos.labels" -}}
{{ include "ente-photos.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "ente-photos.chart" . }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ente-photos.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ente-photos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Museum labels
*/}}
{{- define "ente-photos.museum.labels" -}}
{{ include "ente-photos.labels" . }}
app.kubernetes.io/component: museum
{{- end }}

{{/*
Museum selector labels
*/}}
{{- define "ente-photos.museum.selectorLabels" -}}
{{ include "ente-photos.selectorLabels" . }}
app.kubernetes.io/component: museum
{{- end }}

{{/*
Museum fullname
*/}}
{{- define "ente-photos.museum.fullname" -}}
{{- printf "%s-museum" (include "ente-photos.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate random string for secrets
*/}}
{{- define "ente-photos.randomString" -}}
{{- randAlphaNum 32 }}
{{- end }}
