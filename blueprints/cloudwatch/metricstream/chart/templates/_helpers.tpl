{{/*
Common labels applied to the ACK MetricStream resource.
*/}}
{{- define "aws-cloudwatch-metricstream.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
