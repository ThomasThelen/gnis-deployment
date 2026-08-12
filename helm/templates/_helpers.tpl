{{/*
Expand the name of the chart.
*/}}
{{- define "gnis.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "gnis.fullname" -}}
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
Chart name and version as used by the chart label.
*/}}
{{- define "gnis.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gnis.labels" -}}
helm.sh/chart: {{ include "gnis.chart" . }}
{{ include "gnis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gnis.selectorLabels" -}}
app: {{ include "gnis.name" . }}
app.kubernetes.io/name: {{ include "gnis.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the PVC to mount: an existing claim if configured, otherwise the
chart-managed claim.
*/}}
{{- define "gnis.pvcName" -}}
{{- default (include "gnis.fullname" .) .Values.persistence.existingClaim }}
{{- end }}

{{/*
Render a map of env vars, passing each value through tpl so values.yaml can
reference other chart values.
*/}}
{{- define "gnis.env" -}}
{{- $root := .root }}
{{- range $key, $value := .env }}
- name: {{ $key }}
  value: {{ tpl $value $root | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels for the webapp. Distinct from the GraphDB selector labels so
the GraphDB service never routes to webapp pods.
*/}}
{{- define "gnis.webappSelectorLabels" -}}
app: {{ include "gnis.name" . }}-webapp
app.kubernetes.io/name: {{ include "gnis.name" . }}-webapp
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
