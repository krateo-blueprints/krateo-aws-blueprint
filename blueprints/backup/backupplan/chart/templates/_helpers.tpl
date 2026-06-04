{{/*
Common labels applied to the ACK BackupPlan resource.
*/}}
{{- define "aws-backup-backupplan.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
