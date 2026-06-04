{{/*
Common labels applied to the ACK VirtualCluster resource.
*/}}
{{- define "aws-emrcontainers-virtualcluster.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
