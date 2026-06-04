{{/*
Common labels applied to the ACK Alias resource.
*/}}
{{- define "aws-kms-alias.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
