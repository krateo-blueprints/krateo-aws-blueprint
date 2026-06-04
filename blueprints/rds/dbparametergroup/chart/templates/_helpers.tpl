{{/*
Common labels applied to the ACK DBParameterGroup resource.
*/}}
{{- define "aws-rds-dbparametergroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
