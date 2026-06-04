{{/*
Common labels applied to the ACK DBSubnetGroup resource.
*/}}
{{- define "aws-rds-dbsubnetgroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
