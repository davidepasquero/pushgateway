{{/*
Expand the name of the chart.
*/}}
{{- define "harvester-pusher-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "harvester-pusher-chart.fullname" -}}
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
Create chart-level resource labels to be applied to every resource that comes from this chart.
*/}}
{{- define "harvester-pusher-chart.labels" -}}
helm.sh/chart: {{ include "harvester-pusher-chart.name" . }}-{{ .Chart.Version }}
{{ include "harvester-pusher-chart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels that will be used to select resources.
*/}}
{{- define "harvester-pusher-chart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "harvester-pusher-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "harvester-pusher-chart.secretName" -}}
{{- if .Values.secret.create -}}
{{- include "harvester-pusher-chart.fullname" . }}
{{- else -}}
{{- .Values.secret.existingSecretName | required "A name for an existing secret must be provided if secret.create is false" -}}
{{- end -}}
{{- end -}}