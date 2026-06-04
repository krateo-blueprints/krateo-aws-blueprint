{{/*
Common labels applied to the ACK Group resource.
*/}}
{{- define "aws-iam-group.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
