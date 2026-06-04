{{/*
Common labels applied to the ACK WorkGroup resource.
*/}}
{{- define "aws-athena-workgroup.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
