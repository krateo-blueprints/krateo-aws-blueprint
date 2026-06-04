{{/*
Common labels applied to the ACK Table resource.
*/}}
{{- define "aws-keyspaces-table.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
