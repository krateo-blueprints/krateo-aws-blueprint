{{/*
Common labels applied to the ACK DataSource resource.
*/}}
{{- define "aws-quicksight-datasource.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
