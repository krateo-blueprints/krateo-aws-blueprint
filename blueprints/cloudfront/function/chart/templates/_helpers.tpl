{{/*
Common labels applied to the ACK Function resource.
*/}}
{{- define "aws-cloudfront-function.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
