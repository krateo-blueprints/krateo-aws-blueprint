{{/*
Common labels applied to the ACK BackupVault resource.
*/}}
{{- define "aws-backup-backupvault.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
