{{/*
Common labels applied to the ACK DBCluster resource.
*/}}
{{- define "aws-rds-dbcluster.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
