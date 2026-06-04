{{/*
Common labels applied to the ACK User resource.
*/}}
{{- define "aws-iam-user.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
