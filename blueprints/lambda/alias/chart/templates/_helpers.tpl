{{/*
Common labels applied to the ACK Alias resource.
*/}}
{{- define "aws-lambda-alias.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
