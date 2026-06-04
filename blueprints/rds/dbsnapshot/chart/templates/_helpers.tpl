{{/*
Common labels applied to the ACK DBSnapshot resource.
*/}}
{{- define "aws-rds-dbsnapshot.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
