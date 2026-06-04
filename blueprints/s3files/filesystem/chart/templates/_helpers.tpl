{{/*
Common labels applied to the ACK FileSystem resource.
*/}}
{{- define "aws-s3files-filesystem.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
