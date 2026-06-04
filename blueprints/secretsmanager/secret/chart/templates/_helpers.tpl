{{/*
Common labels applied to the ACK Secret resource.
*/}}
{{- define "aws-secretsmanager-secret.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
