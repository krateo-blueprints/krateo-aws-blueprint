{{/*
Common labels applied to the ACK Snapshot resource.
*/}}
{{- define "aws-memorydb-snapshot.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
