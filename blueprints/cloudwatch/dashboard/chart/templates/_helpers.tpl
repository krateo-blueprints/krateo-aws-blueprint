{{/*
Common labels applied to the ACK Dashboard resource.
*/}}
{{- define "aws-cloudwatch-dashboard.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
