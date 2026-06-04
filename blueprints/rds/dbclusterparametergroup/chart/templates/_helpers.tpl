{{/*
Common labels applied to the ACK DBClusterParameterGroup resource.
*/}}
{{- define "aws-rds-dbclusterparametergroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
