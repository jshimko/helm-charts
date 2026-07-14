####################

{{/*
Build list of enabled frontend web services. This is used to generate templates for each of the frontend web services.
See ./templates/frontend-services/*.md
*/}}
{{- define "services.frontendServices" -}}
{{- $services := list -}}
{{- if .Values.accounts.enabled -}}
{{- $services = append $services "accounts" -}}
{{- end -}}
{{- if .Values.auth.enabled -}}
{{- $services = append $services "auth" -}}
{{- end -}}
{{- if .Values.cast.enabled -}}
{{- $services = append $services "cast" -}}
{{- end -}}
{{- if .Values.photos.enabled -}}
{{- $services = append $services "photos" -}}
{{- end -}}
{{- if .Values.share.enabled -}}
{{- $services = append $services "share" -}}
{{- end -}}
{{- if .Values.memories.enabled -}}
{{- $services = append $services "memories" -}}
{{- end -}}
{{- if .Values.embed.enabled -}}
{{- $services = append $services "embed" -}}
{{- end -}}
{{- if .Values.paste.enabled -}}
{{- $services = append $services "paste" -}}
{{- end -}}
{{- $services | toJson -}}
{{- end -}}

{{/*
Create frontend service name
*/}}
{{- define "services.frontendServiceName" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{- $serviceConfig := index $context.Values $serviceName -}}
{{- if $serviceConfig.fullnameOverride -}}
{{- $serviceConfig.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else if $serviceConfig.nameOverride -}}
{{- printf "%s-%s" $context.Release.Name $serviceConfig.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" $serviceName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create frontend service labels
*/}}
{{- define "services.frontendServiceLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{ include "services.frontendServiceSelectorLabels" . }}
{{- if $context.Chart.AppVersion }}
app.kubernetes.io/version: {{ $context.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $context.Release.Service }}
helm.sh/chart: {{ include "ente-photos.chart" $context }}
{{- with $context.Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Create frontend service selector labels
*/}}
{{- define "services.frontendServiceSelectorLabels" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
app.kubernetes.io/name: "ente-{{ include "services.frontendServiceName" (dict "serviceName" $serviceName "context" $context) }}"
app.kubernetes.io/instance: {{ $context.Release.Name }}
app.kubernetes.io/component: {{ $serviceName }}
{{- end -}}

{{/*
Create frontend service account name
*/}}
{{- define "services.frontendServiceAccountName" -}}
{{- $serviceName := .serviceName -}}
{{- $context := .context -}}
{{- $serviceConfig := index $context.Values $serviceName -}}
{{- if $serviceConfig.serviceAccount.create -}}
{{- default (printf "ente-%s" (include "services.frontendServiceName" (dict "serviceName" $serviceName "context" $context))) $serviceConfig.serviceAccount.name -}}
{{- else -}}
{{- default "default" $serviceConfig.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Generate shared environment variables for all services services
This helper generates common environment variables that should be available
to all frontend services.
*/}}
{{- define "services.sharedEnv" -}}
{{- $context := . -}}

{{- if $context.Values.sharedConfig -}}
{{- with  $context.Values.sharedConfig.env -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "services.sharedEnvFrom" -}}
{{- $context := . -}}
{{- if $context.Values.sharedConfig -}}
{{- with  $context.Values.sharedConfig.envFrom -}}
{{- toYaml . -}}
{{- end -}}
{{- end -}}
{{- end -}}
