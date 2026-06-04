{{/*
Common labels applied to the ACK SubnetGroup resource.
*/}}
{{- define "aws-memorydb-subnetgroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
