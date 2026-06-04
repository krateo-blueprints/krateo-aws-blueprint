{{/*
Common labels applied to the ACK ReplicationGroup resource.
*/}}
{{- define "aws-elasticache-replicationgroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
