{{/*
Common labels applied to the ACK Archive resource.
*/}}
{{- define "aws-eventbridge-archive.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
