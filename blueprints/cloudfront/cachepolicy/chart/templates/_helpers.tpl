{{/*
Common labels applied to the ACK CachePolicy resource.
*/}}
{{- define "aws-cloudfront-cachepolicy.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
