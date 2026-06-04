{{/*
Common labels applied to the ACK GlobalCluster resource.
*/}}
{{- define "aws-rds-globalcluster.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
