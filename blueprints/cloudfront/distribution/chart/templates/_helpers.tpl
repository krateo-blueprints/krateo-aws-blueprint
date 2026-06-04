{{/*
Common labels applied to the ACK Distribution resource.
*/}}
{{- define "aws-cloudfront-distribution.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
