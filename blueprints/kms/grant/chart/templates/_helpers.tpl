{{/*
Common labels applied to the ACK Grant resource.
*/}}
{{- define "aws-kms-grant.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
