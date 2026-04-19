{{/*
Common labels
*/}}
{{- define "roboshop.labels" -}}
project: roboshop
tier: backend
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "roboshop.selectorLabels" -}}
project: roboshop
tier: backend
{{- end }}
