{{/*
Common labels applied to the ACK Keyspace resource.
*/}}
{{- define "aws-keyspaces-keyspace.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
