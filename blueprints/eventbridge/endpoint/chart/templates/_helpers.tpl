{{/*
Common labels applied to the ACK Endpoint resource.
*/}}
{{- define "aws-eventbridge-endpoint.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
