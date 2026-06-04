{{/*
Common labels applied to the ACK Permission resource.
*/}}
{{- define "aws-ram-permission.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
