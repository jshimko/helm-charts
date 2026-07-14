{{/*
Helper functions for the Inngest Helm chart
These functions generate consistent names, labels, and configuration values
used throughout the chart templates.
*/}}

{{/*
Expand the name of the chart.
Returns the chart name, truncated to 63 characters (Kubernetes limit).
Used for consistent labeling across resources.
*/}}
{{- define "inngest.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
The main Inngest application is always named "inngest" regardless of release name.
This ensures consistent resource naming across different Helm releases, making
scripts and documentation predictable across environments.

Example: Whether you run 'helm install my-prod .' or 'helm install dev .',
the deployment will always be named 'inngest'.
*/}}
{{- define "inngest.fullname" -}}
inngest
{{- end }}

{{/*
Create chart name and version as used by the chart label.
Formats the chart name and version for use in Kubernetes labels.
Replaces '+' with '_' for label compatibility.
*/}}
{{- define "inngest.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to all resources.
These labels provide metadata about the chart, version, and management.
Used for resource identification, monitoring, and operational queries.
*/}}
{{- define "inngest.labels" -}}
helm.sh/chart: {{ include "inngest.chart" . }}
{{ include "inngest.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels used for pod/service matching.
These labels are used by Services to select Pods and should remain stable
across chart upgrades to maintain service connectivity.
*/}}
{{- define "inngest.selectorLabels" -}}
app.kubernetes.io/name: {{ include "inngest.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use.
If serviceAccount.create is true, creates a service account with the specified name.
If no name is specified, uses the fullname template.
If serviceAccount.create is false, uses the specified name or "default".
*/}}
{{- define "inngest.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "inngest.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
