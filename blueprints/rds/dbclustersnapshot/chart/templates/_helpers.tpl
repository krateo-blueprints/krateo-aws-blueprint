{{/*
Common labels applied to the ACK DBClusterSnapshot resource.
*/}}
{{- define "aws-rds-dbclustersnapshot.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
