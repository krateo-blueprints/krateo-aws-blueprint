{{/*
Common labels applied to the ACK Policy resource.
*/}}
{{- define "aws-iam-policy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
