{{/*
Common labels applied to the ACK Cluster resource.
*/}}
{{- define "aws-memorydb-cluster.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
