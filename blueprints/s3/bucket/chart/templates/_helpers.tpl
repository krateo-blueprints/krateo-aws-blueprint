{{/*
Common labels applied to the ACK Bucket resource.
*/}}
{{- define "aws-s3-bucket.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
