{{/*
Expand the name of the chart.
*/}}
{{- define "anvil.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully-qualified app name. Used as the prefix for all resource names.
*/}}
{{- define "anvil.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels.
*/}}
{{- define "anvil.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/name: {{ include "anvil.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Per-component selector labels.
*/}}
{{- define "anvil.componentLabels" -}}
app.kubernetes.io/name: {{ include "anvil.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{/*
Image reference: registry/repo:tag with appVersion fallback.
Pass {{ include "anvil.image" (dict "image" .Values.image.api "default" .Chart.AppVersion) }}
*/}}
{{- define "anvil.image" -}}
{{- $tag := default .default .image.tag -}}
{{- printf "%s:%s" .image.repository $tag -}}
{{- end -}}

{{/*
Backing-service URLs — bundled in-cluster Service, or external override.
*/}}
{{- define "anvil.postgresUrl" -}}
{{- if .Values.postgres.enabled -}}
{{- printf "postgresql://%s:%s@%s-postgres:5432/%s" .Values.postgres.auth.user .Values.postgres.auth.password (include "anvil.fullname" .) .Values.postgres.auth.database -}}
{{- else -}}
{{- required "postgres.external.url is required when postgres.enabled is false" .Values.postgres.external.url -}}
{{- end -}}
{{- end -}}

{{- define "anvil.redisUrl" -}}
{{- if .Values.redis.enabled -}}
{{- printf "redis://%s-redis:6379" (include "anvil.fullname" .) -}}
{{- else -}}
{{- required "redis.external.url is required when redis.enabled is false" .Values.redis.external.url -}}
{{- end -}}
{{- end -}}

{{- define "anvil.influxdbUrl" -}}
{{- if .Values.influxdb.enabled -}}
{{- printf "http://%s-influxdb:8086/%s" (include "anvil.fullname" .) .Values.influxdb.database -}}
{{- else -}}
{{- required "influxdb.external.url is required when influxdb.enabled is false" .Values.influxdb.external.url -}}
{{- end -}}
{{- end -}}

{{/*
Grafana base URL the API uses for deep-links. The browser hits this URL, so
it MUST be reachable from the user's machine — never an in-cluster Service.
Resolution order:
  1. external.baseUrl set                       → use it
  2. grafana.baseUrl set                        → use it
  3. bundled grafana with ingress enabled       → derive from ingress host
                                                  (https if tls, http otherwise)
  4. otherwise                                  → empty string; the API hides
                                                  the "Open in Grafana" button
*/}}
{{- define "anvil.grafanaBaseUrl" -}}
{{- if .Values.grafana.external.baseUrl -}}
{{- .Values.grafana.external.baseUrl -}}
{{- else if .Values.grafana.baseUrl -}}
{{- .Values.grafana.baseUrl -}}
{{- else if and .Values.grafana.enabled .Values.grafana.ingress.enabled (gt (len .Values.grafana.ingress.hosts) 0) -}}
{{- $scheme := "http" -}}
{{- if gt (len .Values.grafana.ingress.tls) 0 -}}
{{- $scheme = "https" -}}
{{- end -}}
{{- printf "%s://%s" $scheme (index .Values.grafana.ingress.hosts 0).host -}}
{{- end -}}
{{- end -}}
