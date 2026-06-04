{{/*
Common labels applied to the ACK Configuration resource.
*/}}
{{- define "aws-kafka-configuration.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: krateo-aws-blueprint
krateo.io/composition: {{ .Release.Name }}
{{- end -}}
