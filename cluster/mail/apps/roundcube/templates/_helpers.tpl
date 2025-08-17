{{/*
Expand the name of the chart.
*/}}
{{- define "roundcube.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "roundcube.fullname" -}}
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
{{- define "roundcube.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "roundcube.labels" -}}
helm.sh/chart: {{ include "roundcube.chart" . }}
{{ include "roundcube.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "roundcube.selectorLabels" -}}
app.kubernetes.io/name: {{ include "roundcube.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "roundcube.serviceAccountName" -}}
{{- if .Values.roundcube.serviceAccount.create }}
{{- default (include "roundcube.fullname" .) .Values.roundcube.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.roundcube.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get enabled plugins
*/}}
{{- define "roundcube.enabledPlugins" -}}
{{- $enabledPlugins := list -}}
{{- range $pluginName, $pluginConfig := .Values.roundcube.config.plugins -}}
{{- if $pluginConfig.enabled -}}
{{- $enabledPlugins = append $enabledPlugins $pluginName -}}
{{- end -}}
{{- end -}}
{{- if not $enabledPlugins -}}
{{- $enabledPlugins = list "archive" "zipdownload" "newmail_notifier" -}}
{{- end -}}
{{- join "," $enabledPlugins -}}
{{- end }}
