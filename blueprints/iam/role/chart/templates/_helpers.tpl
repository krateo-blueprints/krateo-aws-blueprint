{{/*
Common labels applied to the ACK Role resource.
*/}}
{{- define "aws-iam-role.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
