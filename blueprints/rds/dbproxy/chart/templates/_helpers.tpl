{{/*
Common labels applied to the ACK DBProxy resource.
*/}}
{{- define "aws-rds-dbproxy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
