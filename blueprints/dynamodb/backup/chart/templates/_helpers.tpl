{{/*
Common labels applied to the ACK Backup resource.
*/}}
{{- define "aws-dynamodb-backup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
